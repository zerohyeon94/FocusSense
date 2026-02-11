//
//  FocusScoreService.swift
//  FocusSense
//
//  집중도 종합 점수 계산 서비스
//  6개 지표를 조합하여 정교한 집중도를 산출
//
//  공식: 기본(30%) + 깜빡임(20%) + 머리안정(15%) + EAR안정(15%) + 연속(10%) + 이벤트(10%)
//

import Foundation
import Combine

// MARK: - Focus Score Breakdown
struct FocusScoreBreakdown {
    var baseScore: Double = 100           // 기본 점수 (하이브리드 졸음 점수 반전)
    var blinkScore: Double = 100          // 깜빡임 빈도 점수
    var headStabilityScore: Double = 100  // 머리 안정성 점수
    var earStabilityScore: Double = 100   // EAR 안정성 점수
    var continuousScore: Double = 100     // 연속 집중 시간 점수
    var eventScore: Double = 100          // 이벤트 감점 점수

    // 부가 정보 (디버그 표시용)
    var blinksPerMinute: Double = 0       // 분당 깜빡임 횟수
    var headStdDev: Double = 0            // 머리 표준편차 (°)
    var earCV: Double = 0                 // EAR 변동계수
    var continuousDuration: TimeInterval = 0  // 연속 집중 시간 (초)
    var recentEventCount: Int = 0         // 최근 이벤트 수

    // MARK: - 가중 합산
    var totalScore: Double {
        let weighted = baseScore * 0.30
            + blinkScore * 0.20
            + headStabilityScore * 0.15
            + earStabilityScore * 0.15
            + continuousScore * 0.10
            + eventScore * 0.10
        return min(max(weighted, 0), 100)
    }
}

// MARK: - Focus Score Service
final class FocusScoreService: ObservableObject {

    // MARK: - Published Properties
    @Published var scoreBreakdown: FocusScoreBreakdown = FocusScoreBreakdown()
    @Published var totalScore: Double = 0

    // MARK: - Blink Detection
    private var blinkTimestamps: [Date] = []
    private var isInBlink = false              // 현재 깜빡임 중인지
    private let blinkEARRatioThreshold = 0.70  // 기준 EAR의 70% 이하면 깜빡임 시작
    private let blinkWindowSeconds: TimeInterval = 60  // 60초 롤링 윈도우

    // MARK: - Head Stability
    private var headPoseHistory: [(yaw: Double, pitch: Double, timestamp: Date)] = []
    private let headStabilityWindowSeconds: TimeInterval = 30  // 30초 롤링 윈도우

    // MARK: - EAR Stability
    private var earStabilityHistory: [(ear: Double, timestamp: Date)] = []
    private let earStabilityWindowSeconds: TimeInterval = 30  // 30초 롤링 윈도우

    // MARK: - Continuous Focus
    private var continuousFocusStart: Date?

    // MARK: - Event Tracking
    private var eventTimestamps: [(level: FocusLevel, timestamp: Date)] = []
    private let eventWindowSeconds: TimeInterval = 300  // 5분 롤링 윈도우

    // MARK: - Smoothing
    private var scoreHistory: [Double] = []
    private let scoreHistorySize = 10  // 점수 스무딩용

    // MARK: - Main Update Method
    /// 매 프레임마다 호출하여 모든 지표를 업데이트
    func updateMetrics(
        ear: Double,
        baselineEAR: Double,
        headPose: HeadPose,
        combinedDrowsyScore: Double,
        focusLevel: FocusLevel
    ) {
        let now = Date()

        // 1. 기본 점수
        updateBaseScore(combinedDrowsyScore: combinedDrowsyScore)

        // 2. 깜빡임 빈도
        updateBlinkDetection(ear: ear, baselineEAR: baselineEAR, now: now)

        // 3. 머리 안정성
        updateHeadStability(yaw: headPose.yaw, pitch: headPose.pitch, now: now)

        // 4. EAR 안정성
        updateEARStability(ear: ear, now: now)

        // 5. 연속 집중 시간
        updateContinuousFocus(focusLevel: focusLevel, now: now)

        // 6. 이벤트 감점
        recordEvent(focusLevel: focusLevel, now: now)

        // 종합 점수 계산 (스무딩 적용)
        let rawScore = scoreBreakdown.totalScore
        scoreHistory.append(rawScore)
        if scoreHistory.count > scoreHistorySize {
            scoreHistory.removeFirst()
        }

        totalScore = scoreHistory.reduce(0, +) / Double(scoreHistory.count)
    }

