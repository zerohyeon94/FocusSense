//
//  SettingsView.swift
//  FocusSense
//
//  앱 설정 화면
//

// ============================================================================
// 📚 [파일 개요] SettingsView - 앱 설정 화면
// ============================================================================
//
// 📚 [@AppStorage - UserDefaults 영속 저장]
//   @AppStorage("key")는 UserDefaults를 SwiftUI 프로퍼티 래퍼로 감싼 것입니다.
//   - 값이 변경되면 자동으로 UserDefaults에 저장되고, 앱 재시작 후에도 유지됩니다.
//   - @State처럼 값이 변경되면 View가 자동 갱신됩니다.
//   - 예: @AppStorage("hapticEnabled") var hapticEnabled = true
//     → UserDefaults.standard.bool(forKey: "hapticEnabled")와 동일
//
// 📚 [List + Section 패턴]
//   iOS 설정 앱과 동일한 구조입니다:
//   List {
//       Section("카테고리 제목") { ... 행들 ... }
//       Section("다른 카테고리") { ... 행들 ... }
//   }
//   Section은 시각적 그룹핑과 헤더/푸터 텍스트를 제공합니다.
//
// 📚 [NavigationLink - 푸시 내비게이션]
//   NavigationLink는 탭하면 새 화면을 오른쪽에서 밀어 넣는(push) 내비게이션입니다.
//   NavigationStack 안에서만 동작하며, 자동으로 뒤로가기 버튼이 생성됩니다.
//
// 📚 [.task 수정자 - 비동기 작업]
//   .task { await ... }는 View가 나타날 때 비동기 작업을 실행합니다.
//   .onAppear와 달리 async/await를 직접 사용할 수 있고,
//   View가 사라지면 자동으로 Task가 취소됩니다.
//
// ============================================================================

import SwiftUI

struct SettingsView: View {
    @ObservedObject var studyPlanStore: StudyPlanStore

    @AppStorage("hapticEnabled") private var hapticEnabled = true
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("autoPauseEnabled") private var autoPauseEnabled = true
    @AppStorage("drowsinessThreshold") private var drowsinessThreshold = 3.0
    @AppStorage("contributionDisplayMode") private var contributionDisplayMode = "grass"

    @State private var notificationStatus: String = ""

    /// 각 선택된 모드에 따른 적용
    var selectedIconColor: Color {
        switch contributionDisplayMode {
        case "grass": return .green
        case "constellation": return .yellow
        case "waterDrop": return .cyan
        default: return .gray
        }
    }

    var selectedTitle: String {
        switch contributionDisplayMode {
        case "grass": return "잔디밭"
        case "constellation": return "별자리"
        case "waterDrop": return "물방울"
        default: return ""
        }
    }

    var selectedIcon: String {
        switch contributionDisplayMode {
        case "grass": return "square.grid.3x3.fill"
        case "constellation": return "star.fill"
        case "waterDrop": return "drop.fill"
        default: return ""
        }
    }
    
    var appVersion: String {
        guard let dictionary = Bundle.main.infoDictionary,
              let version = dictionary["CFBundleShortVersionString"] as? String else {
            return "알 수 없음"
        }
        return version
    }

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

                // 화면 표시
                Section {
                    HStack {
                        SettingRow(
                            icon: "paintbrush.fill",
                            title: "학습 그래프 스타일",
                            color: .yellow
                        )
                        
                        Spacer()
                        
                        Menu {
                            Picker("학습 그래프 스타일", selection: $contributionDisplayMode) {
                                Label("잔디밭", systemImage: "square.grid.3x3.fill").tag("grass")
                                Label("별자리", systemImage: "star.fill").tag("constellation")
                                Label("물방울", systemImage: "drop.fill").tag("waterDrop")
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: selectedIcon)
                                    .foregroundColor(selectedIconColor)
                                
                                Text(selectedTitle)
                                    .foregroundColor(.primary)
                                
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                    }
                } header: {
                    Text("화면 표시")
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

                        Text("ZipJoong은 모든 영상 분석을 기기 내에서만 처리합니다. 카메라 영상은 절대 외부 서버로 전송되지 않습니다.")
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
                        Text(appVersion)
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
            .listSectionSpacing(.default) // HIG 기반 최적화 - 유동적으로 변경되도록 구현
            .task { // 화면이 그려질 때, 동작
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

// MARK: - Preview
#Preview {
    SettingsView(studyPlanStore: StudyPlanStore())
        .preferredColorScheme(.dark)
}
