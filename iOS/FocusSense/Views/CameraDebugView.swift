//
//  CameraDebugView.swift
//  FocusSense
//
//  카메라 프리뷰 + 실시간 분석 데이터 표시 화면
//  - 카메라 영상 위에 얼굴 랜드마크 오버레이
//  - 하단에 실시간 수치 데이터 표시
//

import SwiftUI
import AVFoundation

// MARK: - Camera Debug View
struct CameraDebugView: View {
    @ObservedObject var viewModel: TimerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isReady = false
    
    var body: some View {
        ZStack {
            // 배경
            Color.black.ignoresSafeArea()
            
            if isReady {
                // 메인 컨텐츠 (준비 완료 후)
                mainContent
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                // 로딩 화면
                loadingView
            }
        }
        .task {
            // Swift Concurrency: .task modifier
            // - View가 나타날 때 자동 실행
            // - View가 사라지면 자동으로 Task 취소
            await prepareContent()
        }
    }
    
    // MARK: - Prepare Content (async)
    /// 컨텐츠 준비 (Swift Concurrency)
    private func prepareContent() async {
        // 화면 전환 애니메이션이 완료될 시간을 줌
        try? await Task.sleep(for: .milliseconds(100))
        
        // Task가 취소되지 않았다면 UI 업데이트
        guard !Task.isCancelled else { return }
        
        // @MainActor 컨텍스트에서 UI 업데이트
        await MainActor.run {
            withAnimation(.easeOut(duration: 0.25)) {
                isReady = true
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                .scaleEffect(1.5)
            
            Text("AI 분석 화면 로딩 중...")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        VStack(spacing: 16) {
            // 헤더
            DebugHeaderView(onClose: { dismiss() })
            
            // 카메라 프리뷰 + 오버레이
            CameraPreviewSection(viewModel: viewModel)
            
            // 실시간 분석 데이터
            AnalysisDataSection(data: viewModel.faceAnalysisData)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Debug Header View
struct DebugHeaderView: View {
    let onClose: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("🔬 AI 분석 디버그")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("실시간 얼굴 인식 시각화")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Camera Preview Section
struct CameraPreviewSection: View {
    @ObservedObject var viewModel: TimerViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            // 카메라 프리뷰 + 오버레이
            if let session = viewModel.captureSession {
                CameraPreviewWithOverlay(
                    session: session,
                    analysisData: viewModel.faceAnalysisData
                )
                .aspectRatio(3/4, contentMode: .fit)
                .overlay(
                    // 프레임 테두리
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            viewModel.faceAnalysisData.isFaceDetected ? Color.green : Color.red,
                            lineWidth: 2
                        )
                )
            } else {
                // 카메라 없음
                CameraUnavailableView()
                    .aspectRatio(3/4, contentMode: .fit)
            }
            
            // 상태 표시
            HStack(spacing: 20) {
                StatusIndicator(
                    icon: "camera.fill",
                    label: "카메라",
                    isActive: viewModel.cameraService.isRunning
                )
                
                StatusIndicator(
                    icon: "face.smiling",
                    label: "얼굴 감지",
                    isActive: viewModel.faceAnalysisData.isFaceDetected
                )
                
                StatusIndicator(
                    icon: "eye.fill",
                    label: "시선 추적",
                    isActive: viewModel.faceAnalysisData.isLookingAtScreen
                )
            }
        }
    }
}

// MARK: - Status Indicator
struct StatusIndicator: View {
    let icon: String
    let label: String
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(isActive ? .green : .red)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Camera Unavailable View
struct CameraUnavailableView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.gray.opacity(0.3))
            .overlay(
                VStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    
                    Text("카메라를 사용할 수 없습니다")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            )
    }
}

// MARK: - Analysis Data Section
struct AnalysisDataSection: View {
    let data: FaceAnalysisData
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // 섹션 타이틀
                HStack {
                    Image(systemName: "chart.bar.xaxis")
                        .foregroundColor(.cyan)
                    Text("실시간 분석 데이터")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }
                
                // 상태 요약 배너
                StatusSummaryBanner(data: data)
                
                // 얼굴 방향 정보 (새로 추가!)
                FaceOrientationCard(data: data)
                
                // 데이터 그리드
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    // Head Pose 데이터
                    DataCard(
                        icon: "arrow.left.and.right",
                        title: "좌우 회전 (Yaw)",
                        value: String(format: "%.1f°", data.yaw),
                        detail: data.faceDirectionDescription,
                        color: .blue
                    )
                    
                    DataCard(
                        icon: "arrow.up.and.down",
                        title: "고개 숙임 (Pitch)",
                        value: String(format: "%.1f°", data.pitch),
                        detail: data.pitchDescription,
                        color: .purple
                    )
                    
                    DataCard(
                        icon: "rotate.right",
                        title: "기울임 (Roll)",
                        value: String(format: "%.1f°", data.roll),
                        detail: data.rollDescription,
                        color: .orange
                    )
                    