    // MARK: - 1. Base Score (30%)
    private func updateBaseScore(combinedDrowsyScore: Double) {
        // combinedDrowsyScore: 0 = 깨어있음, 1 = 졸음
        // baseScore: 0 = 졸음, 100 = 깨어있음
        scoreBreakdown.baseScore = (1.0 - combinedDrowsyScore) * 100.0
    }

    // MARK: - 2. Blink Detection (20%)
    private func updateBlinkDetection(ear: Double, baselineEAR: Double, now: Date) {
        let threshold = baselineEAR * blinkEARRatioThreshold

        if ear < threshold {
            // EAR이 임계값 아래 → 깜빡임 시작
            if !isInBlink {
                isInBlink = true
            }
        } else {
            // EAR이 다시 올라옴 → 깜빡임 1회 완료
            if isInBlink {
                isInBlink = false
                blinkTimestamps.append(now)
            }
        }

        // 윈도우 밖 데이터 제거
        let cutoff = now.addingTimeInterval(-blinkWindowSeconds)
        blinkTimestamps.removeAll { $0 < cutoff }

        // 분당 깜빡임 횟수 계산
        let elapsed = min(blinkWindowSeconds, now.timeIntervalSince(blinkTimestamps.first ?? now))
        let bpm: Double
        if elapsed > 5 {  // 최소 5초 경과 후부터 계산
            bpm = Double(blinkTimestamps.count) / (elapsed / 60.0)
        } else {
            bpm = 15.0  // 초기에는 정상값 가정
        }

        scoreBreakdown.blinksPerMinute = bpm
        scoreBreakdown.blinkScore = calculateBlinkScore(bpm: bpm)
    }

    private func calculateBlinkScore(bpm: Double) -> Double {
        // 정상 범위: 15~20회/분 → 100점
        // 범위를 벗어날수록 점수 하락
        switch bpm {
        case 15...20:
            return 100
        case 10..<15, 20..<25:
            return 80
        case 5..<10, 25..<30:
            return 50
        default:
            return 20
        }
    }

    // MARK: - 3. Head Stability (15%)
    private func updateHeadStability(yaw: Double, pitch: Double, now: Date) {
        headPoseHistory.append((yaw: yaw, pitch: pitch, timestamp: now))

        // 윈도우 밖 데이터 제거
        let cutoff = now.addingTimeInterval(-headStabilityWindowSeconds)
        headPoseHistory.removeAll { $0.timestamp < cutoff }

        guard headPoseHistory.count >= 5 else {
            scoreBreakdown.headStabilityScore = 100
            scoreBreakdown.headStdDev = 0
            return
        }

        // yaw, pitch 각각 표준편차 계산
        let yaws = headPoseHistory.map { $0.yaw }
        let pitches = headPoseHistory.map { $0.pitch }

        let yawStdDev = standardDeviation(yaws)
        let pitchStdDev = standardDeviation(pitches)
        let avgStdDev = (yawStdDev + pitchStdDev) / 2.0

        scoreBreakdown.headStdDev = avgStdDev
        scoreBreakdown.headStabilityScore = calculateHeadStabilityScore(stdDev: avgStdDev)
    }

    private func calculateHeadStabilityScore(stdDev: Double) -> Double {
        switch stdDev {
        case ..<3:
            return 100
        case 3..<6:
            // 3~6: 선형 보간 100→80
            return 100 - (stdDev - 3) / 3 * 20
        case 6..<10:
            // 6~10: 선형 보간 80→50
            return 80 - (stdDev - 6) / 4 * 30
        default:
            // 10+: 선형 보간 50→20 (최대 15에서 20)
            return max(20, 50 - (stdDev - 10) / 5 * 30)
        }
    }

