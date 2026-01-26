# FocusSense 📚👁️

> AI-Powered Focus Tracking Study Timer for iOS

**공부할 때 켜두는 스마트 탁상시계** - 감시자가 아닌 페이스 메이커

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org/)
[![Python](https://img.shields.io/badge/Python-3.9+-blue.svg)](https://python.org/)
[![PyTorch](https://img.shields.io/badge/PyTorch-2.0-red.svg)](https://pytorch.org/)
[![CoreML](https://img.shields.io/badge/CoreML-iOS15+-green.svg)](https://developer.apple.com/documentation/coreml)

---

## 🎯 프로젝트 개요

FocusSense는 **On-device AI**를 활용하여 사용자의 집중 상태를 실시간으로 분석하는 iOS 앱입니다.

### 핵심 기능

| 기능 | 설명 |
|------|------|
| 🔍 **졸음 감지** | EAR(Eye Aspect Ratio) 기반 실시간 졸음 탐지 |
| 👀 **시선 추적** | 화면/책 응시 vs 딴청 분류 |
| 🏃 **이탈 감지** | 사용자가 자리를 비웠는지 판단 |
| ⏱️ **순수 집중 시간** | 실제 집중한 시간만 정확히 측정 |
| 🔒 **완전한 프라이버시** | 모든 처리가 기기 내에서 수행 (Serverless) |

### 기술 스택

```
┌─────────────────────────────────────────────────────────────┐
│                    FocusSense Architecture                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   PyTorch    │ → │  CoreML     │ → │    iOS App    │  │
│  │   Training   │    │  Conversion │    │   SwiftUI    │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│                                                             │
│  Python 3.9+         coremltools        Swift 5.9          │
│  MobileNetV3         Quantization       Vision Framework   │
│  Multi-Task          .mlpackage         AVFoundation       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 📁 프로젝트 구조

```
FocusSense/
├── iOS/                          # iOS 앱 (Swift)
│   └── FocusSense/
│       ├── App/                  # 앱 진입점
│       ├── Models/               # 데이터 모델
│       ├── Views/                # SwiftUI 뷰
│       ├── ViewModels/           # MVVM 뷰모델
│       ├── Services/             # 카메라, AI 서비스
│       ├── Coordinators/         # 화면 전환 관리
│       └── Resources/            # 에셋, CoreML 모델
│
├── ML/                           # 머신러닝 파이프라인 (Python)
│   ├── data/                     # 데이터셋
│   ├── models/                   # PyTorch 모델 정의
│   ├── training/                 # 학습 스크립트
│   ├── conversion/               # CoreML 변환
│   └── notebooks/                # 실험 노트북
│
└── README.md
```

---

## 🚀 시작하기

### 1. 환경 설정

#### Python ML 환경

```bash
cd FocusSense/ML

# 가상환경 생성 (권장)
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 의존성 설치
pip install -r requirements.txt
```

#### iOS 개발 환경

- Xcode 15.0+
- iOS 15.0+ 타겟
- macOS Ventura 이상

### 2. 데이터셋 준비

```bash
cd FocusSense/ML

# 테스트용 샘플 데이터 생성
python data/download_datasets.py --dataset sample --output ./data

# 실제 학습을 위한 데이터셋 다운로드 안내
python data/download_datasets.py --dataset all --output ./data
```

### 3. 모델 학습

```bash
cd FocusSense/ML

# 졸음 감지 모델 학습
python training/train.py \
    --train_dir ./data/sample/train \
    --val_dir ./data/sample/val \
    --task drowsiness \
    --model default \
    --epochs 50 \
    --batch_size 32 \
    --pretrained
```

### 4. CoreML 변환

```bash
# PyTorch → CoreML 변환
python conversion/convert_to_coreml.py \
    --checkpoint ./checkpoints/best_model.pth \
    --output ./output \
    --model default
```

### 5. iOS 앱 빌드

1. `FocusSense/iOS/FocusSense.xcodeproj` 열기
2. 변환된 `.mlpackage` 파일을 Xcode 프로젝트에 드래그
3. 실제 디바이스에서 빌드 및 실행

---

## 🔬 모델 아키텍처

### Multi-Task Learning Model

```
Input: 224x224 RGB Image
           │
           ▼
    ┌─────────────────┐
    │  MobileNetV3    │  (Backbone - Pretrained)
    │     Small       │
    └────────┬────────┘
             │
             ▼
    ┌─────────────────┐
    │   Shared FC     │  (256 units)
    │     Layer       │
    └────────┬────────┘
             │
     ┌───────┼───────┐
     │       │       │
     ▼       ▼       ▼
┌────────┐ ┌────────┐ ┌────────┐
│Drowsy  │ │ Gaze   │ │ Face   │
│ Head   │ │ Head   │ │ Head   │
└────────┘ └────────┘ └────────┘
     │       │       │
     ▼       ▼       ▼
  [awake,  [screen, [no_face,
   drowsy]  away]   detected]
```

### 성능 최적화

| 최적화 기법 | 효과 |
|-------------|------|
| Frame Throttling | 1 FPS로 제한 → 배터리 절약 |
| INT8 Quantization | 모델 크기 75% 감소 |
| No Preview Layer | GPU 렌더링 부하 제거 |
| Thermal Monitoring | 발열 시 자동 조절 |

---

## 📊 성능 지표 (목표)

| 메트릭 | 목표값 |
|--------|--------|
| 졸음 감지 정확도 | > 95% |
| 시선 분류 정확도 | > 90% |
| 추론 시간 (iPhone 12) | < 10ms |
| 모델 크기 | < 5MB |
| 배터리 소모 (1시간) | < 10% |

---

## 🎯 면접 대비 포인트

### Q: 발열과 배터리 문제를 어떻게 해결했나요?

1. **Frame Throttling**: 30fps → 1fps로 제한
   ```swift
   let frameInterval: CFAbsoluteTime = 1.0  // 1초에 1번만 추론
   ```

2. **Preview Layer 숨기기**: 카메라는 동작하지만 화면에 렌더링 안 함
   ```swift
   // previewLayer.isHidden = true 대신 아예 추가 안 함
   ```

3. **Thermal State Monitoring**:
   ```swift
   ProcessInfo.processInfo.thermalState  // .critical이면 분석 중지
   ```

4. **INT8 Quantization**: 모델 연산량 75% 감소

### Q: 개인정보 보호는 어떻게 처리했나요?

- **100% On-device 처리**: CoreML로 모든 추론이 기기 내에서 수행
- **영상 미전송**: 네트워크 요청 없음
- **Privacy Manifest 작성**: App Store 심사 대응

---

## 📚 참고 자료

- [Apple Vision Framework](https://developer.apple.com/documentation/vision)
- [CoreML Tools Documentation](https://apple.github.io/coremltools/)
- [MobileNetV3 Paper](https://arxiv.org/abs/1905.02244)
- [Eye Aspect Ratio (EAR)](https://www.pyimagesearch.com/2017/04/24/eye-blink-detection-opencv-python-dlib/)

---

## 📄 라이선스

MIT License

---

## 🤝 기여하기

Issue와 Pull Request를 환영합니다!

---

**Made with ❤️ for better focus**
