//
//  FocusState.swift
//  FocusSense
//
//  집중도 상태를 나타내는 모델
//

import Foundation
import SwiftUI

// MARK: - Focus Level Enum
enum FocusLevel: String, CaseIterable {
    case focused = "집중 중"
    case warning = "주의"
    case drowsy = "졸음"
    case unfocused = "집중 이탈"
    case away = "자리 비움"
    case unknown = "감지 중"
    
    var icon: String {
        switch self {
        case .focused: return "eye"
        case .warning: return "exclamationmark.triangle"
        case .drowsy: return "moon.zzz"
        case .unfocused: return "eye.slash"
        case .away: return "figure.walk"
        case .unknown: return "questionmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .focused: return .green
        case .warning: return .yellow
        case .drowsy: return .red
        case .unfocused: return .orange
        case .away: return .gray
        case .unknown: return .gray
        }
    }
    
    var description: String {
        switch self {
        case .focused: return "집중하고 있어요!"
        case .warning: return "조금 졸리신가요?"
        case .drowsy: return "졸음이 감지되었어요!"
        case .unfocused: return "집중이 필요해요"
        case .away: return "자리를 비우셨네요"
        case .unknown: return "얼굴을 감지 중..."
        }
    }
}

// MARK: - Head Pose
struct HeadPose: Equatable {
    let pitch: Double  // 위아래 고개
    let yaw: Double    // 좌우 회전
    let roll: Double   // 기울임
    
    init(pitch: Double = 0, yaw: Double = 0, roll: Double = 0) {
        self.pitch = pitch
        self.yaw = yaw
        self.roll = roll
    }
}

// MARK: - Focus State
struct FocusState: Equatable {
    let level: FocusLevel
    let eyeAspectRatio: Double
    let isLookingAtScreen: Bool
    let isFaceDetected: Bool
    let headPose: HeadPose?
    let combinedDrowsyScore: Double

    init(
        level: FocusLevel = .unknown,
        eyeAspectRatio: Double = 0,
        isLookingAtScreen: Bool = false,
        isFaceDetected: Bool = false,
        headPose: HeadPose? = nil,
        combinedDrowsyScore: Double = 0
    ) {
        self.level = level
        self.eyeAspectRatio = eyeAspectRatio
        self.isLookingAtScreen = isLookingAtScreen
        self.isFaceDetected = isFaceDetected
        self.headPose = headPose
        self.combinedDrowsyScore = combinedDrowsyScore
    }
}

// MARK: - Gaze Direction
enum GazeDirection: String {
    case center = "정면"
    case left = "왼쪽"
    case right = "오른쪽"
    case up = "위"
    case down = "아래"
    
    var icon: String {
        switch self {
        case .left: return "arrow.left"
        case .right: return "arrow.right"
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .center: return "circle.fill"
        }
    }
}

// MARK: - Eye Aspect Ratio Constants (상수 정의)
// static: 인스턴스 생성 없이 접근 가능
struct EARConstants {
    static let drowsinessThreshold: Double = 0.2  // 이 값 이하면 졸음
    static let blinkThreshold: Double = 0.25      // 깜빡임 감지 임계값
    static let consecutiveFramesForDrowsiness: Int = 15  // 연속 프레임 수
}
