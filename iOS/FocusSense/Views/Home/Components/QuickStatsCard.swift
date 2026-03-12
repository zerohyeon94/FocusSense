//
//  QuickStatsCard.swift
//  FocusSense
//
//  Created by 조영현 on 3/12/26.
//

import SwiftUI

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
