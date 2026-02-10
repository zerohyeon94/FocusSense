//
//  MLFocusDetectionService.swift
//  FocusSense
//
//  CoreML 모델을 사용한 집중도 감지 서비스
//  - Vision Framework: 얼굴 감지 + 랜드마크 추출
//  - CoreML: 졸음 분류 (awake/drowsy)
//

import CoreML
import Vision
import AVFoundation
import UIKit
import Combine

// MARK: - ML Detection State (디버그용)
struct MLDetectionState {
    var step: String = "대기 중"
    var faceDetected: Bool = false
    var faceRect: CGRect = .zero
    var mlModelLoaded: Bool = false
    var mlInferenceResult: String = "없음"
    var awakeProb: Float = 0
    var drowsyProb: Float = 0
    var errorMessage: String?
    var isCalibrated: Bool = false
    var calibrationPosition: String = "미설정"
    var deviationFromBaseline: String = ""
}

// MARK: - ML Focus Detection Service
final class MLFocusDetectionService: ObservableObject, FocusDetectionServiceProtocol {
    
    // MARK: - Published Properties
    @Published var currentState: FocusState = FocusState()
    @Published var isAnalyzing = false
    @Published var faceAnalysisData: FaceAnalysisData = FaceAnalysisData()
    @Published var detectionState: MLDetectionState = MLDetectionState()  // 디버그용
    
    // MARK: - CoreML Model
    private var mlModel: VNCoreMLModel?
    private var isModelLoaded = false
    
    // MARK: - Vision Requests
    private var faceLandmarksRequest: VNDetectFaceLandmarksRequest?
    
    // MARK: - 결과 스무딩
    private var drowsinessHistory: [Float] = []
    private let historySize = 5
    
    // MARK: - EAR 저장
    private var lastLeftEAR: Double = 0
    private var lastRightEAR: Double = 0
    
    // MARK: - Calibration Service 연결
    var calibrationService: CalibrationService?
    
    // MARK: - Initialization
    init() {
        setupCoreMLModel()
        setupVisionRequests()
    }
    
