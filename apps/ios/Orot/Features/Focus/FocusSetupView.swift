//
//  FocusSetupView.swift
//  Orot
//
//  집중 탭 홈 — 세션 설정(시간 · 대상) / 첫 세션 전 빈 상태 / 시작 직전 확인 시트
//

import SwiftUI

struct FocusSetupView: View {
    @ObservedObject var viewModel: TimerViewModel
    @ObservedObject var subjectStore: FocusSubjectStore
    @ObservedObject var sessionStore: StudySessionStore

    @AppStorage(OrotSettings.Key.focusMinutes) private var minutes = 25
    @AppStorage(OrotSettings.Key.detectionEnabled) private var detectionEnabled = true
    @AppStorage("focus.subject") private var subjectName = FocusSubject.defaultNames[0]
    @State private var showsSetupOnEmpty = false
    @State private var showsStartCheck = false
    @State private var pendingDetection: Bool?
    @State private var showsSettings = false

    private var isEmpty: Bool { sessionStore.sessions.isEmpty && !showsSetupOnEmpty }

    var body: some View {
        Group {
            if isEmpty {
                FocusEmptyStateView(
                    onStart: { minutes = 25; start() },
                    onCustomize: { showsSetupOnEmpty = true },
                    onSettings: { showsSettings = true }
                )
            } else {
                FocusSetupContent(
                    minutes: $minutes,
                    subjectName: $subjectName,
                    subjectStore: subjectStore,
                    sessionStore: sessionStore,
                    onStart: start,
                    onSettings: { showsSettings = true },
                    notificationService: viewModel.notificationService
                )
            }
        }
        .sheet(isPresented: $showsStartCheck, onDismiss: startPendingSession) {
            StartCheckSheet(viewModel: viewModel, camera: viewModel.cameraService, minutes: minutes, subjectName: subjectName) { detection in
                pendingDetection = detection
                showsStartCheck = false
            }
        }
        .fullScreenCover(isPresented: $showsSettings) {
            SettingsView(subjectStore: subjectStore, sessionStore: sessionStore, timerViewModel: viewModel)
        }
    }

    /// 감지를 끈 경우에는 확인 시트 없이 바로 시작합니다.
    private func start() {
        if detectionEnabled {
            showsStartCheck = true
        } else {
            viewModel.startSession(minutes: minutes, subject: subjectName, detection: false)
        }
    }

    /// 시트가 완전히 닫힌 뒤 세션 화면을 띄웁니다.
    private func startPendingSession() {
        guard let detection = pendingDetection else {
            viewModel.stopPreview()
            return
        }
        pendingDetection = nil
        viewModel.startSession(minutes: minutes, subject: subjectName, detection: detection)
    }
}

// MARK: - Setup Content (2-1)
private struct FocusSetupContent: View {
    @Binding var minutes: Int
    @Binding var subjectName: String
    @ObservedObject var subjectStore: FocusSubjectStore
    @ObservedObject var sessionStore: StudySessionStore
    let onStart: () -> Void
    let onSettings: () -> Void
    let notificationService: NotificationService

    @State private var showsAddSubject = false
    @State private var showsNotificationNotice = false
    @AppStorage(OrotSettings.Key.notificationNoticeDismissedAt) private var noticeDismissedAt = 0.0
    @State private var newSubjectName = ""

    private let background = OrotColor.skyLate

