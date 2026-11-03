//
//  SessionFocusContent.swift
//  Orot
//
//  집중 중 · 잠시 멈춤 · 오버타임 상태의 앞 레이어(시간 정보와 버튼)
//

import SwiftUI

struct SessionFocusContent: View {
    @ObservedObject var viewModel: TimerViewModel
    let landscape: Bool

    var body: some View {
        if landscape { landscapeLayout } else { portraitLayout }
    }

    // MARK: - Landscape (탁상시계)
    private var landscapeLayout: some View {
        ZStack(alignment: .topLeading) {
            MoonCaption()
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 56)
                .padding(.top, 32)

            FormingStar(formation: viewModel.starFormation, scale: 1.2)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 140)
                .padding(.top, 102)

            VStack(alignment: .leading, spacing: 14) {
                statusRow
                SessionClock(text: viewModel.clockText, size: 172, color: clockColor, overtime: viewModel.isOvertime)
                    .padding(.leading, -8)
                    .onTapGesture(count: 3, perform: openDebug)
                footer(barWidth: 240, alignment: .leading)
                    .padding(.top, 10)
            }
            .padding(.leading, OrotSpace.screenInsetH)
            .padding(.top, 66)

            controls
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 60)
                .padding(.bottom, 70)
        }
    }

    // MARK: - Portrait
    private var portraitLayout: some View {
        VStack(spacing: 0) {
            MoonCaption(size: 18)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 28)
                .padding(.top, 64)

            Spacer()
            FormingStar(formation: viewModel.starFormation, scale: 1.6)
                .frame(height: 40)
            Spacer()

            VStack(spacing: 14) {
                statusRow
                SessionClock(text: viewModel.clockText, size: 116, color: clockColor, overtime: viewModel.isOvertime)
                    .onTapGesture(count: 3, perform: openDebug)
                footer(barWidth: 200, alignment: .center)
                    .padding(.top, 6)
            }
            .padding(.horizontal, 24)

            Spacer()
            Spacer()

            controls
                .frame(maxWidth: .infinity)
                .padding(.bottom, 36)
        }
    }

    // MARK: - Pieces

    private var statusRow: some View {
        HStack(spacing: 12) {
            SessionBadge(state: viewModel.badgeKind)
            Text(viewModel.subjectName)
                .font(OrotFont.label)
                .tracking(0.3)
                .foregroundStyle(OrotColor.textSecondary)
        }
        .animation(OrotMotion.tap, value: viewModel.badgeKind)
    }

    private var clockColor: Color {
        viewModel.badgeKind == .paused ? OrotColor.textSecondary : OrotColor.textPrimary
    }

    private var isPaused: Bool { viewModel.badgeKind == .paused }

    @ViewBuilder
    private func footer(barWidth: CGFloat, alignment: HorizontalAlignment) -> some View {
        if isPaused {
            VStack(alignment: alignment, spacing: 4) {
                Text("별빛이 잠시 모이기를 멈췄어요")
                    .font(OrotFont.body)
                    .foregroundStyle(OrotColor.textPrimary)
                Text(pausedCaption)
                    .font(OrotFont.caption)
                    .tracking(0.5)
                    .foregroundStyle(OrotColor.textCaption)
            }
            .multilineTextAlignment(alignment == .center ? .center : .leading)
        } else if alignment == .center {
            VStack(spacing: 10) {
                SessionProgressBar(progress: viewModel.progress, width: barWidth)
                ratioText
            }
        } else {
            HStack(spacing: 14) {
                SessionProgressBar(progress: viewModel.progress, width: barWidth)
                ratioText
            }
        }
    }

    private var pausedCaption: String {
        if viewModel.timerState == .paused { return "다시 시작하면 이어서 모을게요" }
        return "자리로 돌아오면 이어서 모을게요 · 비운 시간 \(TimerViewModel.clock(viewModel.awayDuration))"
    }

    private var ratioText: some View {
        let ratio = Int((viewModel.pureFocusRatio * 100).rounded())
        let text = viewModel.isOvertime
            ? "정한 \(viewModel.targetMinutes)분 완료 · 흐름을 이어가는 중 · 순수 집중 \(ratio)%"
            : (viewModel.isDetectionEnabled ? "순수 집중 \(ratio)%" : "타이머로만 재는 중")
        return Text(text)
            .font(OrotFont.regular(13))
            .foregroundStyle(OrotColor.textSecondary)
            .monospacedDigit()
    }

    @ViewBuilder
    private var controls: some View {
        let fill = landscape ? Color.clear : OrotColor.skyNight.opacity(0.7)
        if viewModel.isOvertime {
            Button("여기서 마치기") { viewModel.finishFocus() }
                .font(OrotFont.regular(13))
                .foregroundStyle(OrotColor.textSecondary)
                .padding(.horizontal, 20)
                .frame(height: 44)
                .background(Capsule().fill(fill))
                .overlay(Capsule().strokeBorder(OrotColor.hairline))
                .buttonStyle(.plain)
        } else {
            HStack(spacing: landscape ? 12 : 16) {
                if viewModel.timerState == .paused {
                    SessionIconButton(icon: .play, background: fill) { viewModel.resume() }
                        .accessibilityLabel("다시 시작")
                } else {
                    SessionIconButton(icon: .pause, background: fill) { viewModel.pause() }
                        .accessibilityLabel("일시정지")
                }
                LongPressStopButton(background: fill) { viewModel.finishFocus() }
            }
        }
    }

    private func openDebug() {
        #if DEBUG
        viewModel.showDebugView = true
        #endif
    }
}
