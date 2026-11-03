//
//  StartCheckSheet.swift
//  Orot
//
//  시작 직전 확인 — 카메라 미리보기로 거치 상태를 보고, 감지 없이 시작할 수도 있습니다.
//

import SwiftUI

struct StartCheckSheet: View {
    @ObservedObject var viewModel: TimerViewModel
    @ObservedObject var camera: CameraService
    let minutes: Int
    let subjectName: String
    let onStart: (_ detection: Bool) -> Void

    private var faceDetected: Bool { viewModel.currentFocusState.isFaceDetected }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(subjectName) · \(minutes)분")
                    .font(OrotFont.caption)
                    .tracking(0.5)
                    .foregroundStyle(OrotColor.textCaption)
                Text("얼굴이 잘 보이게 거치해 주세요")
                    .font(OrotFont.title)
                    .foregroundStyle(OrotColor.textPrimary)
            }
            .padding(.top, 32)

            previewCard.padding(.top, 20)

            HStack(spacing: 24) {
                check("카메라", ok: camera.isRunning)
                check("얼굴 위치", ok: faceDetected)
                Spacer()
                if viewModel.needsCalibration {
                    Button("기준 맞추기") { viewModel.showCalibrationView = true }
                        .font(OrotFont.regular(13))
                        .foregroundStyle(OrotColor.accent)
                }
            }
            .padding(.top, 16)

            Spacer(minLength: 16)

            VStack(spacing: 4) {
                Button("\(subjectName) \(minutes)분 시작") { onStart(true) }
                    .buttonStyle(OrotPrimaryButtonStyle())
                Button("감지 없이 시작하기") { onStart(false) }
                    .buttonStyle(OrotTextButtonStyle())
                Text("감지 없이 시작하면 별은 기본 밝기(3등급)로 떠요")
                    .font(OrotFont.caption)
                    .foregroundStyle(OrotColor.textCaption)
            }
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 24)
        .background(OrotColor.surfaceRaised.ignoresSafeArea())
        .presentationDetents([.height(470)])
        .presentationDragIndicator(.visible)
        .presentationBackground(OrotColor.surfaceRaised)
        .onAppear { viewModel.startPreview() }
        .fullScreenCover(isPresented: $viewModel.showCalibrationView, onDismiss: { viewModel.startPreview() }) {
            FaceAlignView(viewModel: viewModel, camera: camera, mode: .settings) {}
        }
    }

    // MARK: - Preview Card
    private var previewCard: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle().fill(Color(hex: 0x0C0E10))
                if let session = viewModel.captureSession {
                    CameraPreviewView(session: session)
                        .clipShape(Circle())
                }
                Circle().strokeBorder(faceDetected ? OrotColor.accent : OrotColor.hairline, lineWidth: 2)
            }
            .frame(width: 84, height: 84)
            .animation(.easeOut(duration: 0.6), value: faceDetected)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    BreathingDot()
                    Text("자리 감지 켜짐")
                        .font(OrotFont.regular(14))
                        .foregroundStyle(OrotColor.textPrimary)
                }
                Text(faceDetected ? "얼굴이 잘 보여요" : "얼굴을 찾고 있어요")
                    .font(OrotFont.regular(13))
                    .foregroundStyle(faceDetected ? OrotColor.accent : OrotColor.textSecondary)
                Text("기기 안에서만 처리")
                    .font(OrotFont.caption)
                    .foregroundStyle(OrotColor.textCaption)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .overlay(RoundedRectangle(cornerRadius: OrotRadius.md).strokeBorder(OrotColor.hairline))
    }

    private func check(_ title: String, ok: Bool) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(ok ? OrotColor.accent : .clear)
                .overlay(Circle().strokeBorder(ok ? OrotColor.accent : OrotColor.textCaption))
                .frame(width: 8, height: 8)
            Text(title)
                .font(OrotFont.regular(13))
                .foregroundStyle(ok ? OrotColor.textPrimary : OrotColor.textSecondary)
        }
    }
}

// MARK: - Breathing Dot
struct BreathingDot: View {
    @State private var on = false

    var body: some View {
        Circle()
            .fill(OrotColor.accent)
            .frame(width: 6, height: 6)
            .opacity(on ? 1 : 0.45)
            .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: on)
            .onAppear { on = true }
    }
}
