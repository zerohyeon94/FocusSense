# iOS/CLAUDE.md

ZipJoong iOS 앱 작업 시 참고하는 가이드입니다.
저장소 전체 규칙은 루트 `CLAUDE.md`를 함께 참고해주세요.

## 빌드 및 실행

- `iOS/FocusSense.xcodeproj`를 Xcode 15+에서 열기
- 타겟: iOS 17.0+
- **반드시 실제 기기에서 실행** — 카메라가 필요하므로 시뮬레이터 불가
- CoreML 모델 위치: `Resources/FocusSense_default.mlpackage`

## 아키텍처

**패턴**: MVVM + Services

```
Views (SwiftUI) → ViewModels (@MainActor) → Services
                                            ├── SimpleFocusDetectionService  ← 핵심
                                            ├── CameraService
                                            └── CalibrationService
```

### 주요 파일

| 파일 | 역할 |
|------|------|
| `SimpleFocusDetectionService.swift` | 핵심 감지: Vision EAR + CoreML 하이브리드 |
| `TimerViewModel.swift` | 메인 상태 관리, 자동 일시정지/재개 로직 |
| `CameraService.swift` | 카메라 세션 + 프레임 전달 |
| `CalibrationService.swift` | 사용자별 EAR 기준값 보정 |

## 집중도 감지 로직

### 하이브리드 스코어링 (Vision 70% + CoreML 30%)

```swift
let combinedDrowsyScore = 0.7 * visionDrowsyScore + 0.3 * coreMLDrowsyProb
```

### 상태 판별표

| Combined Score | 눈 상태 | 집중 레벨 |
|----------------|---------|-----------|
| < 0.3 | open | 집중 |
| 0.3 – 0.6 | halfClosed | 경고 |
| > 0.6 (2초 이상) | closed | 졸음 → 자동 일시정지 |
| 얼굴 미감지 (3초 이상) | — | 자리 비움 → 자동 일시정지 |

### EAR (Eye Aspect Ratio)

```swift
// EAR = (|p2-p6| + |p3-p5|) / (2 × |p1-p4|)
// 정상: ~0.3  |  졸음: < 0.2
// 절대값이 아닌 보정된 기준값과 비교할 것
let earRatio = currentEAR / calibrationData.baselineEAR
```

## 핵심 규칙

### 카메라 방향으로 집중 여부를 판단하지 말 것

```swift
// ❌ 잘못됨 — 모니터를 보는 사용자를 비집중으로 판단함
if headPose.yaw > 30 { return .unfocused }

// ✅ 올바름
if !isFaceDetected { return .away }       // 얼굴 없음 → 자리 비움
if eyeState == .closed { return .drowsy } // 눈 감음 → 졸음
// 그 외 → 집중 (모니터를 바라보고 있어도 집중)
```

### 시간 기반 임계값

```swift
private let awayThreshold: TimeInterval    = 3.0  // 3초 얼굴 미감지 → 자리 비움
private let drowsyThreshold: TimeInterval  = 2.0  // 2초 눈 감음 → 졸음
```

### Swift Concurrency

```swift
// ✅ DispatchQueue가 아닌 Task 사용
Task { @MainActor in
    self.focusService.processFrame(sampleBuffer)
}

// ✅ Delegate 메서드는 nonisolated 사용
nonisolated func cameraService(_ service: CameraService, didOutput sampleBuffer: CMSampleBuffer) {
    Task { @MainActor in
        self.focusService.processFrame(sampleBuffer)
    }
}
```

## 코드 스타일

- `// MARK: -` 섹션으로 파일 구조화
- UI를 업데이트하는 클래스에는 `@MainActor` 적용
- 모든 delegate/callback 메서드에 `nonisolated` 사용
- 네이밍: 서비스는 `*Service`, 뷰모델은 `*ViewModel`
- SwiftUI View 파일이 ~100줄을 초과하면 별도 struct로 분리

## 디버깅

앱 실행 → 타이머 시작 → **"AI 분석 보기"** 탭하여 확인:

- 존재 상태 (`present` / `away` / `returning`)
- 눈 상태 (`open` / `halfClosed` / `closed`)
- EAR 값 (현재값 / 기준값 / 비율)
- CoreML 졸음 확률
- 종합 점수
