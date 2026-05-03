//
//  TimerViewModel.swift
//  FocusSense
//

// ============================================================================
// 📚 [파일 개요] TimerViewModel - 타이머 화면의 핵심 ViewModel
// ============================================================================
//
// 📚 아키텍처 다이어그램:
//
//   TimerView (SwiftUI)
//       │
//       ▼
//   TimerViewModel (@MainActor, ObservableObject)
//       │
//       ├── CameraService          ← 카메라 프레임 수신 (Delegate 패턴)
//       ├── SimpleFocusDetectionService  ← 집중도 분석 (Combine 구독)
//       ├── CalibrationService     ← 사용자 보정 데이터
//       ├── StudySessionStore      ← 세션 영속 저장
//       └── StudyPlanStore         ← 학습 계획 관리
//
// 📚 [MVVM 패턴에서 ViewModel의 역할]
//   - View는 "어떻게 보여줄지"만 담당하고, ViewModel은 "무슨 데이터를, 어떤 로직으로" 처리할지 담당합니다.
//   - View → ViewModel: 사용자 액션 전달 (startTimer, pauseTimer 등)
//   - ViewModel → View: @Published 프로퍼티 변경 → SwiftUI가 자동으로 UI 갱신
//   - ViewModel → Service: 실제 비즈니스 로직 위임 (카메라, 집중도 분석)
//
// 📚 [상태 머신 (State Machine)]
//   이 ViewModel의 핵심은 TimerState 상태 전이입니다:
//
//   idle ──(start)──▶ running ──(pause)──▶ paused ──(resume)──▶ running
//     ▲                  │                                        │
//     │                  └──(auto)──▶ autoPaused ──(resume)───────┘
//     │                                                           │
//     └─────────────────(stop/reset)──────────────────────────────┘
//
// ============================================================================

import Foundation
import Combine
import AVFoundation
import UIKit
import UserNotifications

// MARK: - Timer State

// 📚 [Swift enum] 열거형으로 가능한 상태를 "유한하게" 정의합니다.
//    문자열이나 Int 플래그 대신 enum을 쓰면:
//    1. switch문에서 컴파일러가 모든 케이스 처리를 강제합니다 (안전성)
//    2. 잘못된 값이 들어올 수 없습니다 (타입 안전성)
//    3. 코드 가독성이 올라갑니다 (.running vs magic number 1)
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

// MARK: - Pomodoro Phase
enum PomodoroPhase {
    case focus, shortBreak, longBreak

    var label: String {
        switch self {
        case .focus: return "집중"
        case .shortBreak: return "짧은 휴식"
        case .longBreak: return "긴 휴식"
        }
    }
}

// MARK: - Timer ViewModel

// 📚 [@MainActor 클래스]
//    Swift Concurrency의 핵심 개념입니다.
//    @MainActor를 클래스에 붙이면 이 클래스의 "모든 프로퍼티와 메서드"가
//    자동으로 메인 스레드(=UI 스레드)에서 실행됩니다.
//
//    왜 필요한가?
//    - SwiftUI의 @Published 프로퍼티는 반드시 메인 스레드에서 변경해야 합니다.
//    - 만약 백그라운드 스레드에서 @Published 값을 바꾸면 런타임 크래시가 발생합니다.
//    - @MainActor가 이를 컴파일 타임에 보장해줍니다.
//
// 📚 [final class]
//    final 키워드는 "이 클래스를 상속할 수 없다"는 의미입니다.
//    상속이 필요 없는 클래스에 final을 붙이면:
//    1. 컴파일러가 "정적 디스패치(Static Dispatch)"를 사용해 성능이 향상됩니다.
//    2. 의도치 않은 상속을 방지하여 설계 의도가 명확해집니다.
//
// 📚 [ObservableObject 프로토콜]
//    SwiftUI에서 데이터 바인딩의 핵심 프로토콜입니다.
//    이 프로토콜을 채택한 클래스의 @Published 프로퍼티가 변경되면,
//    이를 구독하는 SwiftUI View가 자동으로 다시 렌더링됩니다.
//    View에서는 @StateObject 또는 @ObservedObject로 이 ViewModel을 관찰합니다.
@MainActor
final class TimerViewModel: ObservableObject {

    // MARK: - Published Properties