                    DataCard(
                        icon: "eye",
                        title: "눈 비율 (EAR)",
                        value: String(format: "%.3f", data.averageEAR),
                        detail: data.earStatusDescription,
                        color: data.averageEAR < 0.2 ? .red : .green
                    )
                    
                    DataCard(
                        icon: "person.crop.rectangle",
                        title: "얼굴 위치",
                        value: data.facePositionInFrame,
                        detail: "화면 내 위치",
                        color: .cyan
                    )
                    
                    DataCard(
                        icon: "target",
                        title: "시선 방향",
                        value: data.gazeDirection.rawValue,
                        detail: data.isLookingAtScreen ? "화면 응시 중" : "화면 이탈",
                        color: data.isLookingAtScreen ? .green : .red
                    )
                }
                
                // 집중 상태 요약
                FocusSummaryBar(level: data.focusLevel, ear: data.averageEAR)
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Status Summary Banner
struct StatusSummaryBanner: View {
    let data: FaceAnalysisData
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: data.isFaceDetected ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title2)
                .foregroundColor(statusColor)
            
            Text(data.summaryDescription)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(statusColor.opacity(0.2))
        )
    }
    
    private var statusColor: Color {
        if !data.isFaceDetected {
            return .red
        } else if data.focusLevel == .focused {
            return .green
        } else if data.focusLevel == .warning {
            return .yellow
        } else {
            return .orange
        }
    }
}

// MARK: - Face Orientation Card (새로 추가!)
struct FaceOrientationCard: View {
    let data: FaceAnalysisData
    
    var body: some View {
        VStack(spacing: 12) {
            // 타이틀
            HStack {
                Image(systemName: "face.smiling")
                    .foregroundColor(.yellow)
                Text("얼굴 방향 분석")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Spacer()
            }
            
            HStack(spacing: 16) {
                // 어느 쪽 얼굴이 보이는지
                VStack(alignment: .leading, spacing: 4) {
                    Text("보이는 얼굴")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 4) {
                        FaceDirectionIcon(yaw: data.yaw)
                        Text(data.visibleFaceSide)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                    .frame(height: 30)
                    .background(Color.gray.opacity(0.5))
                
                // 카메라 위치
                VStack(alignment: .leading, spacing: 4) {
                    Text("카메라 위치")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Text(data.cameraPositionRelativeToUser)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                    .frame(height: 30)
                    .background(Color.gray.opacity(0.5))
                
                // 전체 각도
                VStack(alignment: .leading, spacing: 4) {
                    Text("카메라 각도")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Text(String(format: "%.1f°", data.totalFaceAngle))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(data.isFacingCamera ? .green : .yellow)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // 정면 여부 인디케이터
            HStack {
                Circle()
                    .fill(data.isFacingCamera ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                
                Text(data.isFacingCamera ? "✓ 정면을 향하고 있습니다" : "⚠️ 카메라를 정면으로 바라봐 주세요")
                    .font(.caption)
                    .foregroundColor(data.isFacingCamera ? .green : .orange)
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Face Direction Icon
struct FaceDirectionIcon: View {
    let yaw: Double
    
    var body: some View {
        ZStack {
            // 얼굴 윤곽
            Circle()
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                .frame(width: 24, height: 24)
            
            // 코 방향 표시 (어느 쪽을 보고 있는지)
            Circle()
                .fill(Color.yellow)
                .frame(width: 6, height: 6)
                .offset(x: CGFloat(yaw / 90 * 8))
        }
    }
}

// MARK: - Data Card
struct DataCard: View {
    let icon: String
    let title: String
    let value: String
    let detail: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Text(value)
                .font(.system(.title3, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(detail)
                .font(.caption2)
                .foregroundColor(color.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Focus Summary Bar
struct FocusSummaryBar: View {
    let level: FocusLevel
    let ear: Double
    
    var body: some View {
        HStack(spacing: 12) {
            // 상태 아이콘
            Image(systemName: level.icon)
                .font(.title2)
                .foregroundColor(level.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("현재 집중 상태")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(level.description)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // EAR 게이지
            VStack(alignment: .trailing, spacing: 2) {
                Text("EAR")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                EARGauge(value: ear)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(level.color.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(level.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - EAR Gauge
struct EARGauge: View {
    let value: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 배경
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                
                // 값 표시
                RoundedRectangle(cornerRadius: 4)
                    .fill(gaugeColor)
                    .frame(width: geometry.size.width * CGFloat(min(value / 0.5, 1.0)))
                
                // 임계값 표시선
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 2)
                    .offset(x: geometry.size.width * 0.4 - 1)  // 0.2 / 0.5 = 0.4
            }
        }
        .frame(width: 60, height: 8)
    }
    
    private var gaugeColor: Color {
        if value < 0.2 {
            return .red
        } else if value < 0.25 {
            return .yellow
        } else {
            return .green
        }
    }
}

// MARK: - Preview
#Preview {
    CameraDebugView(viewModel: TimerViewModel())
}
