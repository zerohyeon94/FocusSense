//
//  FocusDetectionService.swift
//  FocusSense
//
//  Apple Vision Framework를 사용한 집중도 감지
//  - 얼굴 인식 및 랜드마크 추출
//  - EAR(Eye Aspect Ratio) 계산으로 졸음 감지
//  - Head Pose 추정으로 이탈 감지
//

/*
 카메라 영상 → 집중 상태 판단
┌──────────────┐     ┌──────────────────┐     ┌──────────────┐
│ Camera Frame │ ──→ │ Apple Vision API │ ──→ │  FocusState  │
│   (이미지)     │     │   (얼굴/눈 분석)    │     │   (결과)      │
└──────────────┘     └──────────────────┘     └──────────────┘
*/

// ============================================================================
// 📚 [파일 개요] FocusDetectionService - Vision 단독 집중도 감지 구현체
// ============================================================================
//
// 📌 Vision Framework 단독 방식
//    Apple Vision Framework만 사용하여 얼굴 랜드마크를 추출하고,
//    EAR(Eye Aspect Ratio) 계산으로 졸음 여부를 판단합니다.
//    CoreML 모델 없이도 동작하는 경량 구현입니다.
//
// 📌 EAR (Eye Aspect Ratio) 알고리즘
//    눈의 6개 랜드마크 포인트(p1~p6)에서 세로/가로 비율을 계산합니다.
//    공식: EAR = (|p2-p6| + |p3-p5|) / (2 × |p1-p4|)
//    - 눈을 떴을 때: EAR ≈ 0.3~0.4
//    - 눈을 감았을 때: EAR < 0.2
//    Vision Framework가 VNFaceLandmarks2D를 통해 눈 포인트를 제공합니다.
//
// 📌 Delegate 패턴
//    FocusDetectionDelegate 프로토콜을 통해 상태 변화를 외부에 알립니다.
//    이 패턴은 iOS의 전통적인 콜백 방식으로,
//    서비스와 ViewModel 사이의 느슨한 결합을 유지합니다.
//
// 📌 현재 상태
//    SimpleFocusDetectionService(Vision 70% + CoreML 30% 하이브리드)가
//    메인 서비스로 사용되며, 이 파일은 Vision 단독 대안 구현입니다.
//
// ============================================================================

import Vision // Apple의 컴퓨터 비전 프레임워크
import AVFoundation
import UIKit

// MARK: - Focus Detection Delegate
protocol FocusDetectionDelegate: AnyObject {
    func focusDetection(_ service: FocusDetectionService, didDetect state: FocusState)
}

// MARK: - Focus Detection Service
final class FocusDetectionService: ObservableObject, FocusDetectionServiceProtocol {
    
    // MARK: - Published Properties
    @Published var currentState: FocusState = FocusState()
    @Published var isAnalyzing = false
    @Published var faceAnalysisData: FaceAnalysisData = FaceAnalysisData()  // 디버그용 상세 데이터
    
    // MARK: - Properties
    weak var delegate: FocusDetectionDelegate?
    
    // Vision Request - "이 이미지에서 얼굴 랜드마크를 찾아줘"
    private var faceDetectionRequest: VNDetectFaceLandmarksRequest?
    private let sequenceHandler = VNSequenceRequestHandler()
    
    // 졸음 감지용 카운터
    private var lowEARFrameCount = 0
    private let drowsinessFrameThreshold = 3  // 3초 연속 (1 FPS 기준)
    
    // EAR 히스토리 (평균 계산용)
    private var earHistory: [Double] = []
    private let earHistorySize = 10
    
    // 개별 EAR 저장 (디버그용)
    private var lastLeftEAR: Double = 0
    private var lastRightEAR: Double = 0
    
    // MARK: - Initialization
    init() {
        setupVisionRequest()
    }
    
    // MARK: - Vision Request Setup
    private func setupVisionRequest() {
        faceDetectionRequest = VNDetectFaceLandmarksRequest { [weak self] request, error in // 결과가 오면 해당 클로저 실행
            if let error = error {
                print("❌ Face detection error: \(error)")
                return
            }
            self?.processDetectionResults(request.results)
        }
        
        // 정확도보다 속도 우선 (모바일 최적화)
        faceDetectionRequest?.revision = VNDetectFaceLandmarksRequestRevision3
    }
    
    // MARK: - Process Video Frame (카메라 프레임 처리)
    func processFrame(_ sampleBuffer: CMSampleBuffer) {
        // CMSampleBuffer: 카메라에서 온 raw 데이터
        // PixelBuffer: Vision이 처리할 수 있는 형태로 변환
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let request = faceDetectionRequest else {
            return
        }
        
        isAnalyzing = true
        
        do {
            // Vision API 실행
            // [request]: 요청 목록
            // pixelBuffer: 이미지 데이터
            // orientation: 이미지 방향
            try sequenceHandler.perform([request], on: pixelBuffer, orientation: .up)
        } catch {
            print("❌ Vision request failed: \(error)")
        }
    }
    
