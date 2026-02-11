# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FocusSense is an iOS study timer app that measures user focus in real-time using the device camera. It uses a **hybrid approach** combining Vision Framework (70%) and CoreML (30%) for drowsiness detection.

### Core Principle
> **"Determine focus by presence + eye state, NOT camera direction"**
>
> Users looking at a monitor while coding should be considered **focused**.
> They don't need to face the phone camera directly.

## Build & Run

### iOS App
- Open `iOS/FocusSense.xcodeproj` in Xcode 15+
- Target: iOS 17.0+
- **Must run on physical device** (camera required, simulator won't work)

### ML Pipeline
```bash
cd ML
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Train
python training/train.py \
  --train_dir ./data/drowsiness/train \
  --val_dir ./data/drowsiness/val \
  --epochs 50

# Convert to CoreML
python conversion/convert_to_coreml.py
```

## Architecture

**Pattern**: MVVM + Services

```
Views (SwiftUI) → ViewModels (@MainActor) → Services
                                            ├── SimpleFocusDetectionService (core analysis)
                                            ├── CameraService
                                            └── CalibrationService
```

### Key Files
- `SimpleFocusDetectionService.swift` - **Core detection logic**: Vision EAR + CoreML hybrid
- `TimerViewModel.swift` - Main ViewModel, handles auto-pause/resume
- `CameraService.swift` - Camera management and frame delivery
- `CalibrationService.swift` - User-specific baseline calibration

## Focus Detection Logic

### Hybrid Scoring (Vision 70% + CoreML 30%)
```swift
let combinedDrowsyScore = 0.7 * visionDrowsyScore + 0.3 * coreMLDrowsyProb
```

### State Determination
| Combined Score | Eye State | Focus Level |
|----------------|-----------|-------------|
| < 0.3 | open | focused |
| 0.3 - 0.6 | halfClosed | warning |
| > 0.6 (2s+) | closed | drowsy → auto-pause |
| No face (3s+) | - | away → auto-pause |

### EAR (Eye Aspect Ratio)
```swift
// EAR = (|p2-p6| + |p3-p5|) / (2 × |p1-p4|)
// Normal: ~0.3, Drowsy: < 0.2
// Use ratio against calibrated baseline, not absolute values
let earRatio = currentEAR / calibrationData.baselineEAR
```

## Critical Guidelines

### DO NOT judge focus by camera direction
```swift
// ❌ WRONG
if headPose.yaw > 30 { return .unfocused }

// ✅ CORRECT
if !isFaceDetected { return .away }      // No face → away
if eyeState == .closed { return .drowsy } // Eyes closed → drowsy
// Otherwise → focused (even when looking at monitor)
```

### Use time-based thresholds
```swift
private let awayThreshold: TimeInterval = 3.0   // 3s no face → away
private let drowsyThreshold: TimeInterval = 2.0 // 2s eyes closed → drowsy
```

### Swift Concurrency
```swift
// Use Task instead of DispatchQueue
// ❌ DispatchQueue.main.async { }
// ✅ Task { @MainActor in }

// Delegate methods need nonisolated + Task
nonisolated func cameraService(_ service: CameraService, didOutput sampleBuffer: CMSampleBuffer) {
    Task { @MainActor in
        self.focusService.processFrame(sampleBuffer)
    }
}
```

## Debugging

Run app → Start timer → Tap "AI 분석 보기" to see:
- Presence state (present/away/returning)
- Eye state (open/halfClosed/closed)
- EAR values (current/baseline/ratio)
- CoreML drowsy probability
- Combined score

Console log conventions:
- `✅` success, `❌` failure, `⚠️` warning
- `🔄` reset, `👋` return detected, `🚶` away

## Code Style

- Use `// MARK: -` sections
- `@MainActor` for UI-updating classes
- `nonisolated` for delegate methods
- Services: `~Service`, ViewModels: `~ViewModel`
- Split Views into separate structs when > 100 lines
