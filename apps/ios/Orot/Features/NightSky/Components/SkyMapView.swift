//
//  SkyMapView.swift
//  Orot
//
//  28수 성도 — 북극을 가운데 두고 네 방위에 7수씩 둘러놓습니다.
//  드래그로 움직이고, 두 손가락이나 +/− 버튼으로 확대합니다. 수를 누르면 상세로 갑니다.
//

import SwiftUI

struct SkyMapView: View {
    let sky: SkyProgress
    let onSelect: (Mansion) -> Void

    private static let canvas: CGFloat = 900
    private static let center = CGPoint(x: 450, y: 450)
    private static let zoomRange: ClosedRange<CGFloat> = 0.4...2.2

    @State private var zoom: CGFloat = 0.48
    @State private var pan = CGSize(width: -21, height: 89)
    @State private var dragStart: CGSize?
    @State private var pinchStart: (zoom: CGFloat, pan: CGSize)?

    var body: some View {
        GeometryReader { geo in
            let layout = MapLayout(sky: sky)
            ZStack(alignment: .topLeading) {
                mapContent(layout)
                    .frame(width: Self.canvas, height: Self.canvas)
                    .scaleEffect(zoom, anchor: .topLeading)
                    .offset(pan)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            .clipped()
            .contentShape(Rectangle())
            .gesture(dragGesture)
            .simultaneousGesture(pinchGesture(viewport: geo.size))
            .overlay(alignment: .bottomLeading) { legend.padding(.leading, 20).padding(.bottom, 18) }
            .overlay(alignment: .bottomTrailing) { zoomButtons(viewport: geo.size).padding(16) }
        }
    }

    // MARK: - Content
    private func mapContent(_ layout: MapLayout) -> some View {
        ZStack(alignment: .topLeading) {
            Canvas { context, _ in
                let c = Self.center
                func ring(_ r: CGFloat, color: Color, dash: [CGFloat] = []) {
                    context.stroke(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)), with: .color(color), style: StrokeStyle(lineWidth: 1, dash: dash))
                }
                ring(405, color: Color(hex: 0x23272B))
                ring(215, color: Color(hex: 0x1F2226))
                ring(60, color: Color(hex: 0x1B1E22), dash: [2, 5])
                for deg in [225.0, 135, 45, -45] {
                    let a = deg * .pi / 180
                    var p = Path()
                    p.move(to: CGPoint(x: c.x + 215 * cos(a), y: c.y + 215 * sin(a)))
                    p.addLine(to: CGPoint(x: c.x + 405 * cos(a), y: c.y + 405 * sin(a)))
                    context.stroke(p, with: .color(Color(hex: 0x1F2226)), lineWidth: 1)
                }
                for seg in layout.segments {
                    var p = Path()
                    p.move(to: seg.from)
                    p.addLine(to: seg.to)
                    context.stroke(p, with: .color(seg.color), style: StrokeStyle(lineWidth: 1, dash: seg.dash))
                }
                for star in layout.stars {
                    let rect = CGRect(x: star.point.x - star.size / 2, y: star.point.y - star.size / 2, width: star.size, height: star.size)
                    if star.isRing {
                        context.stroke(Path(ellipseIn: rect.insetBy(dx: 0.5, dy: 0.5)), with: .color(star.color.opacity(star.opacity)), lineWidth: 1)
                    } else {
                        context.drawLayer { layer in
                            if star.glow > 0 { layer.addFilter(.shadow(color: star.color.opacity(0.45), radius: star.glow / 2)) }
                            layer.fill(Path(ellipseIn: rect), with: .color(star.color.opacity(star.opacity)))
                        }
                    }
                }
            }

            ForEach(MansionDirection.allCases, id: \.rawValue) { dir in
                quadrantLabel(dir).position(layout.quadrantPoint(dir))
            }
            Text("北極")
                .font(OrotFont.regular(11))
                .tracking(0.7)
                .foregroundStyle(Color(hex: 0x56534D))
                .position(Self.center)

            ForEach(Mansion.all) { m in
                Button { onSelect(m) } label: {
                    Circle().fill(Color.clear).frame(width: 76, height: 76).contentShape(Circle())
                }
                .buttonStyle(.plain)
                .position(layout.cluster(m))
                .accessibilityHidden(true)

                Button { onSelect(m) } label: {
                    Text(m.hanja)
                        .font(OrotFont.regular(14))
                        .foregroundStyle(labelColor(sky.state(m)))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .position(layout.labelPoint(m))
                .accessibilityLabel("\(m.korean)수, \(sky.filledCount(m)) / \(m.starCount)")
            }
        }
    }

