//
//  AnalyticsView.swift
//  FocusSense
//
//  집중도 통계 및 분석 화면
//

import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @ObservedObject var viewModel: TimerViewModel

    /// 오늘의 모든 세션 (저장된 세션 + 현재 진행 중 세션)
    private var todaySessions: [StudySession] {
        var sessions = viewModel.sessionStore.todaySessions
        if let current = viewModel.currentSession,
           !sessions.contains(where: { $0.id == current.id }) {
            sessions.insert(current, at: 0)
        }
        return sessions
    }

    /// 오늘의 총 학습 시간
    private var todayTotalDuration: TimeInterval {
        todaySessions.reduce(0) { $0 + $1.totalDuration }
    }

    /// 오늘의 평균 집중률
    private var todayAverageFocusRate: Double {
        let sessions = todaySessions.filter { !$0.focusRecords.isEmpty }
        guard !sessions.isEmpty else { return 0 }
        return sessions.map { $0.focusRate }.reduce(0, +) / Double(sessions.count)
    }

    /// 오늘의 총 순수 집중 시간
    private var todayNetFocusTime: TimeInterval {
        todaySessions.reduce(0) { $0 + $1.netFocusTime }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 오늘의 종합 요약
                    TodaySummaryCard(
                        sessionCount: todaySessions.count,
                        totalDuration: todayTotalDuration,
                        netFocusTime: todayNetFocusTime,
                        averageFocusRate: todayAverageFocusRate
                    )

                    // 종합 집중도 차트 (focusScore 기반 - 현재 세션)
                    FocusChartCard(session: viewModel.currentSession)

                    // 시간대별 집중도 타임라인 (좌우 스크롤)
                    FocusScoreTimelineCard(session: viewModel.currentSession)

                    // 오늘의 완료된 세션 목록
                    TodaySessionsCard(sessions: viewModel.sessionStore.todaySessions)

                    // 상세 통계
                    DetailedStatsCard(session: viewModel.currentSession)

                    // 팁 카드
                    TipsCard()
                }
                .padding()
            }
            .background(Color(hex: "0f0f1a"))
            .navigationTitle("집중 분석")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        HistoryView(sessionStore: viewModel.sessionStore)
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.orange)
                    }
                }
            }
        }
    }
}

// MARK: - Today Summary Card
struct TodaySummaryCard: View {
    let sessionCount: Int
    let totalDuration: TimeInterval
    let netFocusTime: TimeInterval
    let averageFocusRate: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.orange)
                Text("오늘의 학습")
                    .font(.headline)
                Spacer()
                Text(Date(), style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if sessionCount > 0 {
                HStack(spacing: 20) {
                    SummaryItem(
                        title: "총 학습",
                        value: formatDuration(totalDuration),
                        color: .blue
                    )

                    SummaryItem(
                        title: "순수 집중",
                        value: formatDuration(netFocusTime),
                        color: .green
                    )

                    SummaryItem(
                        title: "집중률",
                        value: String(format: "%.1f%%", averageFocusRate),
                        color: focusRateColor(averageFocusRate)
                    )
                }

                if sessionCount > 1 {
                    Text("\(sessionCount)회 학습")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            } else {
                Text("아직 학습 기록이 없습니다.\n타이머를 시작해보세요!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d시간 %02d분", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%d분 %02d초", minutes, seconds)
        } else {
            return String(format: "%d초", seconds)
        }
    }

    private func focusRateColor(_ rate: Double) -> Color {
        switch rate {
        case 80...: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
}

// MARK: - Summary Item (재사용 컴포넌트)
struct SummaryItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3.bold())
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity) // 가로로 균등 분할
    }
}

// MARK: - Focus Chart Card (종합 집중도 점수 기반)
struct FocusChartCard: View {
    let session: StudySession?
    @State private var selectedIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundColor(.purple)
                Text("집중도 변화")
                    .font(.headline)

                Spacer()

