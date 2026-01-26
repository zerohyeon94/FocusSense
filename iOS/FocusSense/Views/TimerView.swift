//
//  TimerView.swift
//  FocusSense
//
//  메인 타이머 화면 - 플립 시계 스타일
//

import SwiftUI

struct TimerView: View {
    @ObservedObject var viewModel: TimerViewModel
    @State private var showingResetAlert = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 배경 (집중 상태에 따라 변화)
                backgroundGradient
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.5), value: viewModel.currentFocusState.level)
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // 집중 상태 인디케이터
                    FocusStatusIndicator(focusState: viewModel.currentFocusState)
                    
                    // 메인 타이머 디스플레이
                    TimerDisplay(
                        elapsedTime: viewModel.formattedElapsedTime,
                        netFocusTime: viewModel.formattedNetFocusTime,
                        focusRate: viewModel.focusRate
                    )
                    
                    Spacer()
                    
                    // 컨트롤 버튼
                    TimerControls(
                        timerState: viewModel.timerState,
                        onStart: { viewModel.startTimer() },
                        onPause: { viewModel.pauseTimer() },
                        onResume: { viewModel.resumeTimer() },
                        onStop: { viewModel.stopTimer() },
                        onReset: { showingResetAlert = true }
                    )
                    
                    Spacer()
                        .frame(height: 50)
                }
                .padding()
            }
        }
        .alert("타이머 리셋", isPresented: $showingResetAlert) {
            Button("취소", role: .cancel) { }
            Button("리셋", role: .destructive) {
                viewModel.resetTimer()
            }
        } message: {
            Text("타이머를 리셋하시겠습니까?\n현재 세션의 기록이 삭제됩니다.")
        }
        .alert(viewModel.alertMessage, isPresented: $viewModel.showAlert) {
            Button("확인") {
                if viewModel.timerState == .autoPaused {
                    viewModel.resumeTimer()
                }
            }
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
    let elapsedTime: String
    let netFocusTime: String
    let focusRate: Double
    
    var body: some View {
        VStack(spacing: 20) {
            // 메인 시간 (총 경과 시간)
            Text(elapsedTime)
                .font(.system(size: 72, weight: .light, design: .monospaced))
                .foregroundColor(.white)
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
    let onStart: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onStop: () -> Void
    let onReset: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            // 리셋 버튼
            if timerState != .idle {
                ControlButton(
                    icon: "arrow.counterclockwise",
                    color: .gray,
                    action: onReset
                )
            }
            
            // 메인 버튼 (시작/일시정지/재개)
            MainControlButton(
                timerState: timerState,
                onStart: onStart,
                onPause: onPause,
                onResume: onResume
            )
            
            // 정지 버튼
            if timerState == .running || timerState == .paused || timerState == .autoPaused {
                ControlButton(
                    icon: "stop.fill",
                    color: .red,
                    action: onStop
                )
            }
        }
    }
}

// MARK: - Control Button
struct ControlButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview
#Preview {
    TimerView(viewModel: TimerViewModel())
        .preferredColorScheme(.dark)
}
