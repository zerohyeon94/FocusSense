//
//  TimerView.swift
//  FocusSense
//
//  메인 타이머 화면 - 플립 시계 스타일
//

// ============================================================================
// 📚 [파일 개요] TimerView - 메인 타이머 화면 (집중 상태 시각화)
// ============================================================================
//
// 📚 [컴포넌트 분해 패턴]
//   SwiftUI에서 큰 View는 작은 struct로 분해하여 가독성과 재사용성을 높입니다.
//   이 파일은 하나의 큰 화면을 여러 private computed property와 별도 struct로 나눕니다:
//
//   TimerView (메인)
//       ├── backgroundGradient          ← 집중 상태별 배경 그라디언트
//       ├── FocusStatusIndicator        ← 상단 집중 상태 아이콘 + 텍스트
//       ├── TimerDisplay                ← 플립 시계 스타일 시간 표시
//       ├── TimerControls               ← 시작/일시정지/정지 버튼
//       └── .fullScreenCover(...)       ← 전체화면 모달 (디버그, 캘리브레이션)
//
// 📚 [GeometryReader 사용]
//   GeometryReader는 부모 뷰의 크기(geometry.size)를 런타임에 읽어옵니다.
//   이를 통해 화면 크기에 비례하는 반응형 레이아웃을 구현합니다.
//   예: geometry.size.width * 0.8 → 화면 너비의 80%
//
// 📚 [.fullScreenCover vs .sheet]
//   - .sheet: 화면 하단에서 올라오는 반투명 모달 (아래로 스와이프하여 닫기 가능)
//   - .fullScreenCover: 전체 화면을 덮는 모달 (명시적 닫기 버튼 필요)
//   타이머 화면에서는 카메라 프리뷰 등 전체화면이 필요한 경우 fullScreenCover를 사용합니다.
//
// 📚 [Color(hex:) Extension]
//   파일 하단에 정의된 Color 확장으로, "#1a1a2e" 같은 HEX 문자열을 SwiftUI Color로 변환합니다.
//   디자인 시스템의 색상 코드를 코드에서 직접 사용할 수 있게 해주는 유틸리티입니다.
//
// ============================================================================

import SwiftUI

struct TimerView: View {
    /// @ObservedObject: 외부에서 전달받은 객체를 관찰
    /// - ContentView에서 생성된 viewModel을 받아서 사용
    /// - 이 View가 소유하지 않음 (생성 x)
    @ObservedObject var viewModel: TimerViewModel
    /// @State: 이 View 내부에서만 사용하는 단순 값
    /// - Alert 표시 여부 (true/false)
    @State private var showingResetAlert = false
    @State private var showingGoalPicker = false
    
