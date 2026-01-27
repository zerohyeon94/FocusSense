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
        view.session = session
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        // 세션이 변경되면 업데이트
        uiView.session = session
    }
}

// MARK: - Camera Preview UIView
/// AVCaptureVideoPreviewLayer를 포함하는 UIView
class CameraPreviewUIView: UIView {
    
    // Preview Layer
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    // Capture Session
    var session: AVCaptureSession? {
        didSet {
            setupPreviewLayer()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPreviewLayer() {
        // 기존 레이어 제거
        previewLayer?.removeFromSuperlayer()
        
        guard let session = session else { return }
        
        // 새 프리뷰 레이어 생성
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill  // 화면 채우기
        layer.frame = bounds
        
        // 전면 카메라 미러링
        if let connection = layer.connection, connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = true
        }
        
        self.layer.addSublayer(layer)
        self.previewLayer = layer
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // 뷰 크기가 변경되면 프리뷰 레이어 크기도 업데이트
        previewLayer?.frame = bounds
    }
}

// MARK: - Camera Preview with Overlay
/// 카메라 프리뷰 + 얼굴 분석 오버레이를 함께 표시
struct CameraPreviewWithOverlay: View {
    let session: AVCaptureSession
    let analysisData: FaceAnalysisData
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 1. 카메라 프리뷰 (배경)
                CameraPreviewView(session: session)
                
                // 2. 얼굴 분석 오버레이 (위에 겹침)
                FaceOverlayView(
                    analysisData: analysisData,
                    frameSize: geometry.size
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
