//
//  StudySession.swift
//  FocusSense
//
//  학습 세션 기록 모델 (SwiftData)
//

import Foundation
import SwiftData

// MARK: - Study Session Model
@Model
final class StudySession {
    var id: UUID
    var startTime: Date
    var endTime: Date?

    @Relationship(deleteRule: .cascade, inverse: \FocusRecord.session)
    var focusRecords: [FocusRecord]

    // MARK: - 학습 계획 연동 (스냅샷)
    var studyPlanId: UUID?
    var studyPlanTitle: String?
    var studyPlanColorHex: String?

    init(id: UUID = UUID(), startTime: Date = Date()) {
        self.id = id
        self.startTime = startTime
        self.endTime = nil
        self.focusRecords = []
        self.studyPlanId = nil
        self.studyPlanTitle = nil
        self.studyPlanColorHex = nil
    }

    // MARK: - Computed Properties

    /// 총 학습 시간 (초)
    var totalDuration: TimeInterval {
        guard let endTime = endTime else {
            return Date().timeIntervalSince(startTime)
        }
        return endTime.timeIntervalSince(startTime)
    }

    /// 순수 집중 시간 (초)
    var netFocusTime: TimeInterval {
        focusRecords
            .filter { $0.focusLevel == .focused }
            .reduce(0) { $0 + $1.duration }
    }

    /// 집중률 (%)
    var focusRate: Double {
        guard totalDuration > 0 else { return 0 }
        return (netFocusTime / totalDuration) * 100
    }

    /// 졸음 감지 횟수
    var drowsinessCount: Int {
        focusRecords.filter { $0.focusLevel == .drowsy }.count
    }

    /// 이탈 횟수
    var unfocusedCount: Int {
        focusRecords.filter { $0.focusLevel == .unfocused }.count
    }

    // MARK: - Formatted Strings

    var formattedTotalDuration: String {
        formatDuration(totalDuration)
    }

    var formattedNetFocusTime: String {
        formatDuration(netFocusTime)
    }

    var formattedFocusRate: String {
        String(format: "%.1f%%", focusRate)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d시간 %02d분 %02d초", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%d분 %02d초", minutes, seconds)
        } else {
            return String(format: "%d초", seconds)
        }
    }
}

// MARK: - Focus Record (시간대별 집중도 기록)
@Model
final class FocusRecord {
    var id: UUID
    var timestamp: Date
    var focusLevelRaw: String
    var duration: TimeInterval
    var focusScore: Double
    var session: StudySession?

    /// FocusLevel computed property (focusLevelRaw ↔ FocusLevel)
    var focusLevel: FocusLevel {
        get { FocusLevel(rawValue: focusLevelRaw) ?? .unknown }
        set { focusLevelRaw = newValue.rawValue }
    }

    init(id: UUID = UUID(), timestamp: Date = Date(), focusLevel: FocusLevel, duration: TimeInterval = 1.0, focusScore: Double = 0.0) {
        self.id = id
        self.timestamp = timestamp
        self.focusLevelRaw = focusLevel.rawValue
        self.duration = duration
        self.focusScore = focusScore
    }
}

// MARK: - FocusLevel Codable Extension
extension FocusLevel: Codable {}

// MARK: - Hourly Focus Summary (시간대별 집중도 요약)
struct HourlyFocusSummary: Identifiable {
    let id = UUID()
    let hour: Int  // 0-23
    let averageFocusRate: Double
    let totalRecords: Int

    var hourString: String {
        String(format: "%02d:00", hour)
    }
}
