//
//  DayActivity.swift
//  FocusSense
//
//  일별 학습 활동 모델 (잔디 그래프용)
//

import SwiftUI

// MARK: - Activity Level
enum ActivityLevel: Int, CaseIterable {
    case none = 0      // 학습 없음
    case low = 1       // < 30분
    case medium = 2    // 30-60분
    case high = 3      // 1-2시간
    case veryHigh = 4  // > 2시간

    var color: Color {
        switch self {
        case .none:     return Color.white.opacity(0.05)
        case .low:      return Color.green.opacity(0.2)
        case .medium:   return Color.green.opacity(0.4)
        case .high:     return Color.green.opacity(0.65)
        case .veryHigh: return Color.green.opacity(0.85)
        }
    }

    static func from(duration: TimeInterval) -> ActivityLevel {
        let minutes = duration / 60
        switch minutes {
        case 0:             return .none
        case ..<30:         return .low
        case ..<60:         return .medium
        case ..<120:        return .high
        default:            return .veryHigh
        }
    }
}

// MARK: - Day Activity
struct DayActivity: Identifiable {
    let id = UUID()
    let date: Date
    let sessionCount: Int
    let totalDuration: TimeInterval
    let averageFocusRate: Double
    let level: ActivityLevel

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 (E)"
        return formatter.string(from: date)
    }

    var formattedDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        if hours > 0 {
            return "\(hours)시간 \(minutes)분"
        } else {
            return "\(minutes)분"
        }
    }
}
