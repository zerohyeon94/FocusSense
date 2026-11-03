//
//  MoonPhaseIcon.swift
//  Orot
//

import SwiftUI

// MARK: - Moon Phase Icon
struct MoonPhaseIcon: View {
    var phase: MoonPhase = MoonPhase()
    var size: CGFloat = 16
    var shadow: Color = OrotColor.moonShadow

    var body: some View {
        ZStack {
            Circle().fill(shadow)
            MoonLitShape(fraction: phase.fraction).fill(OrotColor.moonLit)
        }
        .frame(width: size, height: size)
    }
}

/// 밝은 면: 바깥 반원 + 명암 경계 타원 반쪽
private struct MoonLitShape: Shape {
    let fraction: Double

    func path(in rect: CGRect) -> Path {
        let r = rect.width / 2
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let rx = r * abs(cos(2 * .pi * fraction))
        let waxing = fraction < 0.5
        // 차오를 때는 오른쪽, 기울 때는 왼쪽이 밝습니다.
        let side: CGFloat = waxing ? 1 : -1
        // 초승·그믐(위상 1/4 이전·3/4 이후)에는 경계가 밝은 면 쪽으로 볼록합니다.
        let terminatorSide: CGFloat = (fraction < 0.25 || fraction > 0.75) ? side : -side

        var path = Path()
        let steps = 48
        for i in 0...steps {
            let t = -Double.pi / 2 + Double.pi * Double(i) / Double(steps)
            path.addLine(to: CGPoint(x: c.x + side * r * cos(t), y: c.y + r * sin(t)), first: i == 0)
        }
        for i in 0...steps {
            let t = Double.pi / 2 - Double.pi * Double(i) / Double(steps)
            path.addLine(to: CGPoint(x: c.x + terminatorSide * rx * cos(t), y: c.y + r * sin(t)), first: false)
        }
        path.closeSubpath()
        return path
    }
}

private extension Path {
    mutating func addLine(to point: CGPoint, first: Bool) {
        if first { move(to: point) } else { addLine(to: point) }
    }
}

// MARK: - Moon Caption
/// 세션 화면 오른쪽 위의 "위상 이름 + 아이콘"
struct MoonCaption: View {
    var prefix: String = ""
    var size: CGFloat = 16

    var body: some View {
        let phase = MoonPhase()
        HStack(spacing: 8) {
            Text(prefix + phase.name)
                .font(OrotFont.caption)
                .foregroundStyle(OrotColor.textCaption)
            MoonPhaseIcon(phase: phase, size: size)
        }
    }
}
