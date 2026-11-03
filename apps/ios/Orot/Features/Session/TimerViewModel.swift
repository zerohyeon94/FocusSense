//
//  TimerViewModel.swift
//  Orot
//

// ============================================================================
// 세션 화면의 핵심 ViewModel
//
//   SessionView ──▶ TimerViewModel (@MainActor)
//                     ├── CameraService               ← 프레임 수신 (Delegate)
//                     ├── SimpleFocusDetectionService ← 자리·눈 상태 판단 (Combine)
//                     ├── CalibrationService
//                     ├── StudySessionStore / FocusSubjectStore
//                     └── FocusScoreService           ← 디버그용 점수
//
// 세션 흐름 (디자인 시스템 v0.1):
//   집중 ──(정한 시간 도달)──▶ 오버타임 ──(마치기)──▶ 완료 ──(쉬기)──▶ 휴식 ──▶ 다음 집중
//
// 자리를 비우거나 눈을 감아도 시계는 멈추지 않습니다. 그 시간은 순수 집중에서만 빠지고
// 화면에는 '잠시 멈춤'으로 보입니다. 시계를 멈추는 것은 사용자의 일시정지 버튼뿐입니다.
// ============================================================================

import Foundation
import Combine
import AVFoundation
import UIKit
import UserNotifications

// MARK: - Timer State
enum TimerState {
    case idle
    case running
    case paused
}

// MARK: - Session Phase
enum SessionPhase: Equatable {
    case focusing
    case complete
    case rest
}

