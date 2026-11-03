//
//  SessionRecordDetailView.swift
//  Orot
//
//  세션 상세 — 순수 집중 · 타임라인 · 사건 목록.
//  미확인 구간(화면이 잠겨 측정하지 못한 시간)은 경고처럼 보이지 않게 달빛 청회색 빗금으로 표시합니다.
//

import SwiftUI

struct SessionRecordDetailView: View {
    let session: StudySession
    let sky: SkyProgress

    @Environment(\.dismiss) private var dismiss

    private var segments: [TimelineSegment] { TimelineSegment.build(from: session) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Button { dismiss() } label: {
                    Text("‹ 기록").font(OrotFont.regular(15)).foregroundStyle(OrotColor.textSecondary).frame(height: 44)
                }
                .buttonStyle(.plain)

                header.padding(.top, 10)
                stats.padding(.top, 24)
                timeline.padding(.top, 22)
                events.padding(.top, 20)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(OrotColor.skyNight.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 16)
                .fill(OrotColor.skyDeepNight)
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(OrotColor.hairline))
                .overlay(StarDot(magnitude: session.starMagnitude, scale: 1.6))
                .frame(width: 72, height: 72)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(RecordFormat.monthDayWeekday(session.startTime)) · \(RecordFormat.time(session.startTime)) – \(RecordFormat.time(session.endTime ?? session.startTime))")
                    .font(OrotFont.caption).tracking(0.5).foregroundStyle(OrotColor.textCaption)
                Text("\(session.studyPlanTitle ?? "이름 없는 대상") · \(RecordFormat.plannedMinutes(session))분 세션")
                    .font(OrotFont.title).foregroundStyle(OrotColor.textPrimary)
                Text(starLine).font(OrotFont.regular(13)).foregroundStyle(OrotColor.textSecondary)
            }
        }
    }

    private var starLine: String {
        let star = "\(session.starMagnitude)등급 별"
        guard let place = sky.place(of: session.id) else { return star }
        return "\(star) · \(place.mansion.label)의 \(KoreanOrdinal.word(place.star + 1)) 번째 별이 됐어요"
    }

    // MARK: - Stats
    private var stats: some View {
        HStack(alignment: .bottom, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text(TimerViewModel.clock(session.netFocusTime)).font(OrotFont.extraLight(40)).foregroundStyle(OrotColor.textPrimary)
                Text("순수 집중").font(OrotFont.caption).tracking(0.5).foregroundStyle(OrotColor.textSecondary)
            }
            small(TimerViewModel.clock(session.measuredDuration), "전체")
            small(session.isDetectionEnabled ? "\(Int((session.pureFocusRatio * 100).rounded()))%" : "—", "집중 비율")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 20)
        .overlay(alignment: .bottom) { Rectangle().fill(OrotColor.hairline).frame(height: 1) }
    }

    private func small(_ value: String, _ title: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(OrotFont.light(18)).monospacedDigit().foregroundStyle(Color(hex: 0x9C9890))
            Text(title).font(OrotFont.caption).tracking(0.5).foregroundStyle(OrotColor.textCaption)
        }
    }

    // MARK: - Timeline
    private var timeline: some View {
        let total = max(1, segments.reduce(0) { $0 + $1.duration })
        return VStack(alignment: .leading, spacing: 10) {
            Text("타임라인").font(OrotFont.body).foregroundStyle(OrotColor.textPrimary)
            GeometryReader { geo in
                HStack(spacing: 2) {
                    ForEach(segments) { seg in
                        seg.kind.fill
                            .frame(width: max(2, (geo.size.width - CGFloat(segments.count - 1) * 2) * seg.duration / total))
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                            .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(seg.kind == .paused ? OrotColor.textCaption : .clear))
                    }
                }
            }
            .frame(height: 16)
            HStack {
                ForEach(Array(timeLabels.enumerated()), id: \.offset) { i, t in
                    if i > 0 { Spacer() }
                    Text(t)
                }
            }
            .font(OrotFont.regular(11)).monospacedDigit().foregroundStyle(OrotColor.textCaption)
            HStack(spacing: 16) {
                ForEach([TimelineSegment.Kind.focus, .paused, .unverified], id: \.self) { k in
                    HStack(spacing: 6) {
                        k.fill.frame(width: 12, height: 8).clipShape(RoundedRectangle(cornerRadius: 2))
                            .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(k == .paused ? OrotColor.textCaption : .clear))
                        Text(k.title)
                    }
                }
            }
            .font(OrotFont.caption).foregroundStyle(OrotColor.textSecondary)
        }
    }

    private var timeLabels: [String] {
        let start = session.startTime
        let total = session.measuredDuration
        return [0, 1.0 / 3, 2.0 / 3, 1].map { RecordFormat.time(start.addingTimeInterval(total * $0)) }
    }

    // MARK: - Events
    private var events: some View {
        VStack(spacing: 0) {
            eventRow(time: session.startTime, kind: .focus, title: "집중 시작", detail: "\(session.studyPlanTitle ?? "이름 없는 대상") · \(RecordFormat.plannedMinutes(session))분")
            ForEach(segments.filter { $0.kind != .focus }) { seg in
                eventRow(
                    time: seg.start,
                    kind: seg.kind,
                    title: "\(seg.kind.title) · \(RecordFormat.minutesSeconds(seg.duration))",
                    detail: seg.kind == .paused
                        ? "자리를 비운 시간이에요. 별빛이 잠시 모이기를 멈췄어요."
                        : "화면이 잠겼거나 카메라를 쓸 수 없던 시간이에요. 측정하지 못해 순수 집중에서는 뺐어요."
                )
            }
            if let end = session.endTime {
                eventRow(time: end, kind: .focus, title: "세션 완료", detail: "\(session.starMagnitude)등급 별이 떴어요.")
            }
        }
    }

    private func eventRow(time: Date, kind: TimelineSegment.Kind, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(RecordFormat.time(time)).font(OrotFont.caption).monospacedDigit().foregroundStyle(OrotColor.textCaption).frame(width: 44, alignment: .leading)
            kind.fill.frame(width: 8, height: 8).clipShape(RoundedRectangle(cornerRadius: 2))
                .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(kind == .paused ? OrotColor.textCaption : .clear))
                .padding(.top, 5)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(OrotFont.regular(13)).foregroundStyle(kind == .unverified ? OrotColor.stateOvertime : OrotColor.textPrimary)
                Text(detail).font(OrotFont.caption).lineSpacing(3).foregroundStyle(Color(hex: 0x7E7B74))
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
        .overlay(alignment: .top) { Rectangle().fill(Color(hex: 0x23272B)).frame(height: 1) }
    }
}