    var body: some View {
        /// GeometryReader: 부모 뷰의 크기/위치 정보 제공
        /// geometry.size.width → 화면 너비
        /// geometry.size.height → 화면 높이
        GeometryReader { geometry in
            /// ZStack: 뷰들을 겹쳐서 배치 (Z축 = 깊이)
            /// 먼저 쓴 뷰가 아래, 나중에 쓴 뷰가 위
            ZStack {
                // 배경 (집중 상태에 따라 변화) - 맨 아래
                backgroundGradient
                    .ignoresSafeArea() // 노치/홈바 영역까지 확장
                    .animation(.easeInOut(duration: 0.5), value: viewModel.currentFocusState.level)
                
                // 콘텐츠 (위에 겹쳐짐)
                /// VStack: 뷰들을 세로로 배치
                /// spacing 각 view 사이 40pt 간격
                VStack(spacing: 40) {
                    // 상단 툴바 (디버그 버튼)
                    DebugToolbar(
                        isDebugMode: $viewModel.showDebugView,
                        showCalibration: $viewModel.showCalibrationView,
                        isCalibrated: viewModel.calibrationService.calibrationData.isCalibrated,
                        isRunning: viewModel.timerState == .running
                    )
                    
                    Spacer() // 빈 공간 (유연하게 늘어남)

                    // 목표 시간 설정 버튼 (idle 상태에서만 표시)
                    if viewModel.timerState == .idle {
                        GoalTimeButton(
                            targetDuration: viewModel.targetDuration,
                            onTap: { showingGoalPicker = true }
                        )
                    }

                    // 선택된 학습 계획 배지 (항상 공간 확보 → 레이아웃 안정)
                    ZStack {
                        if let plan = viewModel.selectedPlan, viewModel.timerState != .idle {
                            SelectedPlanBadge(plan: plan)
                                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                        }
                    }
                    .frame(height: 28)

                    // 집중 상태 인디케이터
                    FocusStatusIndicator(focusState: viewModel.currentFocusState)
                    
                    // 메인 타이머 디스플레이
                    TimerDisplay(
                        mainTime: viewModel.isCountdownMode
                            ? viewModel.formattedRemainingTime
                            : viewModel.formattedElapsedTime,
                        isCountdown: viewModel.isCountdownMode,
                        countdownProgress: viewModel.countdownProgress,
                        netFocusTime: viewModel.formattedNetFocusTime,
                        focusRate: viewModel.focusRate
                    )
                    
                    Spacer()
                    
                    // 컨트롤 버튼
                    TimerControls(
                        timerState: viewModel.timerState,
                        onStart: { viewModel.startTimer() }, // 클로저 전달
                        onPause: { viewModel.pauseTimer() },
                        onResume: { viewModel.resumeTimer() },
                        onStop: { viewModel.stopTimer() },
                        onReset: { showingResetAlert = true }
                    )

                    // 뽀모도로 모드 진입 버튼 (idle 상태에서만 표시)
                    if viewModel.timerState == .idle {
                        PomodoroModeButton {
                            viewModel.startPomodoroTimer()
                        }
                        .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                    }

                    Spacer()
                        .frame(height: 50)
                }
                .padding()
            }
        }
        /// $: Binding - alert가 이 값을 바꿀 수 있음
        /// true가 되면 표시, 닫으면 false로 변경
        .alert("타이머 리셋", isPresented: $showingResetAlert) {
            Button("취소", role: .cancel) { } // .cancel: 취소 버튼 스타일
            Button("리셋", role: .destructive) { // .destructive: 위험한 동작
                viewModel.resetTimer()
            }
        } message: {
            Text("타이머를 리셋하시겠습니까?\n현재 세션의 기록이 삭제됩니다.")
        }
        .alert(viewModel.alertMessage, isPresented: $viewModel.showAlert) {
            Button("확인") {
                if viewModel.timerState == .autoPaused && viewModel.lastAutoPauseReason != .drowsy {
                    viewModel.resumeTimer()
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.showDebugView) {
            AIAnalysisView(viewModel: viewModel)
        }
        // 캘리브레이션 화면 (추가!)
        .fullScreenCover(isPresented: $viewModel.showCalibrationView) {
            CalibrationView(
                viewModel: viewModel,
                calibrationService: viewModel.calibrationService
            )
        }
        // 뽀모도로 타이머 화면
        .fullScreenCover(isPresented: $viewModel.showPomodoroView) {
            PomodoroTimerView(viewModel: viewModel)
        }
        // 학습 계획 선택 시트
        .sheet(isPresented: $viewModel.showPlanPicker) {
            StudyPlanPickerView(
                studyPlanStore: viewModel.studyPlanStore
            ) { plan in
                viewModel.startTimerWithPlan(plan)
            }
            .presentationDetents([.medium, .large])
        }
        // 목표 시간 설정 시트
        .sheet(isPresented: $showingGoalPicker) {
            TimerGoalPickerSheet(targetDuration: $viewModel.targetDuration)
                .presentationDetents([.medium])
        }
        // 목표 시간 완료 알럿
        .alert("목표 시간 완료! 🎉", isPresented: $viewModel.isTimerCompleted) {
            Button("확인") { viewModel.isTimerCompleted = false }
        } message: {
            Text("설정한 목표 시간을 달성했습니다.\n수고하셨습니다!")
        }
    }
    
    // MARK: - Background Gradient
    private var backgroundGradient: some View {
        let colors: [Color] = {
            switch viewModel.currentFocusState.level {
            case .focused:
                return [Color(hex: "1a1a2e"), Color(hex: "16213e")]
            case .warning:
                return [Color(hex: "2d2d44"), Color(hex: "1a1a2e")]
            case .unfocused:
                return [Color(hex: "3d2c29"), Color(hex: "1a1a2e")]
            case .drowsy:
                return [Color(hex: "4a1c1c"), Color(hex: "1a1a2e")]
            case .away:
                return [Color(hex: "1a1a2e"), Color(hex: "0f0f1a")]
            case .unknown:
                return [Color(hex: "1a1a2e"), Color(hex: "0f0f1a")]
            }
        }()
        
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Selected Plan Badge
struct SelectedPlanBadge: View {
    let plan: StudyPlan

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(plan.color)
                .frame(width: 8, height: 8)
            Text(plan.title)
                .font(.caption.bold())
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(plan.color.opacity(0.25))
                .overlay(
                    Capsule()
                        .strokeBorder(plan.color.opacity(0.5), lineWidth: 1)
                )
        )
    }
}

// MARK: - Focus Status Indicator
struct FocusStatusIndicator: View {
    let focusState: FocusState
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: focusState.level.icon)
                .font(.title2)
                .foregroundColor(focusState.level.color)
            
            Text(focusState.level.description)
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(focusState.level.color.opacity(0.2))
                .overlay(
                    Capsule()
                        .strokeBorder(focusState.level.color.opacity(0.5), lineWidth: 1)
                )
        )
    }
}

