"""
FocusSense Multi-Task Model

집중도 감지를 위한 멀티태스크 학습 모델
- Task 1: 졸음 감지 (Drowsiness Detection)   → awake / drowsy 이진 분류
- Task 2: 시선 방향 분류 (Gaze Direction)     → looking_at_screen / looking_away
- Task 3: 얼굴 존재 여부 (Face Presence)      → no_face / face_detected

Architecture: MobileNetV3-Small 기반 경량 멀티태스크 모델 (모바일 최적화)

멀티태스크 학습의 장점:
- 공유된 표현(Shared Representation)으로 여러 관련 태스크를 동시에 학습
- 단일 태스크 대비 일반화 성능 향상
- 하나의 Forward Pass로 여러 예측값을 동시에 산출 → 추론 속도 향상

모델 선택 가이드:
    - FocusSenseModel : 정확도 우선 (1.12M 파라미터, MobileNetV3 백본)
    - FocusSenseLite  : 속도/크기 우선 (0.03M 파라미터, 커스텀 DSConv)
    - EyeAspectRatioModel : EAR 수치 직접 예측 (눈 영역 이미지 입력)
"""

"""
======== 모델 테스트 결과 ========

[FocusSenseModel]
Input shape: torch.Size([1, 3, 224, 224])
    - 배치 크기 1 (이미지 1장)
    - RGB 3채널 (컬러)
    - 너비 224px
    - 높이 224px
Output shapes:
  - drowsiness: torch.Size([1, 2])   # [awake 확률, drowsy 확률]
  - gaze: torch.Size([1, 2])         # [화면 응시, 다른 곳 응시]
  - face: torch.Size([1, 2])         # [얼굴 없음, 얼굴 있음]
Total parameters: 1,116,166 (1.12M)

[FocusSenseLite]
Total parameters: 31,734 (0.03M)    # ~31KB 초경량

[EyeAspectRatioModel]
Input shape: torch.Size([1, 1, 64, 32])  # 그레이스케일 눈 영역
Output shape: torch.Size([1, 1])          # EAR 수치 (0.0 ~ 0.5)
Total parameters: 56,417
"""

import torch
import torch.nn as nn
import torch.nn.functional as F
from torchvision import models


