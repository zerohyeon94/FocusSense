//
//  TimerViewModel.swift
//  FocusSense
//

import Foundation
import Combine
import AVFoundation
import UIKit

// MARK: - Timer State
enum TimerState {
    case idle
    case running
    case paused
    case autoPaused
}

// MARK: - Auto Pause Reason
enum AutoPauseReason {
    case away       // 자리 비움
    case drowsy     // 졸음
}

// MARK: - Timer ViewModel
@MainActor
final class TimerViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var timerState: TimerState = .idle
    @Published var elapsedTime: TimeInterval = 0
    @Published var netFocusTime: TimeInterval = 0
    @Published var currentFocusState: FocusState = FocusState()
    @Published var currentSession: StudySession?
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var showDebugView = false
    @Published var showCalibrationView = false

    // MARK: - Study Plan
    @Published var showPlanPicker = false
    @Published var selectedPlan: StudyPlan?

    // MARK: - Services
    let cameraService: CameraService
    private(set) var focusService: SimpleFocusDetectionService
    let calibrationService = CalibrationService()
    let sessionStore: StudySessionStore
    let studyPlanStore: StudyPlanStore

    // MARK: - Computed Properties
    var captureSession: AVCaptureSession? {
        return cameraService.session
    }

    var faceAnalysisData: FaceAnalysisData {
        return focusService.faceAnalysisData
    }

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
    private var consecutiveDrowsyCount = 0
    private let autoPauseThreshold = 3  // 3번 연속 drowsy면 일시정지
    private var lastAutoPauseReason: AutoPauseReason?

    // MARK: - Auto Resume Setting
    var autoResumeOnReturn: Bool = true  // 복귀 시 자동 재개 여부

    // MARK: - Haptic
    private let hapticGenerator = UINotificationFeedbackGenerator()

    // MARK: - Initialization
    init() {
        self.cameraService = CameraService()
        self.focusService = SimpleFocusDetectionService()
        self.sessionStore = StudySessionStore()
        self.studyPlanStore = StudyPlanStore()

        // 서비스 연결
        focusService.calibrationService = calibrationService

        // 카메라 delegate 설정
        cameraService.delegate = self

        // 상태 변화 구독
        setupBindings()

        print("✅ TimerViewModel 초기화 완료")
    }

    // MARK: - Setup Bindings
    private func setupBindings() {
        focusService.$currentState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleFocusStateChange(state)
            }
            .store(in: &cancellables)
    }

    // MARK: - Handle Focus State Change
    private func handleFocusStateChange(_ newState: FocusState) {
        let previousLevel = currentFocusState.level
        currentFocusState = newState

        // 타이머가 실행 중이 아니면 무시
        guard timerState == .running || timerState == .autoPaused else { return }

        switch newState.level {
        case .away:
            // 자리 비움 → 자동 일시정지
            if timerState == .running {
                triggerAutoPause(reason: .away)
            }

        case .drowsy:
            // 졸음 → 카운트 증가 후 일시정지
            consecutiveDrowsyCount += 1
            if consecutiveDrowsyCount >= autoPauseThreshold && timerState == .running {
                triggerAutoPause(reason: .drowsy)
            }

        case .focused:
            // 집중 → 카운트 리셋
            consecutiveDrowsyCount = 0

            // 자리 비움 후 복귀한 경우
            if previousLevel == .away && timerState == .autoPaused {
                handleUserReturned()
            }

        case .warning:
            // 경고 → 카운트 약간 증가
            consecutiveDrowsyCount += 1

        default:
            break
        }
    }

    // MARK: - Trigger Auto Pause
    private func triggerAutoPause(reason: AutoPauseReason) {
        timerState = .autoPaused
        timer?.invalidate()
        lastAutoPauseReason = reason

        hapticGenerator.notificationOccurred(.warning)

        switch reason {
        case .away:
            alertMessage = "🚶 자리를 비우셔서 일시정지되었습니다.\n돌아오시면 자동으로 재개됩니다."
        case .drowsy:
            alertMessage = "😴 졸음이 감지되어 일시정지되었습니다.\n확인을 누르면 재개됩니다."
        }

        showAlert = true
        print("⏸️ 자동 일시정지: \(reason)")
    }

    // MARK: - Handle User Returned
    private func handleUserReturned() {
        if autoResumeOnReturn && lastAutoPauseReason == .away {
            // 자리 비움으로 일시정지됐던 경우 → 자동 재개
            resumeTimer()

            alertMessage = "👋 돌아오셨네요! 타이머를 재개합니다."
            showAlert = true

            hapticGenerator.notificationOccurred(.success)
            print("▶️ 자동 재개 (복귀)")
        } else {
            // 졸음으로 일시정지됐던 경우 → 알림만
            alertMessage = "👋 돌아오셨네요! 재개 버튼을 눌러주세요."
            showAlert = true
        }
    }

    // MARK: - Timer Controls

    /// 시작 버튼 → 학습 계획이 있으면 선택 시트, 없으면 바로 시작
    func startTimer() {
        if studyPlanStore.plans.isEmpty {
            startTimerWithPlan(nil)
        } else {
            showPlanPicker = true
        }
    }

    /// 학습 계획을 선택한 후 타이머 시작
    func startTimerWithPlan(_ plan: StudyPlan?) {
        selectedPlan = plan
        timerState = .running

        let session = StudySession(startTime: Date())
        // 학습 계획 정보 스냅샷
        if let plan = plan {
            session.studyPlanId = plan.id
            session.studyPlanTitle = plan.title
            session.studyPlanColorHex = plan.colorHex
        }
        currentSession = session

        consecutiveDrowsyCount = 0
        lastAutoPauseReason = nil

        // 카메라 시작
        cameraService.startSession()

        // 타이머 시작
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTimer()
            }
        }

        if let plan = plan {
            print("▶️ 타이머 시작 (계획: \(plan.title))")
        } else {
            print("▶️ 타이머 시작")
        }
    }

    func pauseTimer() {
        timerState = .paused
        timer?.invalidate()
        print("⏸️ 타이머 일시정지 (수동)")
    }

    func resumeTimer() {
        timerState = .running
        consecutiveDrowsyCount = 0

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTimer()
            }
        }

        print("▶️ 타이머 재개")
    }

    func stopTimer() {
        timerState = .idle
        timer?.invalidate()
        cameraService.stopSession()

        currentSession?.endTime = Date()

        // 세션 저장
        if let session = currentSession {
            sessionStore.saveSession(session)
        }

        selectedPlan = nil
        print("⏹️ 타이머 정지")
    }

    func resetTimer() {
        stopTimer()
        elapsedTime = 0
        netFocusTime = 0
        currentSession = nil
        consecutiveDrowsyCount = 0
        lastAutoPauseReason = nil
        selectedPlan = nil

        focusService.reset()

        print("🔄 타이머 리셋")
    }

    // MARK: - Update Timer
    private func updateTimer() {
        elapsedTime += 1

        // 집중 상태일 때만 순수 집중 시간 증가
        if currentFocusState.level == .focused {
            netFocusTime += 1
        }

        // 세션에 기록 추가
        let record = FocusRecord(
            timestamp: Date(),
            focusLevel: currentFocusState.level,
            duration: 1.0
        )
        record.session = currentSession
        currentSession?.focusRecords.append(record)
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
            // 캘리브레이션 중이면 샘플 수집
            if calibrationService.isCalibrating {
                collectCalibrationSample()
            }

            // 프레임 분석
            focusService.processFrame(sampleBuffer)
        }
    }

    @MainActor
    private func collectCalibrationSample() {
        let data = faceAnalysisData

        guard data.isFaceDetected else { return }

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
