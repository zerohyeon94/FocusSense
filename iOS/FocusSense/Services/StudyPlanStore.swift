//
//  StudyPlanStore.swift
//  FocusSense
//
//  학습 계획 CRUD 서비스 (SwiftData 기반)
//

import Foundation
import SwiftData

// MARK: - Study Plan Store
@MainActor
final class StudyPlanStore: ObservableObject {

    // MARK: - Published Properties
    @Published private(set) var plans: [StudyPlan] = []

    // MARK: - SwiftData
    private var modelContext: ModelContext?

    // MARK: - Services
    let notificationService = NotificationService()

    // MARK: - Initialization
    init() {
        print("✅ StudyPlanStore 초기화 (SwiftData)")
    }

    // MARK: - Configure
    func configure(with context: ModelContext) {
        self.modelContext = context
        loadAllPlans()
        print("✅ StudyPlanStore configured: \(plans.count)개 계획 로드")
    }

    // MARK: - Save Plan
    func savePlan(_ plan: StudyPlan) {
        guard let modelContext else {
            print("❌ ModelContext가 설정되지 않았습니다")
            return
        }

        modelContext.insert(plan)

        do {
            try modelContext.save()
            loadAllPlans()

            // 알림 갱신
            if plan.isReminderEnabled {
                notificationService.scheduleNotifications(for: plan)
            }

            print("✅ 학습 계획 저장: \(plan.title)")
        } catch {
            print("❌ 학습 계획 저장 실패: \(error)")
        }
    }

    // MARK: - Update Plan
    func updatePlan(_ plan: StudyPlan) {
        guard let modelContext else { return }

        do {
            try modelContext.save()
            loadAllPlans()

            // 알림 갱신
            notificationService.removeNotifications(for: plan.id)
            if plan.isReminderEnabled && plan.isActive {
                notificationService.scheduleNotifications(for: plan)
            }

            print("✅ 학습 계획 업데이트: \(plan.title)")
        } catch {
            print("❌ 학습 계획 업데이트 실패: \(error)")
        }
    }

    // MARK: - Delete Plan
    func deletePlan(_ plan: StudyPlan) {
        guard let modelContext else { return }

        // 알림 제거
        notificationService.removeNotifications(for: plan.id)

        modelContext.delete(plan)

        do {
            try modelContext.save()
            plans.removeAll { $0.id == plan.id }
            print("✅ 학습 계획 삭제: \(plan.title)")
        } catch {
            print("❌ 학습 계획 삭제 실패: \(error)")
        }
    }

    // MARK: - Load All Plans
    func loadAllPlans() {
        guard let modelContext else { return }

        do {
            let descriptor = FetchDescriptor<StudyPlan>(
                sortBy: [SortDescriptor(\.createdAt, order: .forward)]
            )
            plans = try modelContext.fetch(descriptor)
        } catch {
            print("❌ 학습 계획 로드 실패: \(error)")
            plans = []
        }
    }

    // MARK: - Query Helpers

    /// 오늘 해당하는 계획들
    var todayPlans: [StudyPlan] {
        plans.filter { $0.isScheduledToday }
    }

    /// 활성 계획들
    var activePlans: [StudyPlan] {
        plans.filter { $0.isActive }
    }
}
