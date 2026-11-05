//
//  TimeDial.swift
//  Orot
//
//  시간 설정 다이얼 — 한 바퀴 120분, 5분 단위로 맞춥니다.
//

import SwiftUI

struct TimeDial: View {
    @Binding var minutes: Int
    var size: CGFloat = 230

    private let fullTurn = 120
    private let step = 5

    @State private var isDragging = false

    var body: some View {
        let center = CGPoint(x: size / 2, y: size / 2)

        ZStack {
            // 프리셋을 누르면 바늘과 게이지가 원을 따라 돌아갑니다. 끌 때는 손가락을 바로 따라갑니다.
            DialFace(progress: Double(minutes) / Double(fullTurn), size: size, tickCount: fullTurn / step)
                .animation(isDragging ? nil : .easeInOut(duration: 0.6), value: minutes)

            VStack(spacing: 2) {
                Text("\(minutes)")
                    .font(OrotFont.clockCompact)
                    .tracking(-0.6)
                    .foregroundStyle(OrotColor.textPrimary)
                Text("분 · 한 바퀴 \(fullTurn)분")
                    .font(OrotFont.caption)
                    .tracking(0.5)
                    .foregroundStyle(OrotColor.textSecondary)
            }
            .allowsHitTesting(false)
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged {
                    isDragging = true
                    update(with: $0.location, center: center)
                }
                .onEnded { _ in isDragging = false }
        )
        .sensoryFeedback(.selection, trigger: minutes)
        .accessibilityElement()
        .accessibilityLabel("집중 시간")
        .accessibilityValue("\(minutes)분")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: minutes = min(fullTurn, minutes + step)
            case .decrement: minutes = max(step, minutes - step)
            @unknown default: break
            }
        }
    }

    private func update(with location: CGPoint, center: CGPoint) {
        let a = atan2(location.x - center.x, -(location.y - center.y))
        let turn = (a / (2 * .pi) + 1).truncatingRemainder(dividingBy: 1)
        var m = Int((turn * Double(fullTurn / step)).rounded()) * step
        // 12시 방향에서는 직전 값에 따라 처음(5분) 또는 끝(120분)으로 붙입니다.
        if m == 0 || m == fullTurn { m = minutes > fullTurn / 2 ? fullTurn : step }
        if m != minutes { minutes = m }
    }
}

// MARK: - Dial Face
/// 진행률(각도) 하나로 게이지·눈금·바늘을 함께 그려, 애니메이션 중에도 바늘이 원 위를 지나갑니다.
private struct DialFace: View, Animatable {
    var progress: Double
    let size: CGFloat
    let tickCount: Int

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        let radius = size * 0.4
        let center = CGPoint(x: size / 2, y: size / 2)
        let angle = progress * 2 * .pi

        ZStack {
            Circle()
                .stroke(Color(hex: 0x2D3237), lineWidth: 2)
                .frame(width: radius * 2, height: radius * 2)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(OrotColor.accent, lineWidth: 2)
                .rotationEffect(.degrees(-90))
                .frame(width: radius * 2, height: radius * 2)

            ticks(center: center)

            Circle()
                .fill(OrotColor.textPrimary)
                .frame(width: 16, height: 16)
                .position(x: center.x + radius * sin(angle), y: center.y - radius * cos(angle))
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
    }

    private func ticks(center: CGPoint) -> some View {
        Canvas { context, _ in
            for i in 0..<tickCount {
                let isMajor = i % 3 == 0
                let isPassed = Double(i) < progress * Double(tickCount) || progress >= 1
                let a = Double(i) / Double(tickCount) * 2 * .pi
                let outer = size / 2 - 10
                let inner = size / 2 - (isMajor ? 20 : 15)
                var path = Path()
                path.move(to: CGPoint(x: center.x + inner * sin(a), y: center.y - inner * cos(a)))
                path.addLine(to: CGPoint(x: center.x + outer * sin(a), y: center.y - outer * cos(a)))
                context.stroke(path, with: .color(isPassed ? OrotColor.textSecondary : Color(hex: 0x41454B)), lineWidth: 1)
            }
        }
        .frame(width: size, height: size)
    }
}
