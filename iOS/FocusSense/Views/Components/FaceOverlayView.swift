//
//  FaceOverlayView.swift
//  FocusSense
//
//  카메라 프리뷰 위에 얼굴 분석 결과를 시각적으로 표시
//  - 얼굴 바운딩 박스
//  - 눈 위치 (좌/우)
//  - 코, 입 위치
//  - 시선 방향 화살표
//

import SwiftUI

// MARK: - Face Overlay View
struct FaceOverlayView: View {
    let analysisData: FaceAnalysisData
    let frameSize: CGSize
    
    var body: some View {
        ZStack {
            if analysisData.isFaceDetected {
                // 얼굴 바운딩 박스
                FaceBoundingBoxView(
                    boundingBox: analysisData.faceBoundingBox,
                    frameSize: frameSize
                )
                
                // 눈 표시
                EyeLandmarksView(
                    leftEyeCenter: analysisData.leftEyeCenter,
                    rightEyeCenter: analysisData.rightEyeCenter,
                    leftEyePoints: analysisData.leftEyePoints,
                    rightEyePoints: analysisData.rightEyePoints,
                    frameSize: frameSize,
                    boundingBox: analysisData.faceBoundingBox
                )
                
                // 코 위치
                if analysisData.nosePosition != .zero {
                    LandmarkPointView(
                        position: analysisData.nosePosition,
                        frameSize: frameSize,
                        boundingBox: analysisData.faceBoundingBox,
                        color: DebugOverlayStyle.noseColor,
                        size: 10
                    )
                }
                
                // 시선 방향 화살표
                GazeDirectionIndicator(
                    direction: analysisData.gazeDirection,
                    position: CGPoint(
                        x: (analysisData.leftEyeCenter.x + analysisData.rightEyeCenter.x) / 2,
                        y: (analysisData.leftEyeCenter.y + analysisData.rightEyeCenter.y) / 2
                    ),
                    frameSize: frameSize,
                    boundingBox: analysisData.faceBoundingBox
                )
                
                // 집중 상태 배지
                FocusStatusBadge(level: analysisData.focusLevel)
                    .position(x: frameSize.width - 60, y: 30)
                
            } else {
                // 얼굴 미감지 상태
                NoFaceDetectedView()
            }
        }
    }
}

// MARK: - Face Bounding Box
struct FaceBoundingBoxView: View {
    let boundingBox: CGRect
    let frameSize: CGSize
    
    var body: some View {
        let rect = convertRect(boundingBox, to: frameSize)
        
        RoundedRectangle(cornerRadius: 8)
            .strokeBorder(DebugOverlayStyle.faceBoundingBoxColor, lineWidth: DebugOverlayStyle.boundingBoxLineWidth)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .animation(.easeOut(duration: 0.1), value: boundingBox)
    }
    
