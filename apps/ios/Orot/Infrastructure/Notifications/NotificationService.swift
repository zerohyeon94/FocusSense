//
//  NotificationService.swift
//  Orot
//
//  세션 · 휴식이 끝날 시각에 맞춰 로컬 알림을 예약합니다.
//  앱 화면이 켜져 있으면 화면이 직접 알려 주므로 알림을 띄우지 않습니다.
//

import Foundation
import UserNotifications

@MainActor
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {

    private let center = UNUserNotificationCenter.current()
    private let sessionEndID = "orot.session.end"
    private let restEndID = "orot.rest.end"

    override init() {
        super.init()
        center.delegate = self
    }

    // MARK: - Permission

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    /// 처음 한 번만 묻습니다.
    func requestIfNeeded() async {
        guard await authorizationStatus() == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    // MARK: - Schedule

    func scheduleSessionEnd(after seconds: TimeInterval, minutes: Int) {
        let s = OrotSettings.current
        guard s.notifySessionEnd, seconds > 0 else { return }
        schedule(id: sessionEndID, title: "정한 \(minutes)분을 채웠어요", body: "흐름을 이어가도 되고, 여기서 마쳐도 돼요.", after: seconds, sound: s.sound)
    }

    func scheduleRestEnd(after seconds: TimeInterval) {
        let s = OrotSettings.current
        guard s.notifyRestEnd, seconds > 0 else { return }
        schedule(id: restEndID, title: "휴식이 끝났어요", body: "다음 세션을 이어서 시작할게요.", after: seconds, sound: s.sound)
    }

    func cancelAll() {
        center.removePendingNotificationRequests(withIdentifiers: [sessionEndID, restEndID])
    }

    private func schedule(id: String, title: String, body: String, after seconds: TimeInterval, sound: Bool) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound ? .default : nil
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        center.removePendingNotificationRequests(withIdentifiers: [id])
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    // MARK: - UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([])
    }
}
