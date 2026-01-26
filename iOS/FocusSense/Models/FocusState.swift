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
    case focused = "집중"
    case warning = "주의"
    case unfocused = "이탈"
    case drowsy = "졸음"
    case unknown = "분석중"
    
    var color: Color {
        switch self {
        case .focused: return .green
        case .warning: return .yellow
        case .unfocused: return .orange
        case .drowsy: return .red
        case .unknown: return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .focused: return "eye.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .unfocused: return "eye.slash.fill"
        case .drowsy: return "moon.zzz.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .focused: return "집중하고 있어요! 👍"
        case .warning: return "집중력이 흐트러지고 있어요"
        case .unfocused: return "화면을 보고 있지 않아요"
        case .drowsy: return "졸음이 감지되었어요"
        case .unknown: return "얼굴을 인식하고 있어요..."
        }
    }
}

// MARK: - Focus State Model
struct FocusState: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let level: FocusLevel
    let eyeAspectRatio: Double  // EAR 값 (졸음 감지용)
    let isLookingAtScreen: Bool
    let isFaceDetected: Bool
    let headPose: HeadPose?
    
    init(
        timestamp: Date = Date(),
        level: FocusLevel = .unknown,
        eyeAspectRatio: Double = 0.0,
        isLookingAtScreen: Bool = false,
        isFaceDetected: Bool = false,
        headPose: HeadPose? = nil
    ) {
        self.timestamp = timestamp
        self.level = level
        self.eyeAspectRatio = eyeAspectRatio
        self.isLookingAtScreen = isLookingAtScreen
        self.isFaceDetected = isFaceDetected
        self.headPose = headPose
    }
    
    static func == (lhs: FocusState, rhs: FocusState) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Head Pose Model
struct HeadPose: Equatable {
    let pitch: Double  // 고개 숙임/들기
    let yaw: Double    // 좌우 회전
    let roll: Double   // 갸웃거림
    
    var isLookingForward: Bool {
        abs(pitch) < 20 && abs(yaw) < 30 && abs(roll) < 20
    }
}

// MARK: - Eye Aspect Ratio Constants
struct EARConstants {
    static let drowsinessThreshold: Double = 0.2  // 이 값 이하면 졸음
    static let blinkThreshold: Double = 0.25      // 깜빡임 감지 임계값
    static let consecutiveFramesForDrowsiness: Int = 15  // 연속 프레임 수
}
