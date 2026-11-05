//
//  SessionLiveActivity.swift
//  OrotWidgets
//
//  잠금 화면 · StandBy · 다이내믹 아일랜드의 세션 표시.
//  세션 화면처럼 밤하늘 위에 남은 시간 하나만 크게 두고, 별이 모이는 정도를 작게 곁들입니다.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct SessionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SessionActivityAttributes.self) { context in
            LockScreenSessionView(context: context)
                .activityBackgroundTint(OrotColor.skyNight)
                .activitySystemActionForegroundColor(OrotColor.textPrimary)
        } dynamicIsland: { context in
            let state = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    PhaseLabel(state: state, subject: context.attributes.subject)
                        .padding(.leading, 6)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(state.mansionCaption)
                        .font(OrotFont.regular(12))
                        .foregroundStyle(OrotColor.textCaption)
                        .lineLimit(1)
                        .padding(.trailing, 6)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        HStack(alignment: .center, spacing: 16) {
                            SessionClockText(state: state, size: 44)
                            Spacer(minLength: 0)
                            FormingStarGlyph(formation: state.starFormation, magnitude: state.magnitude, complete: state.phase == .complete, size: 30)
                        }
                        SessionProgress(state: state)
                    }
                    .padding(.horizontal, 6)
                }
            } compactLeading: {
                FormingStarGlyph(formation: state.starFormation, magnitude: state.magnitude, complete: state.phase == .complete, size: 18)
            } compactTrailing: {
                SessionClockText(state: state, size: 14, compact: true)
                    .frame(maxWidth: 52)
            } minimal: {
                FormingStarGlyph(formation: state.starFormation, magnitude: state.magnitude, complete: state.phase == .complete, size: 18)
            }
            .keylineTint(OrotColor.accent)
        }
    }
}

// MARK: - Lock Screen
private struct LockScreenSessionView: View {
    let context: ActivityViewContext<SessionActivityAttributes>

    private var state: SessionActivityAttributes.ContentState { context.state }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            HorizonGlyph()
                .frame(width: 140, height: 22)
                .opacity(0.9)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    PhaseLabel(state: state, subject: context.attributes.subject)
                    Spacer()
                    Text(state.mansionCaption)
                        .font(OrotFont.regular(12))
                        .foregroundStyle(OrotColor.textCaption)
                        .lineLimit(1)
                }

                HStack(alignment: .center) {
                    SessionClockText(state: state, size: 52)
                    Spacer(minLength: 12)
                    FormingStarGlyph(formation: state.starFormation, magnitude: state.magnitude, complete: state.phase == .complete, size: 40)
                        .padding(.trailing, 8)
                }
                .padding(.top, 2)

                SessionProgress(state: state)
                    .padding(.top, 6)

                Text(footnote)
                    .font(OrotFont.regular(12))
                    .foregroundStyle(OrotColor.textSecondary)
                    .lineLimit(1)
                    .padding(.top, 10)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var footnote: String {
        switch state.phase {
        case .focusing:
            return "\(context.attributes.targetMinutes)분 세션 · \(Self.time(state.endsAt))에 끝나요"
        case .paused:
            return "잠시 멈췄어요 · 별빛이 모이기를 기다리는 중"
        case .rest:
            return "\(Self.time(state.endsAt))에 다음 집중이 시작돼요"
        case .complete:
            return "\(state.magnitude)등급 별이 떴어요"
        }
    }

    private static func time(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "a h:mm"
        return f.string(from: date)
    }
}

// MARK: - Pieces
private struct PhaseLabel: View {
    let state: SessionActivityAttributes.ContentState
    let subject: String

    var body: some View {
        HStack(spacing: 7) {
            switch state.phase {
            case .focusing: Circle().fill(OrotColor.accent).frame(width: 6, height: 6)
            case .paused: Circle().strokeBorder(OrotColor.textSecondary, lineWidth: 1).frame(width: 7, height: 7)
            case .rest: Circle().fill(OrotColor.windowLitWarm).frame(width: 6, height: 6)
            case .complete: Circle().fill(OrotColor.starMag1).frame(width: 6, height: 6)
            }
            Text("\(subject) · \(title)")
                .lineLimit(1)
        }
        .font(OrotFont.regular(13))
        .foregroundStyle(color)
    }

