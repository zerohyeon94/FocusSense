//
//  SettingsRows.swift
//  Orot
//
//  iOS 기본 설정처럼 그룹 리스트로 묶되, 면은 surfaceRaised · 구분선은 hairline · 켜진 스위치는 강조색입니다.
//

import SwiftUI

// MARK: - Section
struct SettingsSection<Content: View>: View {
    let title: String
    var footer: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(OrotFont.caption).tracking(0.5)
                .foregroundStyle(OrotColor.textCaption)
                .padding(.horizontal, 16)
            VStack(spacing: 0) {
                Group(subviews: content) { rows in
                    ForEach(Array(rows.enumerated()), id: \.offset) { i, row in
                        row.overlay(alignment: .top) {
                            if i > 0 { Rectangle().fill(Color(hex: 0x23272B)).frame(height: 1) }
                        }
                    }
                }
            }
            .background(RoundedRectangle(cornerRadius: OrotRadius.md).fill(OrotColor.surfaceRaised))
            .clipShape(RoundedRectangle(cornerRadius: OrotRadius.md))
            if let footer {
                Text(footer)
                    .font(OrotFont.caption).lineSpacing(3)
                    .foregroundStyle(OrotColor.textCaption)
                    .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Row Label
struct SettingsRowLabel: View {
    let title: String
    var subtitle: String?
    var dimmed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(OrotFont.body).foregroundStyle(dimmed ? OrotColor.textCaption : OrotColor.textPrimary)
            if let subtitle {
                Text(subtitle).font(OrotFont.caption).lineSpacing(2).foregroundStyle(OrotColor.textCaption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Navigation Row
struct SettingsNavRow<Destination: View>: View {
    let title: String
    var subtitle: String?
    var value: String?
    var dimmed = false
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 12) {
                SettingsRowLabel(title: title, subtitle: subtitle, dimmed: dimmed)
                if let value {
                    Text(value).font(OrotFont.body).monospacedDigit().foregroundStyle(Color(hex: 0x7E7B74))
                }
                Text("›").font(OrotFont.regular(17)).foregroundStyle(Color(hex: 0x4A4E54))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(dimmed)
    }
}

// MARK: - Toggle Row
struct SettingsToggleRow: View {
    let title: String
    var subtitle: String?
    @Binding var isOn: Bool
    var disabled = false

    var body: some View {
        Toggle(isOn: $isOn) {
            SettingsRowLabel(title: title, subtitle: subtitle, dimmed: disabled)
        }
        .tint(OrotColor.accent)
        .disabled(disabled)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 52)
    }
}

// MARK: - Segment Row
struct SettingsSegmentRow: View {
    let title: String
    var subtitle: String?
    let options: [String]
    @Binding var selection: Int
    var disabled = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SettingsRowLabel(title: title, subtitle: subtitle, dimmed: disabled)
            HStack(spacing: 0) {
                ForEach(Array(options.enumerated()), id: \.offset) { i, label in
                    let on = i == selection
                    Button { selection = i } label: {
                        Text(label)
                            .font(OrotFont.regular(13))
                            .foregroundStyle(on ? OrotColor.textPrimary : Color(hex: 0x76736C))
                            .frame(maxWidth: .infinity, minHeight: 32)
                            .background(RoundedRectangle(cornerRadius: 7).fill(on ? OrotColor.accentSubtle : .clear))
                            .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(on ? OrotColor.accent.opacity(0.6) : .clear))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(2)
            .background(RoundedRectangle(cornerRadius: 9).fill(OrotColor.skyNight))
            .opacity(disabled ? 0.4 : 1)
            .disabled(disabled)
            .animation(OrotMotion.tap, value: selection)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 14)
    }
}

// MARK: - Option List
/// 값 하나를 고르는 하위 화면 (기본 집중 시간 등)
struct SettingsOptionList: View {
    let title: String
    let options: [Int]
    let label: (Int) -> String
    @Binding var selection: Int

    var body: some View {
        SettingsPage(title: title) {
            SettingsSection(title: title) {
                ForEach(options, id: \.self) { option in
                    Button { selection = option } label: {
                        HStack {
                            Text(label(option)).font(OrotFont.body).foregroundStyle(OrotColor.textPrimary)
                            Spacer()
                            if option == selection {
                                Circle().fill(OrotColor.accent).frame(width: 8, height: 8)
                            }
                        }
                        .padding(.horizontal, 16)
                        .frame(minHeight: 52)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Page
/// 설정 하위 화면 틀: 가운데 제목 + "‹ 뒤로"
struct SettingsPage<Content: View>: View {
    let title: String
    var backTitle = "설정"
    @ViewBuilder let content: Content
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text(title).font(OrotFont.regular(17)).foregroundStyle(OrotColor.textPrimary)
                HStack {
                    Button { dismiss() } label: {
                        Text("‹ \(backTitle)").font(OrotFont.regular(15)).foregroundStyle(OrotColor.textSecondary)
                            .frame(height: 44).padding(.horizontal, 14)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
            }
            .frame(height: 52)
            .overlay(alignment: .bottom) { Rectangle().fill(OrotColor.hairline).frame(height: 1) }

            ScrollView {
                VStack(alignment: .leading, spacing: 26) { content }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    .padding(.bottom, 48)
            }
            .scrollIndicators(.hidden)
        }
        .background(OrotColor.skyNight.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}
