//
//  DashboardView.swift
//  FocusSense
//
//  대시보드 홈 화면 - 인사말 + 잔디 그래프 + 빠른 시작
//

import SwiftUI

// MARK: - Dashboard View
struct DashboardView: View {
    @ObservedObject var dashboardViewModel: DashboardViewModel
    @Binding var selectedTab: Int

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 인사말
                    GreetingHeader()

                    // 요약 통계
                    QuickStatsCard(
                        streak: dashboardViewModel.currentStreak,
                        todayTime: dashboardViewModel.todayStudyTime,
                        weekTime: dashboardViewModel.thisWeekStudyTime
                    )

                    // 잔디 그래프
                    ContributionGraphCard(viewModel: dashboardViewModel)

                    // 빠른 시작
                    QuickStartCard {
                        selectedTab = 1 // 타이머 탭으로 이동
                    }
                }
                .padding()
            }
            .background(Color(hex: "0f0f1a"))
            .navigationTitle("Focus")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Greeting Header
struct GreetingHeader: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.title2.bold())
                Text(todayDateString)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "좋은 아침이에요"
        case 12..<17: return "좋은 오후에요"
        case 17..<21: return "좋은 저녁이에요"
        default:      return "늦은 시간 화이팅"
        }
    }

    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        return formatter.string(from: Date())
    }
}
