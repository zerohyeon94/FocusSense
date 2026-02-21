//
//  SplashView.swift
//  FocusSense
//
//  앱 시작 시 스플래시 화면
//

import SwiftUI

// MARK: - Splash View
struct SplashView: View {
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8
    @State private var glowOpacity: Double = 0

    var body: some View {
        ZStack {
            Color(hex: "0f0f1a")
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text("Focus")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .orange.opacity(glowOpacity), radius: 20, x: 0, y: 0)

                Text("Sense your focus")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                opacity = 1
                scale = 1.0
            }
            withAnimation(.easeInOut(duration: 0.8).delay(0.4).repeatForever(autoreverses: true)) {
                glowOpacity = 0.6
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SplashView()
}
