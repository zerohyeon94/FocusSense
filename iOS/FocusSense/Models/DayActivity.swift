//
//  DayActivity.swift
//  FocusSense
//
//  일별 학습 활동 데이터 모델 (GitHub 잔디 그래프용)
//

import SwiftUI

// MARK: - Day Activity Model
struct DayActivity: Identifiable {
    let id = UUID()
    let date: Date
    let sessionCount: Int
    let totalDuration: TimeInterval
    let averageFocusRate: Double
    let level: ActivityLevel

    // MARK: - Formatted Strings

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
            return String(format: "%d시간 %02d분", hours, minutes)
        } else if minutes > 0 {
            return "\(minutes)분"
        } else {
            return "0분"
        }
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

// MARK: - Activity Level (학습량에 따른 잔디 색상 단계)
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

    /// 학습 시간에 따른 활동 수준 결정
    static func from(duration: TimeInterval) -> ActivityLevel {
        switch duration {
        case 0:          return .none
        case ..<1800:    return .low       // < 30분
        case ..<3600:    return .medium    // 30-60분
        case ..<7200:    return .high      // 1-2시간
        default:         return .veryHigh  // > 2시간
        }
    }
}
