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
    
    // Computed Property (계산 속성)
    var color: Color {
        switch self {
        case .focused: return .green
        case .warning: return .yellow
        case .unfocused: return .orange
        case .drowsy: return .red
        case .unknown: return .gray
        }
    }
    
    // SF Symbols
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
// Identifiable: 고유 ID 필요
// Equatable: 비교 가능 (==)
struct FocusState: Identifiable, Equatable {
    
    let id = UUID()             // 고유 식별자 (자동 생성)
    let timestamp: Date         // 측정 시간
    let level: FocusLevel       // 집중 정도
    let eyeAspectRatio: Double  // EAR 값 (졸음 감지용) - 눈 가로세로 비율 (0.0 ~ 0.5)
    let isLookingAtScreen: Bool
    let isFaceDetected: Bool
    let headPose: HeadPose?     // Optional
    
    // 기본값이 있는 초기화 함수
    init(
        timestamp: Date = Date(),       // 기본값: 현재시간
        level: FocusLevel = .unknown,   // 기본값: 분석중
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
    
    // 정면을 보고 있는지 계산
    var isLookingForward: Bool {
        // 모든 각도가 작으면 정면
        abs(pitch) < 20 && abs(yaw) < 30 && abs(roll) < 20
    }
}

// MARK: - Eye Aspect Ratio Constants (상수 정의)
// static: 인스턴스 생성 없이 접근 가능
struct EARConstants {
    static let drowsinessThreshold: Double = 0.2  // 이 값 이하면 졸음
    static let blinkThreshold: Double = 0.25      // 깜빡임 감지 임계값
    static let consecutiveFramesForDrowsiness: Int = 15  // 연속 프레임 수
}
