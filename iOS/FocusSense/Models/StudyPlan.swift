//
//  StudyPlan.swift
//  FocusSense
//
//  학습 계획 모델 (SwiftData)
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - Recurrence Type
enum RecurrenceType: Equatable {
    case daily
    case weekdays([Int])  // 1=일, 2=월, 3=화, 4=수, 5=목, 6=금, 7=토

    /// String 인코딩 (SwiftData 저장용)
    var rawString: String {
        switch self {
        case .daily:
            return "daily"
        case .weekdays(let days):
            return "weekdays:" + days.map(String.init).joined(separator: ",")
        }
    }

    /// String 디코딩
    static func from(rawString: String) -> RecurrenceType {
        if rawString == "daily" {
            return .daily
        } else if rawString.hasPrefix("weekdays:") {
            let daysString = rawString.replacingOccurrences(of: "weekdays:", with: "")
            let days = daysString.split(separator: ",").compactMap { Int($0) }
            return .weekdays(days)
        }
        return .daily
    }

    /// 표시용 요약 문자열
    var summary: String {
        switch self {
        case .daily:
            return "매일"
        case .weekdays(let days):
            let dayNames = ["", "일", "월", "화", "수", "목", "금", "토"]
            let names = days.sorted().compactMap { $0 >= 1 && $0 <= 7 ? dayNames[$0] : nil }
            return names.joined(separator: ", ")
        }
    }
}

// MARK: - Study Plan Model
@Model
final class StudyPlan {
    var id: UUID
    var title: String
    var colorHex: String
    var recurrenceTypeRaw: String
    var reminderHour: Int
    var reminderMinute: Int
    var isReminderEnabled: Bool
    var isActive: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String = "",
        colorHex: String = "FF6B35",
        recurrenceType: RecurrenceType = .daily,
        reminderHour: Int = 9,
        reminderMinute: Int = 0,
        isReminderEnabled: Bool = false,
        isActive: Bool = true
    ) {
        self.id = id
        self.title = title
        self.colorHex = colorHex
        self.recurrenceTypeRaw = recurrenceType.rawString
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.isReminderEnabled = isReminderEnabled
        self.isActive = isActive
        self.createdAt = Date()
    }

    // MARK: - Computed Properties

    /// RecurrenceType enum
    var recurrenceType: RecurrenceType {
        get { RecurrenceType.from(rawString: recurrenceTypeRaw) }
        set { recurrenceTypeRaw = newValue.rawString }
    }

    /// SwiftUI Color
    var color: Color {
        Color(hex: colorHex)
    }

    /// 반복 일정 요약 문자열
    var recurrenceSummary: String {
        recurrenceType.summary
    }

    /// 알림 시간 표시 문자열
    var reminderTimeString: String {
        guard isReminderEnabled else { return "" }
        return String(format: "%02d:%02d", reminderHour, reminderMinute)
    }

    /// 오늘 해당되는 계획인지
    var isScheduledToday: Bool {
        guard isActive else { return false }
        switch recurrenceType {
        case .daily:
            return true
        case .weekdays(let days):
            let todayWeekday = Calendar.current.component(.weekday, from: Date())
            return days.contains(todayWeekday)
        }
    }
}

// MARK: - Preset Colors
extension StudyPlan {
    static let presetColors: [(name: String, hex: String)] = [
        ("오렌지", "FF6B35"),
        ("블루", "4A90D9"),
        ("그린", "2ECC71"),
        ("퍼플", "9B59B6"),
        ("레드", "E74C3C"),
        ("시안", "1ABC9C")
    ]
}
