//
//  SimpleFocusDetectionService.swift
//  FocusSense
//
//  단순화된 집중도 감지 서비스
//  핵심 원칙: "존재 + 눈 상태"로만 판단 (카메라 방향 무관)
//  하이브리드: Vision EAR (70%) + CoreML (30%)
//

// ============================================================================
// 📚 [파일 개요] SimpleFocusDetectionService - 앱의 핵심 엔진
// ============================================================================
//
// 📚 이 파일은 FocusSense 앱의 **가장 중요한 파일**입니다.
//    카메라에서 받은 영상 프레임을 분석하여 "집중/주의/졸음/자리비움"을 판단합니다.
//
// 📚 [하이브리드 분석 파이프라인] - 프레임 1장이 처리되는 5단계:
//    Step 1. Vision Framework로 얼굴 감지 (VNDetectFaceLandmarksRequest)
//    Step 2. 눈 랜드마크 6개 포인트로 EAR(Eye Aspect Ratio) 계산
//    Step 3. CoreML 모델로 졸음 확률 추론 (얼굴 영역만 크롭하여 입력)
//    Step 4. 하이브리드 점수 = Vision EAR 70% + CoreML 30% 가중 합산
//    Step 5. 결합 점수 → 눈 상태(EyeState) → 최종 집중도(FocusLevel) 결정
//
// 📚 [핵심 원칙: 시선 방향으로 판단하지 않는다!]
//    사용자가 모니터를 보며 코딩 중이면 카메라를 안 봐도 "집중 중"입니다.
//    yaw(좌우 회전)로 unfocused를 판단하면 안 됩니다.
//    판단 기준은 오직: (1) 얼굴 존재 여부 (2) 눈 감김 상태
//
// 📚 [이 파일에 정의된 타입들]:
//    - PresenceState (enum) : 사용자 존재 상태 (present/away/returning)
//    - EyeState (enum)      : 눈 상태 (open/halfClosed/closed/unknown)
//    - SimpleDebugInfo      : "AI 분석 보기" 디버그 화면에 표시할 데이터
//    - SimpleFocusDetectionService (class) : 핵심 서비스 클래스
//
// 📚 [EAR 계산 공식]:
//    EAR = (|p2-p6| + |p3-p5|) / (2 × |p1-p4|)
//    - p1~p6: 눈 윤곽 6개 포인트 (Vision Framework 제공)
//    - 정상 눈: ~0.3 | 졸음: < 0.2
//    - 캘리브레이션 기준값 대비 비율(earRatio)로 개인차를 보정합니다
//
// 📚 [시간 기반 임계값 (오판 방지)]:
//    - 3초간 얼굴 미감지 → away (깜빡임과 구분)
//    - 2초간 눈 감김 → drowsy (의도적 감김과 구분)
//    - 일반 깜빡임(~0.3초)은 이 임계값 이하이므로 무시됩니다
//
// 📚 [ObservableObject + @Published 패턴]:
//    final class ... : ObservableObject는 SwiftUI에게 "이 객체가 변하면 UI 갱신"을 알립니다.
//    @Published var currentState → 값이 바뀔 때마다 이 객체를 @ObservedObject로 관찰 중인
//    모든 View가 자동으로 다시 그려집니다(re-render).
//    final: 상속 불가를 명시하여 컴파일러 최적화(정적 디스패치)를 가능하게 합니다.
//
// ============================================================================

import Foundation
import Vision
import AVFoundation
import CoreML
import Combine
import UIKit

// MARK: - Presence State
enum PresenceState: String {
    case present = "존재함"
    case away = "자리 비움"
    case returning = "복귀 중"
}

// MARK: - Eye State
enum EyeState: String {
    case open = "눈 떠있음"
    case halfClosed = "반쯤 감김"
    case closed = "눈 감김"
    case unknown = "알 수 없음"
}

