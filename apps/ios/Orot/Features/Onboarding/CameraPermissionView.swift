//
//  CameraPermissionView.swift
//  Orot
//
//  카메라 권한 (2-1 요청 · 2-2 거부 시 선택). 거부해도 타이머로만 쓸 수 있습니다.
//

import SwiftUI
import AVFoundation

struct CameraPermissionView: View {
    @ObservedObject var camera: CameraService
    /// true: 카메라 사용 가능 → 얼굴 맞추기 / false: 타이머만 사용
    let onResult: (Bool) -> Void

    @AppStorage(OrotSettings.Key.detectionEnabled) private var detectionEnabled = true
    @Environment(\.scenePhase) private var scenePhase
    @State private var denied = false
    @State private var choice = 0

    var body: some View {
        ZStack {
            OrotColor.skyNight.ignoresSafeArea()
            if denied { deniedView } else { requestView }
        }
        .onAppear {
            switch camera.authorizationStatus {
            case .authorized: onResult(true)
            case .denied, .restricted: denied = true
            default: break
            }
        }
        .onChange(of: scenePhase) { _, phase in
            // 설정 앱에서 켜고 돌아오면 이어서 맞춥니다.
            if phase == .active, denied, camera.authorizationStatus == .authorized {
                camera.checkPermission()
                detectionEnabled = true
                onResult(true)
            }
        }
    }

    // MARK: - 2-1
    private var requestView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("카메라 설정 · 1 / 2").font(OrotFont.caption).tracking(0.5).foregroundStyle(OrotColor.textCaption)
            Text("자리 확인을 위해\n카메라를 켤게요").font(OrotFont.light(28)).lineSpacing(4).foregroundStyle(OrotColor.textPrimary)
            Text("다음 알림에서 '허용'을 눌러 주세요. 영상은 기기 안에서만 처리되며 저장하거나 전송하지 않아요.")
                .font(OrotFont.body).lineSpacing(6).foregroundStyle(OrotColor.textSecondary)
            Spacer()
            Button("계속") {
                Task {
                    let granted = await camera.requestPermission()
                    if granted {
                        detectionEnabled = true
                        onResult(true)
                    } else {
                        denied = true
                    }
                }
            }
            .buttonStyle(OrotPrimaryButtonStyle())
        }
        .padding(.horizontal, 32)
        .padding(.top, 70)
        .padding(.bottom, 24)
    }

    // MARK: - 2-2
    private var deniedView: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                Text("카메라 없이도\n시작할 수 있어요").font(OrotFont.light(28)).lineSpacing(4).foregroundStyle(OrotColor.textPrimary)
                Text("카메라가 꺼져 있어서 자리를 확인할 수 없어요. 어떻게 할지 골라 주세요.")
                    .font(OrotFont.body).lineSpacing(6).foregroundStyle(OrotColor.textSecondary)
            }
            .padding(.horizontal, 8)

            VStack(spacing: 12) {
                option(0, "타이머만 사용하기", "정한 시간을 그대로 재고, 마치면 별이 떠요. 자리 확인을 하지 않아서 별은 기본 밝기(3등급)로 떠요.")
                option(1, "카메라 다시 켜기", "설정 › 오롯 › 카메라에서 켤 수 있어요. 켜고 돌아오면 이어서 맞춰 드릴게요.")
            }
            .padding(.top, 40)

            Spacer()
            VStack(spacing: 12) {
                Button(choice == 0 ? "타이머로 시작하기" : "설정 열기") {
                    if choice == 0 {
                        detectionEnabled = false
                        onResult(false)
                    } else if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(OrotPrimaryButtonStyle())
                Text("나중에 설정에서 언제든 바꿀 수 있어요").font(OrotFont.caption).tracking(0.5).foregroundStyle(OrotColor.textCaption)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 70)
        .padding(.bottom, 24)
    }

    private func option(_ index: Int, _ title: String, _ detail: String) -> some View {
        let on = choice == index
        return Button { choice = index } label: {
            HStack(alignment: .top, spacing: 12) {
                Circle().strokeBorder(on ? OrotColor.accent : OrotColor.hairline)
                    .overlay(Circle().fill(on ? OrotColor.accent : .clear).frame(width: 8, height: 8))
                    .frame(width: 16, height: 16).padding(.top, 2)
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(OrotFont.body).foregroundStyle(OrotColor.textPrimary)
                    Text(detail).font(OrotFont.regular(13)).lineSpacing(3).foregroundStyle(OrotColor.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(18)
            .background(RoundedRectangle(cornerRadius: OrotRadius.md).fill(on ? OrotColor.accentSubtle.opacity(0.6) : .clear))
            .overlay(RoundedRectangle(cornerRadius: OrotRadius.md).strokeBorder(on ? OrotColor.accent : OrotColor.hairline))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(OrotMotion.tap, value: choice)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}
