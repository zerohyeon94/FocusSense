//
//  OrotControls.swift
//  Orot
//
//  버튼 · 칩 · 상태 배지 · 탭바
//

import SwiftUI

// MARK: - Primary Button
/// 화면마다 하나만 두는 주요 버튼
struct OrotPrimaryButtonStyle: ButtonStyle {
    var height: CGFloat = 52

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(OrotFont.medium(15))
            .tracking(0.3)
            .foregroundStyle(OrotColor.skyNight)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(Capsule().fill(OrotColor.accent))
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(OrotMotion.tap, value: configuration.isPressed)
    }
}

// MARK: - Secondary Button
struct OrotSecondaryButtonStyle: ButtonStyle {
    var height: CGFloat = 48

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(OrotFont.regular(15))
            .tracking(0.3)
            .foregroundStyle(OrotColor.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(Capsule().fill(configuration.isPressed ? OrotColor.surfaceRaised : .clear))
            .overlay(Capsule().strokeBorder(OrotColor.hairline))
            .animation(OrotMotion.tap, value: configuration.isPressed)
    }
}

/// 배경 없이 글자만 있는 보조 동작 ("감지 없이 시작하기" 등)
struct OrotTextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(OrotFont.regular(14))
            .foregroundStyle(OrotColor.textSecondary)
            .frame(minHeight: 44)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

// MARK: - Session Icon Button
/// 세션 중 선만 있는 원형 아이콘 버튼
struct SessionIconButton: View {
    enum Icon { case pause, play, stop }

    let icon: Icon
    var background: Color = .clear
    let action: () -> Void

    var body: some View {
        Button(action: action) { label }
            .buttonStyle(.plain)
    }

    var label: some View {
        ZStack {
            Circle().fill(background)
            Circle().strokeBorder(OrotColor.hairline)
            glyph
        }
        .frame(width: 44, height: 44)
        .contentShape(Circle())
    }

    @ViewBuilder
    private var glyph: some View {
        let color = Color(hex: 0x76736C)
        switch icon {
        case .pause:
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 1).fill(color).frame(width: 3, height: 11)
                RoundedRectangle(cornerRadius: 1).fill(color).frame(width: 3, height: 11)
            }
        case .play:
            PlayTriangle().fill(color).frame(width: 10, height: 12).offset(x: 1.5)
        case .stop:
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 10, height: 10)
        }
    }
}

private struct PlayTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

/// 종료는 0.6초 길게 눌러서 확인합니다.
struct LongPressStopButton: View {
    var background: Color = .clear
    let action: () -> Void
    @State private var isPressing = false

    var body: some View {
        SessionIconButton(icon: .stop, background: background) {}
            .label
            .overlay(
                Circle()
                    .trim(from: 0, to: isPressing ? 1 : 0)
                    .stroke(OrotColor.textSecondary, lineWidth: 1)
                    .rotationEffect(.degrees(-90))
                    .animation(isPressing ? .linear(duration: 0.6) : .easeOut(duration: 0.2), value: isPressing)
            )
            .onLongPressGesture(minimumDuration: 0.6, perform: action) { isPressing = $0 }
            .accessibilityLabel("세션 마치기")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(.default) { action() }
    }
}

// MARK: - Focus Chip
struct FocusChip: View {
    let title: String
    let isSelected: Bool
    var showsDot = true
    var height: CGFloat = 44
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .fill(isSelected ? OrotColor.accent : (showsDot ? Color(hex: 0x4A4E54) : .clear))
                    .frame(width: 6, height: 6)
                Text(title).lineLimit(1)
            }
            .font(OrotFont.regular(15))
            .tracking(0.3)
            .foregroundStyle(isSelected ? OrotColor.textPrimary : OrotColor.textSecondary)
            .padding(.horizontal, 12)
            .frame(height: height)
            .background(Capsule().fill(isSelected ? OrotColor.accentSubtle : .clear))
            .overlay(Capsule().strokeBorder(isSelected ? OrotColor.accent : OrotColor.hairline))
            .animation(OrotMotion.tap, value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Session Badge
struct SessionBadge: View {
    enum Kind: Equatable { case focusing, paused, overtime, rest }

    let state: Kind
    @State private var breathing = false

    var body: some View {
        HStack(spacing: 7) {
            indicator
            Text(title)
        }
        .font(OrotFont.regular(12))
        .foregroundStyle(foreground)
        .padding(.horizontal, 11)
        .frame(height: 26)
        .overlay(Capsule().strokeBorder(state == .rest ? Color(hex: 0x353B43) : OrotColor.hairline))
        .onAppear { breathing = true }
    }

    private var title: String {
        switch state {
        case .focusing: return "집중 중"
        case .paused: return "잠시 멈춤"
        case .overtime: return "오버타임"
        case .rest: return "휴식"
        }
    }

    private var foreground: Color {
        switch state {
        case .focusing: return OrotColor.textPrimary
        case .paused: return OrotColor.textSecondary
        case .overtime: return OrotColor.stateOvertime
        case .rest: return OrotColor.windowLitWarm
        }
    }

    @ViewBuilder
    private var indicator: some View {
        switch state {
        case .focusing:
            // 3초 주기로 아주 천천히 숨 쉬는 점
            Circle().fill(OrotColor.accent).frame(width: 6, height: 6)
                .opacity(breathing ? 1 : 0.45)
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: breathing)
        case .paused:
            HStack(spacing: 2) {
                Rectangle().frame(width: 2, height: 8)
                Rectangle().frame(width: 2, height: 8)
            }
            .foregroundStyle(OrotColor.textSecondary)
        case .overtime:
            Circle().strokeBorder(OrotColor.stateOvertime).frame(width: 6, height: 6)
        case .rest:
            RoundedRectangle(cornerRadius: 1).fill(OrotColor.windowLitWarm.opacity(0.8)).frame(width: 6, height: 6)
        }
    }
}

// MARK: - Settings Glyph
/// 집중 탭 오른쪽 위 설정 진입 아이콘 (슬라이더 두 줄)
struct SettingsGlyph: View {
    var background: Color

    var body: some View {
        VStack(spacing: 6) {
            slider(knobX: 4)
            slider(knobX: 11)
        }
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
    }

    private func slider(knobX: CGFloat) -> some View {
        Rectangle()
            .fill(OrotColor.textSecondary)
            .frame(width: 20, height: 1.5)
            .overlay(alignment: .leading) {
                Circle()
                    .fill(background)
                    .overlay(Circle().strokeBorder(OrotColor.textSecondary, lineWidth: 1.5))
                    .frame(width: 7, height: 7)
                    .offset(x: knobX)
            }
    }
}
