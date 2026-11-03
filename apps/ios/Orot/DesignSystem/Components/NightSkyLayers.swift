//
//  NightSkyLayers.swift
//  Orot
//
//  밤하늘 배경 레이어: 별 무리, 도시 스카이라인, 지평선 불빛.
//  창문은 세션 진행도(progress)를 넘어서는 순서대로 하나씩 꺼지고, 별은 차례로 드러납니다.
//

import SwiftUI

// MARK: - Seeded Random
/// 시안과 같은 배치를 재현하는 Park–Miller 난수
struct SeededRandom {
    private var state: Int64

    init(seed: Int64) { state = seed }

    mutating func next() -> Double {
        state = (state * 16807) % 2_147_483_647
        return Double(state - 1) / 2_147_483_646
    }
}

// MARK: - Skyline
struct Skyline {
    struct Building { let rect: CGRect }
    struct Window {
        let rect: CGRect
        /// 이 값보다 진행도가 커지면 꺼집니다.
        let threshold: Double
        let brightness: Double
        let color: Color
    }

    struct Style {
        var seed: Int64
        var height: CGFloat
        var heightRange: ClosedRange<CGFloat>
        var widthRange: ClosedRange<CGFloat>
        var gapRange: ClosedRange<CGFloat>
        /// 창문 너비, 높이, 가로 간격, 세로 간격, 좌우 여백, 위 여백
        var window: (w: CGFloat, h: CGFloat, gx: CGFloat, gy: CGFloat, px: CGFloat, pt: CGFloat)
        var density: Double

        static let landscape = Style(seed: 11, height: 52, heightRange: 12...48, widthRange: 18...46, gapRange: 0...4, window: (2, 2, 4, 5, 4, 5), density: 0.5)
        static let portrait = Style(seed: 31, height: 150, heightRange: 40...145, widthRange: 34...72, gapRange: 0...6, window: (3, 4, 6, 8, 7, 9), density: 0.42)
        static let low = Style(seed: 41, height: 60, heightRange: 14...58, widthRange: 22...50, gapRange: 0...4, window: (2, 3, 5, 7, 5, 6), density: 0.4)
        static let tall = Style(seed: 31, height: 190, heightRange: 60...185, widthRange: 34...72, gapRange: 0...6, window: (3, 4, 6, 8, 7, 9), density: 0.55)
    }

    static let warmColors = [OrotColor.windowLitWarm, OrotColor.windowLitAmber, OrotColor.windowLitPale]

    let buildings: [Building]
    let windows: [Window]

    init(style: Style, width: CGFloat) {
        var r = SeededRandom(seed: style.seed)
        var buildings: [Building] = []
        var windows: [Window] = []
        let lerp: (ClosedRange<CGFloat>, Double) -> CGFloat = { ($0.lowerBound + ($0.upperBound - $0.lowerBound) * $1).rounded() }
        let win = style.window
        var x: CGFloat = -6
        while x < width {
            let bw = lerp(style.widthRange, r.next())
            let bh = lerp(style.heightRange, r.next())
            let top = style.height - bh
            buildings.append(Building(rect: CGRect(x: x, y: top, width: bw, height: bh)))
            let cols = Int(((bw - 2 * win.px + win.gx) / (win.w + win.gx)).rounded(.down))
            let rows = Int(((bh - win.pt - 4 + win.gy) / (win.h + win.gy)).rounded(.down))
            let ox = ((bw - (CGFloat(cols) * (win.w + win.gx) - win.gx)) / 2).rounded()
            for i in 0..<max(0, rows) {
                for j in 0..<max(0, cols) where r.next() < style.density {
                    let rect = CGRect(x: x + ox + CGFloat(j) * (win.w + win.gx), y: top + win.pt + CGFloat(i) * (win.h + win.gy), width: win.w, height: win.h)
                    let threshold = r.next(), brightness = r.next()
                    let color = Self.warmColors[Int(r.next() * Double(Self.warmColors.count))]
                    windows.append(Window(rect: rect, threshold: threshold, brightness: brightness, color: color))
                }
            }
            x += bw + lerp(style.gapRange, r.next())
        }
        self.buildings = buildings
        self.windows = windows
    }
}

// MARK: - Skyline View
struct SkylineView: View {
    let style: Skyline.Style
    /// 0 = 모두 켜짐, 1 = 모두 꺼짐. 음수면 모두 켜진 상태입니다.
    var progress: Double
    var buildingColor: Color = OrotColor.buildingSilhouette
    var windowIntensity: Double = 0.55

