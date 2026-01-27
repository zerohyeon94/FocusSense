//
//  FaceLandmarks.swift
//  FocusSense
//
//  얼굴 랜드마크 좌표 모델 (디버그 시각화용)
//

import Foundation
import SwiftUI

// MARK: - Face Landmarks Data
struct FaceLandmarksData: Equatable {
    let boundingBox: CGRect           // 얼굴 영역
    let leftEye: [CGPoint]            // 왼쪽 눈 포인트들
    let rightEye: [CGPoint]           // 오른쪽 눈 포인트들
    let nose: [CGPoint]               // 코 포인트들
    let outerLips: [CGPoint]          // 입술 외곽
    let faceContour: [CGPoint]        // 얼굴 윤곽
    
    let leftPupil: CGPoint?           // 왼쪽 동공 (추정)
    let rightPupil: CGPoint?          // 오른쪽 동공 (추정)
    
    // 빈 데이터
    static let empty = FaceLandmarksData(
        boundingBox: .zero,
        leftEye: [],
        rightEye: [],
        nose: [],
        outerLips: [],
        faceContour: [],
        leftPupil: nil,
        rightPupil: nil
    )
    
    var hasFace: Bool {
        boundingBox != .zero
    }
}

// MARK: - Debug Info
struct FocusDebugInfo: Equatable {
    let landmarks: FaceLandmarksData
    let headPose: HeadPose
    let eyeAspectRatio: Double
    let focusLevel: FocusLevel
    let isFaceDetected: Bool
    let timestamp: Date
    
    // 얼굴 방향 설명
    var faceDirectionDescription: String {
        let yaw = headPose.yaw
        if yaw < -15 {
            return "← 왼쪽 보는 중"
        } else if yaw > 15 {
            return "오른쪽 보는 중 →"
        } else {
            return "정면"
        }
    }
    
    // 고개 상하 설명
    var headTiltDescription: String {
        let pitch = headPose.pitch
        if pitch < -10 {
            return "↓ 아래 보는 중"
        } else if pitch > 10 {
            return "↑ 위 보는 중"
        } else {
            return "수평"
        }
    }
    
    // 눈 상태 설명
    var eyeStateDescription: String {
        if eyeAspectRatio < 0.2 {
            return "😴 눈 감음"
        } else if eyeAspectRatio < 0.25 {
            return "😑 눈 반쯤"
        } else {
            return "👀 눈 뜸"
        }
    }
    
    // 빈 정보
    static let empty = FocusDebugInfo(
        landmarks: .empty,
        headPose: HeadPose(pitch: 0, yaw: 0, roll: 0),
        eyeAspectRatio: 0,
        focusLevel: .unknown,
        isFaceDetected: false,
        timestamp: Date()
    )
}
