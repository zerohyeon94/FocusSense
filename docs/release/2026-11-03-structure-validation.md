# 2026-11-03 폴더 구조 변경 검증

## 변경 범위

- 기존 저장소 디렉터리 `FocusSense`를 `orot`으로 변경. 상위 `FocusSense Project`는 현재 Codex 작업공간 컨테이너로 유지.
- `iOS` → `apps/ios`, `Web` → `apps/web`, `ML` → `research/ml`.
- iOS 소스 44개를 기능·도메인·인프라·디자인 시스템별로 이동.
- Xcode 프로젝트·타깃·스킴·앱 진입점은 Orot으로 변경.
- 기존 앱 Bundle ID, Swift 모듈 이름, SwiftData 모델·속성, 설정 키와 CoreML 모델 파일 이름은 유지.
- Xcode 프로젝트·공유 스킴이 Git 무시 대상에서 제외되도록 `.gitignore` 정리.
- 새 기능의 준비 폴더와 구조·개발 문서 추가. 위젯 타깃과 새 제품 기능은 아직 구현하지 않음.

## 결과

| 확인 | 결과 |
|---|---|
| 기존 Git 추적 파일 3,085개 경로 매핑 | 누락 0개 |
| 기존 미커밋 사용자 변경 5개 | 모두 보존, 앱 진입점 명칭만 추가 변경 |
| Xcode 파일 참조 49개 | 모두 실제 경로 존재 |
| 앱 Swift 소스 44개 | 모두 빌드 대상 포함 |
| iOS Debug 일반 시뮬레이터 빌드, 서명 제외 | 성공 |
| 웹 `npm run build` | 성공 |
| 웹 `npm run lint` | 성공 |
| ML Python 소스 구문 검사 | 성공 |
| `bash -n research/ml/train.sh` | 성공 |
| Xcode 프로젝트·Info.plist·entitlements 형식 검사 | 성공 |
| `git diff --check` | 성공 |
| iOS `build-for-testing` | 기존 테스트 API 불일치로 실패 |

검증 중 발견한 기존 웹 문법 오류 두 곳은 JSX 속성 사이 주석 표기를 수정했다. 기존 테마 초기화의 lint 오류는 시스템 테마를 useState 지연 초기값으로 읽도록 수정했다. 소개 문구와 화면 구성은 이번 단계에서 리디자인하지 않았다.

## 남아 있는 기존 테스트 문제

`OrotTests.swift`는 앱 모듈을 정상적으로 찾지만 현재 모델에 없는 `HeadPose.isLookingForward`, `FocusRecord(level:)`, `record.level`을 사용한다. 현재 API는 `FocusRecord(focusLevel:)`, `record.focusLevel`이다. 이 불일치는 구조 이동 전 테스트 코드에도 존재했으며, 이번 폴더 변경에서 테스트의 검증 의미를 재작성하지 않았다.

실제 기기 카메라 동작과 기존 설치 데이터의 업데이트 검증은 수행하지 않았다. 앱 빌드에는 기존 Swift 동시성 경고 등이 남아 있다.

## 로컬 백업

이동 전 Xcode 프로젝트, 사용자 변경 diff, 파일 SHA-256 및 경로 매핑을 `/private/tmp/orot-structure-backup-20261103`에 보관했다. 임시 디렉터리이므로 장기 백업은 Git 커밋이나 별도 백업으로 관리해야 한다. 이번 작업에서 커밋과 원격 저장소 이름 변경은 수행하지 않았다.
