"""
FocusSense Multi-Task Model

집중도 감지를 위한 멀티태스크 학습 모델
- Task 1: 졸음 감지 (Drowsiness Detection)
- Task 2: 시선 방향 분류 (Gaze Direction)
- Task 3: 얼굴 존재 여부 (Face Presence)

Architecture: MobileNetV3 기반 경량 모델 (모바일 최적화)
"""

import torch
import torch.nn as nn
import torch.nn.functional as F
from torchvision import models


class FocusSenseModel(nn.Module):
    """
    Multi-Task Learning Model for Focus Detection
    
    Input: 224x224 RGB image (face crop)
    Output:
        - drowsiness: [awake, drowsy] (2 classes)
        - gaze: [looking_at_screen, looking_away] (2 classes)
        - face_present: [no_face, face_detected] (2 classes)
    """
    
    def __init__(self, pretrained: bool = True):
        super(FocusSenseModel, self).__init__()
        
        # Backbone: MobileNetV3-Small (경량화)
        backbone = models.mobilenet_v3_small(
            weights=models.MobileNet_V3_Small_Weights.DEFAULT if pretrained else None
        )
        
        # Feature extractor (마지막 분류층 제외)
        self.features = backbone.features
        self.avgpool = backbone.avgpools
        
        # Backbone output features
        backbone_out_features = 576  # MobileNetV3-Small의 출력 채널
        
        # Shared representation layer
        self.shared_fc = nn.Sequential(
            nn.Linear(backbone_out_features, 256),
            nn.ReLU(inplace=True),
            nn.Dropout(0.3),
        )
        
        # Task-specific heads
        # Task 1: 졸음 감지
        self.drowsiness_head = nn.Sequential(
            nn.Linear(256, 64),
            nn.ReLU(inplace=True),
            nn.Dropout(0.2),
            nn.Linear(64, 2),
        )
        
        # Task 2: 시선 방향
        self.gaze_head = nn.Sequential(
            nn.Linear(256, 64),
            nn.ReLU(inplace=True),
            nn.Dropout(0.2),
            nn.Linear(64, 2),
        )
        
        # Task 3: 얼굴 존재 여부
        self.face_head = nn.Sequential(
            nn.Linear(256, 32),
            nn.ReLU(inplace=True),
            nn.Linear(32, 2),
        )
        
    def forward(self, x: torch.Tensor) -> dict:
        """
        Forward pass
        
        Args:
            x: Input tensor of shape (batch, 3, 224, 224)
            
        Returns:
            Dictionary with logits for each task
        """
        # Feature extraction
        features = self.features(x)
        features = self.avgpool(features)
        features = torch.flatten(features, 1)
        
        # Shared representation
        shared = self.shared_fc(features)
        
        # Task-specific outputs
        drowsiness_logits = self.drowsiness_head(shared)
        gaze_logits = self.gaze_head(shared)
        face_logits = self.face_head(shared)
        
        return {
            'drowsiness': drowsiness_logits,
            'gaze': gaze_logits,
            'face': face_logits,
        }
    
    def predict(self, x: torch.Tensor) -> dict:
        """
        Inference with probabilities
        
        Returns:
            Dictionary with probabilities for each task
        """
        self.eval()
        with torch.no_grad():
            logits = self.forward(x)
            
            return {
                'drowsiness': F.softmax(logits['drowsiness'], dim=1),
                'gaze': F.softmax(logits['gaze'], dim=1),
                'face': F.softmax(logits['face'], dim=1),
            }


class EyeAspectRatioModel(nn.Module):
    """
    Eye Aspect Ratio (EAR) 예측을 위한 경량 모델
    
    눈 영역 이미지에서 직접 EAR 값을 회귀
    Input: 64x32 eye crop (grayscale)
    Output: EAR value (0.0 ~ 0.5)
    """
    
    def __init__(self):
        super(EyeAspectRatioModel, self).__init__()
        
        self.features = nn.Sequential(
            # Conv Block 1
            nn.Conv2d(1, 16, kernel_size=3, padding=1),
            nn.BatchNorm2d(16),
            nn.ReLU(inplace=True),
            nn.MaxPool2d(2),
            
            # Conv Block 2
            nn.Conv2d(16, 32, kernel_size=3, padding=1),
            nn.BatchNorm2d(32),
            nn.ReLU(inplace=True),
            nn.MaxPool2d(2),
            
            # Conv Block 3
            nn.Conv2d(32, 64, kernel_size=3, padding=1),
            nn.BatchNorm2d(64),
            nn.ReLU(inplace=True),
            nn.AdaptiveAvgPool2d((4, 2)),
        )
        
        self.regressor = nn.Sequential(
            nn.Flatten(),
            nn.Linear(64 * 4 * 2, 64),
            nn.ReLU(inplace=True),
            nn.Dropout(0.3),
            nn.Linear(64, 1),
            nn.Sigmoid(),  # EAR은 0~1 범위로 정규화
        )
        
    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """
        Args:
            x: Input tensor of shape (batch, 1, 64, 32)
            
        Returns:
            EAR values of shape (batch, 1) in range [0, 0.5]
        """
        features = self.features(x)
        ear = self.regressor(features) * 0.5  # Scale to [0, 0.5]
        return ear


