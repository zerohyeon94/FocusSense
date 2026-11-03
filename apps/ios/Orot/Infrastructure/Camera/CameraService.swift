//
//  CameraService.swift
//  FocusSense
//
//  카메라 캡처 관리 서비스
//  - Preview Layer 숨기기 (GPU 부하 감소)
//  - 프레임 스로틀링 (1 FPS로 제한)
//

import AVFoundation
import UIKit

// MARK: - Camera Service Delegate
// protocol: 계약서 같은 것
protocol CameraServiceDelegate: AnyObject {
    func cameraService(_ service: CameraService, didOutput sampleBuffer: CMSampleBuffer)
    func cameraService(_ service: CameraService, didFailWithError error: Error)
}

// MARK: - Camera Service
// final: 상속 불가
// NSObject:  Objective-C 호환
// ObservableObject: SwiftUI에서 관찰 가능
final class CameraService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    // @Published: 이 값이 바뀌면 UI가 자동 업데이트 됨
    @Published var isRunning = false
    @Published var permissionGranted = false
    /// 다른 앱이 카메라를 쓰는 등으로 세션이 끊긴 상태
    @Published var isInterrupted = false
    /// 권한이 거부되었거나 제한됨
    @Published var permissionDenied = false
    
    // MARK: - Properties
    // weak: 약한 참조 (메모리 누수 방지)
    weak var delegate: CameraServiceDelegate?
    
    // AVFoundation 객체
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    
    // DispatchQueue: 작업을 특정 스레드에서 실행
    private let sessionQueue = DispatchQueue(label: "com.focussense.camera.session") // 백그라운드 스레드 (UI 멈춤 방지)
    private let outputQueue = DispatchQueue(label: "com.focussense.camera.output")
    
    /// 외부에서 카메라 세션에 접근할 수 있는 접근자 (프리뷰용)
    var session: AVCaptureSession {
        return captureSession
    }
    
    // MARK: - Frame Throttling (핵심 최적화!)
    // 카메라는 기본 30fps (초당 30프레임)
    // 모든 프레임을 AI로 분석하면 → 배터리 소모 + 발열 심함
    // 해결책: 1초에 1번만 처리
    /// 마지막으로 프레임을 처리한 시간
    private var lastFrameTime: CFAbsoluteTime = 0
    /// 프레임 처리 간격 (초) - 기본 1초에 1번, 캘리브레이션 시 동적 변경 가능
    private var frameInterval: CFAbsoluteTime = 1.0
    
    // MARK: - Initialization
    override init() {
        super.init()
        checkPermission()
        observeInterruptions()
    }

    /// 이미 허용된 경우에만 세션을 준비합니다. 처음 묻는 일은 온보딩의 requestPermission()이 맡습니다.
    func checkPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        let granted = status == .authorized
        DispatchQueue.main.async {
            self.permissionGranted = granted
            self.permissionDenied = status == .denied || status == .restricted
        }
        if granted && captureSession.inputs.isEmpty { setupSession() }
    }

    var authorizationStatus: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    func requestPermission() async -> Bool {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        checkPermission()
        return granted
    }

    private func observeInterruptions() {
        let center = NotificationCenter.default
        center.addObserver(forName: AVCaptureSession.wasInterruptedNotification, object: captureSession, queue: .main) { [weak self] _ in
            self?.isInterrupted = true
            print("⚠️ 카메라 세션 끊김")
        }
        center.addObserver(forName: AVCaptureSession.interruptionEndedNotification, object: captureSession, queue: .main) { [weak self] _ in
            self?.isInterrupted = false
            print("✅ 카메라 세션 다시 연결")
        }
    }

    private func setupSession() {
        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }
    
    private func configureSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .medium  // 해상도 낮춤 (배터리 절약)
        
        // 전면 카메라 설정
        guard let frontCamera = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .front
        ) else {
            print("❌ Front camera not available")
            captureSession.commitConfiguration()
            return
        }
        
        do {
            // 카메라 입력 설정
            let input = try AVCaptureDeviceInput(device: frontCamera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            // 프레임 레이트 제한 (추가 최적화)
            try frontCamera.lockForConfiguration()
            frontCamera.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 15)  // 15 FPS 제한
            frontCamera.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 15)
            frontCamera.unlockForConfiguration()
            
        } catch {
            print("❌ Camera input error: \(error)")
            delegate?.cameraService(self, didFailWithError: error)
            captureSession.commitConfiguration()
            return
        }
        
        // 비디오 출력 설정
        videoOutput.setSampleBufferDelegate(self, queue: outputQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        // 비디오 방향 설정
        if let connection = videoOutput.connection(with: .video) {
            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = true
            }
        }
        
        captureSession.commitConfiguration()
    }
    
    // MARK: - Session Control
    func startSession() {
        guard permissionGranted else {
            print("⚠️ Camera permission not granted")
            return
        }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                DispatchQueue.main.async {
                    self.isRunning = true
                }
                print("✅ Camera session started")
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                DispatchQueue.main.async {
                    self.isRunning = false
                }
                print("✅ Camera session stopped")
            }
        }
    }
    
    // MARK: - Frame Rate Adjustment (발열 대응)
    /// 발열 상태에 따라 프레임 처리 간격 조정
    func adjustFrameInterval(for thermalState: ProcessInfo.ThermalState) {
        switch thermalState {
        case .nominal:
            // 정상: 1초에 1번
            setFrameInterval(1.0)
        case .fair:
            // 약간 뜨거움: 2초에 1번
            setFrameInterval(2.0)
        case .serious:
            // 심각: 10초에 1번 (세션 화면에 안내 배너)
            setFrameInterval(10.0)
        case .critical:
            // 위험: 분석 중지
            stopSession()
            print("🔥 Critical thermal state - camera stopped")
        @unknown default:
            setFrameInterval(1.0)
        }
    }
    
    private func setFrameInterval(_ interval: CFAbsoluteTime) {
        // captureOutput에서 이 값과 비교하여 프레임을 스킵할지 결정
        frameInterval = interval
        print("📊 Frame interval set to \(interval)s")
    }

    /// 캘리브레이션 모드: 프레임 간격을 0.17초(≈6fps)로 줄여 빠르게 샘플 수집
    /// 30샘플 × 0.17초 = 약 5초 만에 캘리브레이션 완료
    func enableCalibrationMode() {
        setFrameInterval(0.17)
    }

    /// 일반 모드: 프레임 간격을 1초(1fps)로 복원하여 배터리/발열 최적화
    func disableCalibrationMode() {
        setFrameInterval(1.0)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    // 프레임이 들어올 때마다 호출됨 (30번/초)
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // 🔑 핵심 최적화: 프레임 스로틀링
        let currentTime = CFAbsoluteTimeGetCurrent() // 현재 시간
        
        // 1초가 지나지 않았으면 무시
        guard currentTime - lastFrameTime >= frameInterval else {
            return  // 아직 처리 간격이 안 됐으면 스킵
        }
        
        lastFrameTime = currentTime
        
        // Delegate에게 프레임 전달
        delegate?.cameraService(self, didOutput: sampleBuffer)
    }
}

/**
 ┌─────────────┐      30fps       ┌────────┐
 │   Camera                               │ ────→   │  CameraService  │
 │  (하드웨어)                              │                      │   (스로틀링)           │
 └─────────────┘                      └────────┘
                                           │
                                     1fps (최적화!)
                                           │
                                           ▼
                                  ┌─────────┐
                                  │          Delegate        │
                                  │   (TimerViewModel)│
                                  └─────────┘
                                           │
                                           ▼
                                  ┌─────────┐
                                  │        AI Analysis       │
                                  │   (FocusDetection)  │
                                  └─────────┘
 */