class FocusSenseModel(nn.Module):
    """
    집중도 감지를 위한 멀티태스크 학습 모델 (기본 버전)

    MobileNetV3-Small을 백본으로 사용하고 공유 레이어 위에
    3개의 태스크별 분류 헤드를 붙인 구조입니다.

    아키텍처:
        Input (224×224 RGB)
            ↓
        MobileNetV3-Small features (특징 추출)
            ↓
        AdaptiveAvgPool + Flatten (576차원 벡터)
            ↓
        shared_fc: Linear(576→256) + ReLU + Dropout(0.3)
            ↓
        ┌─────────────────┬─────────────────┬─────────────────┐
        │  drowsiness_head│   gaze_head     │   face_head     │
        │ Linear(256→64)  │ Linear(256→64)  │ Linear(256→32)  │
        │ ReLU + Dropout  │ ReLU + Dropout  │ ReLU            │
        │ Linear(64→2)    │ Linear(64→2)    │ Linear(32→2)    │
        └─────────────────┴─────────────────┴─────────────────┘
            ↓                   ↓                   ↓
        drowsiness logits   gaze logits         face logits

    Args:
        pretrained (bool): ImageNet 사전학습 가중치 사용 여부.
                           True 권장 (전이학습으로 수렴 속도 향상)
    """

    def __init__(self, pretrained: bool = True):
        super(FocusSenseModel, self).__init__()

        # ── 백본: MobileNetV3-Small ───────────────────────────────
        # 모바일 환경을 위해 설계된 경량 CNN
        # Squeeze-and-Excitation 모듈과 h-swish 활성화 함수 사용
        backbone = models.mobilenet_v3_small(
            weights=models.MobileNet_V3_Small_Weights.DEFAULT if pretrained else None
        )

        # 원본 분류 헤드(classifier)는 제거하고 특징 추출기만 사용
        self.features = backbone.features  # CNN 특징 추출 블록들
        self.avgpool = backbone.avgpool    # 공간 차원을 1×1로 압축

        # MobileNetV3-Small의 마지막 특징 맵 채널 수
        backbone_out_features = 576

        # ── 공유 표현 레이어 ──────────────────────────────────────
        # 모든 태스크가 공유하는 중간 표현 공간으로 변환
        # Dropout(0.3): 과적합 방지를 위한 정규화
        self.shared_fc = nn.Sequential(
            nn.Linear(backbone_out_features, 256),
            nn.ReLU(inplace=True),
            nn.Dropout(0.3),
        )

        # ── 태스크별 분류 헤드 ────────────────────────────────────
        # 각 태스크는 공유 표현을 입력받아 독립적으로 예측

        # Task 1: 졸음 감지 (awake=0 / drowsy=1)
        # CoreML에서 drowsiness_probability로 출력됨
        self.drowsiness_head = nn.Sequential(
            nn.Linear(256, 64),
            nn.ReLU(inplace=True),
            nn.Dropout(0.2),
            nn.Linear(64, 2),   # 2개 클래스: [awake, drowsy]
        )

        # Task 2: 시선 방향 (화면응시=0 / 딴 곳=1)
        # "카메라 방향이 아닌 화면 응시 여부"로 집중도 보조 판단
        self.gaze_head = nn.Sequential(
            nn.Linear(256, 64),
            nn.ReLU(inplace=True),
            nn.Dropout(0.2),
            nn.Linear(64, 2),   # 2개 클래스: [at_screen, away]
        )

        # Task 3: 얼굴 존재 여부 (없음=0 / 있음=1)
        # 얼굴이 검출되지 않으면 자리 이탈로 판단
        self.face_head = nn.Sequential(
            nn.Linear(256, 32),
            nn.ReLU(inplace=True),
            nn.Linear(32, 2),   # 2개 클래스: [no_face, face]
        )

    def forward(self, x: torch.Tensor) -> dict:
        """
        Forward pass: 이미지를 입력받아 각 태스크의 logits를 반환합니다.

        반환값은 Softmax 적용 전의 raw logits입니다.
        학습 시 CrossEntropyLoss가 내부적으로 Softmax를 처리합니다.
        추론 시에는 predict() 메서드 사용을 권장합니다.

        Args:
            x (torch.Tensor): 입력 이미지 텐서, shape (batch, 3, 224, 224)

        Returns:
            dict: 각 태스크의 logits
                  {'drowsiness': (B,2), 'gaze': (B,2), 'face': (B,2)}
        """
        # 1단계: MobileNetV3로 특징 추출
        features = self.features(x)    # (B, 576, 7, 7) 특징 맵
        features = self.avgpool(features)  # (B, 576, 1, 1) 전역 평균 풀링
        features = torch.flatten(features, 1)  # (B, 576) 1D 벡터로 변환

        # 2단계: 공유 표현 공간으로 변환
        shared = self.shared_fc(features)  # (B, 256)

        # 3단계: 각 태스크별 헤드로 예측
        drowsiness_logits = self.drowsiness_head(shared)  # (B, 2)
        gaze_logits = self.gaze_head(shared)               # (B, 2)
        face_logits = self.face_head(shared)               # (B, 2)

        return {
            'drowsiness': drowsiness_logits,
            'gaze': gaze_logits,
            'face': face_logits,
        }

    def predict(self, x: torch.Tensor) -> dict:
        """
        추론 전용 메서드: logits 대신 확률값(Softmax 적용)을 반환합니다.

        gradient 계산 없이 추론만 수행하므로 메모리 효율적입니다.

        Args:
            x (torch.Tensor): 입력 이미지 텐서, shape (batch, 3, 224, 224)

        Returns:
            dict: 각 태스크의 클래스 확률
                  {'drowsiness': (B,2), 'gaze': (B,2), 'face': (B,2)}
                  값은 0~1 범위의 확률이며 각 행의 합 = 1
        """
        self.eval()
        with torch.no_grad():
            logits = self.forward(x)

            return {
                # dim=1: 클래스 차원으로 Softmax 적용
                'drowsiness': F.softmax(logits['drowsiness'], dim=1),
                'gaze': F.softmax(logits['gaze'], dim=1),
                'face': F.softmax(logits['face'], dim=1),
            }


