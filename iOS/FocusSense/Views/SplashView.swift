//
//  SplashView.swift
//  FocusSense
//
//  앱 시작 시 스플래시 화면
//

// =============================================================================
// 📚 파일 개요: SplashView.swift
// =============================================================================
// 이 파일은 앱 시작 시 표시되는 **스플래시(로딩) 화면**입니다.
//
// 📚 핵심 개념:
//   1. @State 애니메이션: @State 값 변경 + withAnimation으로 애니메이션 구현
//   2. withAnimation의 다양한 옵션:
//      - .easeOut: 끝이 느려지는 커브 (자연스러운 등장)
//      - .easeInOut: 시작과 끝이 느린 커브 (부드러운 반복)
//      - .delay(): 지정 시간 후에 애니메이션 시작
//      - .repeatForever(autoreverses:): 무한 반복 (글로우 효과에 사용)
//   3. scaleEffect + opacity: 크기와 투명도를 조합한 등장 애니메이션
//   4. .shadow로 글로우(Glow) 효과 구현
//   5. .onAppear: 뷰가 나타날 때 애니메이션 트리거
//
// 📚 애니메이션 타임라인:
//   0.0s: 뷰 등장 → opacity 0→1, scale 0.8→1.0 (0.6초 동안)
//   0.4s: 글로우 시작 → glowOpacity 0→0.6 (0.8초 동안, 무한 반복)
//   1.8s: FocusSenseApp.swift에서 showSplash = false → 스플래시 페이드아웃
// =============================================================================

import SwiftUI

// MARK: - Splash View
struct SplashView: View {
    // 📚 @State로 애니메이션 상태를 관리합니다.
    //    SwiftUI 애니메이션의 원리:
    //    1. @State 변수의 초기값을 설정 (애니메이션 시작 상태)
    //    2. withAnimation {} 블록 안에서 값을 변경 (애니메이션 끝 상태)
    //    3. SwiftUI가 초기값 → 최종값 사이를 자동으로 보간(interpolation)
    //
    //    예: opacity 0 → 1이면, SwiftUI가 0.0, 0.1, 0.2, ... 0.9, 1.0으로
    //    점진적으로 변경하여 페이드인 효과를 만듭니다.
    @State private var opacity: Double = 0       // 📚 초기값 0: 완전 투명 상태에서 시작
    @State private var scale: CGFloat = 0.8      // 📚 초기값 0.8: 80% 크기에서 시작 (살짝 작게)
    @State private var glowOpacity: Double = 0   // 📚 초기값 0: 글로우 없는 상태에서 시작

    var body: some View {
        ZStack {
            // 📚 .ignoresSafeArea(): Safe Area(노치, 홈 인디케이터 영역)를 무시하고
            //    화면 전체를 채웁니다. 스플래시 배경은 전체 화면이어야 하므로 필수입니다.
            Color(hex: "0f0f1a")
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text("Focus")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    // 📚 .shadow(): 텍스트 뒤에 그림자를 추가합니다.
                    //    여기서는 오렌지색 글로우(Glow) 효과로 활용합니다.
                    //    - color: 그림자 색상 (.orange에 투명도 적용)
                    //    - radius: 20으로 크게 설정하여 퍼지는 빛 효과 연출
                    //    - x, y: 0으로 텍스트 중심에서 퍼지도록 설정
                    //    glowOpacity가 0→0.6으로 변하면서 빛나는 효과가 나타납니다.
                    .shadow(color: .orange.opacity(glowOpacity), radius: 20, x: 0, y: 0)

                Text("Sense your focus")
                    .font(.subheadline)
                    // 📚 .opacity(0.5): 부제목을 반투명하게 하여 시각적 위계(hierarchy)를 만듭니다.
                    //    제목(Focus)은 불투명, 부제목은 반투명 → 자연스러운 강조 효과
                    .foregroundColor(.white.opacity(0.5))
            }
            // 📚 .scaleEffect(): 뷰의 크기를 비율로 조절합니다.
            //    scale = 0.8 → 80% 크기, scale = 1.0 → 원본 크기
            //    opacity와 함께 사용하면 "작은 상태에서 커지면서 나타나는" 효과를 만듭니다.
            //    이 패턴은 iOS 앱에서 매우 흔한 등장 애니메이션입니다.
            .scaleEffect(scale)
            // 📚 .opacity(): 뷰의 투명도를 설정합니다.
            //    0 = 완전 투명, 1 = 완전 불투명
            //    @State와 연결하여 withAnimation으로 부드러운 페이드인 구현
            .opacity(opacity)
        }
        // 📚 .onAppear: 이 View가 화면에 처음 나타날 때 실행됩니다.
        //    여기서 두 개의 withAnimation을 연속으로 호출하여 복합 애니메이션을 구성합니다.
        //    주의: withAnimation은 즉시 반환되며, 애니메이션은 백그라운드에서 진행됩니다.
        //    따라서 두 withAnimation이 동시에 시작 가능합니다 (delay로 시차 조절).
        .onAppear {
            // 📚 첫 번째 애니메이션: 등장 효과 (0.6초)
            //    .easeOut: 처음에 빠르게 시작하고 끝에서 느려지는 커브
            //    → 탄력 있게 나타나서 자연스럽게 멈추는 느낌
            //    opacity 0→1: 투명→불투명 (페이드인)
            //    scale 0.8→1.0: 80%→100% (스케일업)
            withAnimation(.easeOut(duration: 0.6)) {
                opacity = 1
                scale = 1.0
            }
            // 📚 두 번째 애니메이션: 글로우 반복 효과
            //    .easeInOut: 시작과 끝이 모두 부드러운 커브
            //    .delay(0.4): 0.4초 후에 시작 → 등장 애니메이션 중간에 글로우 시작
            //    .repeatForever(autoreverses: true): 무한 반복 + 자동 역방향
            //    → glowOpacity가 0→0.6→0→0.6... 으로 반복되어 숨쉬는 듯한 빛 효과
            //
            //    autoreverses 옵션:
            //    - true: 0→0.6→0→0.6 (부드럽게 왕복)
            //    - false: 0→0.6, 0→0.6 (순간적으로 리셋 후 반복)
            withAnimation(.easeInOut(duration: 0.8).delay(0.4).repeatForever(autoreverses: true)) {
                glowOpacity = 0.6
            }
        }
    }
}

// MARK: - Preview

// 📚 #Preview: Xcode Canvas에서 실시간 미리보기를 제공합니다.
//    스플래시 화면의 애니메이션도 Canvas에서 확인할 수 있습니다.
//    (Canvas 하단의 재생 버튼을 눌러 Live Preview로 확인)
#Preview {
    SplashView()
}
