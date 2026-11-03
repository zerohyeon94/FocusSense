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
            if !showsCameraCard {
                MoonCaption()
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 56)
                    .padding(.top, 32)

                SessionConstellation(
                    sky: viewModel.sky,
                    next: .forming(viewModel.starFormation),
                    size: CGSize(width: 160, height: 100),
                    caption: constellationCaption,
                    captionAlignment: .leading
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 110)
                .padding(.top, 62)
            }

            if viewModel.showsThermalBanner {
                ExceptionBanner(message: Self.thermalMessage, detail: Self.thermalDetail, compact: true)
                    .padding(.leading, OrotSpace.screenInsetH)
                    .padding(.top, 18)
                    .transition(.opacity)
            }

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

            if showsCameraCard {
                cameraCard(compact: true)
                    .frame(width: 268)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 48)
                    .padding(.top, 40)
                    .transition(.opacity)
            } else {
                controls
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, 60)
                    .padding(.bottom, 70)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showsCameraCard)
        .animation(.easeInOut(duration: 0.4), value: viewModel.showsThermalBanner)
    }

    // MARK: - Portrait
    private var portraitLayout: some View {
        VStack(spacing: 0) {
            MoonCaption(size: 18)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 28)
                .padding(.top, 64)
                .opacity(viewModel.showsThermalBanner ? 0 : 1)
                .overlay(alignment: .top) {
                    if viewModel.showsThermalBanner {
                        ExceptionBanner(message: Self.thermalMessage, detail: Self.thermalDetail)
                            .padding(.horizontal, 16)
                            .padding(.top, 54)
                            .transition(.opacity)
                    }
                }

            SessionConstellation(
                sky: viewModel.sky,
                next: .forming(viewModel.starFormation),
                size: CGSize(width: 272, height: 170),
                starScale: 1.36,
                caption: constellationCaption
            )
            .padding(.top, 50)
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
                .opacity(showsCameraCard ? 0 : 1)
        }
        .overlay(alignment: .bottom) {
            if showsCameraCard {
                cameraCard(compact: false)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showsCameraCard)
        .animation(.easeInOut(duration: 0.4), value: viewModel.showsThermalBanner)
    }

    // MARK: - Exceptions

    private static let thermalMessage = "기기가 따뜻해져 자리 확인을 10초마다로 늦췄어요."
    private static let thermalDetail = "그대로 집중하시면 돼요."

    private var showsCameraCard: Bool {
        viewModel.isTimerFallback && !viewModel.cameraIssueAcknowledged && viewModel.timerState == .running
    }

    @ViewBuilder
    private func cameraCard(compact: Bool) -> some View {
        if viewModel.cameraIssue == .permission {
            ExceptionCard(
                message: "카메라 권한이 꺼져 있어서 자리를 확인할 수 없어요.",
                detail: "설정 앱에서 카메라를 켜거나, 이번 세션은 타이머로 계속하세요.",
                primary: "설정 앱 열기",
                secondary: "타이머로 계속하기",
                onPrimary: {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                },
                onSecondary: viewModel.continueWithTimer,
                compact: compact
            )
        } else {
            ExceptionCard(
                message: "다른 앱이 카메라를 쓰고 있어서 자리를 확인할 수 없어요.",
                detail: "이번 세션은 타이머로 계속하거나, 카메라가 풀리면 다시 연결할게요.",
                primary: "타이머로 계속하기",
                secondary: "카메라 다시 연결",
                onPrimary: viewModel.continueWithTimer,
                onSecondary: viewModel.reconnectCamera,
                compact: compact
            )
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

    private var constellationCaption: String {
        let sky = viewModel.sky
        guard let m = sky.currentMansion else { return sky.progressCaption() }
        if viewModel.isOvertime { return "\(m.label) · \(sky.nextStarOrdinal) 별이 자리를 잡았어요" }
        if isPaused && !landscape { return "\(sky.progressCaption()) · \(sky.nextStarOrdinal) 별이 기다리는 중" }
        return sky.progressCaption()
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
        let text: String
        if viewModel.isTimerFallback {
            text = landscape ? "자리 확인 쉬는 중" : "자리 확인 쉬는 중 · 시간은 계속 흘러요"
        } else if viewModel.isOvertime {
            text = "정한 \(viewModel.targetMinutes)분 완료 · 흐름을 이어가는 중 · 순수 집중 \(ratio)%"
        } else if viewModel.isDetectionEnabled {
            text = viewModel.isThermalSlowed ? "순수 집중 \(ratio)% · 확인 10초 간격" : "순수 집중 \(ratio)%"
        } else {
            text = "타이머로만 재는 중"
        }
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
