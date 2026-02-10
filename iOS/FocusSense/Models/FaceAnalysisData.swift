//
//  FaceAnalysisData.swift
//  FocusSense
//
//  얼굴 분석 결과 데이터 (디버그 시각화용)
//

import Foundation
import SwiftUI

// MARK: - Face Analysis Data
/// 얼굴 분석 결과를 담는 구조체 (디버그 화면에서 사용)
struct FaceAnalysisData: Equatable {
    // 얼굴 감지 여부
    var isFaceDetected: Bool = false
    
    // 얼굴 바운딩 박스 (정규화된 좌표 0~1)
    var faceBoundingBox: CGRect = .zero
    
    // 눈 위치 (정규화된 좌표)
    var leftEyePoints: [CGPoint] = []
    var rightEyePoints: [CGPoint] = []
    var leftEyeCenter: CGPoint = .zero
    var rightEyeCenter: CGPoint = .zero
    
    // 코, 입 위치
    var nosePosition: CGPoint = .zero
    var mouthPoints: [CGPoint] = []
    
    // 얼굴 윤곽
    var faceContourPoints: [CGPoint] = []
    
    // Head Pose (각도, degree)
    var yaw: Double = 0      // 좌우 회전 (-: 왼쪽, +: 오른쪽)
    var pitch: Double = 0    // 고개 숙임/들기 (-: 숙임, +: 들기)
    var roll: Double = 0     // 기울임 (-: 왼쪽 기울임, +: 오른쪽 기울임)
    
    // EAR (Eye Aspect Ratio)
    var leftEAR: Double = 0
    var rightEAR: Double = 0
    var averageEAR: Double = 0
    
    // 시선 방향 추정
    var gazeDirection: GazeDirection = .center
    var isLookingAtScreen: Bool = false
    
    // 집중 상태
    var focusLevel: FocusLevel = .unknown
    
    // MARK: - Computed Properties
    
    /// 얼굴 방향 설명
    var faceDirectionDescription: String {
        if abs(yaw) < 10 {
            return "정면"
        } else if yaw > 0 {
            return "오른쪽 \(String(format: "%.0f", abs(yaw)))°"
        } else {
            return "왼쪽 \(String(format: "%.0f", abs(yaw)))°"
        }
    }
    
    /// 고개 숙임 설명
    var pitchDescription: String {
        if abs(pitch) < 5 {
            return "정면"
        } else if pitch > 0 {
            return "위로 \(String(format: "%.0f", abs(pitch)))°"
        } else {
            return "아래로 \(String(format: "%.0f", abs(pitch)))°"
        }
    }
    
    /// 고개 기울임 설명
    var rollDescription: String {
        if abs(roll) < 5 {
            return "수평"
        } else if roll > 0 {
            return "오른쪽 기울임 \(String(format: "%.0f", abs(roll)))°"
        } else {
            return "왼쪽 기울임 \(String(format: "%.0f", abs(roll)))°"
        }
    }
    
    /// 카메라 기준 얼굴 위치 (오른쪽/왼쪽/중앙)
    var facePositionInFrame: String {
        let centerX = faceBoundingBox.midX
        if centerX < 0.35 {
            return "화면 왼쪽"
        } else if centerX > 0.65 {
            return "화면 오른쪽"
        } else {
            return "화면 중앙"
        }
    }
    
    // MARK: - 얼굴 방향 상세 정보
    
    /// 어느 쪽 얼굴이 카메라에 보이는지
    /// yaw가 음수면 카메라는 사용자의 왼쪽에서 보는 것 (오른쪽 얼굴이 더 보임)
    /// yaw가 양수면 카메라는 사용자의 오른쪽에서 보는 것 (왼쪽 얼굴이 더 보임)
    var visibleFaceSide: String {
        if yaw < -30 {
            return "오른쪽 측면"
        } else if yaw > 30 {
            return "왼쪽 측면"
        } else if yaw < -15 {
            return "오른쪽 3/4"
        } else if yaw > 15 {
            return "왼쪽 3/4"
        } else {
            return "정면"
        }
    }
    
    /// 카메라가 사용자로부터 어느 방향에 있는지
    var cameraPositionRelativeToUser: String {
        var position: [String] = []
        
        // 좌우 위치
        if yaw < -15 {
            position.append("왼쪽")
        } else if yaw > 15 {
            position.append("오른쪽")
        }
        
        // 상하 위치
        if pitch < -10 {
            position.append("위")
        } else if pitch > 10 {
            position.append("아래")
        }
        
        return position.isEmpty ? "정면" : "사용자 \(position.joined(separator: " "))에서 촬영 중"
    }
    
    /// 전체 얼굴 각도 (카메라와의 각도)
    var totalFaceAngle: Double {
        return sqrt(yaw * yaw + pitch * pitch)
    }
    
    /// 얼굴이 카메라를 똑바로 보고 있는지 (정면 여부)
    var isFacingCamera: Bool {
        return abs(yaw) < 15 && abs(pitch) < 15 && abs(roll) < 15
    }
    
    /// EAR 상태 설명
    var earStatusDescription: String {
        if averageEAR < 0.2 {
            return "😴 눈 감김"
        } else if averageEAR < 0.25 {
            return "😐 반쯤 감김"
        } else {
            return "👀 정상"
        }
    }
    
    /// 종합 상태 요약
    var summaryDescription: String {
        if !isFaceDetected {
            return "얼굴을 찾을 수 없습니다"
        }
        
        var issues: [String] = []
        
        if averageEAR < 0.2 {
            issues.append("졸음 감지")
        }
        
        if !isFacingCamera {
            issues.append("정면이 아님")
        }
        
        if !isLookingAtScreen {
            issues.append("화면 미응시")
        }
        
        return issues.isEmpty ? "✅ 집중 상태 양호" : "⚠️ " + issues.joined(separator: ", ")
    }
}

// MARK: - Debug Overlay Style
struct DebugOverlayStyle {
    // 색상
    static let faceBoundingBoxColor = Color.green
    static let eyeColor = Color.cyan
    static let noseColor = Color.yellow
    static let mouthColor = Color.pink
    static let contourColor = Color.white.opacity(0.5)
    
    // 선 두께
    static let boundingBoxLineWidth: CGFloat = 2
    static let landmarkPointSize: CGFloat = 6
    static let contourLineWidth: CGFloat = 1
}
