//
//  ContributionGraphView.swift
//  FocusSense
//
//  GitHub 스타일 잔디 그래프 UI 컴포넌트
//

import SwiftUI

// MARK: - Contribution Graph Card
struct ContributionGraphCard: View {
    @ObservedObject var viewModel: DashboardViewModel

    private let spacing: CGFloat = 3
    private let labelWidth: CGFloat = 16

    private var columnCount: Int {
        viewModel.weeklyGrid.first?.count ?? 0
    }

    private var cellSize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let totalHorizontalPadding: CGFloat = 64 // 16*2 (outer) + 16*2 (card)
        let availableWidth = screenWidth - totalHorizontalPadding - labelWidth - spacing
        guard columnCount > 0 else { return 14 }
        return (availableWidth - spacing * CGFloat(columnCount - 1)) / CGFloat(columnCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 헤더
            HStack {
                Image(systemName: "square.grid.3x3.fill")
                    .foregroundColor(.green)
                Text("학습 잔디")
                    .font(.headline)
                Spacer()
            }

            // 월 라벨
            MonthLabelsRow(viewModel: viewModel, cellSize: cellSize, labelWidth: labelWidth)

            // 그리드
            HStack(alignment: .top, spacing: spacing) {
                // 요일 라벨 (전체 표시)
                VStack(spacing: spacing) {
                    ForEach(0..<7, id: \.self) { row in
                        Text(["일", "월", "화", "수", "목", "금", "토"][row])
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .frame(width: labelWidth, height: cellSize)
                    }
                }

                // 잔디 셀 그리드
                HStack(spacing: spacing) {
                    ForEach(0..<columnCount, id: \.self) { col in
                        VStack(spacing: spacing) {
                            ForEach(0..<7, id: \.self) { row in
                                if row < viewModel.weeklyGrid.count {
                                    ContributionCell(
                                        activity: viewModel.weeklyGrid[row][col],
                                        isSelected: isSelected(row: row, col: col),
                                        cellSize: cellSize,
                                        onTap: {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                viewModel.selectedDay = viewModel.weeklyGrid[row][col]
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
            }

            // 선택된 날짜 팝업
            if let selected = viewModel.selectedDay {
                SelectedDayPopup(activity: selected) {
                    withAnimation { viewModel.selectedDay = nil }
                }
            }

            // 범례
            ContributionLegend()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }

    private func isSelected(row: Int, col: Int) -> Bool {
        guard let selected = viewModel.selectedDay,
              row < viewModel.weeklyGrid.count,
              col < viewModel.weeklyGrid[row].count,
              let cell = viewModel.weeklyGrid[row][col] else { return false }
        return Calendar.current.isDate(cell.date, inSameDayAs: selected.date)
    }
}

// MARK: - Month Labels Row
struct MonthLabelsRow: View {
    @ObservedObject var viewModel: DashboardViewModel
    let cellSize: CGFloat
    let labelWidth: CGFloat

    var body: some View {
        let columnCount = viewModel.weeklyGrid.first?.count ?? 0
        HStack(spacing: 3) {
            Color.clear.frame(width: labelWidth)
            ForEach(0..<columnCount, id: \.self) { col in
                if let label = viewModel.monthLabel(for: col) {
                    Text(label)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .frame(width: cellSize, alignment: .leading)
                } else {
                    Color.clear.frame(width: cellSize)
                }
            }
        }
    }
}

// MARK: - Contribution Cell
struct ContributionCell: View {
    let activity: DayActivity?
    let isSelected: Bool
    let cellSize: CGFloat
    let onTap: () -> Void

    var body: some View {
        if let activity {
            RoundedRectangle(cornerRadius: 3)
                .fill(activity.level.color)
                .frame(width: cellSize, height: cellSize)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(
                            isSelected ? Color.orange : Color.clear,
                            lineWidth: isSelected ? 2 : 0
                        )
                )
                .onTapGesture(perform: onTap)
        } else {
            Color.clear
                .frame(width: cellSize, height: cellSize)
        }
    }
}

// MARK: - Selected Day Popup
struct SelectedDayPopup: View {
    let activity: DayActivity
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.formattedDate)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)

                HStack(spacing: 12) {
                    Label("\(activity.sessionCount)회", systemImage: "book.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label(activity.formattedDuration, systemImage: "clock.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if activity.sessionCount > 0 {
                        Label(String(format: "%.0f%%", activity.averageFocusRate), systemImage: "eye.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "1a1a2e"))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.orange.opacity(0.5), lineWidth: 1)
                )
        )
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
    let streak: Int
    let todayTime: TimeInterval
    let weekTime: TimeInterval

    var body: some View {
        HStack(spacing: 0) {
            QuickStatItem(
                title: "연속",
                value: "\(streak)일",
                icon: "flame.fill",
                color: .orange
            )

            Divider()
                .frame(height: 40)
                .background(Color.white.opacity(0.2))

            QuickStatItem(
                title: "오늘",
                value: formatShortDuration(todayTime),
                icon: "clock.fill",
                color: .green
            )

            Divider()
                .frame(height: 40)
                .background(Color.white.opacity(0.2))

            QuickStatItem(
                title: "이번 주",
                value: formatShortDuration(weekTime),
                icon: "calendar",
                color: .blue
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }

    private func formatShortDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)시간 \(minutes)분"
        } else {
            return "\(minutes)분"
        }
    }
}

// MARK: - Quick Stat Item
struct QuickStatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.subheadline.bold())
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Quick Start Card
struct QuickStartCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("학습 시작하기")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("타이머를 시작하고 집중도를 측정해보세요")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.orange)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.orange.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