// MARK: - Debug Info
struct SimpleDebugInfo {
    var step: String = "대기 중"
    var presenceState: PresenceState = .away
    var presenceDescription: String = ""
    var eyeState: EyeState = .unknown
    var eyeDescription: String = ""
    var earValue: Double = 0
    var earBaseline: Double = 0.3
    var earRatio: Double = 1.0
    var coreMLDrowsyProb: Float = 0      // CoreML 결과
    var combinedDrowsyScore: Double = 0  // 결합 점수
    var decision: String = ""
    var awayDuration: TimeInterval = 0
    var closedDuration: TimeInterval = 0
    var usingCoreML: Bool = false        // CoreML 사용 여부
}

// MARK: - Simple Focus Detection Service
final class SimpleFocusDetectionService: ObservableObject, FocusDetectionServiceProtocol {
    
    // MARK: - Published Properties
    @Published var currentState: FocusState = FocusState()
    @Published var isAnalyzing = false
    @Published var faceAnalysisData: FaceAnalysisData = FaceAnalysisData()
    
    @Published var presenceState: PresenceState = .away
    @Published var eyeState: EyeState = .unknown
    @Published var debugInfo: SimpleDebugInfo = SimpleDebugInfo()
    
    // MARK: - Vision
    private var faceLandmarksRequest: VNDetectFaceLandmarksRequest?
    
    // MARK: - CoreML
    private var mlModel: VNCoreMLModel?
    private var isMLModelLoaded = false
    
    // MARK: - 가중치 설정
    private let visionWeight: Double = 0.7   // Vision EAR 가중치
    private let coreMLWeight: Double = 0.3   // CoreML 가중치
    
    // MARK: - Calibration
    var calibrationService: CalibrationService?
    
    // MARK: - EAR Tracking
    private var earHistory: [Double] = []
    private let earHistorySize = 10
    private var baselineEAR: Double = 0.3
    
    // MARK: - Timing
    private var lastFaceDetectedTime: Date?
    private var awayStartTime: Date?
    private let awayThreshold: TimeInterval = 3.0
    
    private var lowEARStartTime: Date?
    private let drowsyThreshold: TimeInterval = 2.0
    
    // MARK: - Initialization
    init() {
        setupVision()
        setupCoreML()
        print("✅ SimpleFocusDetectionService 초기화 완료")
    }
    
    // MARK: - Setup Vision
    private func setupVision() {
        faceLandmarksRequest = VNDetectFaceLandmarksRequest()
        faceLandmarksRequest?.revision = VNDetectFaceLandmarksRequestRevision3
    }
    
    // MARK: - Setup CoreML
    private func setupCoreML() {
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .cpuAndNeuralEngine
            let model = try FocusSense_default(configuration: config)
            mlModel = try VNCoreMLModel(for: model.model)
            isMLModelLoaded = true
            print("✅ CoreML 모델 로드 성공 (하이브리드 모드)")
        } catch {
            isMLModelLoaded = false
            print("⚠️ CoreML 없이 Vision EAR만 사용: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Process Frame
    func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            updateDebug(step: "❌ 픽셀 버퍼 추출 실패")
            return
        }
        
        DispatchQueue.main.async { self.isAnalyzing = true }
        
        analyze(pixelBuffer: pixelBuffer)
    }
    
    // MARK: - Main Analysis
    private func analyze(pixelBuffer: CVPixelBuffer) {
        updateDebug(step: "1️⃣ 얼굴 감지 중...")
        
        guard let request = faceLandmarksRequest else {
            updateDebug(step: "❌ Vision Request 없음")
            return
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            updateDebug(step: "❌ Vision 실행 실패")
            handleNoFace()
            return
        }
        
        guard let face = request.results?.first else {
            handleNoFace()
            return
        }
        
        // 얼굴 감지됨 → CoreML + Vision 하이브리드 분석
        handleFaceDetected(face: face, pixelBuffer: pixelBuffer)
    }
    
