//
//  SettingsView.swift
//  FocusSense
//
//  앱 설정 화면
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var studyPlanStore: StudyPlanStore

    @AppStorage("hapticEnabled") private var hapticEnabled = true
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("autoPauseEnabled") private var autoPauseEnabled = true
    @AppStorage("drowsinessThreshold") private var drowsinessThreshold = 3.0

    @State private var notificationStatus: String = ""

    var body: some View {
        NavigationStack {
            List {
                // 학습 계획 관리
                Section {
                    NavigationLink {
                        StudyPlanListView(studyPlanStore: studyPlanStore)
                    } label: {
                        HStack {
                            SettingRow(
                                icon: "book.fill",
                                title: "학습 계획 관리",
                                color: .orange
                            )
                            Spacer()
                            Text("\(studyPlanStore.plans.count)개")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // 알림 권한 상태
                    HStack {
                        SettingRow(
                            icon: "bell.badge.fill",
                            title: "학습 알림",
                            color: .green
                        )
                        Spacer()
                        Text(notificationStatus)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("학습 계획")
                } footer: {
                    Text("학습 계획을 등록하면 타이머 시작 시 과목을 선택하고, 설정된 시간에 알림을 받을 수 있습니다.")
                }

                // 알림 설정
                Section {
                    Toggle(isOn: $hapticEnabled) {
                        SettingRow(
                            icon: "iphone.radiowaves.left.and.right",
                            title: "진동 알림",
                            color: .purple
                        )
                    }

                    Toggle(isOn: $soundEnabled) {
                        SettingRow(
                            icon: "speaker.wave.2.fill",
                            title: "소리 알림",
                            color: .orange
                        )
                    }
                } header: {
                    Text("알림")
                }

                // 집중 감지 설정
                Section {
                    Toggle(isOn: $autoPauseEnabled) {
                        SettingRow(
                            icon: "pause.circle.fill",
                            title: "자동 일시정지",
                            color: .blue
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        SettingRow(
                            icon: "moon.zzz.fill",
                            title: "졸음 감지 민감도",
                            color: .red
                        )

                        Slider(value: $drowsinessThreshold, in: 1...5, step: 1) {
                            Text("민감도")
                        }

                        HStack {
                            Text("민감")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("둔감")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("집중 감지")
                } footer: {
                    Text("민감도가 높을수록 작은 변화에도 졸음으로 감지합니다.")
                }

                // 개인정보 안내
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.green)
                            Text("개인정보 보호")
                                .font(.headline)
                        }

                        Text("FocusSense는 모든 영상 분석을 기기 내에서만 처리합니다. 카메라 영상은 절대 외부 서버로 전송되지 않습니다.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("개인정보")
                }

                // 앱 정보
                Section {
                    HStack {
                        Text("버전")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://github.com/zerohyeon94/FocusSense")!) {
                        HStack {
                            SettingRow(
                                icon: "chevron.left.forwardslash.chevron.right",
                                title: "소스 코드",
                                color: .gray
                            )
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("앱 정보")
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await updateNotificationStatus()
            }
        }
    }

    // MARK: - Notification Status
    private func updateNotificationStatus() async {
        let status = await studyPlanStore.notificationService.checkPermissionStatus()
        switch status {
        case .authorized:
            notificationStatus = "허용됨"
        case .denied:
            notificationStatus = "거부됨"
        case .notDetermined:
            notificationStatus = "미설정"
        case .provisional:
            notificationStatus = "임시 허용"
        case .ephemeral:
            notificationStatus = "임시"
        @unknown default:
            notificationStatus = "알 수 없음"
        }
    }
}

// MARK: - Setting Row
struct SettingRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 24)

            Text(title)
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsView(studyPlanStore: StudyPlanStore())
        .preferredColorScheme(.dark)
}
