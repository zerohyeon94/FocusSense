//
//  NotificationService.swift
//  FocusSense
//
//  로컬 알림 관리 서비스
//

import Foundation
import UserNotifications

// MARK: - Notification Service
final class NotificationService {

    private let center = UNUserNotificationCenter.current()

    // MARK: - Permission

    /// 알림 권한 요청
    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                print("✅ 알림 권한 허용")
            } else {
                print("⚠️ 알림 권한 거부")
            }
            return granted
        } catch {
            print("❌ 알림 권한 요청 실패: \(error)")
            return false
        }
    }

    /// 현재 알림 권한 상태 확인
    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Schedule Notifications

    /// 학습 계획에 대한 알림 등록
    func scheduleNotifications(for plan: StudyPlan) {
        guard plan.isReminderEnabled && plan.isActive else { return }

        switch plan.recurrenceType {
        case .daily:
            // 매일 알림: 모든 요일에 등록
            for weekday in 1...7 {
                scheduleWeekdayNotification(for: plan, weekday: weekday)
            }

        case .weekdays(let days):
            // 특정 요일만 알림
            for weekday in days {
                scheduleWeekdayNotification(for: plan, weekday: weekday)
            }
        }

        print("✅ 알림 등록: \(plan.title)")
    }

    /// 특정 요일에 대한 알림 등록
    private func scheduleWeekdayNotification(for plan: StudyPlan, weekday: Int) {
        let content = UNMutableNotificationContent()
        content.title = "학습 시간"
        content.body = "\(plan.title) 학습을 시작할 시간입니다!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.weekday = weekday
        dateComponents.hour = plan.reminderHour
        dateComponents.minute = plan.reminderMinute

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let identifier = notificationIdentifier(planId: plan.id, weekday: weekday)
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                print("❌ 알림 등록 실패 (\(identifier)): \(error)")
            }
        }
    }

    // MARK: - Remove Notifications

    /// 특정 학습 계획의 모든 알림 제거
    func removeNotifications(for planId: UUID) {
        let identifiers = (1...7).map { notificationIdentifier(planId: planId, weekday: $0) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("✅ 알림 제거: \(planId.uuidString.prefix(8))")
    }

    /// 모든 학습 계획의 알림 전체 재등록
    func refreshAllNotifications(plans: [StudyPlan]) {
        // 기존 알림 모두 제거
        center.removeAllPendingNotificationRequests()

        // 활성 계획의 알림 재등록
        for plan in plans where plan.isReminderEnabled && plan.isActive {
            scheduleNotifications(for: plan)
        }

        print("🔄 전체 알림 갱신: \(plans.filter { $0.isReminderEnabled && $0.isActive }.count)개")
    }

    // MARK: - Helpers

    /// 알림 식별자 생성
    private func notificationIdentifier(planId: UUID, weekday: Int) -> String {
        "studyplan-\(planId.uuidString)-\(weekday)"
    }
}
