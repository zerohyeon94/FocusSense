# 저장소 구조와 책임

## 최상위

| 경로 | 책임 |
|---|---|
| `apps/ios` | 출시 앱, Xcode 프로젝트, 테스트 |
| `apps/web` | 소개·다운로드 웹 |
| `research/ml` | 기존 학습 코드, 데이터, 실험 및 CoreML 변환 |
| `docs/product` | 제품 정의와 로드맵 |
| `docs/architecture` | 현재 구조와 이전 자료 |
| `docs/decisions` | 결정 내용과 이유 |
| `docs/release` | 검증과 출시 기록 |
| `design` | 디자인 원본 링크, 참고 자료 |
| `scripts` | 실제 필요한 저장소 공통 스크립트 |

## iOS

```text
apps/ios/
├── Orot.xcodeproj/
├── Orot/
│   ├── App/                       # 앱 진입, 루트 화면, Navigation
│   ├── Features/
│   │   ├── Onboarding/            # 현재 CalibrationView
│   │   ├── Focus/                 # 현재 대시보드, 홈 컴포넌트
│   │   ├── Session/               # 타이머, 뽀모도로, 진단 UI
│   │   ├── NightSky/              # 향후 밤하늘 화면
│   │   ├── History/               # 통계, 기록, 상세, 집계 모델
│   │   └── Settings/              # 설정과 계획 관리
│   ├── Domain/
│   │   ├── Sessions/              # 기존 SwiftData 세션·기록·계획 모델
│   │   ├── Detection/             # 감지 상태·인터페이스·기존 점수 계산
│   │   └── NightSky/              # 향후 별 생성·별자리 규칙
│   ├── Infrastructure/
│   │   ├── Camera/
│   │   ├── Vision/
│   │   ├── CoreML/                # 기존 CoreML 감지 구현 보존
│   │   ├── Persistence/
│   │   ├── Notifications/
│   │   └── LiveActivities/        # 향후 시스템 연동
│   ├── DesignSystem/
│   │   ├── Tokens/                # 현재 Color 확장
│   │   ├── Components/            # 향후 공통 UI
│   │   └── SkyRendering/          # 향후 하늘·도시·달 렌더링
│   ├── Support/Extensions/        # Date 등 공용 지원 코드
│   └── Resources/
│       └── Constellations/        # 향후 별자리 데이터와 출처
├── OrotWidgets/                   # 준비 폴더, 확장 타깃은 아직 없음
├── Shared/                        # 준비 폴더, 현재 공통 Swift 타입 없음
└── OrotTests/
```

기능별 폴더에 화면·뷰모델·해당 기능 전용 컴포넌트를 함께 둡니다. 기존 감지·저장 코드의 프레임워크 의존은 이번 단계에서 재설계하지 않았습니다. Domain은 향후 순수 규칙을 분리할 위치이며, 현재 완전한 독립 모듈을 의미하지 않습니다.

새 별자리 기능, 3탭 UI, 규칙 기반 감지, Live Activity 및 위젯은 이번 변경에서 구현하지 않습니다. 준비 폴더는 README로 역할을 남깁니다.

## 이름과 호환성

- 프로젝트·타깃·스킴·앱 진입점: `Orot` / `OrotTests` / `OrotApp`.
- Swift 모듈 이름 `FocusSense`는 기존 저장 모델의 타입 식별을 유지하기 위해 보존.
- 기존 앱 Bundle ID `com.focussense.app` 및 테스트 ID 유지.
- `StudySession`, `FocusRecord`, `StudyPlan` 저장 타입과 속성 유지.
- `FocusSense.CalibrationData` 등 기존 저장 키 유지.
- `FocusSense_default.mlpackage`와 ML 클래스 이름은 기존 산출물 호환을 위해 유지.
- Git 원격 저장소 주소는 자동으로 바꾸지 않음.

## 이전 경로

| 이전 | 현재 |
|---|---|
| `iOS/FocusSense.xcodeproj` | `apps/ios/Orot.xcodeproj` |
| `iOS/FocusSense/App` | `apps/ios/Orot/App` |
| `iOS/FocusSense/Views/Home`, `ViewModels/DashboardViewModel.swift` | `apps/ios/Orot/Features/Focus` |
| `iOS/FocusSense/Views/Timer`, `ViewModels/TimerViewModel.swift` | `apps/ios/Orot/Features/Session` (캘리브레이션은 Onboarding) |
| `iOS/FocusSense/Views/Analytics` | `apps/ios/Orot/Features/History` |
| `iOS/FocusSense/Views/Settings` | `apps/ios/Orot/Features/Settings` |
| `iOS/FocusSense/Models` | `Domain/Sessions`, `Domain/Detection`, `Features/History/Models` |
| `iOS/FocusSense/Services` | `Infrastructure` 및 `Domain/Detection` |
| `Web` | `apps/web` |
| `ML` | `research/ml` |

하위 항목을 제외한 상대 경로는 `apps/ios/Orot` 기준입니다. 기존 README는 `legacy-overview.md`로 보존했습니다.