    private func labelColor(_ state: MansionState) -> Color {
        switch state {
        case .done: return OrotColor.moonLit
        case .current: return OrotColor.accent
        case .todo: return Color(hex: 0x4A4E54)
        }
    }

    private func quadrantLabel(_ dir: MansionDirection) -> some View {
        let mansions = Mansion.all.filter { $0.direction == dir }
        let done = mansions.filter { sky.state($0) == .done }.count
        let hasCurrent = mansions.contains { sky.state($0) == .current }
        let status = done == 7 ? "7 / 7 완성" : hasCurrent ? "진행 중" : done > 0 ? "\(done) / 7" : "아직"
        let color = done == 7 ? OrotColor.moonLit : hasCurrent ? OrotColor.accent : Color(hex: 0x5B5F66)
        return VStack(spacing: 2) {
            Text(dir.name).font(OrotFont.regular(15)).foregroundStyle(color)
            Text(status).font(OrotFont.regular(11)).tracking(0.4).foregroundStyle(Color(hex: 0x56534D))
        }
        .fixedSize()
    }

    // MARK: - Overlays
    private var legend: some View {
        HStack(spacing: 14) {
            legendItem("완성") { Circle().fill(OrotColor.starMag2).frame(width: 5, height: 5) }
            legendItem("진행 중") { Circle().fill(OrotColor.accent).frame(width: 5, height: 5) }
            legendItem("아직") { Circle().strokeBorder(Color(hex: 0x4A4E54)).frame(width: 6, height: 6) }
        }
        .font(OrotFont.regular(11))
        .foregroundStyle(OrotColor.textSecondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Capsule().fill(Color(hex: 0x0E1013).opacity(0.85)))
        .overlay(Capsule().strokeBorder(Color(hex: 0x23272B)))
    }

    private func legendItem(_ title: String, @ViewBuilder dot: () -> some View) -> some View {
        HStack(spacing: 6) { dot(); Text(title) }
    }

    private func zoomButtons(viewport: CGSize) -> some View {
        VStack(spacing: 0) {
            zoomButton("+", label: "확대") { zoomBy(1.35, viewport: viewport) }
            Rectangle().fill(Color(hex: 0x23272B)).frame(width: 44, height: 1)
            zoomButton("−", label: "축소") { zoomBy(1 / 1.35, viewport: viewport) }
        }
        .background(RoundedRectangle(cornerRadius: OrotRadius.md).fill(Color(hex: 0x0E1013).opacity(0.85)))
        .overlay(RoundedRectangle(cornerRadius: OrotRadius.md).strokeBorder(Color(hex: 0x23272B)))
    }

