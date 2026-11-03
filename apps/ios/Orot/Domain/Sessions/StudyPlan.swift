//
//  StudyPlan.swift
//  FocusSense
//
//  학습 계획 모델 (SwiftData)
//

/// ============================================================
/// 📚 학습 포인트: Associated Value가 있는 enum을 SwiftData에 저장하기
/// ============================================================
///
/// Swift enum의 종류:
/// 1. Simple enum: case a, b, c  → RawRepresentable로 직접 저장 가능
/// 2. Associated Value enum: case weekdays([Int])  → 직접 저장 불가능!
///
/// SwiftData는 기본 타입만 저장하므로, Associated Value enum은
/// String으로 직접 인코딩/디코딩하는 패턴을 사용합니다.
///
/// 인코딩 규칙:
///   .daily              → "daily"
///   .weekdays([2,4,6])  → "weekdays:2,4,6"
///

import Foundation
import SwiftUI
import SwiftData

// MARK: - Recurrence Type

/// 학습 계획의 반복 패턴을 나타내는 enum
///
/// 📚 Equatable 프로토콜:
/// == 연산자로 두 값을 비교할 수 있게 합니다.
/// Associated Value가 있는 enum은 자동으로 Equatable이 되지 않으므로 명시합니다.
///
enum RecurrenceType: Equatable {
    case daily
    case weekdays([Int])  // 1=일, 2=월, 3=화, 4=수, 5=목, 6=금, 7=토
    // Apple Calendar에서 1=일요일 (미국식) 주의!

    /// String 인코딩 (SwiftData 저장용)
    ///
    /// 📚 .map(String.init) 분석:
    /// String.init은 String의 이니셜라이저를 함수처럼 전달하는 문법입니다.
    /// days.map(String.init)은 days.map { String($0) }과 동일합니다.
    ///
    var rawString: String {
        switch self {
        case .daily:
            return "daily"
        case .weekdays(let days):
            // [2,4,6] → "weekdays:2,4,6"
            return "weekdays:" + days.map(String.init).joined(separator: ",")
        }
    }

    /// String 디코딩 (SwiftData에서 복원)
    ///
    /// 📚 static func (타입 메서드):
    /// 인스턴스 없이 타입 자체에서 호출합니다.
    /// RecurrenceType.from(rawString: "daily") → .daily
    /// 새 인스턴스를 생성하는 "팩토리 메서드" 패턴입니다.
    ///
    static func from(rawString: String) -> RecurrenceType {
        if rawString == "daily" {
            return .daily
        } else if rawString.hasPrefix("weekdays:") {
            // "weekdays:2,4,6" → [2, 4, 6]
            let daysString = rawString.replacingOccurrences(of: "weekdays:", with: "")
            let days = daysString.split(separator: ",").compactMap { Int($0) }
            // 📚 compactMap: map과 같지만 nil 결과를 자동 제거
            // Int("abc") → nil → compactMap이 무시
            return .weekdays(days)
        }
        return .daily // 기본값 (파싱 실패 시 안전하게 daily 반환)
    }

    /// 표시용 요약 문자열
    var summary: String {
        switch self {
        case .daily:
            return "매일"
        case .weekdays(let days):
            let dayNames = ["", "일", "월", "화", "수", "목", "금", "토"]
            let names = days.sorted().compactMap { $0 >= 1 && $0 <= 7 ? dayNames[$0] : nil }
            return names.joined(separator: ", ") // ["월", "수", "금"] → "월, 수, 금"
        }
    }
}

// MARK: - Study Plan Model

/// 학습 계획: 특정 과목의 반복 학습 일정 + 알림 설정
///
/// 📚 이 모델의 데이터 흐름:
/// 1. 설정 → StudyPlanListView에서 생성/수정/삭제 (CRUD)
/// 2. 타이머 시작 → StudyPlanPickerView에서 오늘의 계획 선택
/// 3. 세션 기록 → 선택한 계획 정보가 StudySession에 스냅샷으로 저장
/// 4. 알림 → NotificationService가 UNCalendarNotificationTrigger 등록
///
@Model
final class StudyPlan {
    var id: UUID
    var title: String
    var colorHex: String

    /// 📚 Raw String 저장 패턴:
    /// recurrenceTypeRaw → DB에 실제 저장되는 String ("daily" 또는 "weekdays:2,4,6")
    /// recurrenceType → 외부에서 사용하는 computed property (RecurrenceType enum)
    /// 이 패턴은 FocusRecord.focusLevelRaw / .focusLevel과 동일합니다.
    var recurrenceTypeRaw: String

    /// 알림 시간 (시/분 분리 저장)
    /// Date 대신 Int를 사용하는 이유: Date에 불필요한 날짜 정보가 포함되기 때문
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
        self.recurrenceTypeRaw = recurrenceType.rawString // enum → String 변환 후 저장
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.isReminderEnabled = isReminderEnabled
        self.isActive = isActive
        self.createdAt = Date()
    }

    // MARK: - Computed Properties

    /// 📚 get/set 양방향 computed property:
    /// get: DB에서 읽을 때 String → enum 변환
    /// set: 값을 설정할 때 enum → String 변환 후 DB에 저장
    var recurrenceType: RecurrenceType {
        get { RecurrenceType.from(rawString: recurrenceTypeRaw) }
        set { recurrenceTypeRaw = newValue.rawString }
    }

    /// 📚 Color(hex:) 확장:
    /// TimerView.swift에서 정의한 Color extension을 사용합니다.
    /// "FF6B35" → Color(red: 1.0, green: 0.42, blue: 0.21)
    var color: Color {
        Color(hex: colorHex)
    }

    var recurrenceSummary: String {
        recurrenceType.summary
    }

    /// 알림 시간 표시 문자열 (예: "09:00")
    var reminderTimeString: String {
        guard isReminderEnabled else { return "" }
        return String(format: "%02d:%02d", reminderHour, reminderMinute)
    }

    /// 오늘 해당되는 계획인지 확인
    ///
    /// 📚 Calendar.current.component(.weekday, from:):
    /// 현재 요일을 1(일)~7(토) 범위의 Int로 반환합니다.
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

/// 📚 Extension으로 static 프로퍼티 분리:
/// 모델 정의와 UI 관련 상수를 분리하여 가독성을 높입니다.
/// static: 인스턴스가 아닌 타입 자체에 속하는 프로퍼티
/// → StudyPlan.presetColors 로 접근
extension StudyPlan {
    /// 📚 튜플 배열: struct를 만들기에는 너무 간단한 데이터 묶음에 사용
    static let presetColors: [(name: String, hex: String)] = [
        ("오렌지", "FF6B35"),
        ("블루", "4A90D9"),
        ("그린", "2ECC71"),
        ("퍼플", "9B59B6"),
        ("레드", "E74C3C"),
        ("시안", "1ABC9C")
    ]
}
