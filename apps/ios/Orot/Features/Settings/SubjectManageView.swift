//
//  SubjectManageView.swift
//  Orot
//
//  집중 대상 관리 (5-2) — 이름 바로 고치기, ≡ 끌어서 순서 바꾸기, 지우면 되돌리기
//

import SwiftUI

struct SubjectManageView: View {
    @ObservedObject var subjectStore: FocusSubjectStore
    @ObservedObject var sessionStore: StudySessionStore

    @State private var undoName: String?
    @State private var undoTask: Task<Void, Never>?
    @State private var lastDeleted: (name: String, order: Int)?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("집중 대상").font(OrotFont.regular(17)).foregroundStyle(OrotColor.textPrimary)
                HStack {
                    Button { dismiss() } label: {
                        Text("‹ 설정").font(OrotFont.regular(15)).foregroundStyle(OrotColor.textSecondary).frame(height: 44).padding(.horizontal, 14)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
            }
            .frame(height: 52)
            .overlay(alignment: .bottom) { Rectangle().fill(OrotColor.hairline).frame(height: 1) }

            List {
                Section {
                    ForEach(subjectStore.subjects) { subject in
                        SubjectRow(subject: subject, sessionCount: sessionCount(subject.name), store: subjectStore) {
                            delete(subject)
                        }
                    }
                    .onMove { subjectStore.move(fromOffsets: $0, toOffset: $1) }
                    .listRowBackground(OrotColor.surfaceRaised)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 6))

                    if subjectStore.subjects.count < FocusSubject.maxCount {
                        Button { subjectStore.add(name: "새 대상") } label: {
                            HStack(spacing: 12) {
                                Text("+").font(OrotFont.regular(15)).foregroundStyle(OrotColor.skyNight)
                                    .frame(width: 20, height: 20).background(Circle().fill(OrotColor.accent))
                                Text("대상 추가").font(OrotFont.body).foregroundStyle(OrotColor.accent)
                            }
                        }
                        .listRowBackground(OrotColor.surfaceRaised)
                    }
                } header: {
                    Text("세션 설정에 보이는 순서예요 · \(subjectStore.subjects.count) / \(FocusSubject.maxCount)")
                        .font(OrotFont.caption).foregroundStyle(OrotColor.textCaption)
                } footer: {
                    Text("대상을 지워도 그동안의 기록과 별은 그대로 남아요.")
                        .font(OrotFont.caption).foregroundStyle(OrotColor.textCaption)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .environment(\.editMode, .constant(.active))
            .environment(\.defaultMinListRowHeight, 52)
        }
        .background(OrotColor.skyNight.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .bottom) {
            if let undoName {
                HStack {
                    Text("'\(undoName)'을(를) 지웠어요").font(OrotFont.regular(14)).foregroundStyle(OrotColor.textPrimary)
                    Spacer()
                    Button("되돌리기") { undo() }.font(OrotFont.regular(14)).foregroundStyle(OrotColor.accent).frame(height: 44).padding(.horizontal, 12)
                }
                .padding(.leading, 16).padding(.trailing, 8)
                .frame(height: 52)
                .background(RoundedRectangle(cornerRadius: OrotRadius.md).fill(Color(hex: 0x1C2025)))
                .shadow(color: .black.opacity(0.55), radius: 24, y: 16)
                .padding(.horizontal, 16).padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(OrotMotion.tap, value: undoName)
    }

    private func sessionCount(_ name: String) -> Int {
        sessionStore.sessions.filter { $0.studyPlanTitle == name }.count
    }

    private func delete(_ subject: FocusSubject) {
        lastDeleted = (subject.name, subject.order)
        undoName = subject.name
        subjectStore.delete(subject)
        undoTask?.cancel()
        undoTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            if !Task.isCancelled { undoName = nil }
        }
    }

    private func undo() {
        guard let item = lastDeleted else { return }
        subjectStore.add(name: item.name)
        // 새로 붙은 맨 끝 항목을 원래 자리로 옮깁니다.
        let last = subjectStore.subjects.count - 1
        if item.order < last {
            subjectStore.move(fromOffsets: IndexSet(integer: last), toOffset: item.order)
        }
        undoName = nil
        lastDeleted = nil
    }
}

// MARK: - Row
private struct SubjectRow: View {
    let subject: FocusSubject
    let sessionCount: Int
    let store: FocusSubjectStore
    let onDelete: () -> Void

    @State private var name = ""

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onDelete) {
                Circle().strokeBorder(OrotColor.textCaption).frame(width: 20, height: 20)
                    .overlay(Rectangle().fill(OrotColor.textSecondary).frame(width: 8, height: 1.5))
                    .frame(width: 36, height: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(subject.name) 지우기")
            Circle().fill(OrotColor.accent.opacity(subject.order == 0 ? 1 : 0.5)).frame(width: 6, height: 6)
            TextField("이름", text: $name)
                .font(OrotFont.body)
                .foregroundStyle(OrotColor.textPrimary)
                .submitLabel(.done)
                .onSubmit { commit() }
                .onChange(of: name) { _, new in
                    if new.count > FocusSubject.maxNameLength { name = String(new.prefix(FocusSubject.maxNameLength)) }
                }
            Text("세션 \(sessionCount)").font(OrotFont.caption).foregroundStyle(OrotColor.textCaption).fixedSize()
        }
        .frame(height: 52)
        .onAppear { name = subject.name }
        .onDisappear { commit() }
    }

    private func commit() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty, trimmed != subject.name { store.rename(subject, to: trimmed) }
    }
}
