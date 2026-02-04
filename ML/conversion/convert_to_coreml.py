"""
FocusSense CoreML Conversion Script

PyTorch 모델을 CoreML (.mlmodel) 형식으로 변환
- 양자화 (Quantization) 적용
- iOS 호환성 검증
- 메타데이터 추가

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

import coremltools.optimize.coreml as cto

# Add project root to path
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
    CoreML 변환을 위한 래퍼 모델
    
    Multi-head output을 단일 tuple로 변환
    """
    
    def __init__(self, model: nn.Module):
        super().__init__()
        self.model = model
        
    def forward(self, x: torch.Tensor):
        outputs = self.model(x)
        
        # CoreML은 dictionary output을 지원하지 않으므로 tuple로 변환
        drowsiness = torch.softmax(outputs['drowsiness'], dim=1)
        gaze = torch.softmax(outputs['gaze'], dim=1)
        face = torch.softmax(outputs['face'], dim=1)
        
        return drowsiness, gaze, face


def load_checkpoint(checkpoint_path: str, model_type: str = 'default') -> nn.Module:
    """체크포인트에서 모델 로드"""
    
    # 모델 생성
    model = create_model(model_type, pretrained=False)
    
    # 체크포인트 로드
    checkpoint = torch.load(checkpoint_path, map_location='cpu')
    
    if 'model_state_dict' in checkpoint:
        model.load_state_dict(checkpoint['model_state_dict'])
    else:
        model.load_state_dict(checkpoint)
    
    model.eval()
    print(f"✓ Loaded checkpoint from {checkpoint_path}")
    
    return model


def convert_to_coreml(
    model: nn.Module,
    output_path: str,
    input_shape: tuple = (1, 3, 224, 224),
    quantize: bool = True,
    quantization_type: str = 'linear',  # 'linear' or 'lut'
) -> str:
    """
    PyTorch 모델을 CoreML로 변환
    
    Args:
        model: PyTorch model
        output_path: 출력 .mlmodel 파일 경로
        input_shape: 입력 텐서 shape (batch, channels, height, width)
        quantize: 양자화 적용 여부
        quantization_type: 'linear' (INT8) or 'lut' (look-up table)
        
    Returns:
        저장된 모델 경로
    """
    if not HAS_COREMLTOOLS:
        raise RuntimeError("coremltools is required for conversion")
    
    # 래퍼 적용
    wrapped_model = FocusSenseExportWrapper(model)
    wrapped_model.eval()
    
    # 예제 입력 생성
    example_input = torch.randn(input_shape)
    
    # TorchScript로 변환 (tracing)
    print("Converting to TorchScript...")
    traced_model = torch.jit.trace(wrapped_model, example_input)
    
    # CoreML 변환
    print("Converting to CoreML...")
    
    # 입력 설정
    image_input = ct.ImageType(
        name="image",
        shape=input_shape,
        scale=1.0 / 255.0,  # 0-255 -> 0-1 정규화
        bias=[-0.485/0.229, -0.456/0.224, -0.406/0.225],  # ImageNet 정규화
        color_layout=ct.colorlayout.RGB,
    )
    
    # 변환
    mlmodel = ct.convert(
        traced_model,
        inputs=[image_input],
        outputs=[
            ct.TensorType(name="drowsiness_probability"),
            ct.TensorType(name="gaze_probability"),
            ct.TensorType(name="face_probability"),
        ],
        minimum_deployment_target=ct.target.iOS15,
        convert_to="mlprogram",  # iOS 15+ 최적화 형식
    )
    
    # 메타데이터 추가
    mlmodel.author = "FocusSense"
    mlmodel.short_description = "Focus detection model for study tracking"
    mlmodel.version = "1.0.0"
    
    # 입출력 설명 추가
    spec = mlmodel.get_spec()
    
    # 양자화 (최신 CoreML Optimize API 사용)
    if quantize:
        print(f"Applying {quantization_type} quantization...")
        
        if quantization_type == 'linear':
            # INT8 양자화 (iOS 16+ 최적화)
            op_config = cto.OpLinearQuantizerConfig(
                mode="linear_symmetric",
                dtype="int8",
                granularity="per_tensor"
            )
            config = cto.OptimizationConfig(global_config=op_config)
            mlmodel = cto.linear_quantize_weights(mlmodel, config=config)
            
        elif quantization_type == 'lut':
            # Lookup Table 양자화 (팔레트 방식)
            op_config = cto.OpPalettizerConfig(
                mode="kmeans",
                nbits=8
            )
            config = cto.OptimizationConfig(global_config=op_config)
            mlmodel = cto.palettize_weights(mlmodel, config=config)
    
    # 저장
    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    # .mlpackage로 저장 (iOS 15+)
    if not str(output_path).endswith('.mlpackage'):
        output_path = output_path.with_suffix('.mlpackage')
    
    mlmodel.save(str(output_path))
    print(f"✓ Saved CoreML model to {output_path}")
    
    # 모델 정보 출력
    print_model_info(mlmodel, output_path)
    
    return str(output_path)