    // 📚 [@Published 프로퍼티 래퍼]
    //    @Published는 Combine 프레임워크의 프로퍼티 래퍼입니다.
    //    값이 변경될 때마다 자동으로 Publisher를 통해 변경 사실을 알립니다.
    //    SwiftUI View에서 이 값을 사용하면, 값이 바뀔 때마다 화면이 자동 갱신됩니다.
    //
    //    내부적으로 @Published var timerState는 다음과 같이 동작합니다:
    //    - timerState: 현재 값에 접근하는 일반 프로퍼티
    //    - $timerState: Publisher (Combine 스트림)로, .sink()로 구독 가능
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

    // MARK: - Countdown
    @Published var targetDuration: TimeInterval? = nil  // nil = 업카운트 모드
    @Published var isTimerCompleted = false

    // MARK: - Pomodoro
    @Published var showPomodoroView = false
    @Published var pomodoroPhase: PomodoroPhase = .focus
    @Published var pomodoroRound: Int = 1

    // MARK: - Services

    // 📚 [접근 제어와 의존성 주입]
    //    - let (상수): 한 번 할당되면 변경 불가 → 외부에서 서비스를 교체할 수 없어 안전
    //    - private(set): 외부에서 읽기는 가능하지만, 쓰기는 이 클래스 내부에서만 가능
    //    이렇게 접근 수준을 세밀하게 제어하면, 어디서 값이 바뀔 수 있는지 추적이 쉬워집니다.
    let cameraService: CameraService
    private(set) var focusService: SimpleFocusDetectionService
    let calibrationService = CalibrationService()
    let sessionStore: StudySessionStore
    let studyPlanStore: StudyPlanStore
    // AI 기반 집중도 점수 서비스 (6개 지표 가중 합산 → 0~100점)
    let focusScoreService = FocusScoreService()

    // MARK: - Computed Properties

    // 📚 [연산 프로퍼티 (Computed Property)]
    //    저장 공간을 차지하지 않고, 접근할 때마다 계산해서 값을 반환합니다.
    //    서비스의 내부 구현을 숨기면서 View에 필요한 데이터만 노출하는
    //    "파사드(Facade) 패턴"의 역할을 합니다.
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

    var isCountdownMode: Bool { targetDuration != nil }

    var isPomodoroBreak: Bool {
        showPomodoroView && pomodoroPhase != .focus
    }

    var remainingTime: TimeInterval {
        guard let target = targetDuration else { return 0 }
        return max(0, target - elapsedTime)
    }

    var formattedRemainingTime: String { formatTime(remainingTime) }

    var countdownProgress: Double {
        guard let target = targetDuration, target > 0 else { return 0 }
        return min(1.0, elapsedTime / target)
    }

    // 📚 [guard 문을 이용한 조기 반환 (Early Return)]
    //    guard문은 조건이 false이면 즉시 반환합니다.
    //    0으로 나누는 오류를 방지하면서 코드의 의도를 명확하게 표현합니다.
    // AI 기반 실시간 집중률 (FocusScoreService의 6개 지표 가중 합산 점수)
    var focusRate: Double {
        return focusScoreService.totalScore
    }

    // MARK: - Timer
    private var timer: Timer?

    // MARK: - Combine

    // 📚 [AnyCancellable과 메모리 관리]
    //    Combine에서 .sink()로 구독을 생성하면 AnyCancellable 객체가 반환됩니다.
    //    이 객체가 메모리에서 해제(deinit)되면 구독도 자동으로 취소됩니다.
    //
    //    Set<AnyCancellable>에 저장하는 이유:
    //    1. 구독이 즉시 해제되는 것을 방지 (Set이 참조를 유지)
    //    2. ViewModel이 deinit될 때 Set도 해제 → 모든 구독이 자동 취소
    //    3. 메모리 누수 없이 생명주기가 자동 관리됩니다.
    //
    //    이것은 RxSwift의 DisposeBag과 동일한 역할입니다.
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Auto Pause
    private var consecutiveDrowsyCount = 0
    private let autoPauseThreshold = 3  // 3번 연속 drowsy면 일시정지
    private(set) var lastAutoPauseReason: AutoPauseReason?

    // MARK: - Auto Resume Setting
    var autoResumeOnReturn: Bool = true  // 복귀 시 자동 재개 여부

    var pomodoroFocusDuration: TimeInterval = 25 * 60
    var pomodoroBreakDuration: TimeInterval = 5 * 60
    var pomodoroLongBreakDuration: TimeInterval = 15 * 60
    let pomodoroTotalRounds = 4