                if let session = session, !session.focusRecords.isEmpty {
                    Text("평균 \(String(format: "%.0f%%", session.focusRate))")
                        .font(.caption.bold())
                        .foregroundColor(focusRateColor(session.focusRate))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(focusRateColor(session.focusRate).opacity(0.15))
                        .cornerRadius(8)
                }
            }

            if let session = session, !session.focusRecords.isEmpty {
                // 선택된 지점 정보
                if let idx = selectedIndex, idx < session.focusRecords.count {
                    let record = session.focusRecords[idx]
                    HStack(spacing: 12) {
                        let elapsed = idx + 1
                        let mins = elapsed / 60
                        let secs = elapsed % 60
                        Text(String(format: "%d:%02d", mins, secs))
                            .font(.caption.monospaced())
                            .foregroundColor(.gray)

                        Text(String(format: "집중도 %.0f%%", record.focusScore))
                            .font(.caption.bold())
                            .foregroundColor(scoreColor(record.focusScore))

                        Spacer()

                        Text(record.focusLevel.rawValue)
                            .font(.caption)
                            .foregroundColor(record.focusLevel.color)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                }

                // 차트 (focusScore 기반)
                Chart {
                    ForEach(Array(session.focusRecords.enumerated()), id: \.offset) { index, record in
                        let score = record.focusScore > 0 ? record.focusScore : focusValueFallback(for: record.focusLevel)

                        LineMark(
                            x: .value("Time", index),
                            y: .value("Focus", score)
                        )
                        .foregroundStyle(scoreGradient)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Time", index),
                            y: .value("Focus", score)
                        )
                        .foregroundStyle(areaGradient)
                        .interpolationMethod(.catmullRom)
                    }

                    // 선택 표시 룰 마크
                    if let idx = selectedIndex, idx < session.focusRecords.count {
                        let record = session.focusRecords[idx]
                        let score = record.focusScore > 0 ? record.focusScore : focusValueFallback(for: record.focusLevel)

                        RuleMark(x: .value("Selected", idx))
                            .foregroundStyle(.white.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

                        PointMark(
                            x: .value("Time", idx),
                            y: .value("Focus", score)
                        )
                        .foregroundStyle(.white)
                        .symbolSize(60)
                    }
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                            .foregroundStyle(.gray.opacity(0.3))
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .chartXAxis(.hidden)
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let x = value.location.x
                                        if let index: Int = proxy.value(atX: x) {
                                            selectedIndex = max(0, min(index, session.focusRecords.count - 1))
                                        }
                                    }
                                    .onEnded { _ in
                                        // 선택 상태 유지
                                    }
                            )
                    }
                }
                .frame(height: 200)
            } else {
                // 빈 상태
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("데이터가 쌓이면 집중도 그래프가 표시됩니다")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }

    // focusScore가 없는 기존 데이터 fallback
    private func focusValueFallback(for level: FocusLevel) -> Double {
        switch level {
        case .focused: return 85
        case .warning: return 60
        case .unfocused: return 30
        case .drowsy: return 15
        case .away: return 10
        case .unknown: return 50
        }
    }

    private var scoreGradient: LinearGradient {
        LinearGradient(
            colors: [.cyan, .green],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var areaGradient: LinearGradient {
        LinearGradient(
            colors: [.cyan.opacity(0.3), .green.opacity(0.05)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 80 { return .green }
        else if score >= 60 { return .yellow }
        else if score >= 40 { return .orange }
        else { return .red }
    }

    private func focusRateColor(_ rate: Double) -> Color {
        switch rate {
        case 80...: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
}

// MARK: - Focus Score Timeline Card (시간대별 분석, 좌우 스크롤)
struct FocusScoreTimelineCard: View {
    let session: StudySession?

    /// 5분 단위로 집계한 데이터 포인트
    struct TimeSegment: Identifiable {
        let id = UUID()
        let startIndex: Int      // focusRecords 시작 인덱스
        let endIndex: Int        // focusRecords 끝 인덱스
        let timeLabel: String    // "0:00", "5:00", ...
        let avgScore: Double     // 평균 집중도
        let minScore: Double     // 최저 집중도
        let maxScore: Double     // 최고 집중도
        let dominantLevel: FocusLevel  // 가장 많은 상태
        let drowsyCount: Int     // 졸음 횟수
        let awayCount: Int       // 이탈 횟수
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.arrow.2.circlepath")
                    .foregroundColor(.cyan)
                Text("시간대별 집중도")
                    .font(.headline)

                Spacer()

                Text("좌우로 스크롤")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            if let session = session, !session.focusRecords.isEmpty {
                let segments = buildSegments(from: session)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(segments) { segment in
                            TimeSegmentCard(segment: segment)
                        }
                    }
                    .padding(.horizontal, 4)
                }

                // 하단 범례
                HStack(spacing: 16) {
                    LegendItem(color: .green, label: "80+")
                    LegendItem(color: .yellow, label: "60-79")
                    LegendItem(color: .orange, label: "40-59")
                    LegendItem(color: .red, label: "0-39")
                }
                .padding(.top, 4)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("학습 데이터가 쌓이면\n시간대별 집중도를 확인할 수 있습니다")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 120)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }

    // MARK: - Build Segments (5분 = 300초 단위로 집계)
    private func buildSegments(from session: StudySession) -> [TimeSegment] {
        let records = session.focusRecords
        guard !records.isEmpty else { return [] }

        let segmentSize = 300  // 5분 단위 (초)
        var segments: [TimeSegment] = []
        var startIdx = 0

        while startIdx < records.count {
            let endIdx = min(startIdx + segmentSize - 1, records.count - 1)
            let slice = Array(records[startIdx...endIdx])

            // 평균/최소/최대 점수
            let scores = slice.map { $0.focusScore > 0 ? $0.focusScore : focusValueFallback(for: $0.focusLevel) }
            let avg = scores.reduce(0, +) / Double(scores.count)
            let minVal = scores.min() ?? 0
            let maxVal = scores.max() ?? 100

            // 가장 많은 focusLevel
            var levelCounts: [FocusLevel: Int] = [:]
            for r in slice {
                levelCounts[r.focusLevel, default: 0] += 1
            }
            let dominant = levelCounts.max(by: { $0.value < $1.value })?.key ?? .unknown

            // 졸음/이탈 횟수
            let drowsy = slice.filter { $0.focusLevel == .drowsy }.count
            let away = slice.filter { $0.focusLevel == .away }.count

            // 시간 라벨
            let totalMins = startIdx / 60
            let label = String(format: "%d:%02d", totalMins / 60, totalMins % 60)

            segments.append(TimeSegment(
                startIndex: startIdx,
                endIndex: endIdx,
                timeLabel: label,
                avgScore: avg,
                minScore: minVal,
                maxScore: maxVal,
                dominantLevel: dominant,
                drowsyCount: drowsy,
                awayCount: away
            ))

            startIdx += segmentSize
        }

        return segments
    }

    private func focusValueFallback(for level: FocusLevel) -> Double {
        switch level {
        case .focused: return 85
        case .warning: return 60
        case .unfocused: return 30
        case .drowsy: return 15
        case .away: return 10
        case .unknown: return 50
        }
    }
}

// MARK: - Time Segment Card (각 5분 구간 카드)
struct TimeSegmentCard: View {
    let segment: FocusScoreTimelineCard.TimeSegment

    var body: some View {
        VStack(spacing: 8) {
            // 점수 바
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 80)

                RoundedRectangle(cornerRadius: 4)
                    .fill(barColor.gradient)
                    .frame(width: 40, height: max(4, 80 * segment.avgScore / 100))
            }

            // 점수
            Text(String(format: "%.0f", segment.avgScore))
                .font(.caption2.bold())
                .foregroundColor(barColor)

            // 시간
            Text(segment.timeLabel)
                .font(.caption2)
                .foregroundColor(.gray)

            // 이벤트 아이콘
            HStack(spacing: 2) {
                if segment.drowsyCount > 0 {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.red)
                }
                if segment.awayCount > 0 {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 8))
                        .foregroundColor(.orange)
                }
            }
            .frame(height: 10)
        }
        .frame(width: 56)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.03))
        )
    }

    private var barColor: Color {
        if segment.avgScore >= 80 { return .green }
        else if segment.avgScore >= 60 { return .yellow }
        else if segment.avgScore >= 40 { return .orange }
        else { return .red }
    }
}