    var body: some View {
        ZStack(alignment: .bottom) {
            background.ignoresSafeArea()
            StarFieldView(field: .portrait, baseSize: CGSize(width: 390, height: 844), progress: 0.25, maxOpacity: 0.2)
                .ignoresSafeArea()

            SkylineView(style: .low, progress: -1, buildingColor: Color(hex: 0x181C21), windowIntensity: 0.45)

            VStack(spacing: 0) {
                header
                Spacer(minLength: 8)
                nextSlotPreview
                Spacer(minLength: 8)
                TimeDial(minutes: $minutes)
                presets.padding(.top, 14)
                subjects.padding(.top, 20)
                if showsNotificationNotice {
                    NotificationOffNotice {
                        noticeDismissedAt = Date().timeIntervalSince1970
                        withAnimation(.easeOut(duration: 0.3)) { showsNotificationNotice = false }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .transition(.opacity)
                }
                Button(startLabel, action: onStart)
                    .buttonStyle(OrotPrimaryButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.top, 22)
                Spacer(minLength: 76)
            }
        }
        .alert("집중 대상 추가", isPresented: $showsAddSubject) {
            TextField("무엇에 집중할까요? (최대 12자)", text: $newSubjectName)
            Button("취소", role: .cancel) { newSubjectName = "" }
            Button("추가") {
                let name = newSubjectName.trimmingCharacters(in: .whitespaces)
                if !name.isEmpty {
                    subjectStore.add(name: name)
                    subjectName = String(name.prefix(FocusSubject.maxNameLength))
                }
                newSubjectName = ""
            }
        }
        .task {
            // 알림이 꺼져 있으면 안내합니다. "괜찮아요"를 누르면 7일 동안 다시 띄우지 않아요.
            let s = OrotSettings.current
            let recentlyDismissed = Date().timeIntervalSince1970 - noticeDismissedAt < 7 * 86_400
            let wantsAlerts = s.notifySessionEnd || s.notifyRestEnd
            let status = await notificationService.authorizationStatus()
            showsNotificationNotice = wantsAlerts && !recentlyDismissed && status == .denied
        }
        .onAppear {
            if !subjectStore.subjects.contains(where: { $0.name == subjectName }), let first = subjectStore.subjects.first {
                subjectName = first.name
            }
        }
    }

    private var startLabel: String { "\(subjectName) \(minutes)분 시작" }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("집중")
                    .font(OrotFont.title)
                    .foregroundStyle(OrotColor.textPrimary)
                Spacer()
                Button(action: onSettings) { SettingsGlyph(background: background) }
                    .buttonStyle(.plain)
                    .accessibilityLabel("설정")
            }
            TodaySummary(sessionStore: sessionStore)
        }
        .padding(.leading, 24)
        .padding(.trailing, 14)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var nextSlotPreview: some View {
        let sky = sessionStore.sky
        if let mansion = sky.currentMansion {
            VStack(spacing: 6) {
                ConstellationView(mansion: mansion, magnitudes: sky.magnitudes(mansion), next: .waiting, starScale: 0.9, padding: 8, maxSpacing: 5.6, background: background)
                    .frame(width: 224, height: 120)
                    .opacity(0.75)
                MansionCaption(text: "이번 세션이 채울 자리 · \(mansion.label)의 \(sky.nextStarOrdinal)", color: Color(hex: 0x7E7B74))
            }
        }
    }

    private var presets: some View {
        HStack(spacing: 8) {
            ForEach([25, 50, 90], id: \.self) { m in
                let on = m == minutes
                Button { minutes = m } label: {
                    Text("\(m)분")
                        .font(OrotFont.regular(13))
                        .monospacedDigit()
                        .foregroundStyle(on ? OrotColor.textPrimary : OrotColor.textSecondary)
                        .frame(minWidth: 64, minHeight: 36)
                        .background(Capsule().fill(on ? OrotColor.accentSubtle : .clear))
                        .overlay(Capsule().strokeBorder(on ? OrotColor.accent : Color(hex: 0x2D3237)))
                }
                .buttonStyle(.plain)
            }
        }
        .animation(OrotMotion.tap, value: minutes)
    }

    private var subjects: some View {
        ViewThatFits(in: .horizontal) {
            subjectChips.padding(.horizontal, 24)
            ScrollView(.horizontal, showsIndicators: false) {
                subjectChips.padding(.horizontal, 24)
            }
        }
    }

    private var subjectChips: some View {
        HStack(spacing: 6) {
            ForEach(subjectStore.subjects) { subject in
                FocusChip(title: subject.name, isSelected: subject.name == subjectName) {
                    subjectName = subject.name
                }
            }
            if subjectStore.subjects.count < FocusSubject.maxCount {
                FocusChip(title: "+ 추가", isSelected: false, showsDot: false) {
                    showsAddSubject = true
                }
            }
        }
    }
}

// MARK: - Today Summary
struct TodaySummary: View {
    @ObservedObject var sessionStore: StudySessionStore

    var body: some View {
        let today = sessionStore.sessions(for: Date())
        let pure = Int(today.reduce(0) { $0 + $1.netFocusTime } / 60)
        HStack(spacing: 8) {
            StarDot(magnitude: 2, scale: 0.9)
            Text("오늘 별 \(today.count)개 · 순수 집중 \(Self.duration(minutes: pure))")
                .font(OrotFont.regular(13))
                .foregroundStyle(OrotColor.textSecondary)
        }
    }

    static func duration(minutes: Int) -> String {
        minutes >= 60 ? "\(minutes / 60)시간 \(minutes % 60)분" : "\(minutes)분"
    }
}
