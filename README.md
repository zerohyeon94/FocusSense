# 오롯 (Orot)

온전히 집중한 시간을 기록하는 iOS 타이머 프로젝트입니다.

현재는 기존 FocusSense 앱을 유지하면서 새 오롯 컨셉으로 전환하는 단계입니다. 이번 구조 개편은 파일 배치와 프로젝트 이름을 정리하며, 새 화면·감지 정책·별자리 기능은 별도 구현합니다.

## 저장소 구조

```text
orot/
├── apps/
│   ├── ios/                 # Orot iOS 앱과 테스트
│   └── web/                 # React 소개 웹
├── research/
│   └── ml/                  # 모델 학습·평가·CoreML 변환
├── docs/
│   ├── product/             # 제품 기획
│   ├── architecture/        # 구조와 이전 기록
│   ├── decisions/           # 설계 결정
│   └── release/             # 출시·검증 기록
├── design/
│   └── references/          # 디자인 참고 자료
└── scripts/                 # 저장소 공통 스크립트
```

## 시작하기

### iOS

`apps/ios/Orot.xcodeproj`를 열고 `Orot` 스킴을 선택합니다. 현재 프로젝트의 최소 배포 버전은 iOS 18.6입니다. 카메라 감지는 실제 기기에서 확인합니다.

```sh
xcodebuild -project apps/ios/Orot.xcodeproj -scheme Orot \
  -configuration Debug -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```

현재 앱은 기존 CoreML 모델을 계속 사용합니다. 모델 학습은 앱 빌드의 선행 단계가 아니며, 기존 모델 파일이 앱 리소스에 포함되어 있습니다.

### Web

```sh
cd apps/web
npm ci
npm run dev
```

검증: `npm run build`, `npm run lint`.

### ML 연구

```sh
cd research/ml
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python check_env.py
```

학습과 변환 명령은 [ML 개발 가이드](research/ml/CLAUDE.md)를 참고합니다. 데이터·체크포인트·변환 모델은 이번 이동에서 보존했으며, 향후 산출물 관리 방식은 별도 결정합니다.

## 문서

- [저장소 구조와 책임](docs/architecture/repository-structure.md)
- [구조 개편 결정](docs/decisions/0001-repository-layout.md)
- [제품 컨셉 기획서](docs/product/orot-concept-redesign.md) — 방향 및 미결정 사항을 담은 참고 문서
- [기존 프로젝트 설명](docs/architecture/legacy-overview.md) — 이전 시점의 기록이며 현재 실행 안내가 아님
- [개발 규칙](AGENTS.md)
