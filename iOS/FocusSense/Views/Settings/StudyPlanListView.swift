//
//  StudyPlanListView.swift
//  FocusSense
//
//  학습 계획 관리 화면
//

// ============================================================================
// 📚 [파일 개요] StudyPlanListView - 학습 계획 CRUD 관리 화면
// ============================================================================
//
// CRUD 흐름:
//   Create: + 버튼 → editingPlan = nil → showingEditSheet = true → 새 계획 생성
//   Read:   List + ForEach로 studyPlanStore.plans를 순회하며 표시
//   Update: 행 탭 → editingPlan = plan → showingEditSheet = true → 기존 계획 편집
//   Delete: 스와이프 → .onDelete(perform:) → deletePlans(at:) → 계획 삭제
//
// List + ForEach + .onDelete 패턴:
//   SwiftUI의 List 안에 ForEach를 넣고 .onDelete 수식어를 추가하면
//   자동으로 스와이프-투-딜리트 기능이 활성화된다.
//   onDelete는 IndexSet을 전달하며, 이를 통해 삭제할 항목의 인덱스를 알 수 있다.
//
// .sheet를 이용한 모달 표시:
//   showingEditSheet 바인딩이 true가 되면 StudyPlanEditSheet가 모달로 표시된다.
//   시트가 닫히면 자동으로 false로 돌아간다.
//
// 편집 vs 생성 분기 (editingPlan: StudyPlan?):
//   editingPlan이 nil이면 "새 학습 계획" 생성 모드로 동작한다.
//   editingPlan에 기존 객체가 있으면 "학습 계획 편집" 모드로 동작한다.
//   하나의 StudyPlanEditSheet로 생성과 편집을 모두 처리하는 패턴이다.
//
// Form + Section으로 설정 스타일 입력:
//   StudyPlanEditSheet는 Form { Section("제목") { ... } } 구조를 사용한다.
//   Form은 iOS 설정 앱과 동일한 그룹화된 입력 UI를 자동으로 만들어준다.
//   Section은 관련 입력 필드를 논리적으로 묶고 헤더 텍스트를 표시한다.
//
// ============================================================================

import SwiftUI

// MARK: - Study Plan List View
struct StudyPlanListView: View {
    @ObservedObject var studyPlanStore: StudyPlanStore
    @State private var showingEditSheet = false
    @State private var editingPlan: StudyPlan?

    var body: some View {
        Group {
            if studyPlanStore.plans.isEmpty {
                emptyState
            } else {
                planList
            }
        }
        .navigationTitle("학습 계획")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editingPlan = nil
                    showingEditSheet = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.orange)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            StudyPlanEditSheet(
                studyPlanStore: studyPlanStore,
                editingPlan: editingPlan
            )
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("등록된 학습 계획이 없습니다")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("학습 계획을 등록하면\n타이머 시작 시 과목을 선택할 수 있습니다")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)

            Button {
                editingPlan = nil
                showingEditSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("학습 계획 추가")
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule().fill(Color.orange)
                )
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Plan List
    private var planList: some View {
        List {
            ForEach(studyPlanStore.plans) { plan in
                StudyPlanRow(plan: plan)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingPlan = plan
                        showingEditSheet = true
                    }
            }
            .onDelete(perform: deletePlans)
        }
        .listStyle(.insetGrouped)
    }

    private func deletePlans(at offsets: IndexSet) {
        for index in offsets {
            studyPlanStore.deletePlan(studyPlanStore.plans[index])
        }
    }
}

// MARK: - Study Plan Row
struct StudyPlanRow: View {
    let plan: StudyPlan

