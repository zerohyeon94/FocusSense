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

    var body: some View {
        let radius = size * 0.4
        let center = CGPoint(x: size / 2, y: size / 2)
        let angle = Double(minutes) / Double(fullTurn) * 2 * .pi

        ZStack {
            Circle()
                .stroke(Color(hex: 0x2D3237), lineWidth: 2)
                .frame(width: radius * 2, height: radius * 2)
            Circle()
                .trim(from: 0, to: Double(minutes) / Double(fullTurn))
                .stroke(OrotColor.accent, lineWidth: 2)
                .rotationEffect(.degrees(-90))
                .frame(width: radius * 2, height: radius * 2)
                .animation(OrotMotion.tap, value: minutes)

            ticks(center: center)

            Circle()
                .fill(OrotColor.textPrimary)
                .frame(width: 16, height: 16)
                .position(x: center.x + radius * sin(angle), y: center.y - radius * cos(angle))
                .animation(OrotMotion.tap, value: minutes)

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
                .onChanged { update(with: $0.location, center: center) }
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

    private func ticks(center: CGPoint) -> some View {
        Canvas { context, _ in
            for i in 0..<(fullTurn / step) {
                let isMajor = i % 3 == 0
                let isPassed = i * step < minutes || minutes == fullTurn
                let a = Double(i) / Double(fullTurn / step) * 2 * .pi
                let outer = size / 2 - 10
                let inner = size / 2 - (isMajor ? 20 : 15)
                var path = Path()
                path.move(to: CGPoint(x: center.x + inner * sin(a), y: center.y - inner * cos(a)))
                path.addLine(to: CGPoint(x: center.x + outer * sin(a), y: center.y - outer * cos(a)))
                context.stroke(path, with: .color(isPassed ? OrotColor.textSecondary : Color(hex: 0x41454B)), lineWidth: 1)
            }
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
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
