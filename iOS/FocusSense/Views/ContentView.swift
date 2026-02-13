//
//  ContentView.swift
//  FocusSense
//
//  메인 화면 - 탭 네비게이션
//

import SwiftUI

struct ContentView: View {
    /// @StateObject: 이 View가 ViewModel을 생성하고 소유함
    /// - 이 View가 사라지면 ViewModel도 함께 사라짐
    /// - 자식 View에게는 @ObservedObject로 전달
    @StateObject private var timerViewModel = TimerViewModel()
    /// @State: View 내부에서 변하는 단순한 값
    /// - 현재 선택된 탭 번호
    /// - 값이 바뀌면 View가 다시 그려짐
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 타이머 탭
            TimerView(viewModel: timerViewModel) // 자식 View
                .tabItem { // 탭바 아이템 모양
                    Image(systemName: "timer")
                    Text("타이머")
                }
                .tag(0) // 탭의 고유 번호
            
            // 통계 탭
            AnalyticsView(viewModel: timerViewModel)
                .tabItem {
                    Image(systemName: "chart.xyaxis.line")
                    Text("통계")
                }
                .tag(1)

            // 학습 기록 탭
            HistoryView(sessionStore: timerViewModel.sessionStore)
                .tabItem {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("기록")
                }
                .tag(2)

            // 설정 탭
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("설정")
                }
                .tag(3)
        }
        .tint(.orange) // 선택된 탭 색상
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .preferredColorScheme(.dark) // 다크모드로 미리보기
}
