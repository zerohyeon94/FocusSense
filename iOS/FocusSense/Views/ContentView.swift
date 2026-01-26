//
//  ContentView.swift
//  FocusSense
//
//  메인 화면 - 탭 네비게이션
//

import SwiftUI

struct ContentView: View {
    @StateObject private var timerViewModel = TimerViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 타이머 탭
            TimerView(viewModel: timerViewModel)
                .tabItem {
                    Image(systemName: "timer")
                    Text("타이머")
                }
                .tag(0)
            
            // 통계 탭
            AnalyticsView(viewModel: timerViewModel)
                .tabItem {
                    Image(systemName: "chart.xyaxis.line")
                    Text("통계")
                }
                .tag(1)
            
            // 설정 탭
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("설정")
                }
                .tag(2)
        }
        .tint(.orange)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