// MARK: - Timer Display
struct TimerDisplay: View {
    let mainTime: String
    let isCountdown: Bool
    let countdownProgress: Double
    let netFocusTime: String
    let focusRate: Double

    var body: some View {
        VStack(spacing: 20) {
            // 카운트다운 레이블
            if isCountdown {
                Text("남은 시간")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }

            // 메인 시간 (업카운트 또는 카운트다운)
            Text(mainTime)
                .font(.system(size: 72, weight: .light, design: .monospaced))
                .foregroundColor(isCountdown ? .orange : .white)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            
            // 순수 집중 시간 & 집중률
            HStack(spacing: 30) {
                VStack(spacing: 4) {
                    Text("순수 집중")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Text(netFocusTime)
                        .font(.title3.monospaced())
                        .foregroundColor(.green)
                }
                
                Divider()
                    .frame(height: 40)
                    .background(Color.white.opacity(0.3))
                
                VStack(spacing: 4) {
                    Text("집중률")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Text(String(format: "%.0f%%", focusRate))
                        .font(.title3.monospaced())
                        .foregroundColor(focusRateColor)
                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )
        }
    }
    
    private var focusRateColor: Color {
        switch focusRate {
        case 80...: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
}

// MARK: - Timer Controls
struct TimerControls: View {
    let timerState: TimerState
    let onStart: () -> Void // 파라미터 없고 반환값 없는 함수
    let onPause: () -> Void
    let onResume: () -> Void
    let onStop: () -> Void
    let onReset: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            // 리셋 버튼 (항상 공간 확보 → 레이아웃 안정)
            ControlButton(
                icon: "arrow.counterclockwise",
                color: .gray,
                action: onReset
            )
            .opacity(timerState != .idle ? 1 : 0)

            // 메인 버튼 (시작/일시정지/재개)
            MainControlButton(
                timerState: timerState,
                onStart: onStart,
                onPause: onPause,
                onResume: onResume
            )

            // 정지 버튼 (항상 공간 확보 → 레이아웃 안정)
            ControlButton(
                icon: "stop.fill",
                color: .red,
                action: onStop
            )
            .opacity(timerState == .running || timerState == .paused || timerState == .autoPaused ? 1 : 0)
        }
    }
}

// MARK: - Control Button
struct ControlButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) { // 버튼을 누르면 action 실행
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(color.opacity(0.2))
                )
        }
    }
}