// MARK: - Legend Item
struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Detailed Stats Card
struct DetailedStatsCard: View {
    let session: StudySession?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "list.bullet.clipboard")
                    .foregroundColor(.cyan)
                Text("상세 통계")
                    .font(.headline)
            }
            
            if let session = session {
                VStack(spacing: 12) {
                    StatRow(
                        icon: "moon.zzz.fill",
                        title: "졸음 감지",
                        value: "\(session.drowsinessCount)회",
                        color: .red
                    )
                    
                    StatRow(
                        icon: "eye.slash.fill",
                        title: "이탈 감지",
                        value: "\(session.unfocusedCount)회",
                        color: .orange
                    )
                    
                    StatRow(
                        icon: "clock.fill",
                        title: "평균 집중 시간",
                        value: calculateAverageFocusDuration(session),
                        color: .blue
                    )
                }
            } else {
                Text("학습을 시작하면 상세 통계가 표시됩니다")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private func calculateAverageFocusDuration(_ session: StudySession) -> String {
        let focusedRecords = session.focusRecords.filter { $0.focusLevel == .focused }
        guard !focusedRecords.isEmpty else { return "-" }
        
        // 연속 집중 구간 계산 (간단 버전)
        let avgMinutes = session.netFocusTime / 60 / Double(max(1, session.drowsinessCount + session.unfocusedCount + 1))
        return String(format: "%.1f분", avgMinutes)
    }
}

