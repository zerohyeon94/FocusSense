//
//  SessionActivityAttributes.swift
//  Orot
//
//  앱과 위젯 확장이 함께 쓰는 Live Activity 타입 — 잠금 화면 · 다이내믹 아일랜드 · StandBy
//

import ActivityKit
import Foundation

struct SessionActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        enum Phase: String, Codable, Hashable {
            case focusing, paused, rest, complete
        }

        var phase: Phase
        /// 지금 구간(집중 또는 휴식)이 시작된 것으로 보는 시각 — 진행 막대의 시작점
        var startedAt: Date
        /// 지금 구간이 끝나는 시각. 집중은 이 시각이 지나면 오버타임으로 이어서 셉니다.
        var endsAt: Date
        /// 멈췄을 때 보여 줄 남은 시간 (초)
        var pausedRemaining: TimeInterval
        /// 이번 세션 별이 모인 정도 (0~1)
        var starFormation: Double
        /// "두(斗) · 3 / 6"
        var mansionCaption: String
        /// 완료 시 별 등급
        var magnitude: Int
    }

    var subject: String
    var targetMinutes: Int
}
