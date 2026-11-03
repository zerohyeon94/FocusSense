//
//  SessionView.swift
//  Orot
//
//  세션 전체 화면 — 화면 비율에 따라 가로(탁상시계) / 세로 배치를 고릅니다.
//  레이어는 뒤에서부터 하늘(별 · 달) → 도시 스카이라인 → 시간 정보 순서입니다.
//

import SwiftUI

struct SessionView: View {
    @ObservedObject var viewModel: TimerViewModel
    /// "나의 밤하늘"을 눌렀을 때 탭 이동
    let onOpenNightSky: () -> Void

    var body: some View {
        GeometryReader { geo in
            let landscape = geo.size.width > geo.size.height
            ZStack {
                SessionSkyBackground(viewModel: viewModel, landscape: landscape)

                switch viewModel.phase {
                case .focusing:
                    SessionFocusContent(viewModel: viewModel, landscape: landscape)
                case .complete:
                    SessionCompleteView(viewModel: viewModel, landscape: landscape) {
                        viewModel.closeSession()
                        onOpenNightSky()
                    }
                case .rest:
                    SessionRestView(viewModel: viewModel, landscape: landscape)
                }
            }
            .animation(.easeInOut(duration: 0.8), value: viewModel.phase)
        }
        .ignoresSafeArea()
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $viewModel.showDebugView) {
            AIAnalysisView(viewModel: viewModel)
        }
    }
}

// MARK: - Sky Background
private struct SessionSkyBackground: View {
    @ObservedObject var viewModel: TimerViewModel
    let landscape: Bool

    private static let landscapeBase = CGSize(width: 844, height: 390)
    private static let portraitBase = CGSize(width: 390, height: 844)

    var body: some View {
        let look = self.look
        ZStack(alignment: .bottom) {
            look.sky
            StarFieldView(
                field: landscape ? .landscape : .portrait,
                baseSize: landscape ? Self.landscapeBase : Self.portraitBase,
                progress: look.starProgress,
                maxOpacity: look.starOpacity
            )
            CityGlow(height: landscape ? look.glowHeight.landscape : look.glowHeight.portrait, opacity: look.glow, color: look.glowColor)
            SkylineView(
                style: landscape ? .landscape : .portrait,
                progress: look.windowProgress,
                buildingColor: look.building,
                windowIntensity: look.windowIntensity
            )
        }
        .animation(OrotMotion.sky, value: viewModel.phase)
        .animation(OrotMotion.sky, value: viewModel.isOvertime)
    }

    private struct Look {
        var sky: Color
        var starProgress: Double
        var starOpacity: Double
        var glow: Double
        var glowColor = OrotColor.cityGlow
        var glowHeight: (landscape: CGFloat, portrait: CGFloat) = (120, 240)
        var windowProgress: Double
        var windowIntensity = 0.55
        var building = OrotColor.buildingSilhouette
    }

    private var look: Look {
        switch viewModel.phase {
        case .focusing:
            let p = viewModel.progress
            return Look(
                sky: viewModel.isOvertime ? OrotColor.skyDeepNight : OrotColor.skyNight,
                starProgress: p,
                starOpacity: viewModel.isOvertime ? 0.45 : 0.35,
                glow: (1 - p) * 0.35,
                windowProgress: p
            )
        case .complete:
            return Look(sky: OrotColor.skyDeepNight, starProgress: 1, starOpacity: 0.45, glow: 0, windowProgress: 1.1, building: Color(hex: 0x13161A))
        case .rest:
            // 휴식은 하늘을 한 단계 밝히고 꺼졌던 창문을 다시 켭니다.
            return Look(
                sky: OrotColor.skyEvening, starProgress: 0.3, starOpacity: 0.22,
                glow: 0.6, glowColor: Color(hex: 0x3D2E1C), glowHeight: (160, 300),
                windowProgress: -1, windowIntensity: 0.42, building: Color(hex: 0x191D22)
            )
        }
    }
}

// MARK: - Shared Pieces

