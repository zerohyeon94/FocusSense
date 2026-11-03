//
//  FocusRecord.swift
//  FocusSense
//
//  Created by 조영현 on 3/11/26.
//

import Foundation
import SwiftData

// MARK: - Focus Record (시간대별 집중도 기록)

/// 매 초마다 기록되는 집중 상태 스냅샷
///
/// 📚 SwiftData에서 enum을 저장하는 패턴:
/// SwiftData는 기본 타입(String, Int, Double, Date 등)만 직접 저장 가능합니다.
/// FocusLevel enum은 직접 저장할 수 없으므로, String으로 변환하여 저장합니다.
///
/// 저장: focusLevelRaw = focusLevel.rawValue  (enum → String)
/// 복원: FocusLevel(rawValue: focusLevelRaw)  (String → enum)
///
@Model
final class FocusRecord {
    var id: UUID
    var timestamp: Date

    /// DB에 저장되는 실제 값 (String 타입)
    /// 예: "focused", "drowsy", "away" 등
    var focusLevelRaw: String

    /// 이 기록의 지속 시간 (보통 1.0초)
    var duration: TimeInterval

    /// AI 분석 결합 점수 (0.0 ~ 1.0)
    var focusScore: Double

    /// 📚 역방향 관계: 이 레코드가 속한 세션
    /// Optional인 이유: SwiftData가 관계를 설정할 때 일시적으로 nil일 수 있음
    var session: StudySession?

    /// 📚 Computed Property로 enum 인터페이스 제공
    /// 외부에서는 focusLevel로 접근하지만, 내부적으로는 focusLevelRaw를 읽고 씁니다.
    ///
    /// get: String → enum 변환 (실패 시 .unknown)
    /// set: enum → String 변환
    ///
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
