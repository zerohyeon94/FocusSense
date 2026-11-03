//
//  CalibrationService.swift
//  FocusSense
//
//  사용자의 정상 상태를 기록하고, 그 기준으로 판단
//

import Foundation
import SwiftUI

// MARK: - Calibration Data
struct CalibrationData: Codable {
    // 기준 Head Pose (정상 상태에서의 고개 각도)
    var baselineYaw: Double = 0       // 좌우 회전
    var baselinePitch: Double = 0     // 위아래 고개
    var baselineRoll: Double = 0      // 기울임
    
    // 기준 EAR (눈 뜬 상태)
    var baselineEAR: Double = 0.3
    
    // 기준 얼굴 크기 (화면 대비 비율)
    var baselineFaceSize: Double = 0.3
    
    // 허용 범위
    var yawTolerance: Double = 25     // ±25° 까지 허용
    var pitchTolerance: Double = 20   // ±20° 까지 허용
    var earDropThreshold: Double = 0.08  // EAR이 0.08 이상 떨어지면 졸음
    
    // 캘리브레이션 완료 여부
    var isCalibrated: Bool = false
    var calibrationDate: Date?
    
    // 설명
    var positionDescription: String {
        if abs(baselineYaw) < 10 && abs(baselinePitch) < 10 {
            return "정면"
        } else if baselineYaw < -20 {
            return "왼쪽 측면"
        } else if baselineYaw > 20 {
            return "오른쪽 측면"
        } else if baselinePitch > 15 {
            return "위에서 아래로"
        } else if baselinePitch < -15 {
            return "아래에서 위로"
        } else {
            return "약간 비스듬히"
        }
    }
}

// MARK: - Calibration Service
final class CalibrationService: ObservableObject {
    
    // MARK: - Published
    @Published var calibrationData: CalibrationData = CalibrationData()
    @Published var isCalibrating = false
    @Published var calibrationProgress: Double = 0
    @Published var calibrationMessage = ""
    
    // MARK: - Private
    private var samples: [(yaw: Double, pitch: Double, roll: Double, ear: Double, faceSize: Double)] = []
    private let requiredSamples = 30  // 30프레임 평균
    
    // MARK: - UserDefaults Key
    private let storageKey = "FocusSense.CalibrationData"
    
    // MARK: - Initialization
    init() {
        loadCalibration()
    }
    
    // MARK: - Start Calibration
    func startCalibration() {
        isCalibrating = true
        calibrationProgress = 0
        calibrationMessage = "정상 자세를 유지해주세요..."
        samples.removeAll()
    }
    
    // MARK: - Add Sample (캘리브레이션 중 프레임마다 호출)
    func addSample(yaw: Double, pitch: Double, roll: Double, ear: Double, faceSize: Double) {
        guard isCalibrating else { return }
        
        samples.append((yaw, pitch, roll, ear, faceSize))
        calibrationProgress = Double(samples.count) / Double(requiredSamples)
        
        if samples.count >= requiredSamples {
            completeCalibration()
        } else {
            let remaining = requiredSamples - samples.count
            calibrationMessage = "유지해주세요... \(remaining)프레임 남음"
        }
    }
    
    // MARK: - Complete Calibration
    private func completeCalibration() {
        // 평균 계산
        let avgYaw = samples.map { $0.yaw }.reduce(0, +) / Double(samples.count)
        let avgPitch = samples.map { $0.pitch }.reduce(0, +) / Double(samples.count)
        let avgRoll = samples.map { $0.roll }.reduce(0, +) / Double(samples.count)
        let avgEAR = samples.map { $0.ear }.reduce(0, +) / Double(samples.count)
        let avgFaceSize = samples.map { $0.faceSize }.reduce(0, +) / Double(samples.count)
        
        // 저장
        calibrationData = CalibrationData(
            baselineYaw: avgYaw,
            baselinePitch: avgPitch,
            baselineRoll: avgRoll,
            baselineEAR: avgEAR,
            baselineFaceSize: avgFaceSize,
            yawTolerance: 25,
            pitchTolerance: 20,
            earDropThreshold: avgEAR * 0.25,  // 기준 EAR의 25% 이상 떨어지면 졸음
            isCalibrated: true,
            calibrationDate: Date()
        )
        
        saveCalibration()
        
        isCalibrating = false
        calibrationProgress = 1.0
        calibrationMessage = "✅ 캘리브레이션 완료! (\(calibrationData.positionDescription))"
        
        print("✅ 캘리브레이션 완료:")
        print("   기준 Yaw: \(String(format: "%.1f", avgYaw))°")
        print("   기준 Pitch: \(String(format: "%.1f", avgPitch))°")
        print("   기준 EAR: \(String(format: "%.3f", avgEAR))")
        print("   위치: \(calibrationData.positionDescription)")
    }
    
    // MARK: - Evaluate (캘리브레이션 기준으로 현재 상태 평가)
    func evaluate(
        currentYaw: Double,
        currentPitch: Double,
        currentEAR: Double
    ) -> (isLooking: Bool, isDrowsy: Bool, isAway: Bool) {
        
        guard calibrationData.isCalibrated else {
            // 캘리브레이션 안됨 → 기본 로직 사용
            return (
                isLooking: abs(currentYaw) < 30 && abs(currentPitch) < 25,
                isDrowsy: currentEAR < 0.2,
                isAway: false
            )
        }
        
        // 기준 대비 차이 계산
        let yawDiff = abs(currentYaw - calibrationData.baselineYaw)
        let pitchDiff = abs(currentPitch - calibrationData.baselinePitch)
        let earDrop = calibrationData.baselineEAR - currentEAR
        
        // 판단
        let isLooking = yawDiff < calibrationData.yawTolerance &&
                        pitchDiff < calibrationData.pitchTolerance
        
        let isDrowsy = earDrop > calibrationData.earDropThreshold
        
        let isAway = yawDiff > calibrationData.yawTolerance * 1.5 ||
                     pitchDiff > calibrationData.pitchTolerance * 1.5
        
        return (isLooking, isDrowsy, isAway)
    }
    
    // MARK: - Reset
    func resetCalibration() {
        calibrationData = CalibrationData()
        samples.removeAll()
        isCalibrating = false
        calibrationProgress = 0
        
        UserDefaults.standard.removeObject(forKey: storageKey)
        print("🔄 캘리브레이션 초기화됨")
    }
    
    // MARK: - Persistence
    private func saveCalibration() {
        if let encoded = try? JSONEncoder().encode(calibrationData) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadCalibration() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(CalibrationData.self, from: data) {
            calibrationData = decoded
            print("📂 저장된 캘리브레이션 로드됨: \(decoded.positionDescription)")
        }
    }
}