    // MARK: - Process Detection Results
    private func processDetectionResults(_ results: [Any]?) {
        guard let faceObservations = results as? [VNFaceObservation],
              let face = faceObservations.first else {
            // 얼굴이 감지되지 않음 (이탈)
            updateState(level: .unfocused, isFaceDetected: false)
            return
        }
        
        // 얼굴 랜드마크 분석
        guard let landmarks = face.landmarks else {
            updateState(level: .unknown, isFaceDetected: true)
            return
        }
        
        // 1. EAR 계산 (졸음 감지)
        let ear = calculateEAR(from: landmarks)
        
        // 2. Head Pose 계산 (이탈 감지)
        let headPose = calculateHeadPose(from: face)
        
        // 3. 시선 방향 추정
        let gazeDirection = estimateGazeDirection(from: landmarks, headPose: headPose)
        let isLookingAtScreen = gazeDirection == .center
        
        // 4. 종합적인 집중도 판단
        let focusLevel = determineFocusLevel(
            ear: ear,
            headPose: headPose,
            isLookingAtScreen: isLookingAtScreen
        )
        
        // 5. 상세 분석 데이터 업데이트 (디버그용)
        updateAnalysisData(
            isFaceDetected: true,
            face: face,
            landmarks: landmarks,
            headPose: headPose,
            ear: ear,
            gazeDirection: gazeDirection,
            focusLevel: focusLevel
        )
        
        updateState(
            level: focusLevel,
            ear: ear,
            isLookingAtScreen: isLookingAtScreen,
            isFaceDetected: true,
            headPose: headPose
        )
    }
    
    // MARK: - Update Analysis Data (디버그용)
    private func updateAnalysisData(
        isFaceDetected: Bool,
        face: VNFaceObservation? = nil,
        landmarks: VNFaceLandmarks2D? = nil,
        headPose: HeadPose? = nil,
        ear: Double = 0,
        gazeDirection: GazeDirection = .center,
        focusLevel: FocusLevel = .unknown
    ) {
        var data = FaceAnalysisData()
        data.isFaceDetected = isFaceDetected
        
        if let face = face {
            data.faceBoundingBox = face.boundingBox
        }
        
        if let landmarks = landmarks {
            // 눈 위치 추출
            if let leftEye = landmarks.leftEye {
                data.leftEyePoints = leftEye.normalizedPoints
                data.leftEyeCenter = calculateCenter(of: leftEye.normalizedPoints)
            }
            
            if let rightEye = landmarks.rightEye {
                data.rightEyePoints = rightEye.normalizedPoints
                data.rightEyeCenter = calculateCenter(of: rightEye.normalizedPoints)
            }
            
            // 코 위치
            if let nose = landmarks.nose {
                data.nosePosition = calculateCenter(of: nose.normalizedPoints)
            }
            
            // 입 위치
            if let outerLips = landmarks.outerLips {
                data.mouthPoints = outerLips.normalizedPoints
            }
            
            // 얼굴 윤곽
            if let faceContour = landmarks.faceContour {
                data.faceContourPoints = faceContour.normalizedPoints
            }
        }
        
        if let headPose = headPose {
            data.yaw = headPose.yaw
            data.pitch = headPose.pitch
            data.roll = headPose.roll
        }
        
        data.leftEAR = lastLeftEAR
        data.rightEAR = lastRightEAR
        data.averageEAR = ear
        data.gazeDirection = gazeDirection
        data.isLookingAtScreen = gazeDirection == .center
        data.focusLevel = focusLevel
        
        DispatchQueue.main.async { [weak self] in
            self?.faceAnalysisData = data
        }
    }
    
    /// 점들의 중심점 계산
    private func calculateCenter(of points: [CGPoint]) -> CGPoint {
        guard !points.isEmpty else { return .zero }
        
        let sumX = points.reduce(0) { $0 + $1.x }
        let sumY = points.reduce(0) { $0 + $1.y }
        
        return CGPoint(
            x: sumX / CGFloat(points.count),
            y: sumY / CGFloat(points.count)
        )
    }
    
    // MARK: - EAR (Eye Aspect Ratio) Calculation - 졸음 감지 핵심 알고리즘
    /// 눈의 세로/가로 비율을 계산하여 졸음 감지
    /// EAR = (|p2-p6| + |p3-p5|) / (2 * |p1-p4|)
    /*
    눈이 떠있을 때:              눈이 감겼을 때:
        p2    p3                    p2  p3
      ●────────●                  ●──────●
     /          \                  ──────
    p1            p4    →     p1  ──────  p4
     \          /                  ──────
      ●────────●                  ●──────●
        p6    p5                    p6  p5

    EAR = (|p2-p6| + |p3-p5|) / (2 × |p1-p4|)
        = 세로길이 / 가로길이

    - 눈 떴을 때: EAR ≈ 0.3 ~ 0.4
    - 눈 감았을 때: EAR ≈ 0.1 이하
    - 졸음 판정: EAR < 0.2가 3초 이상 지속
    */
    