    private func zoomButton(_ glyph: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(glyph)
                .font(OrotFont.light(18))
                .foregroundStyle(OrotColor.textSecondary)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: - Gestures
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                if dragStart == nil { dragStart = pan }
                guard pinchStart == nil, let start = dragStart else { return }
                pan = CGSize(width: start.width + value.translation.width, height: start.height + value.translation.height)
            }
            .onEnded { _ in dragStart = nil }
    }

    private func pinchGesture(viewport: CGSize) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                if pinchStart == nil { pinchStart = (zoom, pan) }
                guard let start = pinchStart else { return }
                apply(zoom: start.zoom * value.magnification, from: start, anchor: value.startLocation)
            }
            .onEnded { _ in pinchStart = nil }
    }

    private func zoomBy(_ factor: CGFloat, viewport: CGSize) {
        withAnimation(.easeOut(duration: 0.3)) {
            apply(zoom: zoom * factor, from: (zoom, pan), anchor: CGPoint(x: viewport.width / 2, y: viewport.height / 2))
        }
    }

    /// 화면의 anchor 지점이 제자리에 머물도록 확대합니다.
    private func apply(zoom target: CGFloat, from start: (zoom: CGFloat, pan: CGSize), anchor: CGPoint) {
        let z = min(Self.zoomRange.upperBound, max(Self.zoomRange.lowerBound, target))
        let k = z / start.zoom
        zoom = z
        pan = CGSize(width: anchor.x - (anchor.x - start.pan.width) * k, height: anchor.y - (anchor.y - start.pan.height) * k)
    }
}

// MARK: - Map Layout
private struct MapLayout {
    struct Star { let point: CGPoint; let size: CGFloat; let color: Color; let opacity: Double; let glow: CGFloat; let isRing: Bool }
    struct Segment { let from: CGPoint; let to: CGPoint; let color: Color; let dash: [CGFloat] }

    let sky: SkyProgress
    private(set) var stars: [Star] = []
    private(set) var segments: [Segment] = []

    private static let center = CGPoint(x: 450, y: 450)

    init(sky: SkyProgress) {
        self.sky = sky
        for m in Mansion.all {
            let pts = points(m)
            let filled = sky.filledCount(m)
            let state = sky.state(m)
            for (j, p) in pts.enumerated() {
                if j < filled, let record = sky.record(m, star: j) {
                    let i = record.magnitude - 1
                    stars.append(Star(point: p, size: OrotStar.diameter[i] * 0.8, color: OrotColor.star(magnitude: record.magnitude), opacity: 1, glow: OrotStar.glow[i] * 0.8, isRing: false))
                } else if state == .current && j == filled {
                    stars.append(Star(point: p, size: 3.2, color: OrotColor.starForming, opacity: 0.6, glow: 6, isRing: false))
                } else {
                    stars.append(Star(point: p, size: 6.5, color: state == .todo ? OrotColor.starSlotEmpty : Color(hex: 0x4A4E54), opacity: state == .todo ? 0.8 : 1, glow: 0, isRing: true))
                }
            }
            for (a, b) in m.segments {
                let on = a < filled && b < filled
                let color = on ? (state == .current ? Color(hex: 0x7C705D) : Color(hex: 0x6A655B)) : Color(hex: 0x26292D)
                segments.append(Segment(from: pts[a], to: pts[b], color: color, dash: on ? [3, 4] : [1, 5]))
            }
        }
    }

    private static func angle(_ m: Mansion) -> Double {
        (225 - (Double(m.index) + 0.5) * 360 / 28) * .pi / 180
    }

    func cluster(_ m: Mansion) -> CGPoint {
        let a = Self.angle(m)
        return CGPoint(x: Self.center.x + 300 * cos(a), y: Self.center.y + 300 * sin(a))
    }

    func labelPoint(_ m: Mansion) -> CGPoint {
        let a = Self.angle(m)
        return CGPoint(x: Self.center.x + 372 * cos(a), y: Self.center.y + 372 * sin(a))
    }

    func quadrantPoint(_ dir: MansionDirection) -> CGPoint {
        let a = [180.0, 90, 0, 270][dir.rawValue] * .pi / 180
        return CGPoint(x: Self.center.x + 150 * cos(a), y: Self.center.y + 150 * sin(a))
    }

    private func points(_ m: Mansion) -> [CGPoint] {
        let xs = m.points.map(\.x), ys = m.points.map(\.y)
        let span = max(1, xs.max()! - xs.min()!, ys.max()! - ys.min()!)
        let f = min(1, 52 / span)
        let c = cluster(m)
        return m.points.map { CGPoint(x: c.x + $0.x * f, y: c.y + $0.y * f) }
    }
}