class FocusSenseLite(nn.Module):
    """
    초경량 모델 (CoreML 배포 최적화)
    
    MobileNetV3보다 더 작은 커스텀 아키텍처
    목표: <5MB 모델 사이즈, <10ms 추론 시간
    """
    
    def __init__(self):
        super(FocusSenseLite, self).__init__()
        
        # Depthwise Separable Convolutions 사용
        self.features = nn.Sequential(
            # Initial Conv
            nn.Conv2d(3, 16, kernel_size=3, stride=2, padding=1),
            nn.BatchNorm2d(16),
            nn.ReLU6(inplace=True),
            
            # DSConv Block 1
            self._make_dsconv(16, 32, stride=2),
            
            # DSConv Block 2
            self._make_dsconv(32, 64, stride=2),
            
            # DSConv Block 3
            self._make_dsconv(64, 128, stride=2),
            
            # DSConv Block 4
            self._make_dsconv(128, 128, stride=2),
            
            # Global Average Pooling
            nn.AdaptiveAvgPool2d(1),
        )
        
        # Multi-task heads (경량화)
        self.drowsiness_head = nn.Linear(128, 2)
        self.gaze_head = nn.Linear(128, 2)
        self.face_head = nn.Linear(128, 2)
        
    def _make_dsconv(self, in_ch: int, out_ch: int, stride: int = 1):
        """Depthwise Separable Convolution Block"""
        return nn.Sequential(
            # Depthwise
            nn.Conv2d(in_ch, in_ch, kernel_size=3, stride=stride, 
                     padding=1, groups=in_ch, bias=False),
            nn.BatchNorm2d(in_ch),
            nn.ReLU6(inplace=True),
            # Pointwise
            nn.Conv2d(in_ch, out_ch, kernel_size=1, bias=False),
            nn.BatchNorm2d(out_ch),
            nn.ReLU6(inplace=True),
        )
        
    def forward(self, x: torch.Tensor) -> dict:
        features = self.features(x)
        features = torch.flatten(features, 1)
        
        return {
            'drowsiness': self.drowsiness_head(features),
            'gaze': self.gaze_head(features),
            'face': self.face_head(features),
        }


# Model factory
def create_model(model_name: str = 'default', pretrained: bool = True) -> nn.Module:
    """
    모델 생성 팩토리
    
    Args:
        model_name: 'default', 'lite', 'ear'
        pretrained: ImageNet pretrained weights 사용 여부
        
    Returns:
        PyTorch model
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
    # 모델 테스트
    print("=" * 50)
    print("FocusSense Model Test")
    print("=" * 50)
    
    # Default model
    model = create_model('default')
    dummy_input = torch.randn(1, 3, 224, 224)
    output = model(dummy_input)
    
    print(f"\n[FocusSenseModel]")
    print(f"Input shape: {dummy_input.shape}")
    print(f"Output shapes:")
    for key, value in output.items():
        print(f"  - {key}: {value.shape}")
    
    # Parameter count
    total_params = sum(p.numel() for p in model.parameters())
    print(f"Total parameters: {total_params:,} ({total_params / 1e6:.2f}M)")
    
    # Lite model
    print(f"\n[FocusSenseLite]")
    lite_model = create_model('lite')
    lite_output = lite_model(dummy_input)
    lite_params = sum(p.numel() for p in lite_model.parameters())
    print(f"Total parameters: {lite_params:,} ({lite_params / 1e6:.2f}M)")
    
    # EAR model
    print(f"\n[EyeAspectRatioModel]")
    ear_model = create_model('ear')
    ear_input = torch.randn(1, 1, 64, 32)
    ear_output = ear_model(ear_input)
    ear_params = sum(p.numel() for p in ear_model.parameters())
    print(f"Input shape: {ear_input.shape}")
    print(f"Output shape: {ear_output.shape}")
    print(f"Total parameters: {ear_params:,}")
