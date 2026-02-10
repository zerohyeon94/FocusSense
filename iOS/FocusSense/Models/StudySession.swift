//
//  StudySession.swift
//  FocusSense
//
//  학습 세션 기록 모델
//

import Foundation

// MARK: - Study Session Model
// Codable: JSON 저장/불러오기 가능
struct StudySession: Identifiable, Codable {
    let id: UUID
    let startTime: Date
    var endTime: Date?
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
    
    /// 집중률 (%)
    var focusRate: Double {
        guard totalDuration > 0 else { return 0 } // 0으로 나누기 방지
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
struct FocusRecord: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let focusLevel: FocusLevel
    let duration: TimeInterval  // 해당 상태 지속 시간
    
    init(id: UUID = UUID(), timestamp: Date = Date(), focusLevel: FocusLevel, duration: TimeInterval = 1.0) {
        self.id = id
        self.timestamp = timestamp
        self.focusLevel = focusLevel
        self.duration = duration
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
