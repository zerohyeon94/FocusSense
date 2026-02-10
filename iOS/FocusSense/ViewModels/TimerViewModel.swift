//
//  TimerViewModel.swift
//  FocusSense
//
//  타이머 및 집중도 추적 관리
//

/*
MVVM (Model - View - ViewModel) 패턴:

┌─────────┐         ┌─────────────┐         ┌─────────┐
│  Model  │ ←────── │  ViewModel  │ ←────── │  View   │
│ (데이터)  │         │   (비즈니스   │         │  (UI)   │
│         │ ──────→ │     로직)    │ ──────→ │         │
└─────────┘         └─────────────┘         └─────────┘

- Model: FocusState, StudySession (순수 데이터)
- ViewModel: TimerViewModel (로직 + 상태 관리)
- View: TimerView (화면 표시)

장점: UI와 로직 분리 → 테스트 쉬움, 유지보수 쉬움
*/

import Foundation
import Combine
import AVFoundation
import UIKit

// MARK: - Detection Mode
enum DetectionMode: String, CaseIterable {
    case vision = "Vision Framework"
    case coreML = "CoreML 모델"
}

// MARK: - Timer State
enum TimerState {
    case idle       // 대기
    case running    // 실행 중
    case paused     // 일시정지
    case autoPaused // 자동 일시정지 (졸음/이탈)
}