    var body: some View {
        GeometryReader { geo in
            let skyline = Skyline(style: style, width: geo.size.width)
            Canvas { context, _ in
                for b in skyline.buildings {
                    context.fill(Path(b.rect), with: .color(buildingColor))
                }
                for w in skyline.windows {
                    context.fill(Path(w.rect), with: .color(w.color.opacity(windowOpacity(w))))
                }
            }
        }
        .frame(height: style.height)
    }

    /// 진행도를 넘긴 창문은 약 8초(25분 세션 기준)에 걸쳐 꺼집니다.
    private func windowOpacity(_ w: Skyline.Window) -> Double {
        let lit = (0.45 + 0.5 * w.brightness) * windowIntensity
        let fade = min(1, max(0, (w.threshold - progress) / 0.0053))
        return 0.05 + (lit - 0.05) * fade
    }
}

// MARK: - Star Field
struct StarField {
    struct Star {
        let point: CGPoint
        let size: CGFloat
        /// 진행도가 이 값을 넘으면 드러납니다.
        let threshold: Double
        let brightness: Double
    }

    let stars: [Star]

    /// 기준 화면(baseSize) 좌표로 만든 뒤 실제 크기에 맞게 늘립니다.
    init(seed: Int64, count: Int, x: ClosedRange<CGFloat>, y: ClosedRange<CGFloat>, maxSize: CGFloat, avoid: CGRect? = nil) {
        var r = SeededRandom(seed: seed)
        var stars: [Star] = []
        while stars.count < count {
            let px = (x.lowerBound + r.next() * (x.upperBound - x.lowerBound)).rounded()
            let py = (y.lowerBound + r.next() * (y.upperBound - y.lowerBound)).rounded()
            let star = Star(point: CGPoint(x: px, y: py), size: 1 + r.next() * (maxSize - 1), threshold: r.next() * 1.05 - 0.15, brightness: r.next())
            if let avoid, avoid.contains(star.point) { continue }
            stars.append(star)
        }
        self.stars = stars
    }

    static let landscape = StarField(seed: 5, count: 16, x: 60...800, y: 20...320, maxSize: 1.8, avoid: CGRect(x: 540, y: 30, width: 260, height: 190))
    static let portrait = StarField(seed: 9, count: 26, x: 16...374, y: 50...400, maxSize: 1.8, avoid: CGRect(x: 40, y: 130, width: 310, height: 240))
}

struct StarFieldView: View {
    let field: StarField
    /// 별 무리를 만든 기준 화면 크기
    let baseSize: CGSize
    var progress: Double
    var maxOpacity: Double = 0.35

    var body: some View {
        Canvas { context, size in
            let sx = size.width / baseSize.width, sy = size.height / baseSize.height
            for s in field.stars {
                // 별은 약 3초에 걸쳐 드러납니다.
                let reveal = min(1, max(0, (progress - s.threshold) / 0.002 + 1))
                guard reveal > 0 else { continue }
                let rect = CGRect(x: s.point.x * sx, y: s.point.y * sy, width: s.size, height: s.size)
                context.fill(Path(ellipseIn: rect), with: .color(OrotColor.starMag1.opacity((0.3 + 0.7 * s.brightness) * maxOpacity * reveal)))
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - City Glow
struct CityGlow: View {
    var height: CGFloat
    var opacity: Double
    var color: Color = OrotColor.cityGlow

    var body: some View {
        LinearGradient(colors: [color, color.opacity(0)], startPoint: .bottom, endPoint: .top)
            .frame(height: height)
            .opacity(opacity)
            .allowsHitTesting(false)
    }
}

// MARK: - Star Dot
/// 등급(1~5)별 지름과 빛번짐이 정해진 원형 별. 뾰족한 별 모양은 쓰지 않습니다.
struct StarDot: View {
    let magnitude: Int
    var scale: CGFloat = 1

    var body: some View {
        let i = max(1, min(5, magnitude)) - 1
        let color = OrotColor.star(magnitude: magnitude)
        Circle()
            .fill(color)
            .frame(width: OrotStar.diameter[i] * scale, height: OrotStar.diameter[i] * scale)
            .shadow(color: OrotStar.glow[i] > 0 ? color.opacity(0.45) : .clear, radius: OrotStar.glow[i] * scale / 2)
    }
}