// MARK: - Timer ViewModel
@MainActor
final class TimerViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var isSessionPresented = false
    @Published private(set) var phase: SessionPhase = .focusing
    @Published private(set) var timerState: TimerState = .idle
    @Published private(set) var elapsedTime: TimeInterval = 0
    @Published private(set) var netFocusTime: TimeInterval = 0
    @Published private(set) var awayDuration: TimeInterval = 0
    @Published var currentFocusState: FocusState = FocusState()
    @Published private(set) var currentSession: StudySession?
    @Published private(set) var completedSession: StudySession?
    @Published var showDebugView = false
    @Published var showCalibrationView = false

    // MARK: - Session Settings
    @Published private(set) var targetDuration: TimeInterval = 25 * 60
    @Published private(set) var subjectName = FocusSubject.defaultNames[0]
    @Published private(set) var isDetectionEnabled = true

    // MARK: - Rest
    @Published private(set) var restDuration: TimeInterval = 5 * 60
    @Published private(set) var restElapsed: TimeInterval = 0
    @Published private(set) var completedRounds = 0

    let shortRestDuration: TimeInterval = 5 * 60
    let longRestDuration: TimeInterval = 15 * 60
    let longRestEvery = 4

    // MARK: - Services
    let cameraService: CameraService
    private(set) var focusService: SimpleFocusDetectionService
    let calibrationService = CalibrationService()
    let sessionStore: StudySessionStore
    let studyPlanStore: StudyPlanStore
    let subjectStore: FocusSubjectStore
    let focusScoreService = FocusScoreService()

    // MARK: - Computed Properties
    var captureSession: AVCaptureSession? { cameraService.session }
    var faceAnalysisData: FaceAnalysisData { focusService.faceAnalysisData }
    var needsCalibration: Bool { !calibrationService.calibrationData.isCalibrated }
    var focusRate: Double { focusScoreService.totalScore }
    var sky: SkyProgress { sessionStore.sky }

    var isOvertime: Bool { phase == .focusing && elapsedTime >= targetDuration }
    var remainingTime: TimeInterval { max(0, targetDuration - elapsedTime) }
    var overtime: TimeInterval { max(0, elapsedTime - targetDuration) }
    var progress: Double { targetDuration > 0 ? min(1, elapsedTime / targetDuration) : 0 }
    var restRemaining: TimeInterval { max(0, restDuration - restElapsed) }

    /// 자리를 비웠거나 눈을 감아 순수 집중이 쌓이지 않는 중
    var isAwayPaused: Bool {
        guard isDetectionEnabled, timerState == .running else { return false }
        return currentFocusState.level == .away || currentFocusState.level == .drowsy
    }

    var badgeKind: SessionBadge.Kind {
        if timerState == .paused || isAwayPaused { return .paused }
        return isOvertime ? .overtime : .focusing
    }

    /// 지금까지 순수 집중 비율 (0~1)
    var pureFocusRatio: Double {
        guard isDetectionEnabled else { return 1 }
        return elapsedTime > 0 ? netFocusTime / elapsedTime : 1
    }

    /// 이번 세션의 별이 지금까지 모인 정도 (0~1) — 멈춘 동안에는 밝아지지 않습니다.
    var starFormation: Double {
        targetDuration > 0 ? min(1, (isDetectionEnabled ? netFocusTime : elapsedTime) / targetDuration) : 0
    }

    var clockText: String { Self.clock(isOvertime ? overtime : remainingTime) }
    var restClockText: String { Self.clock(restRemaining) }
    var targetMinutes: Int { Int(targetDuration / 60) }

    /// 다음 휴식이 긴 휴식인지
    var nextRestIsLong: Bool { completedRounds > 0 && completedRounds % longRestEvery == 0 }

    // MARK: - Private
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let hapticGenerator = UINotificationFeedbackGenerator()

    // MARK: - Initialization
    init() {
        self.cameraService = CameraService()
        self.focusService = SimpleFocusDetectionService()
        self.sessionStore = StudySessionStore()
        self.studyPlanStore = StudyPlanStore()
        self.subjectStore = FocusSubjectStore()

        focusService.calibrationService = calibrationService
        cameraService.delegate = self
        setupBindings()

        print("✅ TimerViewModel 초기화 완료")
    }

    // MARK: - Setup Bindings
    private func setupBindings() {
        focusService.$currentState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.currentFocusState = state
            }
            .store(in: &cancellables)

        // 디버그 화면용 집중도 점수 (6개 지표 가중 합산 → 0~100점)
        focusService.$currentState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self, self.timerState == .running, state.isFaceDetected else { return }
                let data = self.faceAnalysisData
                let debugInfo = self.focusService.debugInfo
                self.focusScoreService.updateMetrics(
                    ear: data.averageEAR,
                    baselineEAR: debugInfo.earBaseline,
                    headPose: HeadPose(pitch: data.pitch, yaw: data.yaw, roll: data.roll),
                    combinedDrowsyScore: debugInfo.combinedDrowsyScore,
                    focusLevel: state.level
                )
            }
            .store(in: &cancellables)
    }

    // MARK: - Camera Preview (시작 직전 확인)

    func startPreview() {
        guard timerState == .idle else { return }
        cameraService.startSession()
    }

    func stopPreview() {
        guard timerState == .idle else { return }
        cameraService.stopSession()
    }

    // MARK: - Focus Session

    func startSession(minutes: Int, subject: String, detection: Bool) {
        targetDuration = TimeInterval(minutes * 60)
        subjectName = subject
        isDetectionEnabled = detection
        beginFocus()
        isSessionPresented = true
        print("▶️ 세션 시작: \(subject) \(minutes)분, 감지 \(detection ? "켜짐" : "꺼짐")")
    }

    func pause() {
        guard phase == .focusing, timerState == .running else { return }
        timerState = .paused
        timer?.invalidate()
        print("⏸️ 세션 일시정지 (수동)")
    }

    func resume() {
        guard phase == .focusing, timerState == .paused else { return }
        timerState = .running
        startTicking()
        print("▶️ 세션 재개")
    }

    /// 마치기: 1분 이상 머물렀으면 별을 띄우고 완료 화면으로, 아니면 그냥 닫습니다.
    func finishFocus() {
        guard phase == .focusing, let session = currentSession else { return }
        timer?.invalidate()
        cameraService.stopSession()
        timerState = .idle
        session.endTime = Date()

        guard elapsedTime >= 60 else {
            print("⚠️ 1분 미만 세션은 저장하지 않습니다")
            closeSession()
            return
        }

        sessionStore.saveSession(session)
        completedSession = session
        completedRounds += 1
        hapticGenerator.notificationOccurred(.success)
        phase = .complete
        print("✅ 세션 완료: 순수 집중 \(Int(netFocusTime))초, \(session.starMagnitude)등급")
    }

    // MARK: - Rest

    func startRest() {
        restDuration = nextRestIsLong ? longRestDuration : shortRestDuration
        restElapsed = 0
        phase = .rest
        timerState = .running
        startTicking()
        print("☕️ 휴식 시작: \(Int(restDuration / 60))분")
    }

    func startNextFocus() {
        timer?.invalidate()
        beginFocus()
    }

    func closeSession() {
        timer?.invalidate()
        cameraService.stopSession()
        if phase == .focusing, let session = currentSession, session.endTime == nil, elapsedTime >= 60 {
            session.endTime = Date()
            sessionStore.saveSession(session)
        }
        timerState = .idle
        isSessionPresented = false
        UIApplication.shared.isIdleTimerDisabled = false
        resetFocusValues()
        completedSession = nil
        completedRounds = 0
        phase = .focusing
        print("⏹️ 세션 닫기")
    }

    // MARK: - Private Session Helpers

    private func beginFocus() {
        resetFocusValues()
        let session = StudySession(startTime: Date())
        session.studyPlanTitle = subjectName
        session.isDetectionEnabled = isDetectionEnabled
        session.plannedDuration = targetDuration
        currentSession = session
        completedSession = nil
        phase = .focusing
        timerState = .running

        if isDetectionEnabled {
            cameraService.startSession()
        } else {
            cameraService.stopSession()
        }
        UIApplication.shared.isIdleTimerDisabled = true
        startTicking()
    }

    private func resetFocusValues() {
        elapsedTime = 0
        netFocusTime = 0
        awayDuration = 0
        currentSession = nil
        focusService.reset()
        focusScoreService.reset()
    }

    private func startTicking() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    // MARK: - Tick
    private func tick() {
        switch phase {
        case .focusing:
            tickFocus()
        case .rest:
            restElapsed += 1
            if restElapsed >= restDuration {
                hapticGenerator.notificationOccurred(.success)
                startNextFocus()
            }
        case .complete:
            timer?.invalidate()
        }
    }

    private func tickFocus() {
        elapsedTime += 1
        let level: FocusLevel = isDetectionEnabled ? currentFocusState.level : .focused

        if level == .focused { netFocusTime += 1 }
        awayDuration = isAwayPaused ? awayDuration + 1 : 0

        if elapsedTime == targetDuration {
            hapticGenerator.notificationOccurred(.success)
            sendTargetReachedNotification()
        }

        let record = FocusRecord(
            timestamp: Date(),
            focusLevel: level,
            duration: 1.0,
            focusScore: focusScoreService.totalScore
        )
        record.session = currentSession
        currentSession?.focusRecords.append(record)
    }

    private func sendTargetReachedNotification() {
        let content = UNMutableNotificationContent()
        content.title = "정한 \(targetMinutes)분을 채웠어요"
        content.body = "흐름을 이어가도 되고, 여기서 마쳐도 돼요."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "orot-target-\(UUID())", content: content, trigger: trigger))
    }

    // MARK: - Helpers
    static func clock(_ time: TimeInterval) -> String {
        let t = Int(time)
        return String(format: "%02d:%02d", t / 60, t % 60)
    }
}

// MARK: - Camera Service Delegate
extension TimerViewModel: CameraServiceDelegate {

    nonisolated func cameraService(_ service: CameraService, didOutput sampleBuffer: CMSampleBuffer) {
        Task { @MainActor in
            if calibrationService.isCalibrating {
                collectCalibrationSample()
            }
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

        // 캘리브레이션 완료 시 프레임 간격을 1초(1fps)로 복원하여 배터리/발열 최적화
        if !calibrationService.isCalibrating {
            cameraService.disableCalibrationMode()
        }
    }

    nonisolated func cameraService(_ service: CameraService, didFailWithError error: Error) {
        print("❌ Camera error: \(error)")
    }
}
