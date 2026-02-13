//
//  ContentView.swift
//  FocusSense
//
//  메인 화면 - 탭 네비게이션
//

import SwiftUI
import SwiftData

struct ContentView: View {
    /// @StateObject: 이 View가 ViewModel을 생성하고 소유함
    /// - 이 View가 사라지면 ViewModel도 함께 사라짐
    /// - 자식 View에게는 @ObservedObject로 전달
    @StateObject private var timerViewModel: TimerViewModel
    @StateObject private var dashboardViewModel: DashboardViewModel

    /// @State: View 내부에서 변하는 단순한 값
    /// - 현재 선택된 탭 번호
    /// - 값이 바뀌면 View가 다시 그려짐
    @State private var selectedTab = 0

    /// SwiftData ModelContext (환경에서 주입)
    @Environment(\.modelContext) private var modelContext

    init() {
        let timerVM = TimerViewModel()
        _timerViewModel = StateObject(wrappedValue: timerVM)
        _dashboardViewModel = StateObject(wrappedValue: DashboardViewModel(sessionStore: timerVM.sessionStore))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // 홈/대시보드 탭 (학습 잔디 그래프)
            DashboardView(
                dashboardViewModel: dashboardViewModel,
                selectedTab: $selectedTab
            )
            .tabItem {
                Image(systemName: "house.fill")
                Text("홈")
            }
            .tag(0)

            // 타이머 탭
            TimerView(viewModel: timerViewModel)
                .tabItem {
                    Image(systemName: "timer")
                    Text("타이머")
                }
                .tag(1)

            // 통계 탭
            AnalyticsView(viewModel: timerViewModel)
                .tabItem {
                    Image(systemName: "chart.xyaxis.line")
                    Text("통계")
                }
                .tag(2)

            // 학습 기록 탭
            HistoryView(sessionStore: timerViewModel.sessionStore)
                .tabItem {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("기록")
                }
                .tag(3)

            // 설정 탭
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("설정")
                }
                .tag(4)
        }
        .tint(.orange) // 선택된 탭 색상
        .onAppear {
            // SwiftData ModelContext를 SessionStore에 주입
            timerViewModel.sessionStore.configure(with: modelContext)
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .preferredColorScheme(.dark) // 다크모드로 미리보기
        .modelContainer(for: [StudySession.self, FocusRecord.self], inMemory: true)
}
