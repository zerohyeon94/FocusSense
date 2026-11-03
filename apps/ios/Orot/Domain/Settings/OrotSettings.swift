//
//  OrotSettings.swift
//  Orot
//
//  설정 키와 기본값. View에서는 @AppStorage(OrotSettings.Key.xxx), 그 밖에서는 OrotSettings.current로 읽습니다.
//

import Foundation

enum OrotSettings {
    enum Key {
        static let focusMinutes = "focus.minutes"
        static let restMinutes = "rest.minutes"
        static let longRestMinutes = "rest.longMinutes"
        static let longRestEvery = "rest.longEvery"
        static let detectionEnabled = "detect.enabled"
        static let sensitivity = "detect.sensitivity"
        static let constellationDisplay = "display.constellation"
        static let keepAwake = "display.keepAwake"
        static let notifySessionEnd = "notify.sessionEnd"
        static let notifyRestEnd = "notify.restEnd"
        static let sound = "notify.sound"
        static let haptic = "notify.haptic"
        static let onboardingDone = "onboarding.done"
        static let notificationNoticeDismissedAt = "notice.notificationDismissedAt"
    }

    static let defaults: [String: Any] = [
        Key.focusMinutes: 25,
        Key.restMinutes: 5,
        Key.longRestMinutes: 15,
        Key.longRestEvery: 4,
        Key.detectionEnabled: true,
        Key.sensitivity: 1,
        Key.constellationDisplay: 1,
        Key.keepAwake: true,
        Key.notifySessionEnd: true,
        Key.notifyRestEnd: true,
        Key.sound: false,
        Key.haptic: true,
    ]

    static func register() {
        UserDefaults.standard.register(defaults: defaults)
    }

    // MARK: - Sensitivity
    static let sensitivityLabels = ["낮음", "보통", "높음"]
    /// 자리를 비운 지 몇 초 뒤 '잠시 멈춤'으로 볼지 (낮음 · 보통 · 높음)
    static let awayGraceSeconds = [30, 15, 8]

    // MARK: - Constellation Display
    static let constellationLabels = ["끔", "은은하게", "선명하게"]
    /// 별자리 선과 빈자리의 불투명도
    static let constellationIntensity = [0.0, 0.6, 1.0]

    // MARK: - Current Values
    static var current: Values { Values(defaults: .standard) }

    struct Values {
        let defaults: UserDefaults
        var focusMinutes: Int { defaults.integer(forKey: Key.focusMinutes) }
        var restMinutes: Int { defaults.integer(forKey: Key.restMinutes) }
        var longRestMinutes: Int { defaults.integer(forKey: Key.longRestMinutes) }
        var longRestEvery: Int { max(1, defaults.integer(forKey: Key.longRestEvery)) }
        var detectionEnabled: Bool { defaults.bool(forKey: Key.detectionEnabled) }
        var awayGrace: Int { awayGraceSeconds[min(2, max(0, defaults.integer(forKey: Key.sensitivity)))] }
        var keepAwake: Bool { defaults.bool(forKey: Key.keepAwake) }
        var notifySessionEnd: Bool { defaults.bool(forKey: Key.notifySessionEnd) }
        var notifyRestEnd: Bool { defaults.bool(forKey: Key.notifyRestEnd) }
        var sound: Bool { defaults.bool(forKey: Key.sound) }
        var haptic: Bool { defaults.bool(forKey: Key.haptic) }
    }
}
