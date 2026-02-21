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
    @StateObject private var timerViewModel: TimerViewModel
    @StateObject private var dashboardViewModel: DashboardViewModel

    /// @State: View 내부에서 변하는 단순한 값
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
            // 홈 (대시보드) 탭
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

            // 통계 탭 (학습 기록은 통계 내에서 접근)
            AnalyticsView(viewModel: timerViewModel)
                .tabItem {
                    Image(systemName: "chart.xyaxis.line")
                    Text("통계")
                }
                .tag(2)

            // 설정 탭
            SettingsView(studyPlanStore: timerViewModel.studyPlanStore)
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("설정")
                }
                .tag(3)
        }
        .tint(.orange)
        .onAppear {
            // SwiftData ModelContext를 Store에 주입
            timerViewModel.sessionStore.configure(with: modelContext)
            timerViewModel.studyPlanStore.configure(with: modelContext)
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .preferredColorScheme(.dark)
        .modelContainer(for: [StudySession.self, FocusRecord.self, StudyPlan.self], inMemory: true)
}
