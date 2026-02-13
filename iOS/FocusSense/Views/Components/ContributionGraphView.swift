//
//  ContributionGraphView.swift
//  FocusSense
//
//  GitHub 잔디 스타일 학습 활동 그래프 컴포넌트
//

import SwiftUI

// MARK: - Contribution Graph Card
struct ContributionGraphCard: View {
    @ObservedObject var viewModel: DashboardViewModel

    private let cellSize: CGFloat = 14
    private let cellSpacing: CGFloat = 3
    private let dayLabels = ["", "월", "", "수", "", "금", ""]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // MARK: Header
            HStack {
                Image(systemName: "square.grid.3x3.fill")
                    .foregroundColor(.green)
                Text("학습 활동")
                    .font(.headline)

                Spacer()

                Text("최근 \(viewModel.weeksToShow)주")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // MARK: Month Labels
            if !viewModel.monthLabels.isEmpty {
                MonthLabelsRow(
                    monthLabels: viewModel.monthLabels,
                    cellSize: cellSize,
                    cellSpacing: cellSpacing
                )
            }

            // MARK: Grid
            HStack(alignment: .top, spacing: cellSpacing) {
                // 요일 라벨 (왼쪽)
                VStack(spacing: cellSpacing) {
                    ForEach(0..<7, id: \.self) { row in
                        Text(dayLabels[row])
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .frame(width: 14, height: cellSize)
                    }
                }

                // 잔디 셀 그리드
                ScrollView(.horizontal, showsIndicators: false) {
                    let columnCount = viewModel.weeklyGrid.first?.count ?? 0
                    HStack(spacing: cellSpacing) {
                        ForEach(0..<columnCount, id: \.self) { col in
                            VStack(spacing: cellSpacing) {
                                ForEach(0..<7, id: \.self) { row in
                                    if row < viewModel.weeklyGrid.count {
                                        ContributionCell(
                                            activity: viewModel.weeklyGrid[row][col],
                                            isSelected: isCellSelected(row: row, col: col),
                                            onTap: {
                                                viewModel.selectDay(viewModel.weeklyGrid[row][col])
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.trailing, 4)
                }
                .defaultScrollAnchor(.trailing)
            }

            // MARK: Legend
            ContributionLegend()

            // MARK: Selected Day Popup
            if let selected = viewModel.selectedDay {
                SelectedDayPopup(activity: selected) {
                    viewModel.selectedDay = nil
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .animation(.easeOut(duration: 0.2), value: viewModel.selectedDay?.date)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }

    private func isCellSelected(row: Int, col: Int) -> Bool {
        guard let selected = viewModel.selectedDay,
              row < viewModel.weeklyGrid.count,
              col < viewModel.weeklyGrid[row].count,
              let activity = viewModel.weeklyGrid[row][col] else {
            return false
        }
        return Calendar.current.isDate(activity.date, inSameDayAs: selected.date)
    }
}

// MARK: - Month Labels Row
struct MonthLabelsRow: View {
    let monthLabels: [(String, Int)]
    let cellSize: CGFloat
    let cellSpacing: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            // 요일 라벨 너비만큼 여백
            Spacer()
                .frame(width: 14 + cellSpacing)

            ZStack(alignment: .leading) {
                // 빈 영역 (전체 너비 확보)
                Color.clear.frame(height: 14)

                HStack(spacing: 0) {
                    ForEach(Array(monthLabels.enumerated()), id: \.offset) { _, label in
                        Text(label.0)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .offset(x: CGFloat(label.1) * (cellSize + cellSpacing))
                    }
                }
            }
        }
    }
}

// MARK: - Contribution Cell
struct ContributionCell: View {
    let activity: DayActivity?
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(cellColor)
            .frame(width: 14, height: 14)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(
                        isSelected ? Color.orange : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .onTapGesture {
                if activity != nil {
                    onTap()
                }
            }
    }

    private var cellColor: Color {
        guard let activity = activity else {
            return Color.white.opacity(0.03) // 미래 날짜 or 범위 밖
        }
        return activity.level.color
    }
}

// MARK: - Selected Day Popup
struct SelectedDayPopup: View {
    let activity: DayActivity
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 헤더
            HStack {
                Text(activity.formattedDate)
                    .font(.subheadline.bold())

                if activity.isToday {
                    Text("오늘")
                        .font(.caption2.bold())
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(4)
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.body)
                }
            }

            Divider()
                .background(Color.white.opacity(0.1))

            if activity.sessionCount > 0 {
                // 학습 데이터가 있는 경우
                HStack(spacing: 20) {
                    PopupStat(
                        title: "학습 횟수",
                        value: "\(activity.sessionCount)회",
                        color: .white
                    )

                    PopupStat(
                        title: "총 학습 시간",
                        value: activity.formattedDuration,
                        color: .green
                    )

                    if activity.averageFocusRate > 0 {
                        PopupStat(
                            title: "평균 집중률",
                            value: String(format: "%.0f%%", activity.averageFocusRate),
                            color: focusRateColor(activity.averageFocusRate)
                        )
                    }
                }
            } else {
                Text("학습 기록이 없습니다")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "1a1a2e"))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
                )
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

// MARK: - Popup Stat Item
struct PopupStat: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(color)
        }
    }
}

// MARK: - Contribution Legend
struct ContributionLegend: View {
    var body: some View {
        HStack(spacing: 4) {
            Spacer()

            Text("적음")
                .font(.system(size: 9))
                .foregroundColor(.secondary)

            ForEach(ActivityLevel.allCases, id: \.rawValue) { level in
                RoundedRectangle(cornerRadius: 2)
                    .fill(level.color)
                    .frame(width: 10, height: 10)
            }

            Text("많음")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Quick Stats Card
struct QuickStatsCard: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        HStack(spacing: 0) {
            QuickStatItem(
                icon: "flame.fill",
                title: "연속",
                value: "\(viewModel.currentStreak)일",
                color: .orange
            )

            Divider()
                .frame(height: 40)
                .background(Color.white.opacity(0.1))

            QuickStatItem(
                icon: "clock.fill",
                title: "오늘",
                value: formatDuration(viewModel.todayStudyTime),
                color: .green
            )

            Divider()
                .frame(height: 40)
                .background(Color.white.opacity(0.1))

            QuickStatItem(
                icon: "calendar",
                title: "이번 주",
                value: formatDuration(viewModel.thisWeekStudyTime),
                color: .blue
            )
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

        if hours > 0 {
            return String(format: "%d시간 %02d분", hours, minutes)
        } else {
            return "\(minutes)분"
        }
    }
}

// MARK: - Quick Stat Item
struct QuickStatItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)

            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Quick Start Card
struct QuickStartCard: View {
    @Binding var selectedTab: Int

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "play.circle.fill")
                    .foregroundColor(.orange)
                Text("학습 시작")
                    .font(.headline)
                Spacer()
            }

            Button {
                withAnimation {
                    selectedTab = 1 // 타이머 탭으로 이동
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "timer")
                        .font(.title3)
                    Text("학습 시작하기")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color.orange, Color.orange.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}