    // MARK: - Haptic
    private let hapticGenerator = UINotificationFeedbackGenerator()

    // MARK: - Initialization

    // 📚 [init에서의 서비스 초기화 및 연결]
    //    ViewModel의 init에서 모든 서비스를 생성하고 연결합니다.
    //    이 패턴을 "Composition Root"라고 부르며, 의존성 관계를 한 곳에서 설정합니다.
    //    테스트할 때는 init에 Mock 서비스를 주입하면 됩니다(의존성 주입, DI).
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

    // 📚 [Combine 구독 패턴: Publisher → Operator → Subscriber]
    //    Combine의 데이터 흐름은 3단계입니다:
    //    1. Publisher ($currentState) : 데이터 변경을 감지하고 발행
    //    2. Operator (.receive(on:)) : 데이터를 변환/필터/스케줄링
    //    3. Subscriber (.sink)       : 최종적으로 데이터를 받아서 처리
    //
    //    .receive(on: DispatchQueue.main)
    //    → 구독 결과를 메인 스레드에서 받겠다는 의미입니다.
    //    focusService의 상태 변경이 백그라운드 스레드에서 일어날 수 있으므로
    //    UI 업데이트를 위해 메인 스레드로 전환합니다.
    //
    //    .sink { [weak self] state in ... }
    //    → [weak self]는 "약한 참조 캡처 리스트"입니다.
    //    클로저가 self(ViewModel)를 강하게 참조하면 "순환 참조(Retain Cycle)"가 발생합니다:
    //      ViewModel → cancellables → 클로저 → self(ViewModel) → (무한 루프!)
    //    [weak self]를 사용하면 클로저가 self를 약하게 참조하므로,
    //    ViewModel이 해제될 때 클로저도 자연스럽게 정리됩니다.
    //    self?. 형태로 사용하며, self가 이미 해제되었으면 아무 동작도 하지 않습니다 (Optional Chaining).
    //
    //    .store(in: &cancellables)
    //    → 구독 결과(AnyCancellable)를 cancellables Set에 저장합니다.
    //    inout 파라미터(&)로 전달하여 Set에 직접 삽입합니다.
    private func setupBindings() {
        // 자동 일시정지/재개 판단 (SimpleFocusDetectionService 기반)
        focusService.$currentState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleFocusStateChange(state)
            }
            .store(in: &cancellables)

        // AI 집중도 점수 업데이트 (FocusScoreService 기반)
        // 상태 변경 시마다 6개 지표를 업데이트하여 0~100점 산출
        focusService.$currentState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self,
                      self.timerState == .running,
                      state.isFaceDetected else { return }

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

    // MARK: - Handle Focus State Change

    // 📚 [상태 전이 핸들러]
    //    이 메서드는 집중도 상태가 변경될 때마다 호출됩니다.
    //    "이전 상태"와 "새 상태"를 비교하여 적절한 액션을 수행합니다.
    //    예: 이전에 away → 지금 focused = "사용자 복귀" → 자동 재개 고려
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

        // 📚 [UINotificationFeedbackGenerator]
        //    iOS의 햅틱(진동) 피드백 API입니다.
        //    .warning: 경고성 진동, .success: 성공 진동, .error: 에러 진동
        //    사용자가 화면을 보지 않더라도 촉각으로 상태 변화를 알 수 있습니다.
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
            dismissAlertAfterDelay()

