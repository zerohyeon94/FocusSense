"""
FocusSense CoreML Conversion Script

학습된 PyTorch 모델을 Apple CoreML (.mlpackage) 형식으로 변환합니다.
변환된 모델은 iOS 앱(Xcode)에 직접 통합하여 온디바이스 추론에 사용됩니다.

변환 파이프라인:
    PyTorch checkpoint (.pth)
        ↓ load_checkpoint()
    PyTorch 모델 (eval mode)
        ↓ FocusSenseExportWrapper (dict → tuple 변환)
        ↓ torch.jit.trace() → TorchScript
        ↓ ct.convert() → CoreML mlprogram
        ↓ cto.linear_quantize_weights() → INT8 양자화
    CoreML 모델 (.mlpackage)
        ↓ Xcode 프로젝트에 드래그 앤 드롭

양자화(Quantization) 효과:
    - 모델 크기: FP32 → INT8, 약 4배 감소
    - 추론 속도: Apple Neural Engine(ANE) 활용으로 향상
    - 정밀도: 소폭 감소하지만 실용적 수준 유지

Usage:
    python conversion/convert_to_coreml.py --checkpoint ./checkpoints/best_model.pth --output ./output
    python conversion/convert_to_coreml.py --checkpoint ./checkpoints/drowsiness_default_20260204_163610/best_model.pth --output ./output
"""

import os
import sys
import argparse
from pathlib import Path

import torch
import torch.nn as nn
import numpy as np

# CoreML 최적화 도구 (양자화)
import coremltools.optimize.coreml as cto

# 프로젝트 루트를 sys.path에 추가 (상대 import 허용)
sys.path.append(str(Path(__file__).parent.parent))

try:
    import coremltools as ct
    from coremltools.models.neural_network import quantization_utils
    HAS_COREMLTOOLS = True
except ImportError:
    HAS_COREMLTOOLS = False
    print("Error: coremltools not installed. Run: pip install coremltools")

from models.focus_model import create_model, FocusSenseModel, FocusSenseLite


class FocusSenseExportWrapper(nn.Module):
    """
    CoreML 변환을 위한 PyTorch 모델 래퍼

    문제: CoreML은 Python dict 형태의 출력을 지원하지 않습니다.
    해결: FocusSenseModel의 dict 출력을 tuple로 변환합니다.

    변환 전 (원본 모델 출력):
        {'drowsiness': tensor, 'gaze': tensor, 'face': tensor}

    변환 후 (래퍼 출력):
        (drowsiness_prob, gaze_prob, face_prob)
        - 각각 Softmax 적용된 확률값 (합 = 1)
        - CoreML에서 named output으로 접근 가능

    또한 Softmax를 여기서 적용하므로 CoreML 모델이
    직접 확률값을 반환합니다 (별도 후처리 불필요).

    Args:
        model (nn.Module): 래핑할 FocusSenseModel 또는 FocusSenseLite
    """

    def __init__(self, model: nn.Module):
        super().__init__()
        self.model = model

    def forward(self, x: torch.Tensor):
        """
        Args:
            x (torch.Tensor): 입력 이미지, shape (1, 3, 224, 224)

        Returns:
            tuple: (drowsiness_prob, gaze_prob, face_prob)
                   각각 shape (1, 2)의 Softmax 확률 텐서
        """
        outputs = self.model(x)

        # CoreML은 dictionary output을 지원하지 않으므로 tuple로 변환
        # dim=1: 클래스 차원으로 Softmax 적용 → 확률 분포
        drowsiness = torch.softmax(outputs['drowsiness'], dim=1)
        gaze = torch.softmax(outputs['gaze'], dim=1)
        face = torch.softmax(outputs['face'], dim=1)

        return drowsiness, gaze, face


def load_checkpoint(checkpoint_path: str, model_type: str = 'default') -> nn.Module:
    """
    저장된 체크포인트에서 모델 가중치를 불러옵니다.

    체크포인트 형식:
        - dict 형식: {'model_state_dict': ..., 'epoch': ..., 'best_val_acc': ...}
        - 직접 state_dict: {layer_name: tensor, ...}

    Args:
        checkpoint_path (str): .pth 파일 경로
        model_type (str): 'default' 또는 'lite' (모델 아키텍처 선택)

    Returns:
        nn.Module: eval 모드로 설정된 모델 (gradient 비활성화)
    """
    # pretrained=False: 변환 시에는 ImageNet 가중치 불필요
    model = create_model(model_type, pretrained=False)

    # map_location='cpu': GPU 없는 환경에서도 로드 가능
    checkpoint = torch.load(checkpoint_path, map_location='cpu')

    # 체크포인트 형식에 따라 state_dict 추출
    if 'model_state_dict' in checkpoint:
        # Trainer.save_checkpoint()가 저장한 형식
        model.load_state_dict(checkpoint['model_state_dict'])
    else:
        # state_dict만 직접 저장한 경우
        model.load_state_dict(checkpoint)

    model.eval()  # BatchNorm, Dropout 등 평가 모드로 전환
    print(f"✓ Loaded checkpoint from {checkpoint_path}")

    return model


