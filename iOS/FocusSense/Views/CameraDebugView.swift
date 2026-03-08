//
//  CameraDebugView.swift
//  FocusSense
//
//  카메라 프리뷰 + 실시간 분석 데이터 표시 화면
//

// ============================================================================
// 📚 [파일 개요] CameraDebugView - "AI 분석 보기" 디버그 화면
// ============================================================================
//
// 📚 [디버그 화면의 역할]
//   타이머 화면에서 "AI 분석 보기" 버튼을 탭하면 표시되는 화면입니다.
//   카메라 프리뷰와 함께 실시간 분석 데이터를 시각적으로 확인할 수 있습니다:
//   - 존재 상태 (present / away / returning)
//   - 눈 상태 (open / halfClosed / closed)
//   - EAR 값 (현재값 / 기준값 / 비율)
//   - CoreML 졸음 확률, 결합 점수
//
// 📚 [지연 로딩 패턴 - @State isReady]
//   카메라 초기화는 무거운 작업이므로, View가 즉시 표시되지 않습니다.
//   @State private var isReady = false로 로딩 상태를 관리하고,
//   .task { await prepareContent() }에서 준비가 완료되면 isReady = true로 전환합니다.
//   이 패턴으로 로딩 중에는 로딩 화면을, 준비 완료 시 메인 콘텐츠를 표시합니다.
//
// 📚 [컴포넌트 계층 구조]
//   CameraDebugView (메인)
//       ├── DebugHeader              ← 상단 닫기 버튼 + 제목
//       ├── CameraPreviewContainer   ← 카메라 프리뷰 영역
//       ├── DebugSection             ← 분석 데이터 섹션 (접기/펼치기)
//       └── AnalysisDataRow          ← 개별 데이터 행 (레이블 + 값)
//
// 📚 [GeometryReader로 프로그레스 바 구현]
//   EAR 값이나 졸음 확률을 시각적 프로그레스 바로 표시할 때
//   GeometryReader로 부모 너비를 읽고, 비율에 따라 채움 너비를 계산합니다.
//   예: geometry.size.width * CGFloat(progress) → 60%면 부모 너비의 60%만큼 채움
//
// ============================================================================

import SwiftUI
import AVFoundation