    private var title: String {
        switch state.phase {
        case .focusing: return "집중 중"
        case .paused: return "잠시 멈춤"
        case .rest: return "휴식"
        case .complete: return "완료"
        }
    }

    private var color: Color {
        switch state.phase {
        case .focusing, .complete: return OrotColor.textPrimary
        case .paused: return OrotColor.textSecondary
        case .rest: return OrotColor.windowLitWarm
        }
    }
}

/// 시스템이 직접 세는 시계. 집중은 정한 시간이 지나면 그대로 이어서 오버타임을 셉니다.
private struct SessionClockText: View {
    let state: SessionActivityAttributes.ContentState
    let size: CGFloat
    var compact = false

    var body: some View {
        Group {
            switch state.phase {
            case .focusing:
                Text(state.endsAt, style: .timer)
            case .rest:
                Text(timerInterval: Date.now...max(Date.now, state.endsAt), countsDown: true)
            case .paused:
                Text(Self.clock(state.pausedRemaining))
            case .complete:
                Text("완료")
            }
        }
        .font(state.phase == .complete ? OrotFont.light(size * 0.8) : OrotFont.extraLight(size))
        .foregroundStyle(state.phase == .paused ? OrotColor.textSecondary : OrotColor.textPrimary)
        .multilineTextAlignment(compact ? .trailing : .leading)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .contentTransition(.numericText(countsDown: true))
    }

    static func clock(_ time: TimeInterval) -> String {
        let t = Int(max(0, time))
        return String(format: "%d:%02d", t / 60, t % 60)
    }
}

private struct SessionProgress: View {
    let state: SessionActivityAttributes.ContentState

    var body: some View {
        Group {
            switch state.phase {
            case .focusing, .rest:
                ProgressView(timerInterval: state.startedAt...max(state.startedAt.addingTimeInterval(1), state.endsAt), countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
            case .paused:
                ProgressView(value: progressWhilePaused)
            case .complete:
                ProgressView(value: 1)
            }
        }
        .progressViewStyle(.linear)
        .tint(state.phase == .rest ? OrotColor.windowLitWarm.opacity(0.7) : OrotColor.progressFill)
        .labelsHidden()
    }

    private var progressWhilePaused: Double {
        let total = state.endsAt.timeIntervalSince(state.startedAt)
        guard total > 0 else { return 0 }
        return min(1, max(0, 1 - state.pausedRemaining / total))
    }
}

/// 이번 세션의 별 — 모인 만큼 밝아지고, 완료되면 등급 색으로 빛납니다.
private struct FormingStarGlyph: View {
    let formation: Double
    let magnitude: Int
    let complete: Bool
    let size: CGFloat

    var body: some View {
        let color = complete ? OrotColor.star(magnitude: magnitude) : OrotColor.starForming
        let core = size * (complete ? 0.26 : 0.14 + 0.12 * formation)
        ZStack {
            Circle()
                .strokeBorder(OrotColor.starSlotEmpty, style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
                .opacity(complete ? 0 : 1)
            Circle()
                .fill(color.opacity(0.18 * (complete ? 1 : formation)))
                .frame(width: size * 0.8, height: size * 0.8)
                .blur(radius: size * 0.08)
            Circle()
                .fill(color)
                .frame(width: core, height: core)
                .opacity(complete ? 1 : 0.35 + 0.65 * formation)
        }
        .frame(width: size, height: size)
    }
}

/// 오른쪽 아래 지평선 — 불이 꺼진 도시 실루엣
private struct HorizonGlyph: View {
    private let heights: [CGFloat] = [0.45, 0.7, 0.55, 1.0, 0.62, 0.82, 0.4, 0.66, 0.5]

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(heights.indices, id: \.self) { i in
                    Rectangle()
                        .fill(OrotColor.buildingSilhouette)
                        .frame(height: geo.size.height * heights[i])
                        .overlay(alignment: .top) {
                            if i == 3 || i == 5 {
                                Rectangle().fill(OrotColor.windowLitAmber.opacity(0.35)).frame(width: 2, height: 2).padding(.top, 5)
                            }
                        }
                }
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }
}
