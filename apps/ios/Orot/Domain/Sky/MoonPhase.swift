//
//  MoonPhase.swift
//  Orot
//
//  기기 날짜로 계산한 실제 오늘의 달 위상
//

import Foundation

// MARK: - Moon Phase
struct MoonPhase {
    private static let synodicMonth = 29.530588853
    /// 기준 삭(2000-01-06 18:14 UTC)
    private static let referenceNewMoon = Date(timeIntervalSince1970: 947_182_440)

    /// 0(삭) → 0.5(보름) → 1(다음 삭)
    let fraction: Double

    init(date: Date = Date()) {
        let days = date.timeIntervalSince(Self.referenceNewMoon) / 86_400
        let age = days.truncatingRemainder(dividingBy: Self.synodicMonth)
        fraction = (age < 0 ? age + Self.synodicMonth : age) / Self.synodicMonth
    }

    /// 월령(1일부터)
    var age: Int { Int(fraction * Self.synodicMonth) + 1 }

    var name: String {
        switch fraction {
        case ..<0.03, 0.97...: return "삭"
        case ..<0.22: return "초승달"
        case ..<0.28: return "상현달"
        case ..<0.47: return "차오르는 달"
        case ..<0.53: return "보름달"
        case ..<0.72: return "기우는 달"
        case ..<0.78: return "하현달"
        default: return "그믐달"
        }
    }
}
