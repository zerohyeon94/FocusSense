//
//  StudyPlanStore.swift
//  FocusSense
//
//  학습 계획 CRUD 서비스 (SwiftData 기반)
//

// ============================================================================
// 📚 파일 개요: StudyPlanStore
// ============================================================================
// 이 파일은 학습 계획(StudyPlan) 데이터의 CRUD를 중앙 관리하는 Store입니다.
//
// 📚 Store 패턴이란?
// "데이터의 모든 읽기/쓰기 작업을 하나의 클래스에서 관리하는 패턴"
//   - Create: savePlan() → 새 학습 계획 생성
//   - Read:   loadAllPlans(), todayPlans, activePlans → 데이터 조회
//   - Update: updatePlan() → 기존 계획 수정
//   - Delete: deletePlan() → 계획 삭제
//
// 📚 왜 Store 패턴을 사용하는가?
//   - ViewModel이 직접 SwiftData에 접근하면 코드가 분산되고 중복됨
//   - Store가 데이터 접근을 캡슐화하면, ViewModel은 "무엇을 할지"만 알면 됨
//   - 테스트 시 Store를 Mock으로 교체하면 DB 없이 테스트 가능
//
// 📚 StudySessionStore와의 차이:
//   - StudySessionStore: 읽기 중심 (세션은 타이머가 끝나면 한 번 저장)
//   - StudyPlanStore: CRUD 전부 활발 (사용자가 계획을 수시로 생성/수정/삭제)
//   - StudyPlanStore는 추가로 NotificationService와 연동하여 알림을 관리
//
// 📚 아키텍처 흐름:
//    View → ViewModel → StudyPlanStore → SwiftData (저장)
//                              ↓
//                     NotificationService (알림)
// ============================================================================

import Foundation
import SwiftData

// MARK: - Study Plan Store

// 📚 @MainActor + ObservableObject 조합은 StudySessionStore와 동일한 패턴.
// 이 조합이 iOS 앱에서 "데이터를 관리하고 UI에 반영하는 서비스"의 표준 패턴.
// 자세한 설명은 StudySessionStore.swift 참고.
@MainActor
final class StudyPlanStore: ObservableObject {

    // MARK: - Published Properties
    @Published private(set) var plans: [StudyPlan] = []

    // MARK: - SwiftData
    private var modelContext: ModelContext?

    // MARK: - Services

    // 📚 let vs var — 불변 vs 가변
    // notificationService가 let(상수)인 이유:
    //   - 한 번 생성된 후 교체할 필요가 없음 (항상 같은 알림 서비스를 사용)
    //   - let으로 선언하면 "이 객체는 변경되지 않는다"는 의도를 명확히 전달
    //   - 반면 modelContext는 var(변수): configure()에서 나중에 할당되므로 변경 가능해야 함
    //
    // 📚 참조 타입(class)의 let:
    // let으로 선언해도 내부 프로퍼티는 변경 가능! (참조가 고정될 뿐)
    //   → notificationService의 내부 상태는 자유롭게 변경됨
    //   → let은 "다른 NotificationService 인스턴스로 교체 불가"라는 뜻
    let notificationService = NotificationService()

    // MARK: - Initialization
    init() {
        print("✅ StudyPlanStore 초기화 (SwiftData)")
    }

    // MARK: - Configure
    func configure(with context: ModelContext) {
        self.modelContext = context
        Task {
            loadAllPlans()
            print("✅ StudyPlanStore configured: \(plans.count)개 계획 로드")
            await notificationService.refreshAllNotifications(plans: plans)
        }
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

            // 📚 조건부 비동기 실행 패턴
            // 알림이 활성화된 계획만 알림을 등록함.
            // Task { }로 감싸는 이유: scheduleNotifications()가 async 함수이기 때문.
            // 저장(save) 자체는 동기적으로 완료되고, 알림 등록은 비동기로 별도 진행.
            // → 사용자에게 "저장 완료" 피드백을 빠르게 보여주고,
            //   알림 등록은 뒤에서 조용히 처리하는 UX 전략

            // 알림 스케줄 (비동기 - 권한 확인 포함)
            if plan.isReminderEnabled {
                Task {
                    await notificationService.scheduleNotifications(for: plan)
                }
            }

            print("✅ 학습 계획 저장: \(plan.title)")
        } catch {
            print("❌ 학습 계획 저장 실패: \(error)")
        }
    }

    // MARK: - Update Plan

    // 📚 Update vs Save의 차이
    // savePlan(): modelContext.insert() → 새 객체를 DB에 추가
    // updatePlan(): insert 없이 바로 save() → 이미 context에 있는 객체의 변경사항을 반영
    //
    // SwiftData에서 @Model 객체의 프로퍼티를 수정하면,
    // ModelContext가 자동으로 "변경됨"을 추적(dirty tracking).
    // save()를 호출하면 추적된 변경사항만 DB에 반영.
    func updatePlan(_ plan: StudyPlan) {
        guard let modelContext else { return }

        do {
            try modelContext.save()
            loadAllPlans()

            // 📚 알림 업데이트 전략: "제거 후 재등록"
            // 기존 알림을 수정하는 API는 없으므로:
            //   1. 기존 알림 제거 (removeNotifications)
            //   2. 조건에 맞으면 새로 등록 (scheduleNotifications)
            // 이 패턴은 알림 상태를 항상 최신으로 유지하는 가장 안전한 방법

            // 알림 갱신 (비동기 - 권한 확인 포함)
            notificationService.removeNotifications(for: plan.id)
            if plan.isReminderEnabled && plan.isActive {
                Task {
                    await notificationService.scheduleNotifications(for: plan)
                }
            }

            print("✅ 학습 계획 업데이트: \(plan.title)")
        } catch {
            print("❌ 학습 계획 업데이트 실패: \(error)")
        }
    }

    // MARK: - Delete Plan
    func deletePlan(_ plan: StudyPlan) {
        guard let modelContext else { return }

        // 📚 삭제 순서가 중요한 이유:
        // 1. 먼저 알림 제거 → plan.id가 아직 유효할 때 알림을 찾아서 제거
        // 2. 그 다음 DB에서 삭제 → modelContext.delete() + save()
        // 3. 마지막으로 로컬 배열에서 제거 → UI 즉시 반영
        // 만약 DB 삭제를 먼저 하면, plan.id에 접근할 수 없어서 알림 제거 불가

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
            // 📚 SortDescriptor의 .forward vs .reverse
            // .forward: 오름차순 (과거 → 미래, 작은 → 큰)
            // .reverse: 내림차순 (미래 → 과거, 큰 → 작은)
            // 여기서는 생성 순서(.forward)로 정렬 → 먼저 만든 계획이 위에 표시
            // (StudySessionStore는 .reverse → 최근 세션이 위에 표시)
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

    // 📚 Computed Property를 이용한 필터링 헬퍼
    // 매번 plans.filter { ... }를 View에서 직접 쓰는 대신,
    // 의미 있는 이름의 프로퍼티로 제공하면:
    //   - 코드 가독성 향상: todayPlans vs plans.filter { $0.isScheduledToday }
    //   - 비즈니스 로직의 중앙화: 필터 조건이 변경되면 한곳만 수정
    //   - View 코드 간결화: View는 단순히 store.todayPlans만 참조

    /// 오늘 해당하는 계획들
    var todayPlans: [StudyPlan] {
        plans.filter { $0.isScheduledToday }
    }

    /// 활성 계획들
    var activePlans: [StudyPlan] {
        plans.filter { $0.isActive }
    }
}