    private func calculateEAR(from landmarks: VNFaceLandmarks2D) -> Double {
        guard let leftEye = landmarks.leftEye,
              let rightEye = landmarks.rightEye else {
            return 0.3  // 기본값 (정상 범위)
        }
        
        // 양쪽 눈의 EAR 평균
        let leftEAR = calculateSingleEyeEAR(eyePoints: leftEye.normalizedPoints)
        let rightEAR = calculateSingleEyeEAR(eyePoints: rightEye.normalizedPoints)
        
        let averageEAR = (leftEAR + rightEAR) / 2.0
        
        // EAR 히스토리 업데이트 (스무딩 - 급격한 변화 방지 (이동 평균))
        earHistory.append(averageEAR)
        if earHistory.count > earHistorySize {
            earHistory.removeFirst()
        }
        
        // 이동 평균 반환
        return earHistory.reduce(0, +) / Double(earHistory.count)
    }
    
    private func calculateSingleEyeEAR(eyePoints: [CGPoint]) -> Double {
        // Vision의 눈 랜드마크는 여러 포인트로 구성
        // 간단한 근사: 세로 거리 / 가로 거리
        guard eyePoints.count >= 6 else { return 0.3 }
        
        // 눈의 가로 길이 (양 끝점)
        let horizontalDist = distance(from: eyePoints[0], to: eyePoints[3])
        
        // 눈의 세로 길이 (위아래 점들의 평균)
        let verticalDist1 = distance(from: eyePoints[1], to: eyePoints[5])
        let verticalDist2 = distance(from: eyePoints[2], to: eyePoints[4])
        
        guard horizontalDist > 0 else { return 0.3 }
        
        return (verticalDist1 + verticalDist2) / (2.0 * horizontalDist)
    }
    
    private func distance(from p1: CGPoint, to p2: CGPoint) -> Double {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        return sqrt(dx * dx + dy * dy)
    }
    
    // MARK: - Head Pose Calculation
    private func calculateHeadPose(from face: VNFaceObservation) -> HeadPose {
        // VNFaceObservation의 roll, yaw, pitch 사용
        let roll = face.roll?.doubleValue ?? 0  // 라디안
        let yaw = face.yaw?.doubleValue ?? 0    // 라디안
        
        // pitch는 직접 제공되지 않으므로 얼굴 위치로 추정
        let pitch = estimatePitch(from: face)
        
        // 라디안 -> 도(degree) 변환
        return HeadPose(
            pitch: pitch * 180 / .pi,
            yaw: yaw * 180 / .pi,
            roll: roll * 180 / .pi
        )
    }
    
    private func estimatePitch(from face: VNFaceObservation) -> Double {
        // 얼굴 바운딩 박스의 y 위치로 고개 숙임 추정
        // 얼굴이 화면 하단에 있으면 고개를 숙인 것으로 판단
        let faceY = face.boundingBox.midY
        
        // 0.5가 중앙, 0에 가까우면 고개 숙임, 1에 가까우면 고개 들기
        return (faceY - 0.5) * 0.5  // 스케일 조정
    }
    
    // MARK: - Gaze Direction Estimation
    private func estimateGazeDirection(from landmarks: VNFaceLandmarks2D, headPose: HeadPose) -> GazeDirection {
        // Head Pose 기반 시선 방향 추정
        
        // Yaw 기반 좌우 판단
        if headPose.yaw < -20 {
            return .left
        } else if headPose.yaw > 20 {
            return .right
        }
        
        // Pitch 기반 상하 판단
        if headPose.pitch < -15 {
            return .down
        } else if headPose.pitch > 15 {
            return .up
        }
        
        // 정면
        return .center
    }
    
    // MARK: - Focus Level Determination (집중 레벨 최종 판정)
    private func determineFocusLevel(
        ear: Double,
        headPose: HeadPose,
        isLookingAtScreen: Bool
    ) -> FocusLevel {
        
        // 1. 졸음 체크 (최우선)
        if ear < EARConstants.drowsinessThreshold {
            lowEARFrameCount += 1
            if lowEARFrameCount >= drowsinessFrameThreshold {
                return .drowsy
            }
        } else {
            lowEARFrameCount = 0
        }
        
        // 2. 이탈 체크
        if !isLookingAtScreen {
            return .unfocused
        }
        
        // 3. Head Pose 기반 주의 체크
        if abs(headPose.yaw) > 20 || abs(headPose.pitch) > 15 {
            return .warning
        }
        
        // 4. 집중 상태
        return .focused
    }
    
    // MARK: - State Update
    private func updateState(
        level: FocusLevel,
        ear: Double = 0,
        isLookingAtScreen: Bool = false,
        isFaceDetected: Bool,
        headPose: HeadPose? = nil
    ) {
        let newState = FocusState(
            level: level,
            eyeAspectRatio: ear,
            isLookingAtScreen: isLookingAtScreen,
            isFaceDetected: isFaceDetected,
            headPose: headPose
        )
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.currentState = newState
            self.isAnalyzing = false
            self.delegate?.focusDetection(self, didDetect: newState)
        }
    }
    
    // MARK: - Reset
    func reset() {
        lowEARFrameCount = 0
        earHistory.removeAll()
        lastLeftEAR = 0
        lastRightEAR = 0
        currentState = FocusState()
        faceAnalysisData = FaceAnalysisData()
    }
}
