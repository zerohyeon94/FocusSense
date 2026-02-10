//
//  CalibrationView.swift
//  FocusSense
//
//  위치 설정 화면
//

import SwiftUI

struct CalibrationView: View {
    @ObservedObject var viewModel: TimerViewModel
    @ObservedObject var calibrationService: CalibrationService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // 헤더
                headerView
                
                // 카메라 프리뷰
                cameraPreviewSection
                
                // 현재 상태 표시
                CurrentStatusCard(data: viewModel.faceAnalysisData)
                
                // 캘리브레이션 진행 상태
                calibrationStatusSection
                
                Spacer()
                
                // 버튼
                buttonSection
            }
        }
        .onAppear {
            // ✅ 카메라 시작
            viewModel.cameraService.startSession()
        }
        .onDisappear {
            // 캘리브레이션 중이면 취소
            if calibrationService.isCalibrating {
                calibrationService.isCalibrating = false
            }
            
            // 타이머가 실행 중이 아니면 카메라 정지
            if viewModel.timerState == .idle {
                viewModel.cameraService.stopSession()
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            Spacer()
            Text("위치 설정")
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
            Color.clear.frame(width: 44)
        }
        .padding()
    }
    
    // MARK: - Camera Preview
    private var cameraPreviewSection: some View {
        Group {
            if let session = viewModel.captureSession {
                CameraPreviewView(session: session)
                    .frame(height: 300)
                    .cornerRadius(16)
                    .overlay(
                        FaceGuideOverlay(
                            faceDetected: viewModel.faceAnalysisData.isFaceDetected,
                            isCalibrating: calibrationService.isCalibrating
                        )
                    )
                    .padding(.horizontal)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 300)
                    .overlay(
                        Text("카메라 로딩 중...")
                            .foregroundColor(.gray)
                    )
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Calibration Status
    @ViewBuilder
    private var calibrationStatusSection: some View {
        if calibrationService.isCalibrating {
            CalibrationProgressView(
                progress: calibrationService.calibrationProgress,
                message: calibrationService.calibrationMessage
            )
        } else if calibrationService.calibrationData.isCalibrated {
            CalibrationCompleteCard(data: calibrationService.calibrationData)
        } else {
            // 캘리브레이션 안내
            VStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("공부할 때 핸드폰을 둘 위치에서\n정상 자세로 화면을 바라봐주세요")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    // MARK: - Buttons
    private var buttonSection: some View {
        VStack(spacing: 12) {
            if !calibrationService.isCalibrating {
                // 설정 버튼
                Button(action: startCalibration) {
                    HStack {
                        Image(systemName: "scope")
                        Text(calibrationService.calibrationData.isCalibrated
                             ? "다시 설정하기" : "이 위치로 설정")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        viewModel.faceAnalysisData.isFaceDetected ? Color.blue : Color.gray
                    )
                    .cornerRadius(12)
                }
                .disabled(!viewModel.faceAnalysisData.isFaceDetected)
                
                // 완료 버튼 (캘리브레이션 됐으면)
                if calibrationService.calibrationData.isCalibrated {
                    Button(action: { dismiss() }) {
                        Text("완료")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                
                // 초기화 버튼
                if calibrationService.calibrationData.isCalibrated {
                    Button(action: {
                        calibrationService.resetCalibration()
                    }) {
                        Text("초기화")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            } else {
                // 캘리브레이션 중 취소 버튼
                Button(action: {
                    calibrationService.isCalibrating = false
                }) {
                    Text("취소")
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
    }
    
    private func startCalibration() {
        calibrationService.startCalibration()
    }
}

// MARK: - Face Guide Overlay
struct FaceGuideOverlay: View {
    let faceDetected: Bool
    let isCalibrating: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 가이드 원
                Circle()
                    .stroke(
                        isCalibrating ? Color.green :
                            (faceDetected ? Color.blue : Color.gray),
                        lineWidth: isCalibrating ? 4 : 2
                    )
                    .frame(width: 200, height: 200)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    .animation(.easeInOut, value: isCalibrating)
                
                // 안내 텍스트
                VStack {
                    Spacer()
                    
                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                        .padding(.bottom, 16)
                }
            }
        }
    }
    
    private var statusText: String {
        if isCalibrating {
            return "📍 위치 기록 중... 자세를 유지하세요"
        } else if faceDetected {
            return "✅ 얼굴 감지됨 - 버튼을 눌러 설정하세요"
        } else {
            return "😕 얼굴을 화면에 맞춰주세요"
        }
    }
    
    private var statusColor: Color {
        if isCalibrating {
            return .green
        } else if faceDetected {
            return .blue
        } else {
            return .orange
        }
    }
}

// MARK: - Current Status Card
struct CurrentStatusCard: View {
    let data: FaceAnalysisData
    
    var body: some View {
        VStack(spacing: 12) {
            Text("현재 감지값")
                .font(.caption)
                .foregroundColor(.gray)
            
            HStack(spacing: 20) {
                StatusItem(
                    title: "좌우",
                    value: String(format: "%.0f°", data.yaw),
                    icon: "arrow.left.arrow.right"
                )
                StatusItem(
                    title: "상하",
                    value: String(format: "%.0f°", data.pitch),
                    icon: "arrow.up.arrow.down"
                )
                StatusItem(
                    title: "EAR",
                    value: String(format: "%.2f", data.averageEAR),
                    icon: "eye"
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct StatusItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.cyan)
            Text(value)
                .font(.title3.bold())
                .foregroundColor(.white)
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Calibration Progress View
struct CalibrationProgressView: View {
    let progress: Double
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            ProgressView(value: progress)
                .tint(.green)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.green.opacity(0.2))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Calibration Complete Card
struct CalibrationCompleteCard: View {
    let data: CalibrationData
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("설정 완료")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Text("위치: \(data.positionDescription)")
                .font(.caption)
                .foregroundColor(.gray)
            
            if let date = data.calibrationDate {
                Text("설정일: \(date.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
