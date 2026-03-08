//
//  DayActivity.swift
//  FocusSense
//
//  일별 학습 활동 모델 (잔디 그래프용)
//

/// ============================================================
/// 📚 학습 포인트: View 전용 모델 (SwiftData와 무관한 struct)
/// ============================================================
///
/// 이 파일의 모델들은 SwiftData에 저장하지 않습니다.
/// DashboardViewModel이 StudySession 데이터를 가공하여
/// 잔디 그래프 표시에 최적화된 형태로 만든 "뷰 모델 데이터"입니다.
///
/// 데이터 변환 흐름:
/// StudySession (SwiftData)
///     ↓ DashboardViewModel.computeContributionData()
/// DayActivity (struct, 뷰 전용)
///     ↓ ContributionGraphView
/// 잔디 셀 UI (Color 결정)
///

import SwiftUI

// MARK: - Contribution Display Mode

/// 학습 그래프 표시 모드 (잔디 / 별자리 / 물방울)
///
/// 📚 String RawValue를 사용하는 이유:
/// @AppStorage는 기본적으로 String, Int, Bool 등 기본 타입만 저장 가능합니다.
/// String rawValue를 가진 enum은 @AppStorage와 직접 호환됩니다 (iOS 15+).
/// → @AppStorage("contributionDisplayMode") var mode: String = "grass"
///
enum ContributionDisplayMode: String, CaseIterable {
    case grass = "grass"                 // 학습 잔디 (기본)
    case constellation = "constellation" // 별자리
    case waterDrop = "waterDrop"         // 물방울
}

// MARK: - Activity Level

/// 하루 학습량에 따른 활동 레벨 (GitHub 잔디 색상 단계)
///
/// 📚 enum + 여러 프로토콜 조합:
/// - Int: 각 case에 정수값 부여 (none=0, low=1...)
///        → rawValue로 정수 접근 가능 (ActivityLevel.high.rawValue → 3)
/// - CaseIterable: .allCases 배열을 자동 생성
///        → ForEach(ActivityLevel.allCases) { level in ... }
///        → 범례(Legend) UI에서 모든 레벨의 색상을 순회할 때 사용
///
enum ActivityLevel: Int, CaseIterable {
    case none = 0      // 학습 없음
    case low = 1       // < 30분
    case medium = 2    // 30-60분
    case high = 3      // 1-2시간
    case veryHigh = 4  // > 2시간

    /// 📚 opacity(투명도)로 색상 단계를 표현 (GitHub 잔디와 동일 방식)
    var color: Color {
        switch self {
        case .none:     return Color.white.opacity(0.05)  // 거의 투명 (빈칸)
        case .low:      return Color.green.opacity(0.2)
        case .medium:   return Color.green.opacity(0.4)
        case .high:     return Color.green.opacity(0.65)
        case .veryHigh: return Color.green.opacity(0.85)
        }
    }

    /// 📚 팩토리 메서드: 학습 시간(초)으로부터 레벨 결정
    ///
    /// switch에서 Range 패턴 매칭:
    /// - 0:       정확히 0분
    /// - ..<30:   0 초과 ~ 30 미만 (30분 미만)
    /// - default: 나머지 전부 (120분 이상)
    ///
    static func from(duration: TimeInterval) -> ActivityLevel {
        let minutes = duration / 60
        switch minutes {
        case 0:             return .none
        case ..<30:         return .low
        case ..<60:         return .medium
        case ..<120:        return .high
        default:            return .veryHigh
        }
    }

    // MARK: - Constellation Mode Properties

    /// 별자리 모드에서 별 크기 (cellSize 대비 비율)
    var starScale: CGFloat {
        switch self {
        case .none:     return 0.0
        case .low:      return 0.35
        case .medium:   return 0.55
        case .high:     return 0.75
        case .veryHigh: return 0.95
        }
    }

    /// 별자리 모드에서 별 색상 (오렌지 계열)
    var starColor: Color {
        switch self {
        case .none:     return Color.white.opacity(0.15)
        case .low:      return Color.orange.opacity(0.5)
        case .medium:   return Color.orange.opacity(0.7)
        case .high:     return Color.orange.opacity(0.85)
        case .veryHigh: return Color.orange.opacity(1.0)
        }
    }

    // MARK: - Water Drop Mode Properties

    /// 물방울 모드에서 크기 (cellSize 대비 비율)
    var dropScale: CGFloat {
        switch self {
        case .none:     return 0.0
        case .low:      return 0.35
        case .medium:   return 0.55
        case .high:     return 0.75
        case .veryHigh: return 0.95
        }
    }

    /// 물방울 모드에서 색상 (시안/블루 계열)
    var dropColor: Color {
        switch self {
        case .none:     return Color.white.opacity(0.08)
        case .low:      return Color.cyan.opacity(0.4)
        case .medium:   return Color.cyan.opacity(0.6)
        case .high:     return Color.cyan.opacity(0.8)
        case .veryHigh: return Color.cyan
        }
    }
}

// MARK: - Day Activity

/// 특정 날짜의 학습 활동 요약 (잔디 그래프의 한 칸에 해당)
///
/// 📚 struct를 사용하는 이유:
/// SwiftData에 저장하지 않는 일시적 데이터이므로 값 타입(struct)이 적합합니다.
/// - struct: 값 타입, 복사 시 독립적인 복사본 생성, 가벼움, 스택 메모리
/// - class: 참조 타입, 복사 시 같은 객체 가리킴, SwiftData 필수, 힙 메모리
///
/// 📚 Identifiable 프로토콜:
/// ForEach에서 사용하려면 각 요소를 구분할 수 있는 id가 필요합니다.
/// Identifiable을 채택하면 ForEach(activities) { activity in ... } 사용 가능
///
struct DayActivity: Identifiable {
    let id = UUID()
    let date: Date
    let sessionCount: Int
    let totalDuration: TimeInterval
    let averageFocusRate: Double
    let level: ActivityLevel

    /// 📚 DateFormatter 사용법:
    /// - locale: "ko_KR"으로 한국어 표시
    /// - dateFormat: "M월 d일 (E)" → "2월 15일 (토)"
    ///   M: 월(0패딩 없음), d: 일(0패딩 없음), E: 요일 약어
    ///
    /// ⚠️ 성능 주의: DateFormatter 생성은 비용이 큽니다.
    /// 프로덕션에서는 static let으로 한 번만 생성하여 재사용하는 것이 좋습니다.
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 (E)"
        return formatter.string(from: date)
    }

    var formattedDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        if hours > 0 {
            return "\(hours)시간 \(minutes)분"
        } else {
            return "\(minutes)분"
        }
    }
}