    // MARK: - Handle Face Detected
    private func handleFaceDetected(face: VNFaceObservation, pixelBuffer: CVPixelBuffer) {
        let now = Date()
        lastFaceDetectedTime = now
        
        // 복귀 감지
        let wasAway = presenceState == .away
        if wasAway {
            presenceState = .returning
            updateDebug(step: "👋 복귀 감지!", presenceState: .returning)
            print("👋 사용자 복귀 감지!")
        }
        
        presenceState = .present
        awayStartTime = nil
        
        updateDebug(step: "2️⃣ 얼굴 분석 중...", presenceState: .present, presenceDescription: "✅ 존재함")
        
        // MARK: Step 2 - Vision EAR 계산
        var currentEAR: Double = 0.3
        var headPose = HeadPose(pitch: 0, yaw: 0, roll: 0)
        
        if let landmarks = face.landmarks {
            currentEAR = calculateEAR(from: landmarks)
            headPose = extractHeadPose(from: face)
            updateLandmarksData(face: face, landmarks: landmarks)
        }
        
        // 캘리브레이션 기준 EAR
        if let calibration = calibrationService,
           calibration.calibrationData.isCalibrated {
            baselineEAR = calibration.calibrationData.baselineEAR
        }
        
        // EAR 스무딩
        updateEARHistory(currentEAR)
        let smoothedEAR = earHistory.isEmpty ? currentEAR : earHistory.reduce(0, +) / Double(earHistory.count)
        let earRatio = baselineEAR > 0 ? smoothedEAR / baselineEAR : 1.0
        
        // Vision 기반 졸음 점수 (0 = 깨어있음, 1 = 졸음)
        let visionDrowsyScore: Double
        if earRatio > 0.75 {
            visionDrowsyScore = 0.0
        } else if earRatio > 0.55 {
            visionDrowsyScore = (0.75 - earRatio) / 0.2  // 0 ~ 1 사이
        } else {
            visionDrowsyScore = 1.0
        }
        
        // MARK: Step 3 - CoreML 추론 (있으면)
        var coreMLDrowsyProb: Float = 0
        
        if isMLModelLoaded, let model = mlModel {
            updateDebug(step: "3️⃣ CoreML 추론 중...")
            coreMLDrowsyProb = runCoreMLInference(pixelBuffer: pixelBuffer, faceRect: face.boundingBox, model: model)
        }
        
        // MARK: Step 4 - 하이브리드 점수 계산
        let combinedDrowsyScore: Double
        if isMLModelLoaded {
            // 하이브리드: Vision 70% + CoreML 30%
            combinedDrowsyScore = visionWeight * visionDrowsyScore + coreMLWeight * Double(coreMLDrowsyProb)
            updateDebug(usingCoreML: true)
        } else {
            // Vision만 사용
            combinedDrowsyScore = visionDrowsyScore
            updateDebug(usingCoreML: false)
        }
        
        updateDebug(
            step: "4️⃣ 판단 중...",
            earValue: smoothedEAR,
            earBaseline: baselineEAR,
            earRatio: earRatio,
            coreMLDrowsyProb: coreMLDrowsyProb,
            combinedDrowsyScore: combinedDrowsyScore
        )
        
        // MARK: Step 5 - 눈 상태 및 최종 판단
        let newEyeState = determineEyeState(combinedScore: combinedDrowsyScore)
        eyeState = newEyeState
        
        updateDebug(eyeState: newEyeState, eyeDescription: eyeStateDescription(newEyeState))
        
        let focusLevel = determineFocusLevel(eyeState: newEyeState, wasAway: wasAway)
        
        updateFinalState(
            focusLevel: focusLevel,
            ear: smoothedEAR,
            headPose: headPose,
            faceRect: face.boundingBox
        )
    }
    