    /// Vision 좌표계 (좌하단 원점, 0~1) → UIKit 좌표계 변환
    private func convertRect(_ rect: CGRect, to size: CGSize) -> CGRect {
        let x = rect.origin.x * size.width
        let y = (1 - rect.origin.y - rect.height) * size.height  // Y축 반전
        let width = rect.width * size.width
        let height = rect.height * size.height
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

// MARK: - Eye Landmarks View
struct EyeLandmarksView: View {
    let leftEyeCenter: CGPoint
    let rightEyeCenter: CGPoint
    let leftEyePoints: [CGPoint]
    let rightEyePoints: [CGPoint]
    let frameSize: CGSize
    let boundingBox: CGRect
    
    var body: some View {
        ZStack {
            // 왼쪽 눈 (화면 기준 오른쪽 - 미러링)
            EyeView(
                center: leftEyeCenter,
                points: leftEyePoints,
                frameSize: frameSize,
                boundingBox: boundingBox,
                label: "L"
            )
            
            // 오른쪽 눈 (화면 기준 왼쪽 - 미러링)
            EyeView(
                center: rightEyeCenter,
                points: rightEyePoints,
                frameSize: frameSize,
                boundingBox: boundingBox,
                label: "R"
            )
        }
    }
}

// MARK: - Single Eye View
struct EyeView: View {
    let center: CGPoint
    let points: [CGPoint]
    let frameSize: CGSize
    let boundingBox: CGRect
    let label: String
    
    var body: some View {
        let screenCenter = convertPoint(center, to: frameSize)
        
        ZStack {
            // 눈 윤곽선 (점들 연결)
            if points.count >= 4 {
                EyeContourPath(
                    points: points,
                    frameSize: frameSize,
                    boundingBox: boundingBox
                )
                .stroke(DebugOverlayStyle.eyeColor, lineWidth: 1.5)
            }
            
            // 눈 중심점
            Circle()
                .fill(DebugOverlayStyle.eyeColor)
                .frame(width: 12, height: 12)
                .position(screenCenter)
            
            // 라벨
            Text(label)
                .font(.caption2.bold())
                .foregroundColor(.black)
                .position(screenCenter)
        }
        .animation(.easeOut(duration: 0.1), value: center)
    }
    
    private func convertPoint(_ point: CGPoint, to size: CGSize) -> CGPoint {
        // 얼굴 바운딩 박스 내의 정규화된 좌표를 화면 좌표로 변환
        let faceX = boundingBox.origin.x * size.width
        let faceY = (1 - boundingBox.origin.y - boundingBox.height) * size.height
        let faceWidth = boundingBox.width * size.width
        let faceHeight = boundingBox.height * size.height
        
        let x = faceX + point.x * faceWidth
        let y = faceY + (1 - point.y) * faceHeight
        
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Eye Contour Path
struct EyeContourPath: Shape {
    let points: [CGPoint]
    let frameSize: CGSize
    let boundingBox: CGRect
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        guard points.count >= 2 else { return path }
        
        let screenPoints = points.map { convertPoint($0, to: frameSize) }
        
        path.move(to: screenPoints[0])
        for point in screenPoints.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        
        return path
    }
    
    private func convertPoint(_ point: CGPoint, to size: CGSize) -> CGPoint {
        let faceX = boundingBox.origin.x * size.width
        let faceY = (1 - boundingBox.origin.y - boundingBox.height) * size.height
        let faceWidth = boundingBox.width * size.width
        let faceHeight = boundingBox.height * size.height
        
        let x = faceX + point.x * faceWidth
        let y = faceY + (1 - point.y) * faceHeight
        
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Landmark Point View
struct LandmarkPointView: View {
    let position: CGPoint
    let frameSize: CGSize
    let boundingBox: CGRect
    let color: Color
    let size: CGFloat
    
    var body: some View {
        let screenPosition = convertPoint(position, to: frameSize)
        
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .position(screenPosition)
    }
    
    private func convertPoint(_ point: CGPoint, to size: CGSize) -> CGPoint {
        let faceX = boundingBox.origin.x * size.width
        let faceY = (1 - boundingBox.origin.y - boundingBox.height) * size.height
        let faceWidth = boundingBox.width * size.width
        let faceHeight = boundingBox.height * size.height
        
        let x = faceX + point.x * faceWidth
        let y = faceY + (1 - point.y) * faceHeight
        
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Gaze Direction Indicator
struct GazeDirectionIndicator: View {
    let direction: GazeDirection
    let position: CGPoint
    let frameSize: CGSize
    let boundingBox: CGRect
    
    var body: some View {
        let screenPosition = convertPoint(position, to: frameSize)
        
        // 시선 방향 화살표
        Image(systemName: direction.icon)
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.yellow)
            .shadow(color: .black, radius: 2)
            .position(x: screenPosition.x, y: screenPosition.y - 30)
    }
    
    private func convertPoint(_ point: CGPoint, to size: CGSize) -> CGPoint {
        let faceX = boundingBox.origin.x * size.width
        let faceY = (1 - boundingBox.origin.y - boundingBox.height) * size.height
        let faceWidth = boundingBox.width * size.width
        let faceHeight = boundingBox.height * size.height
        
        let x = faceX + point.x * faceWidth
        let y = faceY + (1 - point.y) * faceHeight
        
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Focus Status Badge
struct FocusStatusBadge: View {
    let level: FocusLevel
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(level.color)
                .frame(width: 8, height: 8)
            
            Text(level.rawValue)
                .font(.caption.bold())
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.6))
        )
    }
}

// MARK: - No Face Detected View
struct NoFaceDetectedView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "face.dashed")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.5))
            
            Text("얼굴을 감지하지 못했습니다")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            Text("카메라를 정면으로 바라봐 주세요")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3))
    }
}
