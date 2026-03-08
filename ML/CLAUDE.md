# ML/CLAUDE.md

ZipJoong ML 파이프라인 작업 시 참고하는 가이드입니다.
저장소 전체 규칙은 루트 `CLAUDE.md`를 함께 참고해주세요.

## 개요

졸음 분류 모델을 학습하고 CoreML 형식으로 변환하여 iOS 앱에서 사용합니다.
백본은 모바일에 최적화된 경량 모델인 **MobileNetV3**를 사용합니다.

## 환경 설정

```bash
cd ML
python -m venv venv
source venv/bin/activate   # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

환경 확인:

```bash
python check_env.py
```

## 학습

```bash
python training/train.py \
  --train_dir ./data/drowsiness/train \
  --val_dir   ./data/drowsiness/val \
  --epochs    50
```

체크포인트는 `checkpoints/`에 저장됩니다.
TensorBoard 로그는 `runs/` 디렉토리에 기록됩니다 — `tensorboard --logdir runs`로 모니터링 가능합니다.

## CoreML 변환

학습 완료 후 최적 체크포인트를 CoreML 형식으로 변환합니다:

```bash
python conversion/convert_to_coreml.py
```

출력: `output/*.mlpackage` — 이 파일을 `iOS/FocusSense/Resources/`에 복사합니다.

## 주요 파일

| 파일 | 역할 |
|------|------|
| `models/focus_model.py` | PyTorch 모델 아키텍처 (MobileNetV3 백본) |
| `training/train.py` | 학습 루프, 메트릭, 체크포인트 저장 |
| `training/dataset.py` | 데이터셋 로딩 및 증강 |
| `conversion/convert_to_coreml.py` | PyTorch → CoreML 변환 |
| `data/download_datasets.py` | Kaggle 졸음 데이터셋 다운로드 |
| `check_env.py` | Python 환경 검증 |

## 모델 설계

- **목적**: 졸음 이진 분류 (alert vs. drowsy)
- **입력**: 크롭된 얼굴 이미지 (정규화)
- **출력**: 졸음 확률 [0.0, 1.0]
- **통합**: Vision EAR 점수와 결합 (CoreML 30%, Vision 70%)

## 데이터

```
data/
├── drowsiness/
│   ├── train/
│   │   ├── alert/
│   │   └── drowsy/
│   └── val/
│       ├── alert/
│       └── drowsy/
└── sample/       ← 빠른 스모크 테스트용 소규모 서브셋
```

전체 Kaggle 데이터셋 다운로드:

```bash
python data/download_datasets.py
```

`~/.kaggle/kaggle.json`에 Kaggle API 인증 설정이 필요합니다.

## 코드 스타일

- 모든 함수 시그니처에 Python 타입 힌트 사용
- 학습, 데이터, 모델, 변환 기능을 별도 모듈로 분리
- 경로를 하드코딩하지 않음 — `argparse` 또는 설정 파일 사용
- `requirements.txt`는 정확한 버전을 고정; 테스트 없이 버전 완화 금지

## 의존성 주의사항

- `numpy`는 `< 2.0.0` 유지 필수 (CoreML tools 호환성)
- `sympy==1.12`는 PyTorch 호환성을 위해 고정
- `coremltools`는 전체 변환 파이프라인 테스트 없이 업그레이드 금지
