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

// ============================================================================
// 📚 [파일 개요] FaceOverlayView - Vision 좌표계 변환과 얼굴 랜드마크 오버레이
// ============================================================================
//
// Vision 좌표계 변환 (핵심 개념):
//   Apple Vision 프레임워크는 좌하단 원점(0,0), 우상단(1,1)의 정규화 좌표를 사용한다.
//   UIKit/SwiftUI는 좌상단 원점(0,0), 우하단(width,height)의 좌표를 사용한다.
//   따라서 Y축을 반전해야 한다: screenY = (1 - visionY) * frameHeight
//
// convertPoint 함수 패턴:
//   이 파일의 여러 컴포넌트(EyeView, EyeContourPath, LandmarkPointView,
//   GazeDirectionIndicator)가 동일한 좌표 변환 로직을 반복 사용한다.
//   각 컴포넌트는 독립적인 struct이므로 자체 convertPoint를 가진다.
//   변환 공식: 얼굴 바운딩 박스의 화면 좌표를 구한 뒤,
//   정규화된 랜드마크 좌표를 바운딩 박스 내의 절대 좌표로 매핑한다.
//
// Shape 프로토콜 (EyeContourPath):
//   SwiftUI의 Shape 프로토콜을 채택하면 path(in:) 메서드에서 자유로운 경로를 그릴 수 있다.
//   EyeContourPath는 눈 윤곽점들을 연결하여 닫힌 경로를 만든다.
//   Shape를 사용하면 .stroke(), .fill() 등 SwiftUI 수식어를 바로 적용할 수 있다.
//
// ZStack 레이어 합성:
//   FaceOverlayView는 ZStack으로 여러 오버레이를 겹쳐 표시한다:
//   바운딩 박스 → 눈 랜드마크 → 코 위치 → 시선 화살표 → 집중 상태 배지
//   각 레이어는 독립된 struct으로 분리되어 있어 개별 테스트와 재사용이 가능하다.
//
// ============================================================================

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