def convert_to_coreml(
    model: nn.Module,
    output_path: str,
    input_shape: tuple = (1, 3, 224, 224),
    quantize: bool = True,
    quantization_type: str = 'linear',  # 'linear': INT8 / 'lut': 팔레트
) -> str:
    """
    PyTorch 모델을 CoreML 형식으로 변환합니다.

    변환 단계:
        1. FocusSenseExportWrapper 적용 (dict → tuple 출력 변환)
        2. torch.jit.trace()로 TorchScript 변환 (그래프 고정)
        3. ct.convert()로 CoreML mlprogram 변환
        4. 양자화 적용 (선택사항)
        5. .mlpackage로 저장

    입력 전처리 (ct.ImageType):
        - 0~255 픽셀값을 0~1로 정규화 (scale=1/255)
        - ImageNet 통계로 추가 정규화 (bias 파라미터)
        - iOS 앱에서 CVPixelBuffer를 직접 입력으로 사용 가능

    Args:
        model (nn.Module): 변환할 PyTorch 모델
        output_path (str): 출력 .mlpackage 파일 경로
        input_shape (tuple): 입력 shape (batch, C, H, W)
        quantize (bool): 양자화 적용 여부 (True 권장)
        quantization_type (str):
            'linear' → INT8 선형 양자화 (크기 감소 우선)
            'lut'    → Lookup Table 팔레트 양자화 (정밀도 우선)

    Returns:
        str: 저장된 .mlpackage 파일의 절대 경로
    """
    if not HAS_COREMLTOOLS:
        raise RuntimeError("coremltools is required for conversion")

    # dict 출력을 tuple로 변환하는 래퍼 적용
    wrapped_model = FocusSenseExportWrapper(model)
    wrapped_model.eval()

    # 더미 입력: torch.jit.trace에 필요한 예시 텐서
    example_input = torch.randn(input_shape)

    # ── TorchScript 변환 (tracing 방식) ──────────────────────────
    # trace: 예시 입력을 실제로 실행하며 연산 그래프를 기록
    # (scripting 방식과 달리 if/for 등 동적 흐름은 추적 불가)
    print("Converting to TorchScript...")
    traced_model = torch.jit.trace(wrapped_model, example_input)

    # ── CoreML 변환 ───────────────────────────────────────────────
    print("Converting to CoreML...")

    # 입력 타입 설정: iOS 카메라 프레임(CVPixelBuffer)과 연동
    image_input = ct.ImageType(
        name="image",
        shape=input_shape,
        scale=1.0 / 255.0,   # 픽셀값 정규화: [0,255] → [0,1]
        # ImageNet 정규화: (pixel/255 - mean) / std → bias로 표현
        # bias = -mean/std 이며 각 채널(R,G,B)별로 적용
        bias=[-0.485/0.229, -0.456/0.224, -0.406/0.225],
        color_layout=ct.colorlayout.RGB,  # iOS 기본 색상 순서
    )

    # CoreML 형식으로 변환
    mlmodel = ct.convert(
        traced_model,
        inputs=[image_input],
        outputs=[
            # 출력 이름은 Swift에서 prediction 결과 접근 시 사용
            ct.TensorType(name="drowsiness_probability"),  # [awake, drowsy] 확률
            ct.TensorType(name="gaze_probability"),         # [at_screen, away] 확률
            ct.TensorType(name="face_probability"),         # [no_face, face] 확률
        ],
        minimum_deployment_target=ct.target.iOS15,  # iOS 15+ 지원
        convert_to="mlprogram",  # 최신 ML Program 형식 (iOS 15+ 최적화)
    )

    # ── 모델 메타데이터 추가 ──────────────────────────────────────
    # Xcode의 모델 미리보기에서 표시되는 정보
    mlmodel.author = "FocusSense"
    mlmodel.short_description = "Focus detection model for study tracking"
    mlmodel.version = "1.0.0"

    # 스펙 정보 (입출력 설명 추가용)
    spec = mlmodel.get_spec()

    # ── 양자화 적용 ───────────────────────────────────────────────
    if quantize:
        print(f"Applying {quantization_type} quantization...")

        if quantization_type == 'linear':
            # INT8 선형 양자화:
            # - FP32(4바이트) → INT8(1바이트): 약 4배 크기 감소
            # - linear_symmetric: 양수/음수 대칭 양자화
            # - per_tensor: 텐서 전체에 단일 스케일 적용 (per_channel보다 빠름)
            op_config = cto.OpLinearQuantizerConfig(
                mode="linear_symmetric",
                dtype="int8",
                granularity="per_tensor"
            )
            config = cto.OptimizationConfig(global_config=op_config)
            mlmodel = cto.linear_quantize_weights(mlmodel, config=config)

        elif quantization_type == 'lut':
            # Lookup Table(팔레트) 양자화:
            # - kmeans 클러스터링으로 대표값(팔레트) 결정
            # - nbits=8: 2^8=256개 팔레트 엔트리 → 8비트로 표현
            # - 이미지와 유사하게 값의 분포를 고려한 양자화
            op_config = cto.OpPalettizerConfig(
                mode="kmeans",
                nbits=8
            )
            config = cto.OptimizationConfig(global_config=op_config)
            mlmodel = cto.palettize_weights(mlmodel, config=config)

    # ── 저장 ─────────────────────────────────────────────────────
    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    # .mlpackage 형식: iOS 15+ 최적화된 패키지 형식 (디렉토리 구조)
    # .mlmodel(단일 파일)보다 더 효율적인 최신 형식
    if not str(output_path).endswith('.mlpackage'):
        output_path = output_path.with_suffix('.mlpackage')

    mlmodel.save(str(output_path))
    print(f"✓ Saved CoreML model to {output_path}")

    # 변환 결과 정보 출력
    print_model_info(mlmodel, output_path)

    return str(output_path)