def print_model_info(mlmodel, model_path: Path):
    """모델 정보 출력"""
    
    print("\n" + "=" * 50)
    print("CoreML Model Info")
    print("=" * 50)
    
    # 파일 크기
    if model_path.exists():
        size_mb = sum(f.stat().st_size for f in model_path.rglob('*')) / (1024 * 1024)
        print(f"Model size: {size_mb:.2f} MB")
    
    # 입출력 정보
    spec = mlmodel.get_spec()
    print(f"\nInputs:")
    for input_desc in spec.description.input:
        print(f"  - {input_desc.name}: {input_desc.type}")
    
    print(f"\nOutputs:")
    for output_desc in spec.description.output:
        print(f"  - {output_desc.name}: {output_desc.type}")
    
    print("=" * 50 + "\n")


def validate_coreml_model(model_path: str, test_image_path: str = None):
    """CoreML 모델 검증"""
    
    print("Validating CoreML model...")
    
    # 모델 로드
    mlmodel = ct.models.MLModel(model_path)
    
    # 테스트 입력 생성
    if test_image_path:
        from PIL import Image
        test_image = Image.open(test_image_path).resize((224, 224))
    else:
        # 랜덤 이미지 생성
        test_image = np.random.randint(0, 255, (224, 224, 3), dtype=np.uint8)
        from PIL import Image
        test_image = Image.fromarray(test_image)
    
    # 추론 테스트
    try:
        prediction = mlmodel.predict({'image': test_image})
        
        print("✓ Model validation successful!")
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
    iOS용 모델 내보내기 (전체 파이프라인)
    
    1. 체크포인트 로드
    2. CoreML 변환
    3. 양자화
    4. 검증
    5. iOS 프로젝트에 복사할 준비
    """
    
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # 1. 모델 로드
    print("\n[Step 1/4] Loading checkpoint...")
    model = load_checkpoint(checkpoint_path, model_type)
    
    # 2. CoreML 변환
    print("\n[Step 2/4] Converting to CoreML...")
    model_name = f"FocusSense_{model_type}"
    output_path = output_dir / f"{model_name}.mlpackage"
    
    convert_to_coreml(
        model=model,
        output_path=str(output_path),
        quantize=quantize,
    )
    
    # 3. 검증
    print("\n[Step 3/4] Validating model...")
    is_valid = validate_coreml_model(str(output_path))
    
    if not is_valid:
        print("Warning: Model validation failed!")
        return None
    
    # 4. iOS 프로젝트 복사 안내
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
    parser = argparse.ArgumentParser(description='Convert PyTorch model to CoreML')
    
    parser.add_argument('--checkpoint', type=str, required=True,
                        help='Path to PyTorch checkpoint')
    parser.add_argument('--output', type=str, default='./output',
                        help='Output directory')
    parser.add_argument('--model', type=str, default='default',
                        choices=['default', 'lite'],
                        help='Model architecture')
    parser.add_argument('--no-quantize', action='store_true',
                        help='Disable quantization')
    parser.add_argument('--validate', type=str, default=None,
                        help='Path to test image for validation')
    
    args = parser.parse_args()
    
    if not HAS_COREMLTOOLS:
        print("Error: coremltools is required. Install with: pip install coremltools")
        sys.exit(1)
    
    # 변환 실행
    output_path = export_for_ios(
        checkpoint_path=args.checkpoint,
        output_dir=args.output,
        model_type=args.model,
        quantize=not args.no_quantize,
    )
    
    # 추가 검증 (테스트 이미지 제공 시)
    if args.validate and output_path:
        validate_coreml_model(output_path, args.validate)


if __name__ == '__main__':
    main()
