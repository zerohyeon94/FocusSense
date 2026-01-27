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

@main // 앱의 시작지점
struct FocusSenseApp: App {
    
    // @StateObject: 객체를 생성하고 소유함
    @StateObject private var appCoordinator = AppCoordinator()
    
    // body: 앱의 화면 구성 정의
    var body: some Scene {
        WindowGroup { // 앱의 메인 윈도우
            ContentView() // 첫 화면으로 ContentView 사용
                .environmentObject(appCoordinator) // 각 하위 뷰에 접근 가능하게
                .preferredColorScheme(.dark) // 다크 모드를 강제
        }
    }
}
