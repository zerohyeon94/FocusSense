//
//  StudyPlanPickerView.swift
//  FocusSense
//
//  타이머 시작 시 학습 계획 선택 시트
//

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