// MARK: - Timeline Segment
struct TimelineSegment: Identifiable {
    enum Kind: Hashable {
        case focus, paused, unverified

        var title: String {
            switch self {
            case .focus: return "집중 중"
            case .paused: return "잠시 멈춤"
            case .unverified: return "미확인 구간"
            }
        }

        @ViewBuilder
        var fill: some View {
            switch self {
            case .focus: OrotColor.progressFill
            case .paused: Color.clear
            case .unverified: DiagonalHatch()
            }
        }
    }

    let id: Int
    let kind: Kind
    let start: Date
    var duration: TimeInterval

    /// 1초 단위 기록을 같은 종류끼리 이어 붙입니다.
    static func build(from session: StudySession) -> [TimelineSegment] {
        let records = session.focusRecords.sorted { $0.timestamp < $1.timestamp }
        var result: [TimelineSegment] = []
        for r in records {
            let kind: Kind
            switch r.focusLevel {
            case .focused: kind = .focus
            case .unknown: kind = session.isDetectionEnabled ? .unverified : .focus
            default: kind = .paused
            }
            if let last = result.last, last.kind == kind {
                result[result.count - 1].duration += r.duration
            } else {
                result.append(TimelineSegment(id: result.count, kind: kind, start: r.timestamp, duration: r.duration))
            }
        }
        return result
    }
}

/// 달빛 청회색 빗금
private struct DiagonalHatch: View {
    var body: some View {
        Canvas { context, size in
            var x: CGFloat = -size.height
            while x < size.width {
                var p = Path()
                p.move(to: CGPoint(x: x, y: size.height))
                p.addLine(to: CGPoint(x: x + size.height, y: 0))
                context.stroke(p, with: .color(OrotColor.stateOvertime.opacity(0.7)), lineWidth: 1.4)
                x += 4
            }
        }
    }
}
