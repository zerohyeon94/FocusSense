//
//  RecordsView.swift
//  Orot
//
//  기록 탭 — 잔디 대신 하루를 밤하늘 한 조각으로 보여 줍니다.
//  순수 집중이 길수록 조각의 하늘이 깊은 밤 쪽으로 어두워지고, 그날 만든 별이 그 안에 떠요.
//

import SwiftUI

enum RecordRange: CaseIterable {
    case day, week, month
    var label: String { switch self { case .day: "일"; case .week: "주"; case .month: "월" } }
}

struct RecordsView: View {
    @ObservedObject var sessionStore: StudySessionStore
    let onStartFirstSession: () -> Void

    @State private var range: RecordRange = .week
    @State private var path: [UUID] = []

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if sessionStore.sessions.isEmpty {
                    RecordsEmptyView(onStart: onStartFirstSession)
                } else {
                    content
                }
            }
            .background(OrotColor.skyNight.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: UUID.self) { id in
                if let session = sessionStore.sessions.first(where: { $0.id == id }) {
                    SessionRecordDetailView(session: session, sky: sessionStore.sky)
                }
            }
        }
    }

    private var content: some View {
        let summary = RecordSummary(range: range, sessions: sessionStore.sessions)
        return VStack(spacing: 0) {
            RecordsHeader(range: $range).padding(.top, 12)
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    summaryRow(summary)
                    switch range {
                    case .day: DaySessionTiles(sessions: summary.sessions)
                    case .week: WeekSkyTiles(sessions: sessionStore.sessions)
                    case .month: MonthSkyTiles(sessions: sessionStore.sessions)
                    }
                    SkyLegend()
                    SubjectBreakdown(sessions: summary.sessions)
                    recentSessions
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func summaryRow(_ s: RecordSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(s.periodLabel)
                .font(OrotFont.caption)
                .tracking(0.5)
                .foregroundStyle(OrotColor.textCaption)
            HStack(alignment: .bottom, spacing: 24) {
                stat(RecordFormat.hm(s.pure), "순수 집중", big: true)
                stat(RecordFormat.hm(s.total), "전체 세션")
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        StarDot(magnitude: 2, scale: 0.9)
                        Text("\(s.sessions.count)개").font(OrotFont.light(18)).foregroundStyle(Color(hex: 0x9C9890))
                    }
                    Text("만든 별").font(OrotFont.caption).tracking(0.5).foregroundStyle(OrotColor.textCaption)
                }
            }
        }
    }

    private func stat(_ value: String, _ title: String, big: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(big ? OrotFont.extraLight(40) : OrotFont.light(18))
                .monospacedDigit()
                .foregroundStyle(big ? OrotColor.textPrimary : Color(hex: 0x9C9890))
            Text(title)
                .font(OrotFont.caption)
                .tracking(0.5)
                .foregroundStyle(big ? OrotColor.textSecondary : OrotColor.textCaption)
        }
    }

    private var recentSessions: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("최근 세션").font(OrotFont.body).foregroundStyle(OrotColor.textPrimary).padding(.bottom, 6)
            ForEach(sessionStore.sessions.prefix(5), id: \.id) { s in
                Button { path.append(s.id) } label: {
                    HStack(spacing: 12) {
                        StarDot(magnitude: s.starMagnitude).frame(width: 14)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(s.studyPlanTitle ?? "이름 없는 대상") · \(RecordFormat.plannedMinutes(s))분")
                                .font(OrotFont.regular(13))
                                .foregroundStyle(OrotColor.textPrimary)
                            Text("\(RecordFormat.relativeDayTime(s.startTime)) · 순수 집중 \(Int((s.pureFocusRatio * 100).rounded()))%")
                                .font(OrotFont.regular(11))
                                .tracking(0.4)
                                .foregroundStyle(OrotColor.textCaption)
                        }
                        Spacer()
                        Text("›").font(OrotFont.regular(15)).foregroundStyle(OrotColor.textCaption)
                    }
                    .frame(minHeight: 52)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .overlay(alignment: .top) { Rectangle().fill(OrotColor.hairline).frame(height: 1) }
            }
        }
    }
}

