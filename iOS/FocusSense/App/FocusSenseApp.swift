//
//  FocusSenseApp.swift
//  FocusSense
//
//  AI-Powered Focus Tracking Study Timer
//

/// 해당 파일의 중점
/// 앱 실행 흐름:
/// @main → FocusSenseApp → body → WindowGroup → ContentView()

import SwiftUI
import SwiftData
import UserNotifications

@main // 앱의 시작지점
struct FocusSenseApp: App {

    // @StateObject: 객체를 생성하고 소유함
    @StateObject private var appCoordinator = AppCoordinator()

    // 스플래시 표시 상태
    @State private var showSplash = true

    // SwiftData ModelContainer
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                StudySession.self,
                FocusRecord.self,
                StudyPlan.self
            ])
            let config = ModelConfiguration(schema: schema)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("❌ ModelContainer 초기화 실패: \(error)")
        }
    }

    // body: 앱의 화면 구성 정의
    var body: some Scene {
        WindowGroup { // 앱의 메인 윈도우
            ZStack {
                ContentView()
                    .environmentObject(appCoordinator)
                    .preferredColorScheme(.dark)

                // 스플래시 오버레이
                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .task {
                // 앱 시작 시 알림 권한 상태 확인
                await requestNotificationPermissionIfNeeded()

                try? await Task.sleep(for: .seconds(1.8))
                withAnimation(.easeOut(duration: 0.4)) {
                    showSplash = false
                }
            }
        }
        .modelContainer(modelContainer)
    }

    // MARK: - Notification Permission

    /// 앱 시작 시 알림 권한 확인 (이미 학습 계획에 알림이 설정되어 있으면 권한 요청)
    private func requestNotificationPermissionIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .notDetermined:
            // 아직 권한을 요청하지 않은 경우, 알림 계획이 있을 때만 요청
            // (configure 전이므로 pending requests로 확인)
            let pendingRequests = await center.pendingNotificationRequests()
            if !pendingRequests.isEmpty {
                _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
            }
        case .denied:
            print("⚠️ 알림 권한이 거부되어 있습니다. 설정에서 변경해주세요.")
        case .authorized, .provisional, .ephemeral:
            print("✅ 알림 권한 확인됨")
        @unknown default:
            break
        }
    }
}
