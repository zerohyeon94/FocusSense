//
//  DashboardView.swift
//  FocusSense
//
//  대시보드 홈 화면 - 학습 잔디 그래프 및 요약 통계
//

import SwiftUI
import SwiftData

// MARK: - Dashboard View
struct DashboardView: View {
    @ObservedObject var dashboardViewModel: DashboardViewModel
    @Binding var selectedTab: Int

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 인사말 헤더
                    GreetingHeader()

                    // 빠른 통계 (연속일수 | 오늘 | 이번 주)
                    QuickStatsCard(viewModel: dashboardViewModel)

                    // GitHub 잔디 스타일 학습 활동 그래프
                    ContributionGraphCard(viewModel: dashboardViewModel)

                    // 학습 시작 버튼
                    QuickStartCard(selectedTab: $selectedTab)
                }
                .padding()
            }
            .background(Color(hex: "0f0f1a"))
            .navigationTitle("홈")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            dashboardViewModel.computeContributionData()
        }
    }
}

// MARK: - Greeting Header
struct GreetingHeader: View {
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "좋은 아침이에요"
        case 12..<17: return "좋은 오후에요"
        case 17..<21: return "좋은 저녁이에요"
        default: return "늦은 밤이에요"
        }
    }

    private var greetingIcon: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "sun.max.fill"
        case 12..<17: return "sun.min.fill"
        case 17..<21: return "moon.haze.fill"
        default: return "moon.stars.fill"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: greetingIcon)
                .font(.title2)
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(greetingText)
                    .font(.title3.bold())
                Text("오늘도 집중해볼까요?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Preview
#Preview {
    DashboardView(
        dashboardViewModel: DashboardViewModel(sessionStore: StudySessionStore()),
        selectedTab: .constant(0)
    )
    .preferredColorScheme(.dark)
    .modelContainer(for: [StudySession.self, FocusRecord.self], inMemory: true)
}
