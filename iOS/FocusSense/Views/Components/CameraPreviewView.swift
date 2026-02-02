//
//  CameraPreviewView.swift
//  FocusSense
//
//  UIKit의 AVCaptureVideoPreviewLayer를 SwiftUI에서 사용
//

import SwiftUI
import AVFoundation

// MARK: - Camera Preview View
/// SwiftUI에서 카메라 프리뷰를 표시하기 위한 UIViewRepresentable
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.setSession(session)
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        // 세션이 변경된 경우에만 업데이트
        if uiView.currentSession !== session {
            uiView.setSession(session)
        }
    }
}

// MARK: - Camera Preview UIView
/// AVCaptureVideoPreviewLayer를 포함하는 UIView
/// Swift Concurrency를 활용한 비동기 초기화
class CameraPreviewUIView: UIView {
    
    // Preview Layer
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var setupTask: Task<Void, Never>?
    
    // 현재 세션 (외부에서 확인용)
    private(set) var currentSession: AVCaptureSession?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        // 뷰가 해제될 때 진행 중인 Task 취소
        setupTask?.cancel()
    }
    
    /// 세션 설정 (Swift Concurrency 사용)
    func setSession(_ session: AVCaptureSession) {
        // 이전 작업 취소
        setupTask?.cancel()
        currentSession = session
        
        // 새 Task로 비동기 설정
        setupTask = Task { [weak self] in
            await self?.setupPreviewLayerAsync(session: session)
        }
    }
    
    /// 비동기로 프리뷰 레이어 설정 (Swift Concurrency)
    @MainActor
    private func setupPreviewLayerAsync(session: AVCaptureSession) async {
        // Task가 취소되었는지 확인
        guard !Task.isCancelled else { return }
        
        // 백그라운드에서 무거운 작업 수행
        let layer = await Task.detached(priority: .userInitiated) {
            // AVCaptureVideoPreviewLayer 생성 (무거운 작업)
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            
            // 전면 카메라 미러링 설정
            if let connection = previewLayer.connection,
               connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = true
            }
            
            return previewLayer
        }.value
        
        // 다시 취소 확인 (백그라운드 작업 중에 취소되었을 수 있음)
        guard !Task.isCancelled else { return }
        
        // UI 업데이트 (이미 @MainActor이므로 안전)
        self.previewLayer?.removeFromSuperlayer()
        layer.frame = self.bounds
        self.layer.addSublayer(layer)
        self.previewLayer = layer
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // 애니메이션 없이 즉시 프레임 업데이트
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        previewLayer?.frame = bounds
        CATransaction.commit()
    }
}

// MARK: - Camera Preview with Overlay
/// 카메라 프리뷰 + 얼굴 분석 오버레이를 함께 표시
struct CameraPreviewWithOverlay: View {
    let session: AVCaptureSession
    let analysisData: FaceAnalysisData
    
    @State private var isLoading = true
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 1. 카메라 프리뷰 (배경)
                CameraPreviewView(session: session)
                    .task {
                        // Swift Concurrency: task modifier 사용
                        // View가 나타날 때 자동 실행, 사라지면 자동 취소
                        await delayedLoadingComplete()
                    }
                
                // 2. 로딩 오버레이
                if isLoading {
                    LoadingOverlay()
                        .transition(.opacity)
                }
                
                // 3. 얼굴 분석 오버레이 (위에 겹침)
                if !isLoading {
                    FaceOverlayView(
                        analysisData: analysisData,
                        frameSize: geometry.size
                    )
                    .transition(.opacity)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    /// 로딩 완료 처리 (async/await)
    private func delayedLoadingComplete() async {
        // 0.3초 대기 (프리뷰 레이어 설정 시간)
        try? await Task.sleep(for: .milliseconds(300))
        
        // 취소되지 않았다면 UI 업데이트
        guard !Task.isCancelled else { return }
        
        await MainActor.run {
            withAnimation(.easeOut(duration: 0.2)) {
                isLoading = false
            }
        }
    }
}

// MARK: - Loading Overlay
struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("카메라 연결 중...")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}
