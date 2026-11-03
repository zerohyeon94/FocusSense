//
//  SettingsView.swift
//  Orot
//
//  설정 메인 (5-1) — 집중 탭 오른쪽 위 아이콘으로 들어옵니다.
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var subjectStore: FocusSubjectStore
    @ObservedObject var sessionStore: StudySessionStore
    @ObservedObject var timerViewModel: TimerViewModel

    @AppStorage(OrotSettings.Key.focusMinutes) private var focusMinutes = 25
    @AppStorage(OrotSettings.Key.restMinutes) private var restMinutes = 5
    @AppStorage(OrotSettings.Key.longRestMinutes) private var longRestMinutes = 15
    @AppStorage(OrotSettings.Key.longRestEvery) private var longRestEvery = 4
    @AppStorage(OrotSettings.Key.detectionEnabled) private var detectionEnabled = true
    @AppStorage(OrotSettings.Key.sensitivity) private var sensitivity = 1
    @AppStorage(OrotSettings.Key.constellationDisplay) private var constellationDisplay = 1
    @AppStorage(OrotSettings.Key.keepAwake) private var keepAwake = true
    @AppStorage(OrotSettings.Key.notifySessionEnd) private var notifySessionEnd = true
    @AppStorage(OrotSettings.Key.notifyRestEnd) private var notifyRestEnd = true
    @AppStorage(OrotSettings.Key.sound) private var sound = false
    @AppStorage(OrotSettings.Key.haptic) private var haptic = true

    @State private var showsDeleteConfirm = false

    var body: some View {
        NavigationStack {
            SettingsPage(title: "설정", backTitle: "집중") {
                focusSection
                detectionSection
                displaySection
                notificationSection
                dataSection
                privacySection
                infoSection
            }
        }
        .tint(OrotColor.accent)
        .sheet(isPresented: $showsDeleteConfirm) {
            DeleteAllRecordsSheet(sessionStore: sessionStore)
        }
    }

    // MARK: - Sections

    private var focusSection: some View {
        SettingsSection(title: "집중") {
            SettingsNavRow(title: "기본 집중 시간", value: "\(focusMinutes)분") {
                SettingsOptionList(title: "기본 집중 시간", options: Array(stride(from: 15, through: 120, by: 5)), label: { "\($0)분" }, selection: $focusMinutes)
            }
            SettingsNavRow(title: "휴식 시간", value: "\(restMinutes)분") {
                SettingsOptionList(title: "휴식 시간", options: [3, 5, 10, 15], label: { "\($0)분" }, selection: $restMinutes)
            }
            SettingsNavRow(title: "긴 휴식", value: "\(longRestEvery)세션마다 · \(longRestMinutes)분") {
                LongRestSettings(every: $longRestEvery, minutes: $longRestMinutes)
            }
            SettingsNavRow(title: "집중 대상 관리", value: "\(subjectStore.subjects.count)개") {
                SubjectManageView(subjectStore: subjectStore, sessionStore: sessionStore)
            }
        }
    }

    private var detectionSection: some View {
        SettingsSection(title: "감지", footer: "감지를 끄면 타이머로만 쓰고, 별은 기본 밝기(3등급)로 떠요.") {
            SettingsToggleRow(title: "자리 이탈 감지", subtitle: "전면 카메라로 자리에 계신지만 확인해요", isOn: $detectionEnabled)
            SettingsSegmentRow(
                title: "민감도",
                subtitle: detectionEnabled
                    ? "\(OrotSettings.sensitivityLabels[sensitivity]) · 자리를 비운 지 \(OrotSettings.awayGraceSeconds[sensitivity])초 뒤 잠시 멈춰요"
                    : "감지가 꺼져 있어요",
                options: OrotSettings.sensitivityLabels,
                selection: $sensitivity,
                disabled: !detectionEnabled
            )
            SettingsNavRow(title: "얼굴 위치 다시 맞추기", dimmed: !detectionEnabled) {
                FaceAlignView(viewModel: timerViewModel, camera: timerViewModel.cameraService, mode: .settings) {}
            }
        }
    }

    private var displaySection: some View {
        SettingsSection(title: "화면") {
            SettingsSegmentRow(title: "별자리 표시 밝기", subtitle: "세션 중 하늘에 그리는 별자리 선과 빈 자리", options: OrotSettings.constellationLabels, selection: $constellationDisplay)
            SettingsToggleRow(title: "화면 꺼짐 방지", subtitle: "세션 중에는 화면이 꺼지지 않아요", isOn: $keepAwake)
        }
    }

    private var notificationSection: some View {
        SettingsSection(title: "알림") {
            SettingsToggleRow(title: "세션 종료 알림", isOn: $notifySessionEnd)
            SettingsToggleRow(title: "휴식 종료 알림", isOn: $notifyRestEnd)
            SettingsToggleRow(title: "사운드", subtitle: "알림이 올 때 소리를 함께 내요", isOn: $sound)
            SettingsToggleRow(title: "햅틱", isOn: $haptic)
        }
    }

    private var dataSection: some View {
        SettingsSection(title: "데이터") {
            ShareLink(item: CSVExport(text: sessionStore.csv()), preview: SharePreview("오롯 기록.csv")) {
                HStack {
                    SettingsRowLabel(title: "기록 내보내기", subtitle: "CSV 파일로 저장해요")
                    Text("›").font(OrotFont.regular(17)).foregroundStyle(Color(hex: 0x4A4E54))
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .frame(minHeight: 52)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Button { showsDeleteConfirm = true } label: {
                Text("모든 기록 삭제").font(OrotFont.body).foregroundStyle(OrotColor.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                    .padding(.horizontal, 16)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var privacySection: some View {
        SettingsSection(title: "개인정보") {
            SettingsNavRow(title: "카메라 데이터 처리 방식", subtitle: "영상은 저장·전송하지 않아요") { CameraDataView() }
        }
    }

    private var infoSection: some View {
        SettingsSection(title: "정보") {
            HStack {
                SettingsRowLabel(title: "버전")
                Text(Self.version).font(OrotFont.body).monospacedDigit().foregroundStyle(Color(hex: 0x7E7B74))
            }
            .padding(.horizontal, 16).frame(minHeight: 52)
            SettingsNavRow(title: "오픈소스 라이선스") { LicensesView() }
        }
    }

    private static var version: String {
        let info = Bundle.main.infoDictionary
        return "\(info?["CFBundleShortVersionString"] as? String ?? "") (\(info?["CFBundleVersion"] as? String ?? ""))"
    }
}

// MARK: - Long Rest
private struct LongRestSettings: View {
    @Binding var every: Int
    @Binding var minutes: Int

    var body: some View {
        SettingsPage(title: "긴 휴식") {
            SettingsSection(title: "몇 세션마다") {
                SettingsSegmentRow(title: "긴 휴식 주기", options: ["2", "3", "4", "5", "6"].map { "\($0)세션" }, selection: Binding(get: { every - 2 }, set: { every = $0 + 2 }))
            }
            SettingsSection(title: "긴 휴식 시간") {
                SettingsSegmentRow(title: "시간", options: ["10분", "15분", "20분", "30분"], selection: Binding(
                    get: { [10, 15, 20, 30].firstIndex(of: minutes) ?? 1 },
                    set: { minutes = [10, 15, 20, 30][$0] }
                ))
            }
        }
    }
}

// MARK: - CSV Export
struct CSVExport: Transferable {
    let text: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { Data($0.text.utf8) }
            .suggestedFileName("오롯 기록.csv")
    }
}

// MARK: - Licenses
private struct LicensesView: View {
    var body: some View {
        SettingsPage(title: "오픈소스 라이선스") {
            VStack(alignment: .leading, spacing: 10) {
                Text("IBM Plex Sans KR").font(OrotFont.body).foregroundStyle(OrotColor.textPrimary)
                Text(Self.ofl).font(OrotFont.caption).lineSpacing(3).foregroundStyle(OrotColor.textSecondary).textSelection(.enabled)
            }
        }
    }

    private static let ofl: String = Bundle.main.url(forResource: "OFL", withExtension: "txt")
        .flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? "SIL Open Font License 1.1"
}
