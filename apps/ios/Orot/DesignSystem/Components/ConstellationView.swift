//
//  ConstellationView.swift
//  Orot
//
//  진행 중인 수 하나를 그립니다. 채워진 별끼리만 점선을 진하게 잇고,
//  빈자리로 가는 선은 아주 옅게 남깁니다. 별자리는 시간보다 밝아지지 않습니다.
//

import SwiftUI

struct ConstellationView: View {
    enum NextSlot: Equatable {
        case none
        /// 이번 세션의 별이 순수 집중만큼 밝아지는 중
        case forming(Double)
        /// 다음 세션에서 채울 빈자리가 숨 쉬듯 깜박임
        case waiting
    }

    let mansion: Mansion
    let magnitudes: [Int]
    var next: NextSlot = .none
    /// 가장 최근에 뜬 별을 고리로 표시 (세션 완료)
    var highlightLast = false
    /// 별 지름 배율
    var starScale: CGFloat = 1
    var padding: CGFloat = 12
    var maxSpacing: CGFloat = 4
    /// 빈자리 안쪽을 칠해 선이 비치지 않게 하는 배경색
    var background: Color = OrotColor.skyNight
    var lineColor = Color(hex: 0x3E4247)
    /// 0~1, 설정의 '별자리 표시 밝기'
    var intensity: Double = 1
    /// 앞에서부터 이만큼의 선만 그립니다 (완성 연출). nil이면 모두
    var revealedSegments: Int?
    /// 별을 누를 수 있게 합니다 (별자리 상세)
    var selectedStar: Int?
    var onTapStar: ((Int) -> Void)?

    @State private var breathing = false

    var body: some View {
        GeometryReader { geo in
            let pts = fitted(in: geo.size)
            let filled = magnitudes.count
            ZStack(alignment: .topLeading) {
                Canvas { context, _ in
                    for (n, (a, b)) in mansion.segments.enumerated() where n < (revealedSegments ?? .max) {
                        let on = a < filled && b < filled
                        var path = Path()
                        path.move(to: pts[a])
                        path.addLine(to: pts[b])
                        context.stroke(
                            path,
                            with: .color(on ? lineColor : Color(hex: 0x1E2125)),
                            style: StrokeStyle(lineWidth: 1, dash: on ? [3, 5] : [1, 6])
                        )
                    }
                }
                .opacity(intensity)

                ForEach(0..<mansion.starCount, id: \.self) { i in
                    if let onTapStar {
                        Button { onTapStar(i) } label: {
                            node(i, filled: filled)
                                .frame(width: 44, height: 44)
                                .overlay(Circle().strokeBorder(OrotColor.accent.opacity(i == selectedStar ? 0.7 : 0)))
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .position(pts[i])
                        .accessibilityLabel("\(i + 1)번째 별")
                    } else {
                        node(i, filled: filled)
                            .position(pts[i])
                    }
                }
            }
        }
        .onAppear { breathing = true }
        .accessibilityElement(children: onTapStar == nil ? .ignore : .contain)
        .accessibilityLabel("\(mansion.label) \(magnitudes.count) / \(mansion.starCount)")
    }

    @ViewBuilder
    private func node(_ i: Int, filled: Int) -> some View {
        if i < filled {
            ZStack {
                if highlightLast && i == filled - 1 {
                    Circle()
                        .strokeBorder(OrotColor.starMag2.opacity(0.35))
                        .frame(width: 26, height: 26)
                }
                StarDot(magnitude: magnitudes[i], scale: starScale)
            }
        } else if i == filled, case .forming(let f) = next {
            FormingStar(formation: f, scale: starScale)
        } else {
            let isNext = i == filled && next == .waiting
            Circle()
                .fill(background)
                .overlay(Circle().strokeBorder(isNext ? Color(hex: 0xB39F80) : OrotColor.starSlotEmpty, lineWidth: 1))
                .frame(width: 7 * max(1, starScale * 0.95), height: 7 * max(1, starScale * 0.95))
                .opacity(isNext ? (breathing ? 1 : 0.4) : intensity)
                .animation(isNext ? .easeInOut(duration: 3).repeatForever(autoreverses: true) : nil, value: breathing)
        }
    }

    private func fitted(in size: CGSize) -> [CGPoint] {
        let xs = mansion.points.map(\.x), ys = mansion.points.map(\.y)
        let w = max(1, xs.max()! - xs.min()!), h = max(1, ys.max()! - ys.min()!)
        let k = min((size.width - 2 * padding) / w, (size.height - 2 * padding) / h, maxSpacing)
        return mansion.points.map { CGPoint(x: size.width / 2 + $0.x * k, y: size.height / 2 + $0.y * k) }
    }
}

// MARK: - Mansion Caption
/// "두(斗) · 3 / 6" 형식 캡션
struct MansionCaption: View {
    let text: String
    var color: Color = OrotColor.textCaption

    var body: some View {
        Text(text)
            .font(OrotFont.caption)
            .tracking(0.5)
            .foregroundStyle(color)
            .lineLimit(1)
    }
}