            hapticGenerator.notificationOccurred(.success)
            print("▶️ 자동 재개 (복귀)")
        } else {
            // 졸음으로 일시정지됐던 경우 → 알림만
            alertMessage = "👋 돌아오셨네요! 재개 버튼을 눌러주세요."
            showAlert = true
        }
    }

    private func dismissAlertAfterDelay() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            if showAlert {
                showAlert = false
            }
        }
    }

    // MARK: - Timer Controls

    // 📚 [학습 계획 선택 플로우]
    //    startTimer()는 "전략 패턴(Strategy Pattern)"과 유사한 분기를 수행합니다:
    //    1. 학습 계획이 없으면 → 바로 시작 (nil 전달)
    //    2. 학습 계획이 있으면 → 선택 시트를 보여주고, 사용자 선택 후 startTimerWithPlan 호출
    //    이렇게 분리하면, 계획 선택 UI와 타이머 시작 로직이 독립적입니다.

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

        // 📚 [Timer.scheduledTimer와 클로저 + 스레드 전환 패턴]
        //    Timer.scheduledTimer는 Foundation의 타이머로, 지정된 간격(1초)마다 클로저를 실행합니다.
        //
        //    [weak self] 캡처 리스트:
        //    Timer는 클로저를 "강하게(strong)" 캡처합니다.
        //    만약 [weak self] 없이 self.updateTimer()를 호출하면:
        //      Timer → 클로저 → self(ViewModel) → timer(Timer) → 순환 참조!
        //    [weak self]로 약한 참조를 사용하면 이 순환이 깨집니다.
        //
        //    Task { @MainActor in }:
        //    Timer의 클로저는 메인 RunLoop에서 실행되지만,
        //    @MainActor 클래스의 메서드를 호출하려면 명시적으로 MainActor 컨텍스트가 필요합니다.
        //    Task { @MainActor in }은 "새로운 비동기 작업을 메인 액터에서 실행하라"는 의미입니다.
        //    이것이 Swift Concurrency에서 스레드 전환을 안전하게 하는 표준 패턴입니다.
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

    // 📚 [타이머 종료 시 리소스 정리 순서]
    //    1. 상태를 idle로 전환 → UI가 즉시 "정지 상태"로 갱신됨
    //    2. timer?.invalidate() → 타이머 정지 (메모리 누수 방지)
    //    3. cameraService.stopSession() → 카메라 리소스 해제 (배터리 절약)
    //    4. 세션 데이터 저장 → 사용자 데이터 보존
    //    리소스 정리 순서를 잘못하면 크래시나 데이터 손실이 발생할 수 있습니다.
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
        targetDuration = nil
        isTimerCompleted = false
        currentSession = nil
        consecutiveDrowsyCount = 0
        lastAutoPauseReason = nil
        selectedPlan = nil

        focusService.reset()
        focusScoreService.reset()

        print("🔄 타이머 리셋")
    }

    // MARK: - Pomodoro

    func startPomodoroTimer() {
        pomodoroPhase = .focus
        pomodoroRound = 1
        targetDuration = pomodoroFocusDuration
        showPomodoroView = true
        // fullScreenCover 애니메이션이 완료된 뒤 카메라/타이머를 시작한다.
        // 동기 호출 시 SwiftUI가 상태 변경을 한 렌더에 묶어 화면 전환이 실행되지 않는 문제 방지.
        Task { @MainActor in
            startTimerWithPlan(nil)
        }
    }

    func stopPomodoroTimer() {
        showPomodoroView = false
        pomodoroPhase = .focus
        pomodoroRound = 1
        resetTimer()
    }

    func skipPomodoroPhase() {
        guard timerState == .running || timerState == .paused || timerState == .autoPaused else { return }
        handlePomodoroPhaseComplete()
    }

    private func handlePomodoroPhaseComplete() {
        hapticGenerator.notificationOccurred(.success)
        timer?.invalidate()

        switch pomodoroPhase {
        case .focus:
            currentSession?.endTime = Date()
            if let session = currentSession {
                sessionStore.saveSession(session)
            }
            currentSession = nil
            netFocusTime = 0
            focusScoreService.reset()

            if pomodoroRound >= pomodoroTotalRounds {
                pomodoroPhase = .longBreak
                targetDuration = pomodoroLongBreakDuration
                alertMessage = "🎉 \(pomodoroTotalRounds)번 집중 완료! 긴 휴식 시간입니다."
            } else {
                pomodoroPhase = .shortBreak
                targetDuration = pomodoroBreakDuration
                alertMessage = "✅ 집중 완료! 잠깐 휴식하세요."
            }
            elapsedTime = 0
            cameraService.stopSession()

        case .shortBreak:
            pomodoroRound += 1
            pomodoroPhase = .focus
            targetDuration = pomodoroFocusDuration
            elapsedTime = 0
            alertMessage = "▶️ \(pomodoroRound)번째 집중을 시작합니다!"
            cameraService.startSession()
            let focusSession = StudySession(startTime: Date())
            currentSession = focusSession

        case .longBreak:
            pomodoroRound = 1
            pomodoroPhase = .focus
            targetDuration = pomodoroFocusDuration
            elapsedTime = 0
            alertMessage = "🎊 모든 라운드 완료! 처음부터 다시 시작합니다."
            cameraService.startSession()
            let restartSession = StudySession(startTime: Date())
            currentSession = restartSession
        }

        showAlert = true
        timerState = .running
        consecutiveDrowsyCount = 0

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTimer()
            }
        }

        print("🔄 뽀모도로 페이즈 전환: \(pomodoroPhase), 라운드: \(pomodoroRound)")
    }

    // MARK: - Countdown Completion

    private func handleTimerCompleted() {
        let plan = selectedPlan  // stopTimer()가 selectedPlan을 nil로 리셋하기 전에 저장
        stopTimer()
        isTimerCompleted = true
        hapticGenerator.notificationOccurred(.success)
        sendCompletionNotification(plan: plan)
        print("✅ 목표 시간 완료")
    }

    private func sendCompletionNotification(plan: StudyPlan?) {
        let content = UNMutableNotificationContent()
        content.title = "집중 시간 완료! 🎉"
        content.body = plan.map { "'\($0.title)' 목표 시간을 달성했습니다." }
            ?? "설정한 목표 시간을 완료했습니다."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "timer-completed-\(UUID())",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Update Timer
    private func updateTimer() {
        elapsedTime += 1

        // 휴식 페이즈에서는 집중 시간 미적립
        if currentFocusState.level == .focused && !isPomodoroBreak {
            netFocusTime += 1
        }

        // 카운트다운 완료 체크
        if let target = targetDuration, elapsedTime >= target {
            if showPomodoroView {
                handlePomodoroPhaseComplete()
            } else {
                handleTimerCompleted()
            }
            return
        }

        // 휴식 페이즈에서는 FocusRecord 미기록
        guard !isPomodoroBreak else { return }

        let record = FocusRecord(
            timestamp: Date(),
            focusLevel: currentFocusState.level,
            duration: 1.0,
            focusScore: focusScoreService.totalScore
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

// 📚 [Delegate 패턴 + Swift Concurrency의 조합]
//    CameraServiceDelegate는 "Delegate 패턴"을 사용합니다.
//    Delegate 패턴은 iOS에서 가장 많이 쓰이는 디자인 패턴 중 하나로,
//    "나 대신 이 일을 처리해줘"라는 위임 관계를 표현합니다.
//
//    CameraService(위임자) ──delegate──▶ TimerViewModel(수임자)
//    카메라가 새 프레임을 캡처할 때마다 delegate 메서드를 호출합니다.
//
// 📚 [extension으로 프로토콜 채택]
//    Swift에서는 extension을 사용하여 프로토콜 채택을 분리하는 것이 관례입니다.
//    이렇게 하면:
//    1. 관심사가 분리되어 코드가 깔끔해집니다
//    2. 어떤 프로토콜을 채택했는지 한눈에 보입니다
//    3. // MARK: - 로 Xcode 네비게이션에서 쉽게 찾을 수 있습니다
extension TimerViewModel: CameraServiceDelegate {

    // 📚 [nonisolated 키워드 - Swift Concurrency 핵심 개념]
    //    TimerViewModel은 @MainActor 클래스이므로 모든 메서드가 메인 스레드에서 실행됩니다.
    //    그런데 CameraServiceDelegate의 이 메서드는 "카메라 백그라운드 스레드"에서 호출됩니다.
    //
    //    문제: @MainActor 메서드를 백그라운드 스레드에서 직접 호출할 수 없음
    //    해결: nonisolated 키워드로 "이 메서드는 MainActor 격리에서 제외"한다고 선언
    //
    //    nonisolated = "이 메서드는 어떤 스레드에서든 호출 가능"
    //    대신 내부에서 @MainActor 프로퍼티에 접근하려면 Task { @MainActor in } 필요
    //
    //    실행 흐름:
    //    카메라 스레드 ──(호출)──▶ nonisolated 메서드
    //                              └── Task { @MainActor in }
    //                                   └── 메인 스레드에서 실행
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

        // 캘리브레이션 완료 시 프레임 간격을 1초(1fps)로 복원하여 배터리/발열 최적화
        if !calibrationService.isCalibrating {
            cameraService.disableCalibrationMode()
        }
    }

    nonisolated func cameraService(_ service: CameraService, didFailWithError error: Error) {
        print("❌ Camera error: \(error)")
    }
}
