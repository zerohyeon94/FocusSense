//
//  StudyPlanPickerView.swift
//  FocusSense
//
//  타이머 시작 시 학습 계획 선택 시트
//

// ============================================================================
// 📚 [파일 개요] StudyPlanPickerView - 타이머 시작 시 학습 계획 선택 시트 모달
// ============================================================================
//
// 시트 모달 역할:
//   사용자가 타이머를 시작할 때 .sheet()로 표시되는 하프 시트이다.
//   오늘 예정된 학습 계획을 우선 표시하고, 나머지 전체 계획도 선택할 수 있다.
//   "계획 없이 시작" 옵션으로 계획 선택을 건너뛸 수도 있다.
//
// 클로저 패턴 (onSelect: (StudyPlan?) -> Void):
//   부모 뷰와의 통신에 클로저를 사용한다. 계획을 선택하면 해당 StudyPlan을,
//   "계획 없이 시작"을 선택하면 nil을 전달한다.
//   이 패턴은 자식 뷰가 부모의 구체적인 타입을 알 필요 없이 결과만 전달할 수 있게 한다.
//
// @Environment(\.dismiss):
//   SwiftUI가 제공하는 환경 값으로, 현재 시트/모달을 닫는 액션이다.
//   dismiss()를 호출하면 .sheet()를 표시한 부모의 isPresented 바인딩이 false로 변경된다.
//   각 선택 버튼에서 onSelect 호출 후 dismiss()를 함께 호출하여 시트를 닫는다.
//
// .presentationDetents (참고):
//   SwiftUI의 .presentationDetents([.medium, .large])를 사용하면
//   시트의 높이를 반절(하프 시트) 또는 전체로 제한할 수 있다.
//   이 뷰를 호출하는 쪽에서 detents를 설정하여 하프 시트로 표시한다.
//
// ============================================================================

import SwiftUI

// MARK: - Study Plan Picker View
struct StudyPlanPickerView: View {
    @ObservedObject var studyPlanStore: StudyPlanStore
    let onSelect: (StudyPlan?) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 오늘의 계획
                if !studyPlanStore.todayPlans.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.green)
                                Text("오늘의 학습")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            .padding(.top, 16)

                            ForEach(studyPlanStore.todayPlans) { plan in
                                PlanPickerRow(plan: plan, isToday: true) {
                                    onSelect(plan)
                                    dismiss()
                                }
                            }
                        }
                    }

                    Divider()
                        .padding(.vertical, 8)
                }

                // 전체 계획
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        if studyPlanStore.plans.count > studyPlanStore.todayPlans.count {
                            HStack {
                                Image(systemName: "list.bullet")
                                    .foregroundColor(.secondary)
                                Text("전체 학습 계획")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)

                            let otherPlans = studyPlanStore.plans.filter { !$0.isScheduledToday }
                            ForEach(otherPlans) { plan in
                                PlanPickerRow(plan: plan, isToday: false) {
                                    onSelect(plan)
                                    dismiss()
                                }
                            }
                        }
                    }
                }

                Divider()

                // 계획 없이 시작
                Button {
                    onSelect(nil)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "play.circle")
                            .foregroundColor(.secondary)
                        Text("계획 없이 시작")
                            .font(.body)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding()
                    .background(Color.white.opacity(0.03))
                }
            }
            .navigationTitle("학습 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Plan Picker Row
struct PlanPickerRow: View {
    let plan: StudyPlan
    let isToday: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // 색상 원
                Circle()
                    .fill(plan.color)
                    .frame(width: 14, height: 14)

                // 제목
                Text(plan.title)
                    .font(.body.weight(.medium))
                    .foregroundColor(.primary)

                Spacer()

                // 반복 요약
                Text(plan.recurrenceSummary)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isToday ? plan.color.opacity(0.1) : Color.white.opacity(0.03))
            )
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }
}