def print_model_info(mlmodel, model_path: Path):
    """
    변환된 CoreML 모델의 파일 크기와 입출력 정보를 출력합니다.

    Args:
        mlmodel: coremltools MLModel 객체
        model_path (Path): .mlpackage 파일 경로
    """
    print("\n" + "=" * 50)
    print("CoreML Model Info")
    print("=" * 50)

    # .mlpackage는 디렉토리 구조이므로 내부 파일 크기를 합산
    if model_path.exists():
        size_mb = sum(f.stat().st_size for f in model_path.rglob('*')) / (1024 * 1024)
        print(f"Model size: {size_mb:.2f} MB")

    # 입출력 스펙 출력 (Xcode 모델 인스펙터와 동일한 정보)
    spec = mlmodel.get_spec()
    print(f"\nInputs:")
    for input_desc in spec.description.input:
        print(f"  - {input_desc.name}: {input_desc.type}")

    print(f"\nOutputs:")
    for output_desc in spec.description.output:
        print(f"  - {output_desc.name}: {output_desc.type}")

    print("=" * 50 + "\n")


def validate_coreml_model(model_path: str, test_image_path: str = None):
    """
    변환된 CoreML 모델이 정상적으로 추론하는지 검증합니다.

    테스트 이미지를 입력하여 3가지 출력(drowsiness/gaze/face 확률)을
    실제로 계산하고 결과를 출력합니다.

    Args:
        model_path (str): 검증할 .mlpackage 파일 경로
        test_image_path (str, optional): 테스트용 이미지 경로.
                                         None이면 랜덤 이미지 사용.

    Returns:
        bool: 검증 성공 여부
    """
    print("Validating CoreML model...")

    # CoreML 모델 로드 (Mac에서 직접 추론 가능)
    mlmodel = ct.models.MLModel(model_path)

    # 테스트 입력 준비
    if test_image_path:
        from PIL import Image
        # PIL Image로 로드 (224×224 리사이즈)
        test_image = Image.open(test_image_path).resize((224, 224))
    else:
        # 랜덤 RGB 이미지 생성 (파이프라인 동작 확인용)
        test_image = np.random.randint(0, 255, (224, 224, 3), dtype=np.uint8)
        from PIL import Image
        test_image = Image.fromarray(test_image)

    # CoreML 추론 실행
    try:
        # ct.ImageType으로 정의한 입력명 'image'에 PIL Image 전달
        prediction = mlmodel.predict({'image': test_image})

        print("✓ Model validation successful!")
        # 출력명은 convert_to_coreml()에서 정의한 TensorType name과 일치
        print(f"  Drowsiness: {prediction['drowsiness_probability']}")
        print(f"  Gaze: {prediction['gaze_probability']}")
        print(f"  Face: {prediction['face_probability']}")

        return True

    except Exception as e:
        print(f"✗ Model validation failed: {e}")
        return False