// MARK: - Stat Row
struct StatRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Today Sessions Card
struct TodaySessionsCard: View {
    let sessions: [StudySession]

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }

    var body: some View {
        if !sessions.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "list.bullet")
                        .foregroundColor(.indigo)
                    Text("오늘의 학습 기록")
                        .font(.headline)
                }

                ForEach(sessions) { session in
                    HStack(spacing: 12) {
                        // 집중률 원
                        FocusRateCircle(rate: session.focusRate)
                            .scaleEffect(0.8)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text(timeFormatter.string(from: session.startTime))
                                Text("~")
                                    .foregroundColor(.secondary)
                                if let endTime = session.endTime {
                                    Text(timeFormatter.string(from: endTime))
                                }
                            }
                            .font(.subheadline)

                            Text(session.formattedTotalDuration)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text(session.formattedFocusRate)
                            .font(.subheadline.bold())
                            .foregroundColor(sessionFocusColor(session.focusRate))
                    }
                    .padding(.vertical, 4)

                    if session.id != sessions.last?.id {
                        Divider()
                            .background(Color.white.opacity(0.1))
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )
        }
    }

    private func sessionFocusColor(_ rate: Double) -> Color {
        switch rate {
        case 80...: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
}

// MARK: - Tips Card
struct TipsCard: View {
    private let tips = [
        "💡 50분 집중 후 10분 휴식하는 포모도로 기법을 시도해보세요",
        "💡 졸음이 자주 오면 가벼운 스트레칭이나 환기가 도움됩니다",
        "💡 조명이 너무 어두우면 졸음이 더 쉽게 옵니다",
        "💡 물을 충분히 마시면 집중력 유지에 도움이 됩니다"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("집중력 향상 팁")
                    .font(.headline)
            }
            
            Text(tips.randomElement() ?? tips[0])
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.yellow.opacity(0.1))
        )
    }
}

// MARK: - Preview
#Preview {
    AnalyticsView(viewModel: TimerViewModel())
        .preferredColorScheme(.dark)
        .modelContainer(for: [StudySession.self, FocusRecord.self], inMemory: true)
}
