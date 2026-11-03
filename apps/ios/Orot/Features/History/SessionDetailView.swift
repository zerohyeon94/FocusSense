//
//  SessionDetailView.swift
//  FocusSense
//
//  학습 세션 상세 화면
//

// ============================================================================
// 📚 [파일 개요] SessionDetailView - 학습 세션 상세 분석 화면
// ============================================================================
//
// 📚 [Swift Charts로 집중도 타임라인 시각화]
//   세션 중 기록된 집중도 데이터를 시간축 차트로 표시합니다.
//   LineMark + AreaMark를 조합하여 집중도 변화 추이를 직관적으로 보여줍니다.
//   .chartYScale(domain: 0...100)으로 Y축을 0~100% 범위로 고정합니다.
//
// 📚 [private struct - 파일 스코프 컴포넌트]
//   SessionSummaryHeader, SessionFocusChart, SessionStatsGrid 등은
//   이 파일 내부에서만 사용되는 private struct입니다.
//   외부에 노출할 필요 없는 컴포넌트는 private으로 선언하여
//   모듈의 네임스페이스를 깔끔하게 유지합니다.
//
// 📚 [5분 단위 세그먼트 분석]
//   긴 학습 세션을 5분 단위로 분할하여 각 구간의 집중률을 분석합니다.
//   이를 통해 "어느 시간대에 집중이 잘 되었는지" 패턴을 파악할 수 있습니다.
//   stride(from:to:by: 300)으로 5분(300초) 간격을 생성합니다.
//
// 📚 [LazyVGrid - 2열 통계 그리드]
//   LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())])로
//   2열 그리드 레이아웃을 구성합니다.
//   총 학습시간, 집중시간, 집중률, 졸음 횟수 등의 통계를 카드 형태로 배치합니다.
//   LazyVGrid는 화면에 보이는 항목만 렌더링하여 성능을 최적화합니다.
//
// ============================================================================

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
                SummaryMetric(
                    title: "총 학습",
                    value: session.formattedTotalDuration,
                    color: .blue
                )

                Divider()
                    .frame(height: 40)
                    .background(Color.white.opacity(0.2))

                SummaryMetric(
                    title: "순수 집중",
                    value: session.formattedNetFocusTime,
                    color: .green
                )

                Divider()
                    .frame(height: 40)
                    .background(Color.white.opacity(0.2))

                SummaryMetric(
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

// MARK: - Summary Metric
private struct SummaryMetric: View {
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
                    AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                        AxisGridLine()
                            .foregroundStyle(Color.white.opacity(0.1))
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
                StatCard(
                    icon: "moon.zzz.fill",
                    title: "졸음 감지",
                    value: "\(session.drowsinessCount)회",
                    color: .red
                )

                StatCard(
                    icon: "eye.slash.fill",
                    title: "이탈 감지",
                    value: "\(session.unfocusedCount)회",
                    color: .orange
                )

                StatCard(
                    icon: "eye.fill",
                    title: "집중 비율",
                    value: focusedRatio,
                    color: .green
                )

                StatCard(
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

// MARK: - Stat Card
private struct StatCard: View {
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
                            TimeSegmentBar(segment: segment)
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
    private var segments: [TimeSegment] {
        let segmentDuration = 300 // 5분
        guard !session.focusRecords.isEmpty else { return [] }

        let totalSeconds = Int(session.totalDuration)
        let segmentCount = max(1, (totalSeconds + segmentDuration - 1) / segmentDuration)

        return (0..<segmentCount).compactMap { i in
            let startIndex = i * segmentDuration
            let endIndex = min(startIndex + segmentDuration, session.focusRecords.count)
            guard startIndex < session.focusRecords.count else { return nil }

            let slice = Array(session.focusRecords[startIndex..<endIndex])
            let focused = slice.filter { $0.focusLevel == .focused }.count
            let focusRate = Double(focused) / Double(slice.count) * 100

            return TimeSegment(
                startMinute: i * 5,
                focusRate: focusRate,
                drowsyCount: slice.filter { $0.focusLevel == .drowsy }.count,
                awayCount: slice.filter { $0.focusLevel == .away }.count
            )
        }
    }
}

// MARK: - Time Segment
private struct TimeSegment {
    let startMinute: Int
    let focusRate: Double
    let drowsyCount: Int
    let awayCount: Int
}

// MARK: - Time Segment Bar
private struct TimeSegmentBar: View {
    let segment: TimeSegment

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
                    duration: 1.0
                )
            }
            return s
        }())
    }
    .preferredColorScheme(.dark)
}
