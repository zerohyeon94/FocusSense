//
//  PomodoroTimerView.swift
//  FocusSense
//
//  뽀모도로 타이머 화면 - 원형 카운트다운 링 + 집중도 표시
//

import SwiftUI

struct PomodoroTimerView: View {
    @ObservedObject var viewModel: TimerViewModel
    @State private var showingStopAlert = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundGradient.ignoresSafeArea()

                VStack(spacing: 0) {
                    topBar

                    Spacer()

                    roundDots
                        .padding(.bottom, 32)

                    ringTimer(size: min(geometry.size.width * 0.78, 300))

                    Spacer()

                    if viewModel.isPomodoroBreak {
                        breakMessage
                            .padding(.bottom, 32)
                    } else {
                        statsRow
                            .padding(.bottom, 32)
                    }

                    controls

                    Spacer().frame(height: 50)
                }
                .padding(.horizontal, 24)
            }
        }
        .alert("뽀모도로 종료", isPresented: $showingStopAlert) {
            Button("취소", role: .cancel) {}
            Button("종료", role: .destructive) {
                viewModel.stopPomodoroTimer()
            }
        } message: {
            Text("현재 세션을 종료하시겠습니까?\n지금까지의 집중 기록은 저장됩니다.")
        }
        .alert(viewModel.alertMessage, isPresented: $viewModel.showAlert) {
            Button("확인") {}
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button { showingStopAlert = true } label: {
                Image(systemName: "xmark")
                    .font(.title3.weight(.medium))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }
            Spacer()
            Text("뽀모도로")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.top, 8)
    }

    // MARK: - Round Dots

    private var roundDots: some View {
        HStack(spacing: 8) {
            ForEach(1...viewModel.pomodoroTotalRounds, id: \.self) { i in
                let isCurrent = i == viewModel.pomodoroRound && viewModel.pomodoroPhase == .focus
                let isDone = i < viewModel.pomodoroRound
                RoundedRectangle(cornerRadius: 4)
                    .fill(isCurrent ? phaseColor : (isDone ? phaseColor.opacity(0.4) : Color.white.opacity(0.18)))
                    .frame(width: isCurrent ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.35), value: viewModel.pomodoroRound)
            }
        }
    }

    // MARK: - Ring Timer

    private func ringTimer(size: CGFloat) -> some View {
        // 남은 비율 (1.0 → 0.0으로 감소)
        let remaining = 1.0 - viewModel.countdownProgress

        return ZStack {
            // 트랙
            Circle()
                .stroke(Color.white.opacity(0.07), lineWidth: 16)

            // 잔여량 글로우
            Circle()
                .trim(from: 0, to: max(0.001, remaining))
                .stroke(phaseColor.opacity(0.18), lineWidth: 30)
                .blur(radius: 12)
                .rotationEffect(.degrees(-90))

            // 잔여량 링
            Circle()
                .trim(from: 0, to: max(0.001, remaining))
                .stroke(phaseColor, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.8), value: viewModel.countdownProgress)

            // 중앙 콘텐츠
            VStack(spacing: 10) {
                Text(viewModel.pomodoroPhase.label)
                    .font(.callout.weight(.semibold))
                    .foregroundColor(phaseColor)
                    .tracking(3)

                Text(viewModel.formattedRemainingTime)
                    .font(.system(size: 54, weight: .thin, design: .monospaced))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.5)

                if !viewModel.isPomodoroBreak {
                    FocusStatusIndicator(focusState: viewModel.currentFocusState)
                        .scaleEffect(0.82)
                }
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statCell(title: "순수 집중", value: viewModel.formattedNetFocusTime, color: .green)
            divider
            statCell(
                title: "집중률",
                value: String(format: "%.0f%%", viewModel.focusRate),
                color: focusRateColor
            )
            divider
            statCell(
                title: "라운드",
                value: "\(viewModel.pomodoroRound) / \(viewModel.pomodoroTotalRounds)",
                color: phaseColor
            )
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.12))
            .frame(width: 1, height: 36)
    }

    private func statCell(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
            Text(value)
                .font(.system(.callout, design: .monospaced).weight(.semibold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Break Message

    private var breakMessage: some View {
        VStack(spacing: 8) {
            Text(viewModel.pomodoroPhase == .longBreak ? "긴 휴식 중" : "짧은 휴식 중")
                .font(.headline)
                .foregroundColor(phaseColor)
            Text("잠깐 눈을 감고 쉬세요")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.45))
            Text("\(viewModel.pomodoroRound - (viewModel.pomodoroPhase == .shortBreak ? 0 : 0)) / \(viewModel.pomodoroTotalRounds) 라운드")
                .font(.caption)
                .foregroundColor(.white.opacity(0.3))
        }
        .frame(height: 72)
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 28) {
            // 정지
            Button { showingStopAlert = true } label: {
                Image(systemName: "stop.fill")
                    .font(.title2)
                    .foregroundColor(.red.opacity(0.8))
                    .frame(width: 58, height: 58)
                    .background(Circle().fill(Color.red.opacity(0.12)))
            }

            // 재생/일시정지
            Button {
                switch viewModel.timerState {
                case .running:           viewModel.pauseTimer()
                case .paused, .autoPaused: viewModel.resumeTimer()
                case .idle:              break
                }
            } label: {
                Image(systemName: viewModel.timerState == .running ? "pause.fill" : "play.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 78, height: 78)
                    .background(
                        Circle()
                            .fill(mainButtonColor)
                            .shadow(color: mainButtonColor.opacity(0.45), radius: 14, x: 0, y: 4)
                    )
            }

            // 다음 페이즈 스킵
            Button { viewModel.skipPomodoroPhase() } label: {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.4))
                    .frame(width: 58, height: 58)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }
        }
    }

    // MARK: - Colors

    private var phaseColor: Color {
        switch viewModel.pomodoroPhase {
        case .focus:      return .orange
        case .shortBreak: return Color(red: 0.3, green: 0.72, blue: 1.0)
        case .longBreak:  return Color(red: 0.72, green: 0.45, blue: 1.0)
        }
    }

    private var mainButtonColor: Color {
        switch viewModel.timerState {
        case .running:           return .blue
        case .paused, .autoPaused: return phaseColor
        case .idle:              return .gray
        }
    }

    private var focusRateColor: Color {
        switch viewModel.focusRate {
        case 80...: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }

    private var backgroundGradient: some View {
        let accent: Color = viewModel.pomodoroPhase == .focus
            ? Color(hex: "2a1a08")
            : Color(hex: "081828")
        return LinearGradient(
            colors: [Color(hex: "1a1a2e"), accent],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Preview
#Preview {
    PomodoroTimerView(viewModel: TimerViewModel())
        .preferredColorScheme(.dark)
}
