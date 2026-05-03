//
//  AnalyticsView.swift
//  FocusSense
//
//  집중도 통계 및 분석 화면
//

// ============================================================================
// 📚 [파일 개요] AnalyticsView - 집중도 통계 및 차트 분석 화면
// ============================================================================
//
// 📚 [Swift Charts 프레임워크 (iOS 16+)]
//   Apple의 공식 차트 라이브러리로, 선언적 문법으로 차트를 생성합니다.
//   - LineMark: 선 그래프 (시간별 집중도 추이)
//   - AreaMark: 영역 그래프 (선 아래를 색으로 채움)
//   - BarMark: 막대 그래프 (일별/주별 비교)
//   Chart { ForEach(data) { item in LineMark(x: ..., y: ...) } }
//   .chartXAxis, .chartYScale 등으로 축과 범위를 커스터마이징합니다.
//
// 📚 [computed property를 활용한 데이터 집계]
//   todaySessions, todayTotalDuration, todayAverageFocusRate 등은
//   모두 computed property로 구현되어, 원본 데이터가 변경되면
//   자동으로 재계산됩니다. SwiftUI의 반응형 시스템과 자연스럽게 연동됩니다.
//
// 📚 [카드 기반 UI 구성 패턴]
//   통계 화면은 여러 개의 "카드" 컴포넌트로 구성됩니다:
//   - 각 카드는 독립적인 struct (SummaryCard, ChartCard 등)
//   - RoundedRectangle 배경 + padding으로 카드 외형을 만듭니다
//   - ScrollView 안에 VStack으로 카드들을 수직 배치합니다
//
// ============================================================================

import SwiftUI
import Charts

struct AnalyticsView: View {
    @ObservedObject var viewModel: TimerViewModel

    /// 오늘의 모든 세션 (저장된 세션 + 현재 진행 중 세션)
    private var todaySessions: [StudySession] {
        var sessions = viewModel.sessionStore.todaySessions
        // 현재 진행 중인 세션이 있으면 추가 (아직 저장 안 된 상태)
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
                    TodayOverviewCard(
                        sessionCount: todaySessions.count,
                        totalDuration: todayTotalDuration,
                        netFocusTime: todayNetFocusTime,
                        averageFocusRate: todayAverageFocusRate
                    )

                    // 현재 진행 중인 세션
                    if let session = viewModel.currentSession {
                        CurrentSessionCard(session: session)
                    }

                    // 오늘의 세션 목록
                    TodaySessionsCard(
                        sessions: viewModel.sessionStore.todaySessions
                    )

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
            .task {
                viewModel.sessionStore.loadAllSessions()
            }
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

// MARK: - Today Overview Card
struct TodayOverviewCard: View {
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

// MARK: - Current Session Card
struct CurrentSessionCard: View {
    let session: StudySession

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "record.circle")
                    .foregroundColor(.red)
                Text("진행 중")
                    .font(.headline)
                Spacer()
                Text("LIVE")
                    .font(.caption.bold())
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(Color.red.opacity(0.2))
                    )
            }

            if !session.focusRecords.isEmpty {
                Chart {
                    ForEach(Array(session.focusRecords.enumerated()), id: \.offset) { index, record in
                        // AI 점수가 기록된 경우 실제 점수 사용, 없으면 레벨 기반 폴백
                        LineMark(
                            x: .value("Time", index),
                            y: .value("Focus", record.focusScore > 0 ? record.focusScore : Double(focusValue(for: record.focusLevel)))
                        )
                        .foregroundStyle(Color.orange.gradient)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Time", index),
                            y: .value("Focus", record.focusScore > 0 ? record.focusScore : Double(focusValue(for: record.focusLevel)))
                        )
                        .foregroundStyle(Color.orange.opacity(0.15).gradient)
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(values: [0, 50, 100]) { value in
                        AxisGridLine()
                            .foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartXAxis(.hidden)
                .frame(height: 150)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("데이터가 쌓이면 집중도 그래프가 표시됩니다")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 150)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func focusValue(for level: FocusLevel) -> Int {
        switch level {
        case .focused: return 100
        case .warning: return 70
        case .unfocused: return 30
        case .drowsy: return 10
        case .away: return 20
        case .unknown: return 50
        }
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
                            .foregroundColor(focusRateColor(session.focusRate))
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

    private func focusRateColor(_ rate: Double) -> Color {
        switch rate {
        case 80...: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
}

// MARK: - Summary Item
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
        .frame(maxWidth: .infinity)
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

// MARK: - Tips Card
struct TipsCard: View {
    private let tips = [
        "50분 집중 후 10분 휴식하는 포모도로 기법을 시도해보세요",
        "졸음이 자주 오면 가벼운 스트레칭이나 환기가 도움됩니다",
        "조명이 너무 어두우면 졸음이 더 쉽게 옵니다",
        "물을 충분히 마시면 집중력 유지에 도움이 됩니다"
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
}
