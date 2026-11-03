//
//  FocusSubjectStore.swift
//  Orot
//
//  집중 대상 저장소 (SwiftData)
//

import Foundation
import SwiftData
import Combine
import UserNotifications

@MainActor
final class FocusSubjectStore: ObservableObject {

    @Published private(set) var subjects: [FocusSubject] = []

    private var modelContext: ModelContext?

    // MARK: - Configure

    /// 처음 실행하면 기존 학습 계획 이름을 이관하고, 없으면 기본 대상(학습·업무·과제)을 만듭니다.
    func configure(with context: ModelContext) {
        modelContext = context
        load()
        guard subjects.isEmpty else { return }

        let planTitles = (try? context.fetch(FetchDescriptor<StudyPlan>(sortBy: [SortDescriptor(\.createdAt)])))?
            .map { String($0.title.prefix(FocusSubject.maxNameLength)) } ?? []
        var names: [String] = []
        for title in planTitles + FocusSubject.defaultNames where !names.contains(title) && names.count < FocusSubject.maxCount {
            names.append(title)
        }
        if !planTitles.isEmpty {
            // 학습 계획의 반복 알림은 더 이상 관리할 화면이 없으므로 지웁니다.
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
        for (i, name) in names.enumerated() {
            context.insert(FocusSubject(name: name, order: i))
        }
        save()
        print("✅ 집중 대상 \(names.count)개 준비")
    }

    // MARK: - CRUD

    func add(name: String) {
        guard let modelContext, subjects.count < FocusSubject.maxCount else { return }
        modelContext.insert(FocusSubject(name: String(name.prefix(FocusSubject.maxNameLength)), order: subjects.count))
        save()
    }

    func rename(_ subject: FocusSubject, to name: String) {
        subject.name = String(name.prefix(FocusSubject.maxNameLength))
        save()
    }

    func delete(_ subject: FocusSubject) {
        modelContext?.delete(subject)
        save()
        reindex()
    }

    func move(fromOffsets: IndexSet, toOffset: Int) {
        var list = subjects
        list.move(fromOffsets: fromOffsets, toOffset: toOffset)
        for (i, s) in list.enumerated() { s.order = i }
        save()
    }

    // MARK: - Private

    private func reindex() {
        for (i, s) in subjects.enumerated() { s.order = i }
        save()
    }

    private func save() {
        do {
            try modelContext?.save()
        } catch {
            print("❌ 집중 대상 저장 실패: \(error)")
        }
        load()
    }

    private func load() {
        guard let modelContext else { return }
        subjects = (try? modelContext.fetch(FetchDescriptor<FocusSubject>(sortBy: [SortDescriptor(\.order)]))) ?? []
    }
}
