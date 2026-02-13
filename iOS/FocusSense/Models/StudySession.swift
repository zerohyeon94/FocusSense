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

    /// SwiftData에서 관계 설정: cascade 삭제
    @Relationship(deleteRule: .cascade, inverse: \FocusRecord.session)
    var focusRecords: [FocusRecord]

    init(id: UUID = UUID(), startTime: Date = Date()) {
        self.id = id
        self.startTime = startTime
        self.endTime = nil
        self.focusRecords = []
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

    /// 집중률 (%) - 종합 집중도 점수 평균
    var focusRate: Double {
        let scored = focusRecords.filter { $0.focusScore > 0 }
        guard !scored.isEmpty else {
            // focusScore가 없는 기존 데이터 호환: 기존 로직 fallback
            guard totalDuration > 0 else { return 0 }
            return (netFocusTime / totalDuration) * 100
        }
        return scored.map { $0.focusScore }.reduce(0, +) / Double(scored.count)
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
    var focusLevelRaw: String  // FocusLevel.rawValue 저장
    var duration: TimeInterval  // 해당 상태 지속 시간
    var focusScore: Double      // 종합 집중도 점수 (0~100)

    /// 소속 세션 (inverse)
    var session: StudySession?

    /// FocusLevel computed property
    var focusLevel: FocusLevel {
        get { FocusLevel(rawValue: focusLevelRaw) ?? .unknown }
        set { focusLevelRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        focusLevel: FocusLevel,
        duration: TimeInterval = 1.0,
        focusScore: Double = 0
    ) {
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