// MARK: - Main Control Button
struct MainControlButton: View {
    let timerState: TimerState
    let onStart: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    
    var body: some View {
        Button(action: {
            switch timerState {
            case .idle:
                onStart()
            case .running:
                onPause()
            case .paused, .autoPaused:
                onResume()
            }
        }) {
            Image(systemName: buttonIcon)
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 80, height: 80)
                .background(
                    Circle()
                        .fill(buttonColor)
                        .shadow(color: buttonColor.opacity(0.5), radius: 10, x: 0, y: 5)
                )
        }
    }
    
    private var buttonIcon: String {
        switch timerState {
        case .idle, .paused, .autoPaused:
            return "play.fill"
        case .running:
            return "pause.fill"
        }
    }
    
    private var buttonColor: Color {
        switch timerState {
        case .idle:
            return .orange
        case .running:
            return .blue
        case .paused:
            return .green
        case .autoPaused:
            return .yellow
        }
    }
}

// MARK: - Pomodoro Mode Button
struct PomodoroModeButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Text("🍅")
                Text("뽀모도로 시작")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundColor(.orange.opacity(0.85))
            .padding(.horizontal, 24)
            .padding(.vertical, 11)
            .background(
                Capsule()
                    .fill(Color.orange.opacity(0.1))
                    .overlay(
                        Capsule().strokeBorder(Color.orange.opacity(0.28), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Goal Time Button
struct GoalTimeButton: View {
    let targetDuration: TimeInterval?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .font(.caption)
                Text(targetDuration.map { formatDuration($0) } ?? "목표 시간 설정")
                    .font(.caption.bold())
            }
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.2), lineWidth: 1))
            )
        }
    }

    private func formatDuration(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600
        let m = Int(t) / 60 % 60
        if h > 0 && m > 0 { return "\(h)시간 \(m)분" }
        if h > 0 { return "\(h)시간" }
        return "\(m)분"
    }
}

// MARK: - Timer Goal Picker Sheet
struct TimerGoalPickerSheet: View {
    @Binding var targetDuration: TimeInterval?
    @Environment(\.dismiss) private var dismiss

    @State private var selectedHours = 1
    @State private var selectedMinutes = 0

    private let presets: [(label: String, duration: TimeInterval)] = [
        ("25분", 25 * 60), ("30분", 30 * 60),
        ("1시간", 3600), ("1시간 30분", 90 * 60), ("2시간", 7200)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 프리셋 버튼
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(presets, id: \.duration) { preset in
                        Button(preset.label) {
                            targetDuration = preset.duration
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()

                Divider()

                // 커스텀 시간 피커
                HStack {
                    Picker("시간", selection: $selectedHours) {
                        ForEach(0..<9) { Text("\($0)시간").tag($0) }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)

                    Picker("분", selection: $selectedMinutes) {
                        ForEach([0, 5, 10, 15, 20, 25, 30, 45], id: \.self) {
                            Text("\($0)분").tag($0)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 150)
                .padding(.horizontal)

                // 직접 설정 버튼
                Button("직접 설정") {
                    let total = TimeInterval(selectedHours * 3600 + selectedMinutes * 60)
                    if total > 0 { targetDuration = total }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedHours == 0 && selectedMinutes == 0)
                .padding(.bottom)
            }
            .navigationTitle("목표 시간")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                if targetDuration != nil {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("해제") {
                            targetDuration = nil
                            dismiss()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    TimerView(viewModel: TimerViewModel())
        .preferredColorScheme(.dark)
}
