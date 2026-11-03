//
//  OrotTokens.swift
//  Orot
//
//  오롯 디자인 시스템 v0.1 토큰 — 시안 2a 기준. 색상은 OKLCH에서 sRGB로 변환한 값입니다.
//

import SwiftUI

// MARK: - Color + UInt32 Hex
extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255, opacity: 1)
    }
}

// MARK: - Color
enum OrotColor {
    static let skyDusk = Color(hex: 0x1F262F) // 초저녁 · 세션 시작
    static let skyEvening = Color(hex: 0x191F26) // 저녁
    static let skyLate = Color(hex: 0x15191E) // 늦은 밤
    static let skyNight = Color(hex: 0x101316) // 밤 · 집중 중 기본 배경
    static let skyDeepNight = Color(hex: 0x0C0D10) // 깊은 밤 · 세션 끝 무렵
    static let cityGlow = Color(hex: 0x392B1A) // 지평선 도시 불빛 (진행할수록 사라짐)
    static let buildingSilhouette = Color(hex: 0x161A1E) // 건물 실루엣
    static let windowOff = Color(hex: 0x1B1E23) // 꺼진 창문
    static let windowLitWarm = Color(hex: 0xCAAC7F) // 켜진 창문 · 백열
    static let windowLitAmber = Color(hex: 0xBD9F7C) // 켜진 창문 · 호박
    static let windowLitPale = Color(hex: 0xCBBC9A) // 켜진 창문 · 연한
    static let starMag1 = Color(hex: 0xC9BCA5) // 1등급
    static let starMag2 = Color(hex: 0xADA491) // 2등급
    static let starMag3 = Color(hex: 0x928B7F) // 3등급
    static let starMag4 = Color(hex: 0x767168) // 4등급
    static let starMag5 = Color(hex: 0x5B5852) // 5등급
    static let constellationLine = Color(hex: 0x32363B) // 별자리 연결 점선
    static let starSlotEmpty = Color(hex: 0x35383D) // 빈 별자리 고리
    static let moonLit = Color(hex: 0xB1AA9D) // 달 밝은 면
    static let moonShadow = Color(hex: 0x1E2226) // 달 그림자 면
    static let textPrimary = Color(hex: 0xC8C4BC) // 주 텍스트 · 남은 시간
    static let textSecondary = Color(hex: 0x89867E) // 보조 텍스트 · 라벨
    static let textCaption = Color(hex: 0x605D57) // 캡션 · 별자리 진행도
    static let accent = Color(hex: 0xA68F68) // 강조색 · 단 하나
    static let accentSubtle = Color(hex: 0x2C251A) // 강조 배경 (선택된 칩)
    static let surfaceRaised = Color(hex: 0x161A1E) // 올라온 면 · 칩/시트
    static let hairline = Color(hex: 0x2A2E33) // 1px 구분선·테두리
    static let stateOvertime = Color(hex: 0x86A4B3) // 오버타임 (빨강 대신 달빛 청회색)
    static let stateFocus = accent
    static let statePaused = textSecondary
    static let bgSession = skyNight

    /// 진행 막대 채움 (시안의 oklch(0.62 0.04 80))
    static let progressFill = Color(hex: 0x958870)
    /// 탄생 중인 별 (oklch(0.74 0.04 80))
    static let starForming = Color(hex: 0xB9AB91)

    static func star(magnitude: Int) -> Color {
        [starMag1, starMag2, starMag3, starMag4, starMag5][max(1, min(5, magnitude)) - 1]
    }
}

// MARK: - Font
enum OrotFont {
    // 번들 폰트: IBM Plex Sans KR (OFL). 숫자에는 monospacedDigit을 적용합니다.
    static let clockDisplay = Font.custom("IBMPlexSansKR-ExtraLight", fixedSize: 172).monospacedDigit()
    static let clockCompact = Font.custom("IBMPlexSansKR-ExtraLight", fixedSize: 64).monospacedDigit()
    static let title = Font.custom("IBMPlexSansKR-Light", size: 22, relativeTo: .title2)
    static let body = Font.custom("IBMPlexSansKR-Regular", size: 15, relativeTo: .body)
    static let label = Font.custom("IBMPlexSansKR-Regular", size: 15, relativeTo: .callout)
    static let caption = Font.custom("IBMPlexSansKR-Regular", size: 12, relativeTo: .caption)

    static func extraLight(_ size: CGFloat) -> Font { .custom("IBMPlexSansKR-ExtraLight", fixedSize: size).monospacedDigit() }
    static func light(_ size: CGFloat) -> Font { .custom("IBMPlexSansKR-Light", fixedSize: size) }
    static func regular(_ size: CGFloat) -> Font { .custom("IBMPlexSansKR-Regular", fixedSize: size) }
    static func medium(_ size: CGFloat) -> Font { .custom("IBMPlexSansKR-Medium", fixedSize: size) }
}

// MARK: - Spacing
enum OrotSpace {
    static let space1: CGFloat = 4, space2: CGFloat = 8, space3: CGFloat = 12, space4: CGFloat = 16
    static let space6: CGFloat = 24, space8: CGFloat = 32, space12: CGFloat = 48
    static let screenInsetH: CGFloat = 76, screenInsetV: CGFloat = 32
}

// MARK: - Radius
enum OrotRadius {
    static let xs: CGFloat = 2, sm: CGFloat = 4, md: CGFloat = 12, lg: CGFloat = 20, full: CGFloat = 999
}

// MARK: - Star
enum OrotStar {
    // 등급별 지름(pt)과 빛번짐 반경 — 1등급이 가장 밝음
    static let diameter: [CGFloat] = [7, 5.5, 4.5, 3.5, 2.5]
    static let glow: [CGFloat] = [10, 6, 3, 0, 0]
    static let focusThreshold: [Double] = [0.95, 0.85, 0.70, 0.50, 0]

    /// 순수 집중 비율(0~1)로 등급(1~5)을 정합니다.
    static func magnitude(forFocusRatio ratio: Double) -> Int {
        (focusThreshold.firstIndex { ratio >= $0 } ?? 4) + 1
    }
}

// MARK: - Motion
enum OrotMotion {
    static let tap = Animation.easeOut(duration: 0.2)
    static let star = Animation.easeInOut(duration: 3)
    static let sky = Animation.easeInOut(duration: 6)
    static let window = Animation.easeInOut(duration: 8)
}