/// 남은 시간 / 오버타임 시계
struct SessionClock: View {
    let text: String
    let size: CGFloat
    var color: Color = OrotColor.textPrimary
    var overtime = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            if overtime {
                Text("+")
                    .font(OrotFont.extraLight(size * 0.55))
                    .foregroundStyle(OrotColor.stateOvertime)
            }
            Text(text)
                .font(OrotFont.extraLight(size))
                .tracking(-size * 0.02)
                .foregroundStyle(color)
                .contentTransition(.numericText(countsDown: !overtime))
        }
        .fixedSize()
        // 시안의 line-height 0.9 — 한글 폰트의 기본 줄 높이는 숫자에 비해 너무 큽니다.
        .frame(height: size * 0.9)
        .animation(.easeInOut(duration: 0.4), value: text)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(overtime ? "오버타임 \(text)" : "남은 시간 \(text)")
    }
}

/// 1px 진행 막대
struct SessionProgressBar: View {
    let progress: Double
    let width: CGFloat

    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle().fill(OrotColor.hairline)
            Rectangle().fill(OrotColor.progressFill).frame(width: width * progress)
        }
        .frame(width: width, height: 1)
        .animation(.linear(duration: 1), value: progress)
    }
}

/// 이번 세션의 별 — 순수 집중이 쌓이는 만큼 천천히 밝아집니다. 멈춘 동안에는 그대로 머뭅니다.
struct FormingStar: View {
    let formation: Double
    var scale: CGFloat = 1

    var body: some View {
        let size = (2 + 3.5 * formation) * scale
        Circle()
            .fill(OrotColor.starForming)
            .frame(width: size, height: size)
            .opacity(0.12 + 0.68 * formation)
            .shadow(color: OrotColor.starForming.opacity(0.35), radius: 4 * scale)
            .animation(OrotMotion.star, value: formation)
            .accessibilityHidden(true)
    }
}

// MARK: - Session Constellation
/// 하늘 레이어의 진행 중인 수와 캡션. 28수를 모두 채운 뒤에는 별 하나만 보입니다.
struct SessionConstellation: View {
    let sky: SkyProgress
    /// 그릴 수 (nil이면 지금 채우는 수)
    var mansion: Mansion?
    var next: ConstellationView.NextSlot
    var highlightLast = false
    let size: CGSize
    var starScale: CGFloat = 1
    var background: Color = OrotColor.skyNight
    var lineColor = Color(hex: 0x3E4247)
    let caption: String
    var captionAlignment: Alignment = .center

    var body: some View {
        VStack(alignment: captionAlignment == .leading ? .leading : .center, spacing: 10) {
            if let m = mansion ?? sky.currentMansion {
                ConstellationView(
                    mansion: m,
                    magnitudes: sky.magnitudes(m),
                    next: next,
                    highlightLast: highlightLast,
                    starScale: starScale,
                    padding: 8,
                    maxSpacing: size.width / 40,
                    background: background,
                    lineColor: lineColor
                )
                .frame(width: size.width, height: size.height)
            } else if case .forming(let f) = next {
                FormingStar(formation: f, scale: starScale)
                    .frame(width: size.width, height: size.height)
            }
            MansionCaption(text: caption)
        }
    }
}

// MARK: - Sky Captions
extension SkyProgress {
    /// "두(斗) · 3 / 6"
    func progressCaption(_ mansion: Mansion? = nil) -> String {
        guard let m = mansion ?? currentMansion else { return "스물여덟 수를 모두 채웠어요" }
        return "\(m.label) · \(filledCount(m)) / \(m.starCount)"
    }

    /// 다음에 채울 별 순서 ("네 번째")
    var nextStarOrdinal: String {
        guard let m = currentMansion else { return "" }
        return "\(KoreanOrdinal.word(filledCount(m) + 1)) 번째"
    }

    /// 세션 완료 직후 캡션
    var completionCaption: String {
        guard let last = lastPlaced else { return "" }
        let m = last.mansion
        let remaining = m.starCount - filledCount(m)
        if remaining == 0 { return "\(m.label) · 별자리 완성" }
        let more = remaining <= 10 ? "\(KoreanOrdinal.count(remaining)) 별만 더" : "별 \(remaining)개만 더"
        return "\(m.label) · \(filledCount(m)) / \(m.starCount) · \(more) 모이면 완성"
    }
}
