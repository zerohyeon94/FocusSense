//
//  AnalyticsView.swift
//  FocusSense
//
//  집중도 통계 및 분석 화면
//

import SwiftUI
import Charts

struct AnalyticsView: View {
    @ObservedObject var viewModel: TimerViewModel
    
    var body: some View {
        /// NavigationStack: 화면 상단에 네비게이션 바를 추가
        /// 하위 뷰에서 NavigationLink로 화면 전환 가능
        NavigationStack {
            ScrollView { // 컨텐츠가 화면보다 길면 스크롤 가능
                VStack(spacing: 24) {
                    // 오늘의 요약 카드
                    TodaySummaryCard(session: viewModel.currentSession)
                    
                    // 집중도 차트
                    FocusChartCard(session: viewModel.currentSession)
                    
                    // 상세 통계
                    DetailedStatsCard(session: viewModel.currentSession)
                    
                    // 팁 카드
                    TipsCard()
                }
                .padding()
            }
            .background(Color(hex: "0f0f1a"))
            .navigationTitle("집중 분석") // 네비게이션 바 제목
            .navigationBarTitleDisplayMode(.large) // 큰 제목 스타일
        }
    }
}

// MARK: - Today Summary Card
struct TodaySummaryCard: View {
    let session: StudySession?
    
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
            
            /// StudySession? - Optional if let
            /// - Optional이 nil이 아니면 언래핑하여 사용
            /// - session은 이제 StudySession 타입 (not Optional)
            if let session = session {
                HStack(spacing: 20) {
                    SummaryItem(
                        title: "총 학습",
                        value: session.formattedTotalDuration, // 안전하게 접근
                        color: .blue
                    )
                    
                    SummaryItem(
                        title: "순수 집중",
                        value: session.formattedNetFocusTime,
                        color: .green
                    )
                    
                    SummaryItem(
                        title: "집중률",
                        value: session.formattedFocusRate,
                        color: focusRateColor(session.focusRate)
                    )
                }
            } else {
                // session이 nil일 때 표시
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

// MARK: - Focus Chart Card
struct FocusChartCard: View {
    let session: StudySession?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundColor(.purple)
                Text("집중도 변화")
                    .font(.headline)
            }
            
            if let session = session, !session.focusRecords.isEmpty {
                // Swift Charts
                Chart {
                    /// ForEach: 배열의 각 요소에 대해 반복
                    /// - session.focusRecords.enumerated(): (인덱스, 값) 튜플로 변환
                    /// - id: \.offset: 인덱스를 고유 ID로 사용
                    ForEach(Array(session.focusRecords.enumerated()), id: \.offset) { index, record in
                        // 선그래프
                        LineMark(
                            x: .value("Time", index), // X축: 시간 (인덱스)
                            y: .value("Focus", focusValue(for: record.focusLevel)) // Y츅: 집중도
                        )
                        .foregroundStyle(record.focusLevel.color.gradient) // 색상 그라데이션
                        
                        // 영역 그래프 (선 아래 채우기)
                        AreaMark(
                            x: .value("Time", index),
                            y: .value("Focus", focusValue(for: record.focusLevel))
                        )
                        .foregroundStyle(record.focusLevel.color.opacity(0.2).gradient)
                    }
                }
                .chartYScale(domain: 0...100) // Y축 범위: 0 ~ 100
                .chartYAxis { // Y축 커스터마이징
                    AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                        AxisGridLine() // 눈금선
                        AxisValueLabel { // 눈금 레이블
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartXAxis(.hidden) // X축 숨기기
                .frame(height: 200) // 차트 높이
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
        .padding() // 내부 여백
        .background(
            RoundedRectangle(cornerRadius: 16) // 둥근 사각형
                .fill(Color.white.opacity(0.05)) // 반투명 흰색
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
}