// MARK: - Timer ViewModel
// @MainActor: 이 클래스의 모든 코드는 메인 스레드에서 실행
// ObservableObject: SwiftUI가 이 객체의 변화를 감지할 수 있음
@MainActor
final class TimerViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var timerState: TimerState = .idle
    @Published var elapsedTime: TimeInterval = 0    // 총 경과 시간
    @Published var netFocusTime: TimeInterval = 0   // 순수 집중 시간
    @Published var currentFocusState: FocusState = FocusState()
    @Published var currentSession: StudySession?
    @Published var showAlert = false        // 알림 표시 여부
    @Published var alertMessage = ""        // 알림 메시지
    @Published var showDebugView = false    // 디버그 화면 표시 여부
    @Published var showCalibrationView = false  // CalibrationView 표시 여부
    @Published var detectionMode: DetectionMode = .coreML  // 현재 모드
    
    // MARK: - Services (서비스 객체: Camera, AI)
    let cameraService: CameraService
    
    // 두 서비스를 모두 보유 (선택적 사용)
    private var visionService: FocusDetectionService?
    private(set) var mlService: MLFocusDetectionService?
    
    // MARK: - Calibration
    let calibrationService = CalibrationService()
    
    // MARK: - Computed Properties
    /// 현재 사용 중인 서비스의 카메라 세션
    var captureSession: AVCaptureSession? {
        return cameraService.session
    }
    
    /// 현재 모드에 따른 분석 데이터
    var faceAnalysisData: FaceAnalysisData {
        switch detectionMode {
        case .vision:
            return visionService?.faceAnalysisData ?? FaceAnalysisData()
        case .coreML:
            return mlService?.faceAnalysisData ?? FaceAnalysisData()
        }
    }
    
    // MARK: - 캘리브레이션 필요 여부
    var needsCalibration: Bool {
        return !calibrationService.calibrationData.isCalibrated
    }
    
    var formattedElapsedTime: String {
        formatTime(elapsedTime)
    }
    
    var formattedNetFocusTime: String {
        formatTime(netFocusTime)
    }
    
    var focusRate: Double {
        guard elapsedTime > 0 else { return 0 }
        return (netFocusTime / elapsedTime) * 100
    }
    
    // MARK: - Timer
    private var timer: Timer?
    
    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Auto Pause
    private var consecutiveUnfocusedCount = 0
    private let autoPauseThreshold = 3 // 3초 연속 이탈 시 자동 일시정지
    
    // MARK: - Haptic
    private let hapticGenerator = UINotificationFeedbackGenerator()
    
    // MARK: - Initialization
    init(detectionMode: DetectionMode = .coreML) {
        self.detectionMode = detectionMode
        self.cameraService = CameraService()
        
        // 선택된 모드에 따라 서비스 초기화
        setupDetectionService(mode: detectionMode)
        
        // 카메라 delegate 설정
        cameraService.delegate = self
        
        // Combine 바인딩
        setupBindings()
    }
    
    // MARK: - Setup Detection Service
    private func setupDetectionService(mode: DetectionMode) {
        // 기존 바인딩 해제
        cancellables.removeAll()
        
        switch mode {
        case .vision:
            // Vision 서비스 생성
            if visionService == nil {
                visionService = FocusDetectionService()
            }
            mlService = nil  // 메모리 해제
            
            // Vision 서비스 바인딩
            visionService?.$currentState
                .receive(on: DispatchQueue.main)
                .sink { [weak self] state in
                    self?.handleFocusStateChange(state)
                }
                .store(in: &cancellables)
            
        case .coreML:
            // CoreML 서비스 생성
            if mlService == nil {
                mlService = MLFocusDetectionService()
            }
            visionService = nil  // 메모리 해제
            
            mlService?.calibrationService = calibrationService // CalibrationService 연결
            
            // CoreML 서비스 바인딩
            mlService?.$currentState
                .receive(on: DispatchQueue.main)
                .sink { [weak self] state in
                    self?.handleFocusStateChange(state)
                }
                .store(in: &cancellables)
        }
        
        print("🔄 Detection Mode: \(mode.rawValue)")
    }
    
    // MARK: - Switch Detection Mode (런타임에 변경 가능)
    func switchDetectionMode(to mode: DetectionMode) {
        guard mode != detectionMode else { return }
        
        detectionMode = mode
        setupDetectionService(mode: mode)
        
        print("✅ Switched to \(mode.rawValue)")
    }
    
    // MARK: - Setup Bindings
    private func setupBindings() {
        // 초기 바인딩은 setupDetectionService에서 처리
    }
    
    // MARK: - Handle Focus State Change
    private func handleFocusStateChange(_ state: FocusState) {
        currentFocusState = state
        
        // 자동 일시정지 로직
        if timerState == .running {
            if state.level == .drowsy || state.level == .unfocused {
                consecutiveUnfocusedCount += 1
                if consecutiveUnfocusedCount >= autoPauseThreshold {
                    triggerAutoPause()
                }
            } else {
                consecutiveUnfocusedCount = 0
            }
        }
    }
    
    // MARK: - Timer Controls
    func startTimer() {
        // 캘리브레이션 안됐으면 먼저 안내
        if needsCalibration {
            alertMessage = "먼저 공부 위치를 설정해주세요.\n핸드폰을 둘 위치에서 설정하면 더 정확해집니다."
            showAlert = true
            showCalibrationView = true  // 캘리브레이션 화면으로
            return
        }
        
        timerState = .running // 상태 변경 -> @Published -> UI 업데이트
        currentSession = StudySession(startTime: Date())
        
        // 카메라 시작
        cameraService.start()
        
        // 타이머 시작
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTimer()
            }
        }
    }
    
    func pauseTimer() {
        timerState = .paused
        timer?.invalidate()
    }
    
    func resumeTimer() {
        timerState = .running
        consecutiveUnfocusedCount = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTimer()
            }
        }
    }
    
    func stopTimer() {
        timerState = .idle
        timer?.invalidate()
        cameraService.stop()
        
        currentSession?.endTime = Date()
    }
    
    func resetTimer() {
        stopTimer()
        elapsedTime = 0
        netFocusTime = 0
        currentSession = nil
        consecutiveUnfocusedCount = 0
        
        // 서비스 리셋
        visionService?.reset()
        mlService?.reset()
    }
    
    // MARK: - Update Timer
    private func updateTimer() {
        elapsedTime += 1 // 총 시간 +1초
        
        if currentFocusState.level == .focused {
            netFocusTime += 1 // 짐중 시간 +1초
        }
        
        // 세션에 기록 추가
        let record = FocusRecord(
            timestamp: Date(),
            level: currentFocusState.level,
            duration: 1.0
        )
        currentSession?.focusRecords.append(record)
    }
    
    // MARK: - Auto Pause
    private func triggerAutoPause() {
        timerState = .autoPaused
        timer?.invalidate()
        
        hapticGenerator.notificationOccurred(.warning)
        
        alertMessage = currentFocusState.level == .drowsy
            ? "😴 졸음이 감지되어 일시정지되었습니다."
            : "👀 집중이 흐트러져 일시정지되었습니다."
        showAlert = true
    }
    
    // MARK: - Helpers
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

// MARK: - Camera Service Delegate
extension TimerViewModel: CameraServiceDelegate {
    nonisolated func cameraService(_ service: CameraService, didOutput sampleBuffer: CMSampleBuffer) {
        Task { @MainActor in
            // 현재 모드에 따라 적절한 서비스로 프레임 전달
            switch detectionMode {
            case .vision:
                visionService?.processFrame(sampleBuffer)
            case .coreML:
                // 캘리브레이션 중이면 샘플 수집
                if calibrationService.isCalibrating {
                    collectCalibrationSample()
                }
                mlService?.processFrame(sampleBuffer)
            }
        }
    }
    
    // ✅ 캘리브레이션 샘플 수집
    @MainActor
    private func collectCalibrationSample() {
        let data = faceAnalysisData
        
        guard data.isFaceDetected else { return }
        
        // 얼굴 크기 계산 (화면 대비)
        let faceSize = data.faceBoundingBox.width * data.faceBoundingBox.height
        
        calibrationService.addSample(
            yaw: data.yaw,
            pitch: data.pitch,
            roll: data.roll,
            ear: data.averageEAR,
            faceSize: faceSize
        )
    }
    
    nonisolated func cameraService(_ service: CameraService, didFailWithError error: Error) {
        print("❌ Camera error: \(error)")
    }
}
