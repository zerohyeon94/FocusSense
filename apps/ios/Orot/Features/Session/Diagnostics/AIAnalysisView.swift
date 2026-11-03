//
//  AIAnalysisView.swift
//  FocusSense
//
//  AI 분석 현황 화면 - 카메라 프리뷰 + 실시간 집중도 분석 결과
//

import SwiftUI
import AVFoundation

// MARK: - AI Analysis View
struct AIAnalysisView: View {
    @ObservedObject var viewModel: TimerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isReady = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isReady {
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        topSection(height: geometry.size.height * 0.5)
                        bottomSection
                    }
                }
                .transition(.opacity)
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

    // MARK: - Top Section (Header + Camera)
    private func topSection(height: CGFloat) -> some View {
        VStack(spacing: 8) {
            AnalysisHeaderView(onClose: { dismiss() })
                .padding(.horizontal)

            if let session = viewModel.captureSession {
                CameraPreviewWithOverlay(
                    session: session,
                    analysisData: viewModel.faceAnalysisData
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            } else {
                CameraUnavailableView()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
            }
        }
        .frame(height: height)
    }

    // MARK: - Bottom Section (Analysis Results)
    private var bottomSection: some View {
        ScrollView {
            VStack(spacing: 12) {
                FocusScoreGauge(score: viewModel.focusRate)

                AnalysisScoreRow(debugInfo: viewModel.focusService.debugInfo)

                EARValuesRow(
                    data: viewModel.faceAnalysisData,
                    baseline: viewModel.focusService.debugInfo.earBaseline
                )

                StatusRow(debugInfo: viewModel.focusService.debugInfo)
            }
            .padding()
        }
    }
}

// MARK: - Analysis Header View
private struct AnalysisHeaderView: View {
    let onClose: () -> Void

    var body: some View {
        HStack {
            Text("AI 분석 현황")
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Focus Score Gauge
private struct FocusScoreGauge: View {
    let score: Double

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: min(score / 100, 1.0))
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.3), value: score)

                VStack(spacing: 2) {
                    Text("\(Int(score))")
                        .font(.system(.title, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("집중률")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 90, height: 90)
        }
    }

    private var scoreColor: Color {
        if score >= 70 { return .green }
        else if score >= 40 { return .yellow }
        else { return .red }
    }
}

// MARK: - Analysis Score Row (Vision + CoreML)
private struct AnalysisScoreRow: View {
    let debugInfo: SimpleDebugInfo

    var body: some View {
        HStack(spacing: 12) {
            MetricCard(
                label: "Vision 졸음",
                value: String(format: "%.0f%%", visionDrowsyPercent),
                color: visionDrowsyPercent < 30 ? .green : (visionDrowsyPercent < 60 ? .yellow : .red),
                progress: visionDrowsyPercent / 100
            )

            MetricCard(
                label: "CoreML 졸음",
                value: debugInfo.usingCoreML
                    ? String(format: "%.0f%%", Double(debugInfo.coreMLDrowsyProb) * 100)
                    : "-",
                color: debugInfo.usingCoreML
                    ? (debugInfo.coreMLDrowsyProb < 0.3 ? .green : (debugInfo.coreMLDrowsyProb < 0.6 ? .yellow : .red))
                    : .gray,
                progress: debugInfo.usingCoreML ? Double(debugInfo.coreMLDrowsyProb) : nil
            )
        }
    }

    private var visionDrowsyPercent: Double {
        debugInfo.combinedDrowsyScore * 100
    }
}

// MARK: - EAR Values Row
private struct EARValuesRow: View {
    let data: FaceAnalysisData
    let baseline: Double

    var body: some View {
        HStack(spacing: 12) {
            MetricCard(
                label: "왼쪽 EAR",
                value: String(format: "%.3f", data.leftEAR),
                color: data.leftEAR < 0.2 ? .red : .cyan
            )

            MetricCard(
                label: "오른쪽 EAR",
                value: String(format: "%.3f", data.rightEAR),
                color: data.rightEAR < 0.2 ? .red : .cyan
            )

            MetricCard(
                label: "기준 EAR",
                value: String(format: "%.3f", baseline),
                color: .green
            )
        }
    }
}

// MARK: - Status Row
private struct StatusRow: View {
    let debugInfo: SimpleDebugInfo

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(presenceColor)
                    .frame(width: 8, height: 8)

                Text(debugInfo.presenceState.rawValue)
                    .font(.caption)
                    .foregroundColor(.white)
            }

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(eyeColor)
                    .frame(width: 8, height: 8)

                Text(debugInfo.eyeState.rawValue)
                    .font(.caption)
                    .foregroundColor(.white)
            }

            Spacer()

            Text(debugInfo.decision)
                .font(.caption.bold())
                .foregroundColor(.white)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
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
}

// MARK: - Metric Card (Reusable)
private struct MetricCard: View {
    let label: String
    let value: String
    let color: Color
    var progress: Double? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)

            Text(value)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(color)

            if let progress {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.3))

                        RoundedRectangle(cornerRadius: 2)
                            .fill(color)
                            .frame(width: geometry.size.width * min(CGFloat(progress), 1.0))
                    }
                }
                .frame(height: 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Camera Unavailable View
private struct CameraUnavailableView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
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

// MARK: - Preview
#Preview {
    AIAnalysisView(viewModel: TimerViewModel())
}