def export_for_ios(
    checkpoint_path: str,
    output_dir: str,
    model_type: str = 'default',
    quantize: bool = True,
):
    """
    iOS 배포용 CoreML 모델을 내보내는 전체 파이프라인입니다.

    단계별 진행:
        [Step 1/4] 체크포인트 로드
        [Step 2/4] CoreML 변환 (+ 양자화)
        [Step 3/4] 추론 검증
        [Step 4/4] Xcode 통합 안내 출력

    Args:
        checkpoint_path (str): 학습된 PyTorch 체크포인트 (.pth) 경로
        output_dir (str): .mlpackage 파일 저장 디렉토리
        model_type (str): 'default' 또는 'lite' 모델 선택
        quantize (bool): 양자화 적용 여부 (기본값: True, 권장)

    Returns:
        str: 저장된 .mlpackage 파일 경로, 실패 시 None
    """
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    # ── Step 1: 모델 로드 ─────────────────────────────────────────
    print("\n[Step 1/4] Loading checkpoint...")
    model = load_checkpoint(checkpoint_path, model_type)

    # ── Step 2: CoreML 변환 ───────────────────────────────────────
    print("\n[Step 2/4] Converting to CoreML...")
    model_name = f"FocusSense_{model_type}"
    output_path = output_dir / f"{model_name}.mlpackage"

    convert_to_coreml(
        model=model,
        output_path=str(output_path),
        quantize=quantize,
    )

    # ── Step 3: 변환된 모델 검증 ──────────────────────────────────
    print("\n[Step 3/4] Validating model...")
    is_valid = validate_coreml_model(str(output_path))

    if not is_valid:
        print("Warning: Model validation failed!")
        return None

    # ── Step 4: Xcode 통합 안내 ───────────────────────────────────
    print("\n[Step 4/4] Ready for iOS integration!")
    print(f"""
    ┌─────────────────────────────────────────────────────────┐
    │  CoreML Model Export Complete!                         │
    ├─────────────────────────────────────────────────────────┤
    │                                                         │
    │  Model saved to:                                        │
    │  {output_path}
    │                                                         │
    │  To use in Xcode:                                       │
    │  1. Drag the .mlpackage file into your Xcode project   │
    │  2. Make sure "Copy items if needed" is checked        │
    │  3. The model will be compiled automatically           │
    │                                                         │
    │  Swift usage:                                           │
    │  let model = try FocusSense_{model_type}()             │
    │  let prediction = try model.prediction(image: input)   │
    │                                                         │
    └─────────────────────────────────────────────────────────┘
    """)

    return str(output_path)


def main():
    """
    커맨드라인 인터페이스: 인자를 파싱하고 export_for_ios()를 호출합니다.
    """
    parser = argparse.ArgumentParser(description='Convert PyTorch model to CoreML')

    parser.add_argument('--checkpoint', type=str, required=True,
                        help='Path to PyTorch checkpoint (.pth file)')
    parser.add_argument('--output', type=str, default='./output',
                        help='Output directory for .mlpackage file')
    parser.add_argument('--model', type=str, default='default',
                        choices=['default', 'lite'],
                        help='Model architecture to convert')
    parser.add_argument('--no-quantize', action='store_true',
                        help='Disable quantization (larger model but higher precision)')
    parser.add_argument('--validate', type=str, default=None,
                        help='Path to test image for additional validation after export')

    args = parser.parse_args()

    if not HAS_COREMLTOOLS:
        print("Error: coremltools is required. Install with: pip install coremltools")
        sys.exit(1)

    # 전체 변환 파이프라인 실행
    output_path = export_for_ios(
        checkpoint_path=args.checkpoint,
        output_dir=args.output,
        model_type=args.model,
        quantize=not args.no_quantize,  # --no-quantize 플래그 반전
    )

    # 추가 검증: 테스트 이미지가 제공된 경우 실제 이미지로 재검증
    if args.validate and output_path:
        validate_coreml_model(output_path, args.validate)


if __name__ == '__main__':
    main()