    // MARK: - Setup CoreML Model
    private func setupCoreMLModel() {
        updateDetectionState(step: "CoreML 모델 로딩 중...")
        
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .cpuAndNeuralEngine
            
            // 모델 로드 시도
            let model = try FocusSense_default(configuration: config)
            mlModel = try VNCoreMLModel(for: model.model)
            isModelLoaded = true
            
            updateDetectionState(step: "✅ CoreML 모델 로드 성공", mlModelLoaded: true)
            print("✅ CoreML 모델 로드 성공")
            
        } catch {
            isModelLoaded = false
            updateDetectionState(step: "❌ CoreML 모델 로드 실패", error: error.localizedDescription)
            print("❌ CoreML 모델 로드 실패: \(error)")
        }
    }
    
    // MARK: - Setup Vision Requests
    private func setupVisionRequests() {
        // 얼굴 랜드마크 감지 (얼굴 감지 + EAR 계산용)
        faceLandmarksRequest = VNDetectFaceLandmarksRequest()
        faceLandmarksRequest?.revision = VNDetectFaceLandmarksRequestRevision3
    }
    
    // MARK: - Process Video Frame (메인 진입점)
    func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            updateDetectionState(step: "❌ 픽셀 버퍼 추출 실패")
            return
        }
        
        DispatchQueue.main.async {
            self.isAnalyzing = true
        }
        
        updateDetectionState(step: "📷 프레임 처리 시작...")
        
        // 전체 파이프라인 실행
        processFullPipeline(pixelBuffer: pixelBuffer)
    }
    
    // MARK: - Full Pipeline
    private func processFullPipeline(pixelBuffer: CVPixelBuffer) {
        // Step 1: Vision으로 얼굴 감지 + 랜드마크 추출
        updateDetectionState(step: "1️⃣ 얼굴 감지 중...")
        
        guard let landmarksRequest = faceLandmarksRequest else {
            updateDetectionState(step: "❌ Vision Request 없음")
            return
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        do {
            try handler.perform([landmarksRequest])
        } catch {
            updateDetectionState(step: "❌ Vision 실행 실패", error: error.localizedDescription)
            updateNoFaceState()
            return
        }
        
        // Step 2: 얼굴 감지 결과 확인
        guard let observations = landmarksRequest.results,
              let face = observations.first else {
            updateDetectionState(step: "😕 얼굴을 찾지 못함", faceDetected: false)
            updateNoFaceState()
            return
        }
        
        let faceRect = face.boundingBox
        updateDetectionState(
            step: "2️⃣ 얼굴 감지 성공!",
            faceDetected: true,
            faceRect: faceRect
        )
        
        // Step 3: 랜드마크에서 EAR 계산 (Vision 기반)
        var visionEAR: Double = 0.3
        var headPose = HeadPose(pitch: 0, yaw: 0, roll: 0)
        
        if let landmarks = face.landmarks {
            visionEAR = calculateEARFromLandmarks(landmarks)
            headPose = estimateHeadPose(from: face)
            
            // 랜드마크 데이터 업데이트
            updateLandmarksData(face: face, landmarks: landmarks)
        }
        
        // Step 4: CoreML로 졸음 분류
        updateDetectionState(step: "3️⃣ CoreML 추론 중...")
        
        var mlDrowsinessProb: Float = 0
        
        if isModelLoaded, let model = mlModel {
            mlDrowsinessProb = runCoreMLInference(
                pixelBuffer: pixelBuffer,
                faceRect: faceRect,
                model: model
            )
        } else {
            // CoreML 없으면 Vision EAR로 대체
            mlDrowsinessProb = visionEAR < 0.25 ? 0.8 : 0.2
            updateDetectionState(step: "⚠️ CoreML 없음, Vision EAR 사용")
        }
        
        // Step 5: 최종 상태 결정
        updateDetectionState(
            step: "4️⃣ 분석 완료!",
            awakeProb: 1.0 - mlDrowsinessProb,
            drowsyProb: mlDrowsinessProb
        )
        
        // 스무딩 적용
        let smoothedDrowsiness = addToHistoryAndSmooth(&drowsinessHistory, value: mlDrowsinessProb)
        
//        // 최종 상태 업데이트
//        updateFinalState(
//            isFaceDetected: true,
//            drowsinessProb: smoothedDrowsiness,
//            visionEAR: visionEAR,
//            headPose: headPose,
//            faceRect: faceRect
//        )
        // 캘리브레이션 적용한 최종 상태 결정
        updateFinalStateWithCalibration(
            isFaceDetected: true,
            drowsinessProb: smoothedDrowsiness,
            visionEAR: visionEAR,
            headPose: headPose,
            faceRect: faceRect
        )
    }
    
    // 캘리브레이션 적용된 최종 상태 결정
    private func updateFinalStateWithCalibration(
        isFaceDetected: Bool,
        drowsinessProb: Float,
        visionEAR: Double,
        headPose: HeadPose,
        faceRect: CGRect
    ) {
        // 캘리브레이션 평가
        let evaluation: (isLooking: Bool, isDrowsy: Bool, isAway: Bool)
        var deviationInfo = ""
        
        if let calibration = calibrationService,
           calibration.calibrationData.isCalibrated {
            
            // ✅ 캘리브레이션 데이터 기반 평가
            evaluation = calibration.evaluate(
                currentYaw: headPose.yaw,
                currentPitch: headPose.pitch,
                currentEAR: visionEAR
            )
            
            // 기준 대비 차이 계산 (디버그용)
            let yawDiff = headPose.yaw - calibration.calibrationData.baselineYaw
            let pitchDiff = headPose.pitch - calibration.calibrationData.baselinePitch
            let earDiff = visionEAR - calibration.calibrationData.baselineEAR
            
            deviationInfo = String(format: "Δyaw: %.1f°, Δpitch: %.1f°, ΔEAR: %.2f",
                                   yawDiff, pitchDiff, earDiff)
            
            updateDetectionState(
                step: "4️⃣ 캘리브레이션 적용 완료!",
                isCalibrated: true,
                calibrationPosition: calibration.calibrationData.positionDescription,
                deviationFromBaseline: deviationInfo
            )
            
        } else {
            // ✅ 캘리브레이션 없으면 기본 로직
            evaluation = (
                isLooking: abs(headPose.yaw) < 30 && abs(headPose.pitch) < 25,
                isDrowsy: drowsinessProb > 0.7 || visionEAR < 0.2,
                isAway: abs(headPose.yaw) > 45 || abs(headPose.pitch) > 35
            )
            
            updateDetectionState(
                step: "4️⃣ 분석 완료 (캘리브레이션 없음)",
                isCalibrated: false,
                calibrationPosition: "미설정"
            )
        }
        
        // 집중 레벨 결정
        let focusLevel: FocusLevel
        
        if evaluation.isDrowsy {
            focusLevel = .drowsy
        } else if evaluation.isAway {
            focusLevel = .unfocused
        } else if !evaluation.isLooking {
            focusLevel = .warning
        } else {
            focusLevel = .focused
        }
        
        // 시선 방향 결정
        let gazeDirection: GazeDirection
        if headPose.yaw < -20 {
            gazeDirection = .left
        } else if headPose.yaw > 20 {
            gazeDirection = .right
        } else if headPose.pitch < -15 {
            gazeDirection = .down
        } else if headPose.pitch > 15 {
            gazeDirection = .up
        } else {
            gazeDirection = .center
        }
        
        let isLookingAtScreen = evaluation.isLooking
        
        // UI 업데이트
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.isAnalyzing = false
            
            self.currentState = FocusState(
                level: focusLevel,
                eyeAspectRatio: visionEAR,
                isLookingAtScreen: isLookingAtScreen,
                isFaceDetected: true,
                headPose: headPose
            )
            
            self.faceAnalysisData.isFaceDetected = true
            self.faceAnalysisData.focusLevel = focusLevel
            self.faceAnalysisData.yaw = headPose.yaw
            self.faceAnalysisData.pitch = headPose.pitch
            self.faceAnalysisData.roll = headPose.roll
            self.faceAnalysisData.averageEAR = visionEAR
            self.faceAnalysisData.gazeDirection = gazeDirection
            self.faceAnalysisData.isLookingAtScreen = isLookingAtScreen
        }
        
        // 디버그 상태 업데이트
        updateDetectionState(
            awakeProb: 1.0 - drowsinessProb,
            drowsyProb: drowsinessProb
        )
    }
    
    // MARK: - CoreML Inference
    private func runCoreMLInference(
        pixelBuffer: CVPixelBuffer,
        faceRect: CGRect,
        model: VNCoreMLModel
    ) -> Float {
        
        // CoreML Request 생성
        var resultProb: Float = 0
        
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            if let error = error {
                self?.updateDetectionState(step: "❌ CoreML 에러", error: error.localizedDescription)
                return
            }
            
            // 결과 파싱
            resultProb = self?.parseMLResults(request: request) ?? 0
        }
        
        // 얼굴 영역만 분석
        request.regionOfInterest = faceRect
        request.imageCropAndScaleOption = .scaleFill
        
        // 동기 실행
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            updateDetectionState(step: "❌ CoreML 실행 실패", error: error.localizedDescription)
        }
        
        return resultProb
    }
    
    // MARK: - Parse ML Results
    private func parseMLResults(request: VNRequest) -> Float {
        if let classifications = request.results as? [VNClassificationObservation] {
            for classification in classifications {
                let id = classification.identifier.lowercased()
                if id.contains("drowsy") || id.contains("closed") || id == "1" {
                    updateDetectionState(
                        mlInferenceResult: "\(classification.identifier): \(String(format: "%.1f%%", classification.confidence * 100))"
                    )
                    return classification.confidence
                }
            }
            
            if let first = classifications.first {
                let id = first.identifier.lowercased()
                if id.contains("awake") || id.contains("open") || id == "0" {
                    return 1.0 - first.confidence
                }
            }
        }
        
        if let observations = request.results as? [VNCoreMLFeatureValueObservation] {
            for observation in observations {
                if let multiArray = observation.featureValue.multiArrayValue,
                   multiArray.count >= 2 {
                    let drowsyProb = multiArray[1].floatValue
                    let awakeProb = multiArray[0].floatValue
                    let total = exp(awakeProb) + exp(drowsyProb)
                    return exp(drowsyProb) / total
                }
            }
        }
        
        return 0
    }
    
    // MARK: - Calculate EAR from Landmarks
    private func calculateEARFromLandmarks(_ landmarks: VNFaceLandmarks2D) -> Double {
        guard let leftEye = landmarks.leftEye,
              let rightEye = landmarks.rightEye else {
            return 0.3
        }
        
        let leftEAR = calculateEAR(from: leftEye.normalizedPoints)
        let rightEAR = calculateEAR(from: rightEye.normalizedPoints)
        
        lastLeftEAR = leftEAR
        lastRightEAR = rightEAR
        
        return (leftEAR + rightEAR) / 2.0
    }
    
    private func calculateEAR(from points: [CGPoint]) -> Double {
        guard points.count >= 6 else { return 0.3 }
        
        // EAR = (|p2-p6| + |p3-p5|) / (2 * |p1-p4|)
        let p1 = points[0]
        let p2 = points[1]
        let p3 = points[2]
        let p4 = points[3]
        let p5 = points[4]
        let p6 = points[5]
        
        let vertical1 = distance(p2, p6)
        let vertical2 = distance(p3, p5)
        let horizontal = distance(p1, p4)
        
        guard horizontal > 0 else { return 0.3 }
        
        return (vertical1 + vertical2) / (2.0 * horizontal)
    }
    
    private func distance(_ p1: CGPoint, _ p2: CGPoint) -> Double {
        return sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2))
    }
    
    // MARK: - Estimate Head Pose
    private func estimateHeadPose(from face: VNFaceObservation) -> HeadPose {
        let yaw = (face.yaw?.doubleValue ?? 0) * 180 / .pi
        let pitch = (face.pitch?.doubleValue ?? 0) * 180 / .pi
        let roll = (face.roll?.doubleValue ?? 0) * 180 / .pi
        return HeadPose(pitch: pitch, yaw: yaw, roll: roll)
    }
    
    // MARK: - Update Landmarks Data
    private func updateLandmarksData(face: VNFaceObservation, landmarks: VNFaceLandmarks2D) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.faceAnalysisData.faceBoundingBox = face.boundingBox
            
            // 눈 위치
            if let leftEye = landmarks.leftEye {
                self.faceAnalysisData.leftEyePoints = leftEye.normalizedPoints.map { CGPoint(x: $0.x, y: $0.y) }
                self.faceAnalysisData.leftEyeCenter = self.calculateCenter(leftEye.normalizedPoints)
            }
            
            if let rightEye = landmarks.rightEye {
                self.faceAnalysisData.rightEyePoints = rightEye.normalizedPoints.map { CGPoint(x: $0.x, y: $0.y) }
                self.faceAnalysisData.rightEyeCenter = self.calculateCenter(rightEye.normalizedPoints)
            }
            
            // 코 위치
            if let nose = landmarks.nose {
                self.faceAnalysisData.nosePosition = self.calculateCenter(nose.normalizedPoints)
            }
            
            // 입 위치
            if let outerLips = landmarks.outerLips {
                self.faceAnalysisData.mouthPoints = outerLips.normalizedPoints.map { CGPoint(x: $0.x, y: $0.y) }
            }
            
            // EAR 값
            self.faceAnalysisData.leftEAR = self.lastLeftEAR
            self.faceAnalysisData.rightEAR = self.lastRightEAR
        }
    }
    
    private func calculateCenter(_ points: [CGPoint]) -> CGPoint {
        guard !points.isEmpty else { return .zero }
        let sumX = points.reduce(0) { $0 + $1.x }
        let sumY = points.reduce(0) { $0 + $1.y }
        return CGPoint(x: sumX / CGFloat(points.count), y: sumY / CGFloat(points.count))
    }
    
    // MARK: - Smoothing
    private func addToHistoryAndSmooth(_ history: inout [Float], value: Float) -> Float {
        history.append(value)
        if history.count > historySize {
            history.removeFirst()
        }
        return history.reduce(0, +) / Float(history.count)
    }
    
    // MARK: - Update No Face State
    private func updateNoFaceState() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.isAnalyzing = false
            
            self.currentState = FocusState(
                level: .unfocused,
                eyeAspectRatio: 0,
                isLookingAtScreen: false,
                isFaceDetected: false,
                headPose: nil
            )
            
            self.faceAnalysisData.isFaceDetected = false
            self.faceAnalysisData.focusLevel = .unfocused
        }
    }
    
    // MARK: - Update Detection State
    private func updateDetectionState(
        step: String? = nil,
        faceDetected: Bool? = nil,
        faceRect: CGRect? = nil,
        mlModelLoaded: Bool? = nil,
        mlInferenceResult: String? = nil,
        awakeProb: Float? = nil,
        drowsyProb: Float? = nil,
        error: String? = nil,
        isCalibrated: Bool? = nil,
        calibrationPosition: String? = nil,
        deviationFromBaseline: String? = nil
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let step = step { self.detectionState.step = step }
            if let faceDetected = faceDetected { self.detectionState.faceDetected = faceDetected }
            if let faceRect = faceRect { self.detectionState.faceRect = faceRect }
            if let mlModelLoaded = mlModelLoaded { self.detectionState.mlModelLoaded = mlModelLoaded }
            if let mlInferenceResult = mlInferenceResult { self.detectionState.mlInferenceResult = mlInferenceResult }
            if let awakeProb = awakeProb { self.detectionState.awakeProb = awakeProb }
            if let drowsyProb = drowsyProb { self.detectionState.drowsyProb = drowsyProb }
            if let error = error { self.detectionState.errorMessage = error }
            if let isCalibrated = isCalibrated { self.detectionState.isCalibrated = isCalibrated }
            if let calibrationPosition = calibrationPosition { self.detectionState.calibrationPosition = calibrationPosition }
            if let deviationFromBaseline = deviationFromBaseline { self.detectionState.deviationFromBaseline = deviationFromBaseline }
        }
    }
    
    // MARK: - Reset
    func reset() {
        drowsinessHistory.removeAll()
        currentState = FocusState()
        faceAnalysisData = FaceAnalysisData()
        detectionState = MLDetectionState()
    }
}
