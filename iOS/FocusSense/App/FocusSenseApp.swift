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

    // SwiftData ModelContainer
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([StudySession.self, FocusRecord.self])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            print("✅ SwiftData ModelContainer 초기화 완료")
        } catch {
            fatalError("❌ SwiftData ModelContainer 생성 실패: \(error)")
        }
    }

    // body: 앱의 화면 구성 정의
    var body: some Scene {
        WindowGroup { // 앱의 메인 윈도우
            ContentView() // 첫 화면으로 ContentView 사용
                .environmentObject(appCoordinator) // 각 하위 뷰에 접근 가능하게
                .preferredColorScheme(.dark) // 다크 모드를 강제
        }
        .modelContainer(modelContainer) // SwiftData 컨테이너 전달
    }
}
