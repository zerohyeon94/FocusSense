//
//  FaceAlignView.swift
//  Orot
//
//  얼굴 위치 맞추기 (3-1 맞추는 중 · 3-2 잘 잡힘) — 거치 각도 안내와 실시간 피드백.
//  "이대로 시작하기"를 누르면 몇 초 동안 개인 기준값(캘리브레이션)을 잽니다.
//

import SwiftUI
import CoreMotion

struct FaceAlignView: View {
    enum Mode { case onboarding, settings }

    @ObservedObject var viewModel: TimerViewModel
    @ObservedObject var camera: CameraService
    let mode: Mode
    let onDone: () -> Void

    @ObservedObject private var calibration: CalibrationService
    @StateObject private var tilt = DeviceTilt()
    @Environment(\.dismiss) private var dismiss

    init(viewModel: TimerViewModel, camera: CameraService, mode: Mode, onDone: @escaping () -> Void) {
        self.viewModel = viewModel
        self.camera = camera
        self.mode = mode
        self.onDone = onDone
        self.calibration = viewModel.calibrationService
    }

    // MARK: - Checks
    private var faceDetected: Bool { viewModel.currentFocusState.isFaceDetected }
    private var faceCentered: Bool {
        let box = viewModel.faceAnalysisData.faceBoundingBox
        return faceDetected && (0.3...0.7).contains(box.midX) && (0.3...0.75).contains(box.midY)
    }
    /// 기기가 없으면(시뮬레이터) 각도는 확인하지 않습니다.
    private var angleOK: Bool { tilt.degrees.map { (8...24).contains($0) } ?? true }
    private var isReady: Bool { faceDetected && faceCentered && angleOK }

    private var hint: String {
        if !faceDetected { return "얼굴이 보이지 않아요 · 휴대폰을 조금 더 뒤로" }
        let box = viewModel.faceAnalysisData.faceBoundingBox
        if !faceCentered { return box.midY > 0.75 ? "조금 아래로 앉아 주세요" : box.midY < 0.3 ? "조금 위로 맞춰 주세요" : "가운데로 조금만 옮겨 주세요" }
        if let d = tilt.degrees, d < 8 { return "휴대폰을 살짝 더 뒤로 기울여 주세요" }
        if let d = tilt.degrees, d > 24 { return "휴대폰을 살짝 더 세워 주세요" }
        return "얼굴이 잘 잡혔어요"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(mode == .onboarding ? "카메라 설정 · 2 / 2" : "얼굴 위치 다시 맞추기")
                    .font(OrotFont.caption).tracking(0.5).foregroundStyle(OrotColor.textCaption)
                Spacer()
                Button(mode == .onboarding ? "나중에" : "닫기") { finish() }
                    .font(OrotFont.regular(13)).foregroundStyle(OrotColor.textCaption).frame(minHeight: 44)
            }
            Text(isReady ? "잘 보여요. 이 자리 그대로 두세요" : "얼굴이 원 안에 들어오게 맞춰 주세요")
                .font(OrotFont.title).foregroundStyle(OrotColor.textPrimary)
                .animation(.easeOut(duration: 0.6), value: isReady)

            preview.padding(.top, 18)
            angleCard.padding(.top, 20)
            checks.padding(.top, 20)
            Spacer(minLength: 12)