// MARK: - Header
struct RecordsHeader: View {
    @Binding var range: RecordRange
    var disabled = false

    var body: some View {
        HStack {
            Text("기록").font(OrotFont.title).foregroundStyle(OrotColor.textPrimary)
            Spacer()
            HStack(spacing: 0) {
                ForEach(RecordRange.allCases, id: \.self) { r in
                    Button { range = r } label: {
                        Text(r.label)
                            .font(OrotFont.regular(13))
                            .foregroundStyle(range == r ? OrotColor.textPrimary : OrotColor.textSecondary)
                            .frame(minWidth: 44, minHeight: 30)
                            .padding(.horizontal, 2)
                            .background(Capsule().fill(range == r ? OrotColor.accentSubtle : .clear))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .overlay(Capsule().strokeBorder(OrotColor.hairline))
            .animation(OrotMotion.tap, value: range)
            .opacity(disabled ? 0.5 : 1)
            .disabled(disabled)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Empty (4-3)
private struct RecordsEmptyView: View {
    let onStart: () -> Void
    @State private var range: RecordRange = .week

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RecordsHeader(range: $range, disabled: true).padding(.top, 12)
            HStack(spacing: 6) {
                ForEach(Array(["수", "목", "금", "토", "일", "월", "오늘"].enumerated()), id: \.offset) { i, day in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(OrotColor.skyDusk)
                            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color(hex: 0x2D3237)))
                            .frame(height: 132)
                            .opacity(0.55)
                        Text(day).font(OrotFont.caption).foregroundStyle(i == 6 ? OrotColor.textPrimary : OrotColor.textCaption)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 34)

            VStack(alignment: .leading, spacing: 14) {
                Text("아직 쌓인 하늘이\n없어요").font(OrotFont.light(28)).lineSpacing(4).foregroundStyle(OrotColor.textPrimary)
                Text("첫 세션을 마치면 오늘의 하늘 조각이 여기에 놓이고, 그 안에 별이 떠요. 집중할수록 조각의 하늘은 깊은 밤이 돼요.")
                    .font(OrotFont.body).lineSpacing(6).foregroundStyle(Color(hex: 0x908D85))
            }
            .padding(.horizontal, 32)
            .padding(.top, 40)

            Spacer()
            Button("첫 세션 시작하기", action: onStart)
                .buttonStyle(OrotPrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 37)
        }
    }
}

// MARK: - Legend
private struct SkyLegend: View {
    var body: some View {
        HStack(spacing: 8) {
            Text("집중이 짧은 날")
            HStack(spacing: 2) {
                ForEach([OrotColor.skyDusk, OrotColor.skyEvening, OrotColor.skyLate, OrotColor.skyDeepNight], id: \.self) { c in
                    RoundedRectangle(cornerRadius: 2).fill(c).frame(width: 14, height: 8)
                        .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(c == OrotColor.skyDeepNight ? OrotColor.hairline : .clear))
                }
            }
            Text("깊은 밤")
        }
        .font(OrotFont.regular(11))
        .foregroundStyle(OrotColor.textCaption)
    }
}

// MARK: - Subjects
private struct SubjectBreakdown: View {
    let sessions: [StudySession]
    private static let colors = [OrotColor.accent, Color(hex: 0x7F735E), Color(hex: 0x4F473A), Color(hex: 0x86A4B3), Color(hex: 0x6B7079)]

    var body: some View {
        let groups = Dictionary(grouping: sessions) { $0.studyPlanTitle ?? "이름 없는 대상" }
            .map { (name: $0.key, pure: $0.value.reduce(0) { $0 + $1.netFocusTime }) }
            .filter { $0.pure > 0 }
            .sorted { $0.pure > $1.pure }
        let total = max(1, groups.reduce(0) { $0 + $1.pure })
        if !groups.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("집중 대상").font(OrotFont.body).foregroundStyle(OrotColor.textPrimary)
                GeometryReader { geo in
                    HStack(spacing: 3) {
                        ForEach(Array(groups.enumerated()), id: \.offset) { i, g in
                            RoundedRectangle(cornerRadius: 2).fill(color(i))
                                .frame(width: max(2, (geo.size.width - CGFloat(groups.count - 1) * 3) * g.pure / total))
                        }
                    }
                }
                .frame(height: 8)
                VStack(spacing: 8) {
                    ForEach(Array(groups.enumerated()), id: \.offset) { i, g in
                        HStack(spacing: 10) {
                            RoundedRectangle(cornerRadius: 2).fill(color(i)).frame(width: 8, height: 8)
                            Text(g.name).foregroundStyle(OrotColor.textPrimary)
                            Spacer()
                            Text(RecordFormat.hoursMinutes(g.pure)).foregroundStyle(OrotColor.textSecondary)
                            Text("\(Int((g.pure / total * 100).rounded()))%").frame(width: 36, alignment: .trailing).foregroundStyle(OrotColor.textCaption)
                        }
                        .font(OrotFont.regular(13))
                        .monospacedDigit()
                    }
                }
            }
        }
    }

