//
//  SessionDetailView.swift
//  FocusSense
//
//  학습 세션 상세 화면
//

import SwiftUI
import Charts

struct SessionDetailView: View {
    let session: StudySession

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 세션 요약 헤더
                SessionSummaryHeader(session: session)

                // 집중도 타임라인 차트
                SessionFocusChart(session: session)

                // 상세 통계
                SessionStatsGrid(session: session)

                // 시간대별 분석
                SessionTimelineAnalysis(session: session)
            }
            .padding()
        }
        .background(Color(hex: "0f0f1a"))
        .navigationTitle("학습 상세")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Session Summary Header
private struct SessionSummaryHeader: View {
    let session: StudySession

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 (E) HH:mm"
        return f
    }

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }

    var body: some View {
        VStack(spacing: 16) {
            // 날짜/시간
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateFormatter.string(from: session.startTime))
                        .font(.headline)
                    if let endTime = session.endTime {
                        Text("~ \(timeFormatter.string(from: endTime))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }

            // 핵심 지표 3개
            HStack(spacing: 0) {
                DetailSummaryMetric(
                    title: "총 학습",
                    value: session.formattedTotalDuration,
                    color: .blue
                )

                Divider()
                    .frame(height: 40)
                    .background(Color.white.opacity(0.2))

                DetailSummaryMetric(
                    title: "순수 집중",
                    value: session.formattedNetFocusTime,
                    color: .green
                )

                Divider()
                    .frame(height: 40)
                    .background(Color.white.opacity(0.2))

                DetailSummaryMetric(
                    title: "집중률",
                    value: session.formattedFocusRate,
                    color: focusRateColor(session.focusRate)
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
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

// MARK: - Detail Summary Metric
private struct DetailSummaryMetric: View {
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

// MARK: - Session Focus Chart
private struct SessionFocusChart: View {
    let session: StudySession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundColor(.purple)
                Text("집중도 변화")
                    .font(.headline)
            }

            if !session.focusRecords.isEmpty {
                Chart {
                    ForEach(Array(session.focusRecords.enumerated()), id: \.offset) { index, record in
                        let score = record.focusScore > 0 ? record.focusScore : focusValueFallback(for: record.focusLevel)

                        LineMark(
                            x: .value("Time", index),
                            y: .value("Focus", score)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.cyan, .green],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Time", index),
                            y: .value("Focus", score)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.cyan.opacity(0.3), .green.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
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
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        AxisValueLabel {
                            if let index = value.as(Int.self) {
                                let minutes = index / 60
                                Text("\(minutes)분")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .frame(height: 200)
            } else {
                Text("집중도 데이터 없음")
                    .font(.caption)
                    .foregroundColor(.secondary)
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

// MARK: - Session Stats Grid
private struct SessionStatsGrid: View {
    let session: StudySession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet.clipboard")
                    .foregroundColor(.cyan)
                Text("상세 통계")
                    .font(.headline)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                DetailStatCard(
                    icon: "moon.zzz.fill",
                    title: "졸음 감지",
                    value: "\(session.drowsinessCount)회",
                    color: .red
                )

                DetailStatCard(
                    icon: "eye.slash.fill",
                    title: "이탈 감지",
                    value: "\(session.unfocusedCount)회",
                    color: .orange
                )

                DetailStatCard(
                    icon: "eye.fill",
                    title: "집중 비율",
                    value: focusedRatio,
                    color: .green
                )

                DetailStatCard(
                    icon: "clock.fill",
                    title: "평균 집중 구간",
                    value: averageFocusDuration,
                    color: .blue
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }

    private var focusedRatio: String {
        let total = session.focusRecords.count
        guard total > 0 else { return "-" }
        let focused = session.focusRecords.filter { $0.focusLevel == .focused }.count
        let ratio = Double(focused) / Double(total) * 100
        return String(format: "%.0f%%", ratio)
    }

    private var averageFocusDuration: String {
        let interruptions = max(1, session.drowsinessCount + session.unfocusedCount + 1)
        let avgMinutes = session.netFocusTime / 60 / Double(interruptions)
        if avgMinutes >= 1 {
            return String(format: "%.1f분", avgMinutes)
        } else {
            return String(format: "%.0f초", avgMinutes * 60)
        }
    }
}

// MARK: - Detail Stat Card
private struct DetailStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3.bold())

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Session Timeline Analysis
private struct SessionTimelineAnalysis: View {
    let session: StudySession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.indigo)
                Text("시간대별 분석")
                    .font(.headline)
            }

            if !segments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(segments, id: \.startMinute) { segment in
                            DetailTimeSegmentBar(segment: segment)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } else {
                Text("분석할 데이터가 충분하지 않습니다")
                    .font(.caption)
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

    // 5분 단위 세그먼트 생성
    private var segments: [DetailTimeSegment] {
        let segmentDuration = 300 // 5분
        guard !session.focusRecords.isEmpty else { return [] }

        let totalSeconds = Int(session.totalDuration)
        let segmentCount = max(1, (totalSeconds + segmentDuration - 1) / segmentDuration)

        return (0..<segmentCount).compactMap { i in
            let startIndex = i * segmentDuration
            let endIndex = min(startIndex + segmentDuration, session.focusRecords.count)
            guard startIndex < session.focusRecords.count else { return nil }

            let slice = Array(session.focusRecords[startIndex..<endIndex])

            // focusScore 기반 평균
            let scores = slice.map { $0.focusScore > 0 ? $0.focusScore : focusValueFallback(for: $0.focusLevel) }
            let avgScore = scores.reduce(0, +) / Double(scores.count)

            return DetailTimeSegment(
                startMinute: i * 5,
                focusRate: avgScore,
                drowsyCount: slice.filter { $0.focusLevel == .drowsy }.count,
                awayCount: slice.filter { $0.focusLevel == .away }.count
            )
        }
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

// MARK: - Detail Time Segment
private struct DetailTimeSegment {
    let startMinute: Int
    let focusRate: Double
    let drowsyCount: Int
    let awayCount: Int
}

// MARK: - Detail Time Segment Bar
private struct DetailTimeSegmentBar: View {
    let segment: DetailTimeSegment

    private var color: Color {
        switch segment.focusRate {
        case 80...: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            // 바
            RoundedRectangle(cornerRadius: 4)
                .fill(color.gradient)
                .frame(width: 36, height: CGFloat(segment.focusRate / 100 * 80))
                .frame(height: 80, alignment: .bottom)

            // 시간 라벨
            Text("\(segment.startMinute)분")
                .font(.system(size: 9))
                .foregroundColor(.secondary)

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
                        .foregroundColor(.gray)
                }
            }
            .frame(height: 10)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        SessionDetailView(session: {
            var s = StudySession(startTime: Date().addingTimeInterval(-3600))
            s.endTime = Date()
            s.focusRecords = (0..<3600).map { i in
                FocusRecord(
                    timestamp: Date().addingTimeInterval(-3600 + Double(i)),
                    focusLevel: [.focused, .focused, .focused, .warning, .drowsy].randomElement()!,
                    duration: 1.0,
                    focusScore: Double.random(in: 40...95)
                )
            }
            return s
        }())
    }
    .preferredColorScheme(.dark)
}
