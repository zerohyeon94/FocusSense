//
//  CalibrationView.swift
//  FocusSense
//
//  위치 설정 화면
//

// ============================================================================
// 📚 [파일 개요] CalibrationView - 사용자 캘리브레이션(보정) 화면
// ============================================================================
//
// 📚 [캘리브레이션 흐름]
//   카메라 시작 → 얼굴 감지 대기 → 기준값(Baseline) 측정 → 완료
//   1. 카메라가 사용자의 얼굴을 감지합니다
//   2. EAR(눈 종횡비) 기준값을 여러 프레임에 걸쳐 수집합니다
//   3. 수집된 평균값을 개인별 기준선(baseline)으로 저장합니다
//   이후 집중도 판단 시 절대값이 아닌, 이 기준선 대비 비율로 판단합니다.
//
// 📚 [@ViewBuilder - 조건부 View 조합]
//   @ViewBuilder는 여러 View를 조건에 따라 다르게 반환할 수 있게 합니다.
//   if/else, switch 등으로 상태별 다른 UI를 선언적으로 구성합니다.
//   예: 캘리브레이션 상태(대기/진행/완료)에 따라 다른 화면을 표시합니다.
//
// 📚 [.onAppear / .onDisappear - 생명주기 관리]
//   - .onAppear: View가 화면에 나타날 때 실행 → 카메라 세션 시작
//   - .onDisappear: View가 화면에서 사라질 때 실행 → 카메라 세션 정리
//   카메라 같은 하드웨어 리소스는 반드시 이 생명주기에 맞춰 관리해야 합니다.
//
// 📚 [@Environment(\.dismiss) - 모달 닫기]
//   현재 화면을 프로그래밍적으로 닫는 SwiftUI 환경 값입니다.
//   dismiss()를 호출하면 .sheet나 .fullScreenCover로 표시된 모달이 닫힙니다.
//   NavigationStack에서는 이전 화면으로 pop됩니다.
//
// ============================================================================

import SwiftUI

struct CalibrationView: View {
    @ObservedObject var viewModel: TimerViewModel
    @ObservedObject var calibrationService: CalibrationService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 헤더
                headerView
                    .padding(.bottom, 24)
                
                VStack(spacing: 24) {
                    // 카메라 프리뷰
                    cameraPreviewSection
                    
                    // 현재 상태 표시 (해당 부분은 Debug에서만 사용되게 구현)
    //                CurrentStatusCard(data: viewModel.faceAnalysisData)
                    
                    // 캘리브레이션 진행 상태
                    calibrationStatusSection
                }
                
                Spacer()
                
                VStack(spacing: 0) {
                    // 버튼
                    buttonSection
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .onAppear {
            // ✅ 카메라 시작
            viewModel.cameraService.startSession()
        }
        .onDisappear {
            // 캘리브레이션 중이면 취소 + 프레임 간격 복원
            if calibrationService.isCalibrating {
                calibrationService.isCalibrating = false
                viewModel.cameraService.disableCalibrationMode()
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
        .fixedSize(horizontal: false, vertical: true)
    }
    
    // MARK: - Camera Preview
    private var cameraPreviewSection: some View {
        Group {
            if let session = viewModel.captureSession {
                CameraPreviewView(session: session)
                    .frame(height: 400)
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
                    .frame(maxHeight: .infinity)
                    .overlay(
                        Text("카메라 로딩 중...")
                            .foregroundColor(.gray)
                    )
                    .padding(.horizontal)
            }
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
    
    // MARK: - Current Status Card (Debug용)
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
    
    // MARK: - Calibration Status
    @ViewBuilder
    private var calibrationStatusSection: some View {
        // Calibration 진행중
        if calibrationService.isCalibrating {
            CalibrationProgressView(
                progress: calibrationService.calibrationProgress,
                message: calibrationService.calibrationMessage
            )
        } else if calibrationService.calibrationData.isCalibrated { // Calibration 완료된 경우
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
        
        private var dateFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            
            formatter.amSymbol = "오전"
            formatter.amSymbol = "오후"
            
            formatter.dateFormat = "yyyy년 MM월 dd일 EEEE a h시 mm분 ss초"
            
            return formatter
        }
        
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
                    let settingDate = dateFormatter.string(from: date)
                    
                    Text("설정일: \(settingDate)")
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
        // 캘리브레이션 중에는 프레임 간격을 0.17초(≈6fps)로 줄여 빠르게 샘플 수집
        // 기본 1fps → 6fps로 전환하여 30샘플을 약 5초 만에 완료
        viewModel.cameraService.enableCalibrationMode()
        calibrationService.startCalibration()
    }
}

// MARK: - Preview
#Preview {
    CalibrationView(
        viewModel: TimerViewModel(),
        calibrationService: CalibrationService())
}