            Button(ctaTitle) {
                calibration.startCalibration()
                camera.enableCalibrationMode()
            }
            .buttonStyle(OrotPrimaryButtonStyle())
            .disabled(!isReady || calibration.isCalibrating)
            .opacity(isReady && !calibration.isCalibrating ? 1 : 0.5)
            .animation(.easeOut(duration: 0.3), value: isReady)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .background(OrotColor.skyNight.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.startPreview()
            tilt.start()
        }
        .onDisappear {
            viewModel.stopPreview()
            tilt.stop()
        }
        .onChange(of: calibration.isCalibrating) { was, now in
            if was && !now && calibration.calibrationData.isCalibrated { finish() }
        }
    }

    private var ctaTitle: String {
        if calibration.isCalibrating { return "기준을 맞추는 중… \(Int(calibration.calibrationProgress * 100))%" }
        if !isReady { return "맞추는 중…" }
        return mode == .onboarding ? "이대로 시작하기" : "이 자리로 맞추기"
    }

    private func finish() {
        if mode == .settings { dismiss() }
        onDone()
    }

    // MARK: - Preview
    private var preview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: OrotRadius.lg).fill(Color(hex: 0x0C0E10))
            if let session = viewModel.captureSession {
                CameraPreviewView(session: session).clipShape(RoundedRectangle(cornerRadius: OrotRadius.lg))
            }
            Ellipse()
                .strokeBorder(isReady ? OrotColor.accent : OrotColor.textSecondary.opacity(0.7), lineWidth: isReady ? 2 : 1)
                .frame(width: 176, height: 224)
                .offset(y: isReady ? -10 : 10)
            Ellipse()
                .strokeBorder(Color(hex: 0x4A4E54), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .frame(width: 176, height: 224)
                .offset(y: -10)
                .opacity(isReady ? 0 : 1)
        }
        .frame(height: 380)
        .overlay(RoundedRectangle(cornerRadius: OrotRadius.lg).strokeBorder(OrotColor.hairline))
        .overlay(alignment: .topLeading) {
            HStack(spacing: 6) {
                Circle().fill(OrotColor.accent).frame(width: 5, height: 5)
                Text("기기 안에서 처리 중")
            }
            .font(OrotFont.regular(11)).foregroundStyle(OrotColor.textSecondary)
            .padding(.horizontal, 10).frame(height: 24)
            .background(Capsule().fill(Color(hex: 0x0C0E10).opacity(0.8)))
            .overlay(Capsule().strokeBorder(OrotColor.hairline))
            .padding(14)
        }
        .overlay(alignment: .bottom) {
            Text(hint)
                .font(OrotFont.regular(13))
                .foregroundStyle(isReady ? OrotColor.accent : OrotColor.textPrimary)
                .padding(.horizontal, 14).frame(height: 30)
                .background(Capsule().fill(OrotColor.skyNight.opacity(0.85)))
                .padding(.bottom, 26)
        }
        .animation(.easeOut(duration: 0.6), value: isReady)
    }

    // MARK: - Angle
    private var angleCard: some View {
        HStack(spacing: 16) {
            ZStack(alignment: .bottom) {
                Rectangle().fill(Color(hex: 0x4A4E54)).frame(height: 1)
                RoundedRectangle(cornerRadius: 2).fill(OrotColor.accentSubtle).frame(width: 3, height: 36)
                    .rotationEffect(.degrees(-15), anchor: .bottom)
                RoundedRectangle(cornerRadius: 2).fill(angleOK ? OrotColor.accent : OrotColor.textSecondary).frame(width: 3, height: 36)
                    .rotationEffect(.degrees(-(tilt.degrees ?? 15)), anchor: .bottom)
                    .animation(.easeOut(duration: 0.6), value: tilt.degrees)
            }
            .frame(width: 56, height: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text("거치 각도 \(Text(tilt.degrees.map { "\(Int($0))°" } ?? "—").foregroundStyle(angleOK && tilt.degrees != nil ? OrotColor.accent : OrotColor.textPrimary)) \(Text("· 권장 10–20°").font(OrotFont.caption).foregroundStyle(OrotColor.textCaption))")
                    .font(OrotFont.regular(13)).foregroundStyle(OrotColor.textPrimary)
                Text(tilt.degrees == nil ? "책상 위에 10–20° 기울여 세워 주세요." : angleOK ? "좋아요. 세션 중에 조금 움직여도 괜찮아요." : "조금 더 기울이면 얼굴이 가운데로 와요.")
                    .font(OrotFont.caption).foregroundStyle(OrotColor.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .overlay(RoundedRectangle(cornerRadius: OrotRadius.md).strokeBorder(OrotColor.hairline))
    }

    private var checks: some View {
        HStack {
            check("얼굴 감지", faceDetected)
            Spacer()
            check("얼굴 위치", faceCentered)
            Spacer()
            check("거치 각도", angleOK && tilt.degrees != nil)
        }
    }

    private func check(_ title: String, _ ok: Bool) -> some View {
        HStack(spacing: 8) {
            Circle().fill(ok ? OrotColor.accent : .clear)
                .overlay(Circle().strokeBorder(ok ? OrotColor.accent : OrotColor.textCaption))
                .frame(width: 8, height: 8)
            Text(title).font(OrotFont.regular(13)).foregroundStyle(ok ? OrotColor.textPrimary : OrotColor.textSecondary)
        }
        .animation(.easeOut(duration: 0.3), value: ok)
    }
}

// MARK: - Device Tilt
/// 세로로 세운 상태에서 뒤로 기운 각도(°)
@MainActor
final class DeviceTilt: ObservableObject {
    @Published private(set) var degrees: Double?
    private let motion = CMMotionManager()

    func start() {
        guard motion.isDeviceMotionAvailable else { return }
        motion.deviceMotionUpdateInterval = 0.5
        motion.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let g = data?.gravity else { return }
            let angle = atan2(-g.z, -g.y) * 180 / .pi
            self?.degrees = (angle * 2).rounded() / 2
        }
    }

    func stop() {
        motion.stopDeviceMotionUpdates()
    }
}
