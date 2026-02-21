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
                try? await Task.sleep(for: .seconds(1.8))
                withAnimation(.easeOut(duration: 0.4)) {
                    showSplash = false
                }
            }
        }
        .modelContainer(modelContainer)
    }
}