    // MARK: - CoreML Inference
    private func runCoreMLInference(pixelBuffer: CVPixelBuffer, faceRect: CGRect, model: VNCoreMLModel) -> Float {
        var resultProb: Float = 0
        
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            if let error = error {
                print("❌ CoreML 에러: \(error.localizedDescription)")
                return
            }
            resultProb = self?.parseMLResults(request: request) ?? 0
        }
        
        request.regionOfInterest = faceRect
        request.imageCropAndScaleOption = .scaleFill
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("❌ CoreML 실행 실패: \(error.localizedDescription)")
        }
        
        return resultProb
    }
    
    // MARK: - Parse ML Results
    private func parseMLResults(request: VNRequest) -> Float {
        // VNClassificationObservation (분류 모델)
        if let classifications = request.results as? [VNClassificationObservation] {
            for classification in classifications {
                let id = classification.identifier.lowercased()
                if id.contains("drowsy") || id.contains("closed") || id == "1" {
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
        
        // VNCoreMLFeatureValueObservation (멀티태스크 모델)
        if let observations = request.results as? [VNCoreMLFeatureValueObservation] {
            for observation in observations {
                if let multiArray = observation.featureValue.multiArrayValue,
                   multiArray.count >= 2 {
                    let drowsyProb = multiArray[1].floatValue
                    let awakeProb = multiArray[0].floatValue
                    
                    // Softmax
                    let total = exp(awakeProb) + exp(drowsyProb)
                    return exp(drowsyProb) / total
                }
            }
        }
        
        return 0
    }
    
    // MARK: - Handle No Face
    private func handleNoFace() {
        let now = Date()
        
        if awayStartTime == nil {
            awayStartTime = now
        }
        
        let awayDuration = now.timeIntervalSince(awayStartTime ?? now)
        updateDebug(awayDuration: awayDuration)
        
        if awayDuration >= awayThreshold {
            presenceState = .away
            eyeState = .unknown
            
            updateDebug(
                step: "🚶 자리 비움",
                presenceState: .away,
                presenceDescription: "❌ 자리 비움 (\(Int(awayDuration))초)",
                eyeState: .unknown,
                decision: "⏸️ 자동 일시정지"
            )
            
            updateFinalState(
                focusLevel: .away,
                ear: 0,
                headPose: HeadPose(),
                faceRect: .zero
            )
        } else {
            updateDebug(
                step: "🔍 얼굴 찾는 중...",
                presenceDescription: "⏳ 잠시 안 보임 (\(Int(awayDuration))초)"
            )
        }
        
        DispatchQueue.main.async {
            self.isAnalyzing = false
            self.faceAnalysisData.isFaceDetected = self.presenceState != .away
        }
    }
    
    // MARK: - Determine Eye State (하이브리드 점수 기반)
    private func determineEyeState(combinedScore: Double) -> EyeState {
        if combinedScore < 0.3 {
            lowEARStartTime = nil
            return .open
        } else if combinedScore < 0.6 {
            if lowEARStartTime == nil { lowEARStartTime = Date() }
            return .halfClosed
        } else {
            if lowEARStartTime == nil { lowEARStartTime = Date() }
            return .closed
        }
    }
    
    // MARK: - Determine Focus Level
    private func determineFocusLevel(eyeState: EyeState, wasAway: Bool) -> FocusLevel {
        if wasAway {
            updateDebug(decision: "✅ 복귀 → 집중 시작")
            return .focused
        }
        
        switch eyeState {
        case .open:
            updateDebug(decision: "✅ 집중 중 (눈 떠있음)")
            return .focused
            
        case .halfClosed:
            let closedDuration = getClosedDuration()
            updateDebug(closedDuration: closedDuration)
            
            if closedDuration > drowsyThreshold {
                updateDebug(decision: "😴 졸음 (오래 감음: \(String(format: "%.1f", closedDuration))초)")
                return .drowsy
            }
            updateDebug(decision: "⚠️ 주의 (눈 살짝 감김)")
            return .warning
            
        case .closed:
            let closedDuration = getClosedDuration()
            updateDebug(closedDuration: closedDuration)
            
            if closedDuration > drowsyThreshold {
                updateDebug(decision: "😴 졸음 (\(String(format: "%.1f", closedDuration))초 눈 감음)")
                return .drowsy
            }
            updateDebug(decision: "⚠️ 주의 (눈 감김)")
            return .warning
            
        case .unknown:
            updateDebug(decision: "✅ 집중 추정 (측면)")
            return .focused
        }
    }
    
    private func getClosedDuration() -> TimeInterval {
        guard let startTime = lowEARStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    // MARK: - Calculate EAR
    private func calculateEAR(from landmarks: VNFaceLandmarks2D) -> Double {
        guard let leftEye = landmarks.leftEye,
              let rightEye = landmarks.rightEye else { return 0.3 }
        
        let leftEAR = calculateSingleEAR(from: leftEye.normalizedPoints)
        let rightEAR = calculateSingleEAR(from: rightEye.normalizedPoints)
        
        DispatchQueue.main.async {
            self.faceAnalysisData.leftEAR = leftEAR
            self.faceAnalysisData.rightEAR = rightEAR
        }
        
        return (leftEAR + rightEAR) / 2.0
    }
    
    private func calculateSingleEAR(from points: [CGPoint]) -> Double {
        guard points.count >= 6 else { return 0.3 }
        
        let vertical1 = distance(points[1], points[5])
        let vertical2 = distance(points[2], points[4])
        let horizontal = distance(points[0], points[3])
        
        guard horizontal > 0 else { return 0.3 }
        
        return (vertical1 + vertical2) / (2.0 * horizontal)
    }
    
    private func distance(_ p1: CGPoint, _ p2: CGPoint) -> Double {
        return sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2))
    }
    
    // MARK: - Extract Head Pose
    private func extractHeadPose(from face: VNFaceObservation) -> HeadPose {
        let yaw = (face.yaw?.doubleValue ?? 0) * 180 / .pi
        let pitch = (face.pitch?.doubleValue ?? 0) * 180 / .pi
        let roll = (face.roll?.doubleValue ?? 0) * 180 / .pi
        return HeadPose(pitch: pitch, yaw: yaw, roll: roll)
    }
    
    // MARK: - Update EAR History
    private func updateEARHistory(_ ear: Double) {
        earHistory.append(ear)
        if earHistory.count > earHistorySize {
            earHistory.removeFirst()
        }
    }
    
    // MARK: - Update Landmarks Data
    private func updateLandmarksData(face: VNFaceObservation, landmarks: VNFaceLandmarks2D) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.faceAnalysisData.isFaceDetected = true
            self.faceAnalysisData.faceBoundingBox = face.boundingBox
            
            if let leftEye = landmarks.leftEye {
                self.faceAnalysisData.leftEyePoints = leftEye.normalizedPoints.map { CGPoint(x: $0.x, y: $0.y) }
                self.faceAnalysisData.leftEyeCenter = self.calculateCenter(leftEye.normalizedPoints)
            }
            
            if let rightEye = landmarks.rightEye {
                self.faceAnalysisData.rightEyePoints = rightEye.normalizedPoints.map { CGPoint(x: $0.x, y: $0.y) }
                self.faceAnalysisData.rightEyeCenter = self.calculateCenter(rightEye.normalizedPoints)
            }
            
            if let nose = landmarks.nose {
                self.faceAnalysisData.nosePosition = self.calculateCenter(nose.normalizedPoints)
            }
            
            if let outerLips = landmarks.outerLips {
                self.faceAnalysisData.mouthPoints = outerLips.normalizedPoints.map { CGPoint(x: $0.x, y: $0.y) }
            }
        }
    }
    
    private func calculateCenter(_ points: [CGPoint]) -> CGPoint {
        guard !points.isEmpty else { return .zero }
        let sumX = points.reduce(0) { $0 + $1.x }
        let sumY = points.reduce(0) { $0 + $1.y }
        return CGPoint(x: sumX / CGFloat(points.count), y: sumY / CGFloat(points.count))
    }
    
    // MARK: - Update Final State
    private func updateFinalState(
        focusLevel: FocusLevel,
        ear: Double,
        headPose: HeadPose,
        faceRect: CGRect
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.isAnalyzing = false
            
            self.currentState = FocusState(
                level: focusLevel,
                eyeAspectRatio: ear,
                isLookingAtScreen: focusLevel == .focused || focusLevel == .warning,
                isFaceDetected: focusLevel != .away && focusLevel != .unknown,
                headPose: headPose
            )
            
            self.faceAnalysisData.focusLevel = focusLevel
            self.faceAnalysisData.averageEAR = ear
            self.faceAnalysisData.yaw = headPose.yaw
            self.faceAnalysisData.pitch = headPose.pitch
            self.faceAnalysisData.roll = headPose.roll
            self.faceAnalysisData.isLookingAtScreen = focusLevel == .focused
        }
    }
    
    // MARK: - Debug Helpers
    private func updateDebug(
        step: String? = nil,
        presenceState: PresenceState? = nil,
        presenceDescription: String? = nil,
        eyeState: EyeState? = nil,
        eyeDescription: String? = nil,
        earValue: Double? = nil,
        earBaseline: Double? = nil,
        earRatio: Double? = nil,
        coreMLDrowsyProb: Float? = nil,
        combinedDrowsyScore: Double? = nil,
        decision: String? = nil,
        awayDuration: TimeInterval? = nil,
        closedDuration: TimeInterval? = nil,
        usingCoreML: Bool? = nil
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let step = step { self.debugInfo.step = step }
            if let presenceState = presenceState { self.debugInfo.presenceState = presenceState }
            if let presenceDescription = presenceDescription { self.debugInfo.presenceDescription = presenceDescription }
            if let eyeState = eyeState { self.debugInfo.eyeState = eyeState }
            if let eyeDescription = eyeDescription { self.debugInfo.eyeDescription = eyeDescription }
            if let earValue = earValue { self.debugInfo.earValue = earValue }
            if let earBaseline = earBaseline { self.debugInfo.earBaseline = earBaseline }
            if let earRatio = earRatio { self.debugInfo.earRatio = earRatio }
            if let coreMLDrowsyProb = coreMLDrowsyProb { self.debugInfo.coreMLDrowsyProb = coreMLDrowsyProb }
            if let combinedDrowsyScore = combinedDrowsyScore { self.debugInfo.combinedDrowsyScore = combinedDrowsyScore }
            if let decision = decision { self.debugInfo.decision = decision }
            if let awayDuration = awayDuration { self.debugInfo.awayDuration = awayDuration }
            if let closedDuration = closedDuration { self.debugInfo.closedDuration = closedDuration }
            if let usingCoreML = usingCoreML { self.debugInfo.usingCoreML = usingCoreML }
        }
    }
    
    private func eyeStateDescription(_ state: EyeState) -> String {
        switch state {
        case .open: return "👀 눈 떠있음"
        case .halfClosed: return "😑 반쯤 감김"
        case .closed: return "😴 눈 감김"
        case .unknown: return "❓ 알 수 없음"
        }
    }
    
    // MARK: - Reset
    func reset() {
        earHistory.removeAll()
        presenceState = .away
        eyeState = .unknown
        lowEARStartTime = nil
        awayStartTime = nil
        lastFaceDetectedTime = nil
        currentState = FocusState()
        faceAnalysisData = FaceAnalysisData()
        debugInfo = SimpleDebugInfo()
        print("🔄 SimpleFocusDetectionService 리셋")
    }
}
