//
//  SplashView.swift
//  FocusSense
//
//  앱 실행 시 "Focus" 브랜드를 보여주는 Splash 화면
//

import SwiftUI

// MARK: - Splash View
struct SplashView: View {
    @State private var textOpacity: Double = 0
    @State private var textScale: CGFloat = 0.8
    @State private var glowOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0

    var body: some View {
        ZStack {
            // 배경
            Color(hex: "0f0f1a")
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // 앱 이름
                Text("Focus")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .orange.opacity(glowOpacity), radius: 30, x: 0, y: 0)
                    .shadow(color: .orange.opacity(glowOpacity * 0.5), radius: 60, x: 0, y: 0)
                    .opacity(textOpacity)
                    .scaleEffect(textScale)

                // 서브 텍스트
                Text("Sense your focus")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
                    .opacity(subtitleOpacity)
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    // MARK: - Animation Sequence
    private func startAnimation() {
        // Phase 1: "Focus" 텍스트 fade-in + scale up (0 ~ 0.5s)
        withAnimation(.easeOut(duration: 0.5)) {
            textOpacity = 1.0
            textScale = 1.0
        }

        // Phase 2: 서브타이틀 fade-in (0.3 ~ 0.7s)
        withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
            subtitleOpacity = 1.0
        }

        // Phase 3: Orange glow pulse (0.5 ~ 1.3s)
        withAnimation(.easeInOut(duration: 0.8).delay(0.5)) {
            glowOpacity = 0.7
        }

        // Phase 4: Glow fade out (1.0 ~ 1.5s)
        withAnimation(.easeOut(duration: 0.5).delay(1.0)) {
            glowOpacity = 0.3
        }
    }
}

// MARK: - Preview
#Preview {
    SplashView()
}
