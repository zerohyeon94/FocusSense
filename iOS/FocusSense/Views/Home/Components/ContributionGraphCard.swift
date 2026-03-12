//
//  ContributionGraphCard.swift
//  FocusSense
//
//  GitHub 스타일 잔디 그래프 UI 컴포넌트
//

// ============================================================================
// 📚 [파일 개요] ContributionGraphCard - GitHub 스타일 학습 잔디(Heatmap) 차트
// ============================================================================
//
// "학습 잔디"란:
//   GitHub의 Contribution Graph(잔디)에서 영감을 받은 히트맵 UI이다.
//   날짜별 학습량을 색상 농도로 표현하여 학습 습관을 시각적으로 보여준다.
//   7행(요일) x N열(주) 격자로 구성된다.
//
// 동적 셀 크기 계산:
//   cellSize는 화면 너비에서 좌우 패딩(64pt)과 요일 라벨 너비(16pt)를 뺀 후,
//   열 개수로 균등 분할하여 계산한다. 다양한 디바이스 크기에 자동으로 대응한다.
//
// MonthLabelsRow 정렬:
//   월 라벨은 그리드 열과 동일한 cellSize와 spacing을 사용하여 정렬한다.
//   Color.clear로 요일 라벨 너비만큼 오프셋을 두어 그리드 열과 1:1 대응시킨다.
//   해당 열이 새 달의 시작이 아니면 Color.clear로 빈 공간을 채운다.
//
// nil 셀 처리:
//   weeklyGrid에서 activity가 nil인 셀은 미래 날짜를 의미한다.
//   ContributionCell은 nil일 때 Color.clear를 표시하여 보이지 않게 만든다.
//   이로써 그리드 레이아웃은 유지하면서 미래 날짜 영역은 비워둔다.
//
// 카드 컴포넌트 구성:
//   ContributionGraphCard (최상위 카드)
//     ├── MonthLabelsRow    - 월 이름 라벨 행
//     ├── ContributionCell  - 개별 잔디 셀 (색상 + 탭 선택)
//     ├── SelectedDayPopup  - 선택된 날짜의 상세 정보 팝업
//     └── ContributionLegend - "적음 ↔ 많음" 범례
//
// ============================================================================

import SwiftUI

// MARK: - Contribution Graph Card
struct ContributionGraphCard: View {
    @ObservedObject var viewModel: DashboardViewModel
    @AppStorage("contributionDisplayMode") private var displayMode = "grass"

    private let spacing: CGFloat = 3
    private let labelWidth: CGFloat = 16

    private var columnCount: Int {
        viewModel.weeklyGrid.first?.count ?? 0
    }

