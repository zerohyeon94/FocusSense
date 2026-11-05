//
//  LiveActivityService.swift
//  Orot
//
//  세션을 잠금 화면 · 다이내믹 아일랜드에 띄웁니다. 시계는 시스템이 직접 세므로 상태가 바뀔 때만 갱신합니다.
//

import ActivityKit
import Foundation

@MainActor
final class LiveActivityService {
    private var activity: Activity<SessionActivityAttributes>?

    func update(subject: String, targetMinutes: Int, state: SessionActivityAttributes.ContentState) {
        let content = ActivityContent(state: state, staleDate: nil)
        if let activity, activity.attributes.subject == subject, activity.attributes.targetMinutes == targetMinutes {
            Task { await activity.update(content) }
            return
        }
        end()
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        do {
            activity = try Activity.request(
                attributes: SessionActivityAttributes(subject: subject, targetMinutes: targetMinutes),
                content: content
            )
            print("✅ 잠금 화면 표시 시작")
        } catch {
            print("❌ 잠금 화면 표시 실패: \(error.localizedDescription)")
        }
    }

    /// 앱이 강제 종료돼 남아 있던 표시를 지웁니다.
    func endLeftovers() {
        let leftovers = Activity<SessionActivityAttributes>.activities
        Task {
            for activity in leftovers { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }

    func end() {
        guard let activity else { return }
        self.activity = nil
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }
}