    private func color(_ i: Int) -> Color { Self.colors[i % Self.colors.count] }
}

// MARK: - Summary
struct RecordSummary {
    let periodLabel: String
    let sessions: [StudySession]
    var pure: TimeInterval { sessions.reduce(0) { $0 + $1.netFocusTime } }
    var total: TimeInterval { sessions.reduce(0) { $0 + $1.measuredDuration } }

    init(range: RecordRange, sessions all: [StudySession], now: Date = Date()) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        switch range {
        case .day:
            periodLabel = "오늘 · \(RecordFormat.monthDayWeekday(now))"
            sessions = all.filter { cal.isDate($0.startTime, inSameDayAs: now) }
        case .week:
            let start = cal.date(byAdding: .day, value: -6, to: today)!
            periodLabel = "최근 7일 · \(RecordFormat.monthDay(start)) – \(RecordFormat.monthDay(now))"
            sessions = all.filter { $0.startTime >= start }
        case .month:
            periodLabel = "\(cal.component(.month, from: now))월"
            sessions = all.filter { cal.isDate($0.startTime, equalTo: now, toGranularity: .month) }
        }
    }
}

// MARK: - Format
enum RecordFormat {
    private static func formatter(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = format
        return f
    }

    private static let md = formatter("M월 d일")
    private static let mdw = formatter("M월 d일 EEEE")
    private static let hm = formatter("HH:mm")

    static func monthDay(_ d: Date) -> String { md.string(from: d) }
    static func monthDayWeekday(_ d: Date) -> String { mdw.string(from: d) }
    static func time(_ d: Date) -> String { hm.string(from: d) }

    /// "1:12" (시:분)
    static func hm(_ t: TimeInterval) -> String {
        let m = Int(t / 60)
        return String(format: "%d:%02d", m / 60, m % 60)
    }

    /// "6시간 18분"
    static func hoursMinutes(_ t: TimeInterval) -> String {
        let m = Int(t / 60)
        return m >= 60 ? "\(m / 60)시간 \(m % 60)분" : "\(m)분"
    }

    /// "1분 28초"
    static func minutesSeconds(_ t: TimeInterval) -> String {
        let s = Int(t)
        return s >= 60 ? "\(s / 60)분 \(s % 60)초" : "\(s)초"
    }

    static func relativeDayTime(_ d: Date) -> String {
        let cal = Calendar.current
        let day = cal.isDateInToday(d) ? "오늘" : cal.isDateInYesterday(d) ? "어제" : monthDay(d)
        return "\(day) \(time(d))"
    }

    static func plannedMinutes(_ s: StudySession) -> Int {
        Int((s.plannedDuration > 0 ? s.plannedDuration : s.measuredDuration) / 60)
    }

    /// 순수 집중 시간(시간)에 따라 초저녁 → 깊은 밤으로 어두워지는 하늘
    static func sky(hours h: Double) -> Color {
        let t = min(1, max(0, h / 3.2))
        let from = (r: 0x1F, g: 0x26, b: 0x2F), to = (r: 0x0C, g: 0x0D, b: 0x10)
        func mix(_ a: Int, _ b: Int) -> Double { (Double(a) + (Double(b) - Double(a)) * t) / 255 }
        return Color(.sRGB, red: mix(from.r, to.r), green: mix(from.g, to.g), blue: mix(from.b, to.b))
    }
}