    private var cellSize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let totalHorizontalPadding: CGFloat = 64 // 16*2 (outer) + 16*2 (card)
        /// 가용 폭 = 화면 너비 - 패딩(64) - 요일 Label 너비(16) - spacing(3)
        let availableWidth = screenWidth - totalHorizontalPadding - labelWidth - spacing
        guard columnCount > 0 else { return 14 }
        return (availableWidth - spacing * CGFloat(columnCount - 1)) / CGFloat(columnCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 헤더
            HStack {
                Image(systemName: headerIcon)
                    .foregroundColor(headerColor)
                Text(headerTitle)
                    .font(.headline)
                Spacer()
            }

            // 월 라벨
            MonthLabelsRow(viewModel: viewModel, cellSize: cellSize, labelWidth: labelWidth)

            // 그리드
            ZStack(alignment: .topLeading) {
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

                    // 셀 그리드
                    HStack(spacing: spacing) {
                        ForEach(0..<columnCount, id: \.self) { col in
                            VStack(spacing: spacing) {
                                ForEach(0..<7, id: \.self) { row in
                                    if row < viewModel.weeklyGrid.count {
                                        ContributionCell(
                                            activity: viewModel.weeklyGrid[row][col],
                                            isSelected: isSelected(row: row, col: col),
                                            cellSize: cellSize,
                                            displayMode: displayMode,
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

                // 별자리 연결선 오버레이
                if displayMode == "constellation" {
                    constellationLinesOverlay()
                }
            }

            // 선택된 날짜 팝업
            if let selected = viewModel.selectedDay {
                SelectedDayPopup(activity: selected) {
                    withAnimation { viewModel.selectedDay = nil }
                }
            }

            // 범례
            ContributionLegend(displayMode: displayMode)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }

    // MARK: - Constellation Lines Overlay
    @ViewBuilder
    private func constellationLinesOverlay() -> some View {
        Canvas { context, size in
            let grid = viewModel.weeklyGrid
            guard !grid.isEmpty else { return }
            let cols = grid[0].count

            func cellCenter(row: Int, col: Int) -> CGPoint {
                let x = labelWidth + spacing + CGFloat(col) * (cellSize + spacing) + cellSize / 2
                let y = CGFloat(row) * (cellSize + spacing) + cellSize / 2
                return CGPoint(x: x, y: y)
            }

            func hasActivity(row: Int, col: Int) -> Bool {
                guard row < grid.count, col < cols else { return false }
                guard let activity = grid[row][col] else { return false }
                return activity.level != .none
            }

            for row in 0..<7 {
                for col in 0..<cols {
                    guard hasActivity(row: row, col: col) else { continue }
                    let from = cellCenter(row: row, col: col)

                    // 가로 연결 (오른쪽 이웃)
                    if col + 1 < cols && hasActivity(row: row, col: col + 1) {
                        let to = cellCenter(row: row, col: col + 1)
                        var path = Path()
                        path.move(to: from)
                        path.addLine(to: to)
                        context.stroke(path, with: .color(.white.opacity(0.15)), lineWidth: 0.8)
                    }

                    // 세로 연결 (아래쪽 이웃)
                    if row + 1 < 7 && hasActivity(row: row + 1, col: col) {
                        let to = cellCenter(row: row + 1, col: col)
                        var path = Path()
                        path.move(to: from)
                        path.addLine(to: to)
                        context.stroke(path, with: .color(.white.opacity(0.15)), lineWidth: 0.8)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Header Properties
    private var headerIcon: String {
        switch displayMode {
        case "constellation": return "star.fill"
        case "waterDrop":     return "drop.fill"
        default:              return "square.grid.3x3.fill"
        }
    }

    private var headerColor: Color {
        switch displayMode {
        case "constellation": return .yellow
        case "waterDrop":     return .cyan
        default:              return .green
        }
    }

    private var headerTitle: String {
        switch displayMode {
        case "constellation": return "학습 별자리"
        case "waterDrop":     return "학습 물방울"
        default:              return "학습 잔디밭"
        }
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
    let displayMode: String
    let onTap: () -> Void

    var body: some View {
        if let activity {
            switch displayMode {
            case "constellation":
                constellationBody(activity: activity)
            case "waterDrop":
                waterDropBody(activity: activity)
            default:
                grassBody(activity: activity)
            }
        } else {
            Color.clear
                .frame(width: cellSize, height: cellSize)
        }
    }

    // 잔디 모드
    @ViewBuilder
    private func grassBody(activity: DayActivity) -> some View {
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
    }

    // 별자리 모드
    @ViewBuilder
    private func constellationBody(activity: DayActivity) -> some View {
        ZStack {
            if activity.level == .none {
                Circle()
                    .fill(activity.level.starColor)
                    .frame(width: cellSize * 0.2, height: cellSize * 0.2)
            } else {
                Image(systemName: "star.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: cellSize * activity.level.starScale,
                        height: cellSize * activity.level.starScale
                    )
                    .foregroundColor(activity.level.starColor)
                    .shadow(color: activity.level.starColor.opacity(0.6), radius: 3)
            }
        }
        .frame(width: cellSize, height: cellSize)
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .strokeBorder(
                    isSelected ? Color.yellow : Color.clear,
                    lineWidth: isSelected ? 1.5 : 0
                )
        )
        .onTapGesture(perform: onTap)
    }

    // 물방울 모드
    @ViewBuilder
    private func waterDropBody(activity: DayActivity) -> some View {
        ZStack {
            if activity.level == .none {
                Circle()
                    .fill(activity.level.dropColor)
                    .frame(width: cellSize * 0.2, height: cellSize * 0.2)
            } else {
                let dropSize = cellSize * activity.level.dropScale
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                activity.level.dropColor.opacity(0.3),
                                activity.level.dropColor
                            ],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: dropSize / 2
                        )
                    )
                    .frame(width: dropSize, height: dropSize)
                    .overlay(
                        // 하이라이트 (물방울 반사광)
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: dropSize * 0.3, height: dropSize * 0.3)
                            .offset(x: -dropSize * 0.15, y: -dropSize * 0.15)
                    )
                    .shadow(color: activity.level.dropColor.opacity(0.4), radius: 2)
            }
        }
        .frame(width: cellSize, height: cellSize)
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .strokeBorder(
                    isSelected ? Color.cyan : Color.clear,
                    lineWidth: isSelected ? 1.5 : 0
                )
        )
        .onTapGesture(perform: onTap)
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
    var displayMode: String = "grass"

    var body: some View {
        HStack(spacing: 4) {
            Spacer()
            Text("적음")
                .font(.system(size: 9))
                .foregroundColor(.secondary)

            switch displayMode {
            case "constellation":
                // 별자리 범례: 작은 점 → 크기 증가하는 별
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 4, height: 4)
                ForEach([ActivityLevel.low, .medium, .high, .veryHigh], id: \.rawValue) { level in
                    Image(systemName: "star.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 6 + CGFloat(level.rawValue) * 2,
                               height: 6 + CGFloat(level.rawValue) * 2)
                        .foregroundColor(level.starColor)
                }

            case "waterDrop":
                // 물방울 범례: 작은 점 → 크기 증가하는 원
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 4, height: 4)
                ForEach([ActivityLevel.low, .medium, .high, .veryHigh], id: \.rawValue) { level in
                    Circle()
                        .fill(level.dropColor)
                        .frame(width: 6 + CGFloat(level.rawValue) * 2,
                               height: 6 + CGFloat(level.rawValue) * 2)
                }

            default:
                // 잔디 범례
                ForEach(ActivityLevel.allCases, id: \.rawValue) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(level.color)
                        .frame(width: 10, height: 10)
                }
            }

            Text("많음")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
    }
}