    var body: some View {
        HStack(spacing: 14) {
            // 색상 원
            Circle()
                .fill(plan.color)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                // 제목
                Text(plan.title)
                    .font(.body.weight(.medium))

                // 반복 일정
                HStack(spacing: 8) {
                    Label(plan.recurrenceSummary, systemImage: "repeat")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if plan.isReminderEnabled {
                        Label(plan.reminderTimeString, systemImage: "bell.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }

            Spacer()

            // 오늘 해당 여부
            if plan.isScheduledToday {
                Text("오늘")
                    .font(.caption2.bold())
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(Color.green.opacity(0.2))
                    )
            }

            if !plan.isActive {
                Text("비활성")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Study Plan Edit Sheet
struct StudyPlanEditSheet: View {
    @ObservedObject var studyPlanStore: StudyPlanStore
    var editingPlan: StudyPlan?
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var selectedColorHex: String = "FF6B35"
    @State private var isDaily: Bool = true
    @State private var selectedWeekdays: Set<Int> = []
    @State private var isReminderEnabled: Bool = false
    @State private var reminderTime: Date = {
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    @State private var isActive: Bool = true

    private let weekdayNames = ["일", "월", "화", "수", "목", "금", "토"]

    var body: some View {
        NavigationStack {
            Form {
                // MARK: 기본 정보
                Section("기본 정보") {
                    TextField("학습 과목명", text: $title)

                    // 색상 선택
                    VStack(alignment: .leading, spacing: 8) {
                        Text("색상")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack(spacing: 12) {
                            ForEach(StudyPlan.presetColors, id: \.hex) { preset in
                                Circle()
                                    .fill(Color(hex: preset.hex))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(
                                                selectedColorHex == preset.hex ? Color.white : Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                                    .onTapGesture {
                                        selectedColorHex = preset.hex
                                    }
                            }
                        }
                    }
                }

                // MARK: 반복 설정
                Section("반복 설정") {
                    Picker("반복", selection: $isDaily) {
                        Text("매일").tag(true)
                        Text("요일 선택").tag(false)
                    }
                    .pickerStyle(.segmented)

                    if !isDaily {
                        HStack(spacing: 8) {
                            ForEach(0..<7, id: \.self) { index in
                                let weekday = index == 0 ? 1 : index + 1 // 일=1, 월=2, ...토=7
                                WeekdayToggle(
                                    name: weekdayNames[index],
                                    isSelected: selectedWeekdays.contains(weekday)
                                ) {
                                    if selectedWeekdays.contains(weekday) {
                                        selectedWeekdays.remove(weekday)
                                    } else {
                                        selectedWeekdays.insert(weekday)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // MARK: 알림 설정
                Section("알림") {
                    Toggle("학습 알림", isOn: $isReminderEnabled)

                    if isReminderEnabled {
                        DatePicker(
                            "알림 시간",
                            selection: $reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                    }
                }

                // MARK: 활성 상태
                if editingPlan != nil {
                    Section {
                        Toggle("활성", isOn: $isActive)
                    }
                }
            }
            .navigationTitle(editingPlan == nil ? "새 학습 계획" : "학습 계획 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        savePlan()
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                loadExistingPlan()
            }
        }
    }

    // MARK: - Load Existing Plan
    private func loadExistingPlan() {
        guard let plan = editingPlan else { return }

        title = plan.title
        selectedColorHex = plan.colorHex
        isActive = plan.isActive
        isReminderEnabled = plan.isReminderEnabled

        switch plan.recurrenceType {
        case .daily:
            isDaily = true
            selectedWeekdays = []
        case .weekdays(let days):
            isDaily = false
            selectedWeekdays = Set(days)
        }

        if plan.isReminderEnabled {
            var components = DateComponents()
            components.hour = plan.reminderHour
            components.minute = plan.reminderMinute
            reminderTime = Calendar.current.date(from: components) ?? Date()
        }
    }

    // MARK: - Save Plan
    private func savePlan() {
        let recurrence: RecurrenceType = isDaily ? .daily : .weekdays(Array(selectedWeekdays).sorted())
        let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)

        // 알림이 활성화된 경우, 권한을 먼저 요청한 후 저장
        if isReminderEnabled {
            Task {
                // 1. 먼저 권한 요청
                let granted = await studyPlanStore.notificationService.requestPermission()
                if !granted {
                    print("⚠️ 알림 권한이 거부되어 알림 없이 저장합니다")
                }

                // 2. 권한 확인 후 저장 (MainActor에서 실행)
                await MainActor.run {
                    performSave(recurrence: recurrence, timeComponents: timeComponents)
                }
            }
        } else {
            performSave(recurrence: recurrence, timeComponents: timeComponents)
        }
    }

    /// 실제 저장 수행
    private func performSave(recurrence: RecurrenceType, timeComponents: DateComponents) {
        if let plan = editingPlan {
            // 기존 계획 업데이트
            plan.title = title.trimmingCharacters(in: .whitespaces)
            plan.colorHex = selectedColorHex
            plan.recurrenceType = recurrence
            plan.reminderHour = timeComponents.hour ?? 9
            plan.reminderMinute = timeComponents.minute ?? 0
            plan.isReminderEnabled = isReminderEnabled
            plan.isActive = isActive
            studyPlanStore.updatePlan(plan)
        } else {
            // 새 계획 생성
            let plan = StudyPlan(
                title: title.trimmingCharacters(in: .whitespaces),
                colorHex: selectedColorHex,
                recurrenceType: recurrence,
                reminderHour: timeComponents.hour ?? 9,
                reminderMinute: timeComponents.minute ?? 0,
                isReminderEnabled: isReminderEnabled
            )
            studyPlanStore.savePlan(plan)
        }
    }
}

// MARK: - Weekday Toggle Button
struct WeekdayToggle: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.caption.bold())
                .foregroundColor(isSelected ? .white : .secondary)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(isSelected ? Color.orange : Color.white.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        StudyPlanListView(studyPlanStore: StudyPlanStore())
    }
    .preferredColorScheme(.dark)
}