    // MARK: - 4. EAR Stability (15%)
    private func updateEARStability(ear: Double, now: Date) {
        earStabilityHistory.append((ear: ear, timestamp: now))

        // 윈도우 밖 데이터 제거
        let cutoff = now.addingTimeInterval(-earStabilityWindowSeconds)
        earStabilityHistory.removeAll { $0.timestamp < cutoff }

        guard earStabilityHistory.count >= 5 else {
            scoreBreakdown.earStabilityScore = 100
            scoreBreakdown.earCV = 0
            return
        }

        // 변동계수(CV) = 표준편차 / 평균
        let ears = earStabilityHistory.map { $0.ear }
        let mean = ears.reduce(0, +) / Double(ears.count)
        let stdDev = standardDeviation(ears)
        let cv = mean > 0 ? stdDev / mean : 0

        scoreBreakdown.earCV = cv
        scoreBreakdown.earStabilityScore = calculateEARStabilityScore(cv: cv)
    }

    private func calculateEARStabilityScore(cv: Double) -> Double {
        switch cv {
        case ..<0.05:
            return 100
        case 0.05..<0.10:
            // 선형 보간 100→80
            return 100 - (cv - 0.05) / 0.05 * 20
        case 0.10..<0.20:
            // 선형 보간 80→50
            return 80 - (cv - 0.10) / 0.10 * 30
        default:
            // 0.20+: 선형 보간 50→20
            return max(20, 50 - (cv - 0.20) / 0.10 * 30)
        }
    }

    // MARK: - 5. Continuous Focus Duration (10%)
    private func updateContinuousFocus(focusLevel: FocusLevel, now: Date) {
        switch focusLevel {
        case .focused:
            // 집중 시작 시간 기록 (이미 집중 중이면 유지)
            if continuousFocusStart == nil {
                continuousFocusStart = now
            }
        case .warning:
            // warning은 연속 집중을 깨뜨리지 않음 (잠깐의 주의)
            break
        case .drowsy, .away, .unfocused:
            // 집중 끊김 → 리셋
            continuousFocusStart = nil
        case .unknown:
            break
        }

        let duration: TimeInterval
        if let start = continuousFocusStart {
            duration = now.timeIntervalSince(start)
        } else {
            duration = 0
        }

        scoreBreakdown.continuousDuration = duration
        scoreBreakdown.continuousScore = calculateContinuousScore(duration: duration)
    }

    private func calculateContinuousScore(duration: TimeInterval) -> Double {
        let minutes = duration / 60.0
        switch minutes {
        case 10...:
            return 100
        case 5..<10:
            // 선형 보간 80→100
            return 80 + (minutes - 5) / 5 * 20
        case 2..<5:
            // 선형 보간 60→80
            return 60 + (minutes - 2) / 3 * 20
        case 1..<2:
            // 선형 보간 40→60
            return 40 + (minutes - 1) / 1 * 20
        default:
            // 0~1분: 선형 보간 20→40
            return 20 + minutes / 1 * 20
        }
    }

    // MARK: - 6. Event Penalty (10%)
    private func recordEvent(focusLevel: FocusLevel, now: Date) {
        // 감점 대상 이벤트만 기록
        switch focusLevel {
        case .drowsy, .warning, .away:
            eventTimestamps.append((level: focusLevel, timestamp: now))
        default:
            break
        }

        // 윈도우 밖 데이터 제거
        let cutoff = now.addingTimeInterval(-eventWindowSeconds)
        eventTimestamps.removeAll { $0.timestamp < cutoff }

        // 감점 계산
        var penalty: Double = 0
        for event in eventTimestamps {
            switch event.level {
            case .drowsy:
                penalty += 15
            case .warning:
                penalty += 5
            case .away:
                penalty += 20
            default:
                break
            }
        }

        scoreBreakdown.recentEventCount = eventTimestamps.count
        scoreBreakdown.eventScore = max(0, 100 - penalty)
    }

    // MARK: - Statistics Helpers
    private func standardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let sumOfSquaredDiffs = values.reduce(0) { $0 + pow($1 - mean, 2) }
        return sqrt(sumOfSquaredDiffs / Double(values.count - 1))
    }

    // MARK: - Reset
    func reset() {
        scoreBreakdown = FocusScoreBreakdown()
        totalScore = 0

        blinkTimestamps.removeAll()
        isInBlink = false

        headPoseHistory.removeAll()
        earStabilityHistory.removeAll()

        continuousFocusStart = nil
        eventTimestamps.removeAll()

        scoreHistory.removeAll()

        print("🔄 FocusScoreService 리셋")
    }
}