// MARK: - Camera Debug View
struct CameraDebugView: View {
    @ObservedObject var viewModel: TimerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isReady = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isReady {
                mainContent
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                loadingView
            }
        }
        .task {
            await prepareContent()
        }
    }
    
    private func prepareContent() async {
        try? await Task.sleep(for: .milliseconds(100))
        guard !Task.isCancelled else { return }
        
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
            DebugHeaderView(onClose: { dismiss() })
            
            CameraPreviewSection(viewModel: viewModel)
            
            // 새로운 디버그 섹션
            SimpleDebugSection(debugInfo: viewModel.focusService.debugInfo)
            
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
                
                Text("실시간 집중도 분석")
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
            if let session = viewModel.captureSession {
                CameraPreviewWithOverlay(
                    session: session,
                    analysisData: viewModel.faceAnalysisData
                )
                .aspectRatio(3/4, contentMode: .fit)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(borderColor, lineWidth: 2)
                )
            } else {
                CameraUnavailableView()
                    .aspectRatio(3/4, contentMode: .fit)
            }
            
            // 상태 표시 (간소화)
            HStack(spacing: 20) {
                StatusIndicator(
                    icon: "camera.fill",
                    label: "카메라",
                    isActive: viewModel.cameraService.isRunning
                )
                
                StatusIndicator(
                    icon: "person.fill",
                    label: "존재 감지",
                    isActive: viewModel.focusService.presenceState == .present
                )
                
                StatusIndicator(
                    icon: "eye.fill",
                    label: "눈 상태",
                    isActive: viewModel.focusService.eyeState == .open
                )
            }
        }
    }
    
    private var borderColor: Color {
        switch viewModel.focusService.presenceState {
        case .present:
            return viewModel.focusService.eyeState == .open ? .green : .yellow
        case .away:
            return .red
        case .returning:
            return .blue
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

// MARK: - Simple Debug Section (CoreML 정보 추가)
struct SimpleDebugSection: View {
    let debugInfo: SimpleDebugInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 헤더
            HStack {
                Image(systemName: "brain")
                    .foregroundColor(.cyan)
                Text("분석 상태")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // CoreML 사용 여부 뱃지
                if debugInfo.usingCoreML {
                    Text("🤖 AI")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.3))
                        .cornerRadius(4)
                }
                
                Text(debugInfo.step)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.cyan.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Divider().background(Color.gray.opacity(0.5))
            
            // 2열: 존재 / 눈 상태
            HStack(spacing: 16) {
                // 존재 상태
                VStack(alignment: .leading, spacing: 8) {
                    Label("존재 상태", systemImage: "person.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(presenceColor)
                            .frame(width: 10, height: 10)
                        
                        Text(debugInfo.presenceDescription.isEmpty
                             ? debugInfo.presenceState.rawValue
                             : debugInfo.presenceDescription)
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    
                    if debugInfo.awayDuration > 0 {
                        Text("비움: \(String(format: "%.1f", debugInfo.awayDuration))초")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 눈 상태
                VStack(alignment: .leading, spacing: 8) {
                    Label("눈 상태", systemImage: "eye")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(eyeColor)
                            .frame(width: 10, height: 10)
                        
                        Text(debugInfo.eyeDescription.isEmpty
                             ? debugInfo.eyeState.rawValue
                             : debugInfo.eyeDescription)
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    
                    if debugInfo.closedDuration > 0 {
                        Text("감음: \(String(format: "%.1f", debugInfo.closedDuration))초")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Divider().background(Color.gray.opacity(0.5))
            
            // EAR + CoreML 정보
            VStack(alignment: .leading, spacing: 8) {
                // Vision EAR
                HStack {
                    Text("👁️ Vision EAR")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(String(format: "%.3f", debugInfo.earValue))
                        .font(.caption.monospaced())
                        .foregroundColor(.cyan)
                    
                    Text("/ 기준")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Text(String(format: "%.3f", debugInfo.earBaseline))
                        .font(.caption.monospaced())
                        .foregroundColor(.green)
                }
                
                // EAR 비율 바
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(earRatioColor)
                            .frame(width: geometry.size.width * min(debugInfo.earRatio, 1.2))
                    }
                }
                .frame(height: 6)
                
                // CoreML (있으면)
                if debugInfo.usingCoreML {
                    HStack {
                        Text("🤖 CoreML")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("졸음: \(String(format: "%.0f%%", debugInfo.coreMLDrowsyProb * 100))")
                            .font(.caption.monospaced())
                            .foregroundColor(debugInfo.coreMLDrowsyProb > 0.5 ? .red : .green)
                    }
                    
                    // CoreML 바
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.3))
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(debugInfo.coreMLDrowsyProb > 0.5 ? Color.red : Color.green)
                                .frame(width: geometry.size.width * CGFloat(debugInfo.coreMLDrowsyProb))
                        }
                    }
                    .frame(height: 6)
                }
                
                // 결합 점수
                HStack {
                    Text("📊 결합 점수")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(String(format: "%.0f%%", debugInfo.combinedDrowsyScore * 100))
                        .font(.caption.monospaced().bold())
                        .foregroundColor(combinedScoreColor)
                    
                    if debugInfo.usingCoreML {
                        Text("(70% EAR + 30% AI)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Divider().background(Color.gray.opacity(0.5))
            
            // 최종 판단
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.yellow)
                
                Text("판단:")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(debugInfo.decision)
                    .font(.caption.bold())
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.cyan.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var presenceColor: Color {
        switch debugInfo.presenceState {
        case .present: return .green
        case .away: return .red
        case .returning: return .blue
        }
    }
    
    private var eyeColor: Color {
        switch debugInfo.eyeState {
        case .open: return .green
        case .halfClosed: return .yellow
        case .closed: return .red
        case .unknown: return .gray
        }
    }
    
    private var earRatioColor: Color {
        if debugInfo.earRatio > 0.75 { return .green }
        else if debugInfo.earRatio > 0.55 { return .yellow }
        else { return .red }
    }
    
    private var combinedScoreColor: Color {
        if debugInfo.combinedDrowsyScore < 0.3 { return .green }
        else if debugInfo.combinedDrowsyScore < 0.6 { return .yellow }
        else { return .red }
    }
}

// MARK: - Analysis Data Section (간소화)
struct AnalysisDataSection: View {
    let data: FaceAnalysisData
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // 섹션 타이틀
                HStack {
                    Image(systemName: "chart.bar.xaxis")
                        .foregroundColor(.cyan)
                    Text("상세 데이터")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }
                
                // 데이터 그리드 (간소화)
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    DataCard(
                        icon: "eye",
                        title: "왼쪽 눈 EAR",
                        value: String(format: "%.3f", data.leftEAR),
                        color: data.leftEAR < 0.2 ? .red : .green
                    )
                    
                    DataCard(
                        icon: "eye",
                        title: "오른쪽 눈 EAR",
                        value: String(format: "%.3f", data.rightEAR),
                        color: data.rightEAR < 0.2 ? .red : .green
                    )
                    
                    DataCard(
                        icon: "arrow.left.and.right",
                        title: "좌우 (Yaw)",
                        value: String(format: "%.1f°", data.yaw),
                        color: .blue
                    )
                    
                    DataCard(
                        icon: "arrow.up.and.down",
                        title: "상하 (Pitch)",
                        value: String(format: "%.1f°", data.pitch),
                        color: .purple
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

// MARK: - Data Card (간소화)
struct DataCard: View {
    let icon: String
    let title: String
    let value: String
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
            Image(systemName: level.icon)
                .font(.title2)
                .foregroundColor(level.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("현재 상태")
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
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(gaugeColor)
                    .frame(width: geometry.size.width * CGFloat(min(value / 0.5, 1.0)))
            }
        }
        .frame(width: 60, height: 8)
    }
    
    private var gaugeColor: Color {
        if value < 0.2 { return .red }
        else if value < 0.25 { return .yellow }
        else { return .green }
    }
}

// MARK: - Preview
#Preview {
    CameraDebugView(viewModel: TimerViewModel())
}