class EyeAspectRatioModel(nn.Module):
    """
    Eye Aspect Ratio (EAR) 직접 예측 모델

    눈 영역 크롭 이미지에서 EAR 수치를 직접 회귀(Regression)합니다.
    Vision Framework의 랜드마크 기반 EAR 계산을 보완하는 용도입니다.

    EAR 공식:
        EAR = (|p2-p6| + |p3-p5|) / (2 × |p1-p4|)
        - 정상: ~0.3  (눈을 뜬 상태)
        - 졸음: < 0.2 (눈이 감기는 상태)

    아키텍처:
        Input (1×64×32 그레이스케일 눈 영역)
            ↓ Conv Block 1: Conv(1→16) + BN + ReLU + MaxPool → 16×32×16
            ↓ Conv Block 2: Conv(16→32) + BN + ReLU + MaxPool → 32×16×8
            ↓ Conv Block 3: Conv(32→64) + BN + ReLU + AdaptiveAvgPool → 64×4×2
            ↓ Flatten → 512차원
            ↓ Linear(512→64) + ReLU + Dropout(0.3)
            ↓ Linear(64→1) + Sigmoid → [0,1]
            ↓ × 0.5 → EAR 범위 [0, 0.5]

    Args:
        없음 (파라미터 없이 고정 아키텍처)
    """

    def __init__(self):
        super(EyeAspectRatioModel, self).__init__()

        self.features = nn.Sequential(
            # Conv Block 1: 저수준 엣지/질감 특징 추출
            nn.Conv2d(1, 16, kernel_size=3, padding=1),
            nn.BatchNorm2d(16),    # 배치 정규화: 학습 안정화
            nn.ReLU(inplace=True),
            nn.MaxPool2d(2),       # 공간 크기 절반으로 축소

            # Conv Block 2: 중간 수준 눈 형태 특징
            nn.Conv2d(16, 32, kernel_size=3, padding=1),
            nn.BatchNorm2d(32),
            nn.ReLU(inplace=True),
            nn.MaxPool2d(2),

            # Conv Block 3: 고수준 눈 개폐 상태 특징
            nn.Conv2d(32, 64, kernel_size=3, padding=1),
            nn.BatchNorm2d(64),
            nn.ReLU(inplace=True),
            # AdaptiveAvgPool: 입력 크기에 무관하게 (4,2) 고정 출력
            nn.AdaptiveAvgPool2d((4, 2)),
        )

        self.regressor = nn.Sequential(
            nn.Flatten(),                    # (B, 64, 4, 2) → (B, 512)
            nn.Linear(64 * 4 * 2, 64),
            nn.ReLU(inplace=True),
            nn.Dropout(0.3),
            nn.Linear(64, 1),
            nn.Sigmoid(),  # 출력을 [0,1] 범위로 제한 후 ×0.5 → [0, 0.5]
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """
        눈 영역 이미지에서 EAR 수치를 예측합니다.

        Args:
            x (torch.Tensor): 그레이스케일 눈 이미지, shape (batch, 1, 64, 32)

        Returns:
            torch.Tensor: EAR 예측값, shape (batch, 1), 범위 [0, 0.5]
        """
        features = self.features(x)
        # Sigmoid(0~1) × 0.5 → EAR 실제 범위인 0~0.5로 스케일링
        ear = self.regressor(features) * 0.5
        return ear


class FocusSenseLite(nn.Module):
    """
    초경량 집중도 감지 모델 (CoreML 모바일 배포 최적화)

    MobileNetV3보다 훨씬 작은 커스텀 Depthwise Separable Conv 아키텍처.
    실시간 iOS 추론을 위해 파라미터 수와 연산량을 극단적으로 줄였습니다.

    목표 성능:
        - 모델 크기: < 5MB
        - 추론 시간: < 10ms (iPhone 12 기준)

    Depthwise Separable Convolution (DSConv):
        일반 Conv 대비 약 8~9배 연산량 감소
        Depthwise Conv(채널별 공간 필터링) + Pointwise Conv(채널 혼합) 분리

    아키텍처:
        Input (3×224×224)
            ↓ Initial Conv(3→16, stride=2) + BN + ReLU6 → 16×112×112
            ↓ DSConv(16→32, stride=2) → 32×56×56
            ↓ DSConv(32→64, stride=2) → 64×28×28
            ↓ DSConv(64→128, stride=2) → 128×14×14
            ↓ DSConv(128→128, stride=2) → 128×7×7
            ↓ AdaptiveAvgPool → 128×1×1
            ↓ Flatten → 128차원
            ↓
        ┌──────────────┬──────────────┬──────────────┐
        │ drowsiness   │    gaze      │    face      │
        │ Linear(128→2)│ Linear(128→2)│ Linear(128→2)│
        └──────────────┴──────────────┴──────────────┘
    """

    def __init__(self):
        super(FocusSenseLite, self).__init__()

        # ── 특징 추출 블록 ────────────────────────────────────────
        # ReLU6: 출력을 [0,6]으로 클리핑 → 모바일 고정소수점 연산에 유리
        self.features = nn.Sequential(
            # 초기 Conv: RGB → 16채널 특징 맵, stride=2로 공간 크기 절반
            nn.Conv2d(3, 16, kernel_size=3, stride=2, padding=1),
            nn.BatchNorm2d(16),
            nn.ReLU6(inplace=True),

            # DSConv Block 1: 16 → 32채널, 크기 절반
            self._make_dsconv(16, 32, stride=2),

            # DSConv Block 2: 32 → 64채널, 크기 절반
            self._make_dsconv(32, 64, stride=2),

            # DSConv Block 3: 64 → 128채널, 크기 절반
            self._make_dsconv(64, 128, stride=2),

            # DSConv Block 4: 128 → 128채널, 크기 절반
            self._make_dsconv(128, 128, stride=2),

            # 전역 평균 풀링: 공간 차원 제거, 128차원 벡터로 압축
            nn.AdaptiveAvgPool2d(1),
        )

        # ── 멀티태스크 헤드 (경량화: 단일 Linear만 사용) ──────────
        self.drowsiness_head = nn.Linear(128, 2)  # awake / drowsy
        self.gaze_head = nn.Linear(128, 2)         # at_screen / away
        self.face_head = nn.Linear(128, 2)         # no_face / face

    def _make_dsconv(self, in_ch: int, out_ch: int, stride: int = 1):
        """
        Depthwise Separable Convolution 블록을 생성합니다.

        일반 Conv(in_ch × out_ch × k × k)를 두 단계로 분리:
        1. Depthwise Conv: 각 채널에 독립적으로 공간 필터 적용
           → 파라미터: in_ch × k × k (채널 혼합 없음)
        2. Pointwise Conv: 1×1 Conv로 채널 간 정보 혼합
           → 파라미터: in_ch × out_ch × 1 × 1

        Args:
            in_ch (int): 입력 채널 수
            out_ch (int): 출력 채널 수
            stride (int): Depthwise Conv의 stride (크기 축소 시 2)

        Returns:
            nn.Sequential: Depthwise → Pointwise Conv 블록
        """
        return nn.Sequential(
            # Depthwise Conv: groups=in_ch → 채널별 독립 공간 필터링
            nn.Conv2d(in_ch, in_ch, kernel_size=3, stride=stride,
                      padding=1, groups=in_ch, bias=False),
            nn.BatchNorm2d(in_ch),
            nn.ReLU6(inplace=True),
            # Pointwise Conv: 1×1 → 채널 차원 변환 (in_ch → out_ch)
            nn.Conv2d(in_ch, out_ch, kernel_size=1, bias=False),
            nn.BatchNorm2d(out_ch),
            nn.ReLU6(inplace=True),
        )

    def forward(self, x: torch.Tensor) -> dict:
        """
        Args:
            x (torch.Tensor): 입력 이미지, shape (batch, 3, 224, 224)

        Returns:
            dict: 각 태스크 logits
                  {'drowsiness': (B,2), 'gaze': (B,2), 'face': (B,2)}
        """
        features = self.features(x)
        features = torch.flatten(features, 1)  # (B, 128, 1, 1) → (B, 128)

        return {
            'drowsiness': self.drowsiness_head(features),
            'gaze': self.gaze_head(features),
            'face': self.face_head(features),
        }


# ================================================================
# 모델 팩토리
# ================================================================

def create_model(model_name: str = 'default', pretrained: bool = True) -> nn.Module:
    """
    모델 이름으로 적절한 모델 인스턴스를 생성하는 팩토리 함수입니다.

    지원 모델:
        - 'default': FocusSenseModel (MobileNetV3 기반, 1.12M 파라미터)
                     학습 정확도 우선, 오프라인 분석 등에 적합
        - 'lite'   : FocusSenseLite (DSConv 기반, 0.03M 파라미터)
                     실시간 iOS 추론, CoreML 배포에 최적화
        - 'ear'    : EyeAspectRatioModel (EAR 회귀, 56K 파라미터)
                     눈 영역 이미지에서 EAR 수치 직접 예측

    Args:
        model_name (str): 'default', 'lite', 'ear' 중 하나
        pretrained (bool): ImageNet 사전학습 가중치 사용 여부
                           ('lite', 'ear'는 해당 없음)

    Returns:
        nn.Module: 생성된 모델 인스턴스

    Raises:
        ValueError: 알 수 없는 model_name 입력 시
    """
    models_dict = {
        'default': lambda: FocusSenseModel(pretrained=pretrained),
        'lite': lambda: FocusSenseLite(),
        'ear': lambda: EyeAspectRatioModel(),
    }

    if model_name not in models_dict:
        raise ValueError(f"Unknown model: {model_name}. Available: {list(models_dict.keys())}")

    return models_dict[model_name]()


if __name__ == '__main__':
    # ── 모델 동작 확인 테스트 ─────────────────────────────────────
    print("=" * 50)
    print("FocusSense Model Test")
    print("=" * 50)

    # 기본 모델 테스트
    model = create_model('default')
    dummy_input = torch.randn(1, 3, 224, 224)  # 배치 1개 더미 이미지
    output = model(dummy_input)

    print(f"\n[FocusSenseModel]")
    print(f"Input shape: {dummy_input.shape}")
    print(f"Output shapes:")
    for key, value in output.items():
        print(f"  - {key}: {value.shape}")

    # 파라미터 수 출력 (모델 복잡도 확인)
    total_params = sum(p.numel() for p in model.parameters())
    print(f"Total parameters: {total_params:,} ({total_params / 1e6:.2f}M)")

    # 경량 모델 테스트
    print(f"\n[FocusSenseLite]")
    lite_model = create_model('lite')
    lite_output = lite_model(dummy_input)
    lite_params = sum(p.numel() for p in lite_model.parameters())
    print(f"Total parameters: {lite_params:,} ({lite_params / 1e6:.2f}M)")

    # EAR 모델 테스트 (입력 형식이 다름: 1채널, 64×32)
    print(f"\n[EyeAspectRatioModel]")
    ear_model = create_model('ear')
    ear_input = torch.randn(1, 1, 64, 32)  # 그레이스케일 눈 이미지
    ear_output = ear_model(ear_input)
    ear_params = sum(p.numel() for p in ear_model.parameters())
    print(f"Input shape: {ear_input.shape}")
    print(f"Output shape: {ear_output.shape}")
    print(f"Total parameters: {ear_params:,}")
