# iOS/CLAUDE.md

Guidance for working on the FocusSense iOS app.
Also read the root `CLAUDE.md` for repository-wide conventions.

## Build & Run

- Open `iOS/FocusSense.xcodeproj` in Xcode 15+
- Target: iOS 17.0+
- **Must run on a physical device** — camera is required, simulator won't work
- CoreML model lives at `Resources/FocusSense_default.mlpackage`

## Architecture

**Pattern**: MVVM + Services

```
Views (SwiftUI) → ViewModels (@MainActor) → Services
                                            ├── SimpleFocusDetectionService  ← core
                                            ├── CameraService
                                            └── CalibrationService
```

### Key Files

| File | Role |
|------|------|
| `SimpleFocusDetectionService.swift` | Core detection: Vision EAR + CoreML hybrid |
| `TimerViewModel.swift` | Main state, auto-pause/resume logic |
| `CameraService.swift` | Camera session + frame delivery |
| `CalibrationService.swift` | User-specific EAR baseline |

## Focus Detection Logic

### Hybrid Scoring (Vision 70% + CoreML 30%)

```swift
let combinedDrowsyScore = 0.7 * visionDrowsyScore + 0.3 * coreMLDrowsyProb
```

### State Table

| Combined Score | Eye State | Focus Level |
|----------------|-----------|-------------|
| < 0.3 | open | focused |
| 0.3 – 0.6 | halfClosed | warning |
| > 0.6 for 2s+ | closed | drowsy → auto-pause |
| No face for 3s+ | — | away → auto-pause |

### EAR (Eye Aspect Ratio)

```swift
// EAR = (|p2-p6| + |p3-p5|) / (2 × |p1-p4|)
// Normal: ~0.3  |  Drowsy: < 0.2
// Always compare against calibrated baseline, not absolute values
let earRatio = currentEAR / calibrationData.baselineEAR
```

## Critical Rules

### Do NOT judge focus by camera direction

```swift
// ❌ WRONG — punishes users who look at a monitor
if headPose.yaw > 30 { return .unfocused }

// ✅ CORRECT
if !isFaceDetected { return .away }       // no face → away
if eyeState == .closed { return .drowsy } // eyes closed → drowsy
// otherwise → focused (even when looking sideways at a monitor)
```

### Time-based thresholds

```swift
private let awayThreshold: TimeInterval    = 3.0  // 3s no face → away
private let drowsyThreshold: TimeInterval  = 2.0  // 2s eyes closed → drowsy
```

### Swift Concurrency

```swift
// ✅ Use Task, not DispatchQueue
Task { @MainActor in
    self.focusService.processFrame(sampleBuffer)
}

// ✅ Delegate methods must be nonisolated
nonisolated func cameraService(_ service: CameraService, didOutput sampleBuffer: CMSampleBuffer) {
    Task { @MainActor in
        self.focusService.processFrame(sampleBuffer)
    }
}
```

## Code Style

- Use `// MARK: -` sections to organize files
- `@MainActor` on any class that updates UI
- `nonisolated` for all delegate/callback methods
- Naming: `*Service` for services, `*ViewModel` for view models
- Split SwiftUI Views into separate structs when the file exceeds ~100 lines

## Debugging

Run app → Start timer → Tap **"AI 분석 보기"** to inspect:

- Presence state (`present` / `away` / `returning`)
- Eye state (`open` / `halfClosed` / `closed`)
- EAR values (current / baseline / ratio)
- CoreML drowsy probability
- Combined score
