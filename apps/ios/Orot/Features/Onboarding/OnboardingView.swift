//
//  OnboardingView.swift
//  Orot
//
//  첫 실행: 온보딩 3장 → 카메라 권한 → 얼굴 위치 맞추기. 탭바 없이 세로로만 보여 줍니다.
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var viewModel: TimerViewModel
    let onFinish: () -> Void

    private enum Step { case intro, permission, align }
    @State private var step: Step = .intro
    @State private var page = 0

    var body: some View {
        ZStack {
            switch step {
            case .intro:
                introPages
            case .permission:
                CameraPermissionView(camera: viewModel.cameraService) { granted in
                    if granted { step = .align } else { onFinish() }
                }
            case .align:
                FaceAlignView(viewModel: viewModel, camera: viewModel.cameraService, mode: .onboarding, onDone: onFinish)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: step)
        .preferredColorScheme(.dark)
    }

    // MARK: - Intro
    private var introPages: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $page) {
                IntroCityPage().tag(0)
                IntroMeasurePage().tag(1)
                IntroPromisePage().tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            VStack(spacing: 20) {
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Capsule().fill(i == page ? OrotColor.accent : Color(hex: 0x4A4E54))
                            .frame(width: i == page ? 18 : 4, height: 4)
                    }
                }
                .animation(OrotMotion.tap, value: page)
                .accessibilityHidden(true)
                Button(page == 2 ? "카메라 설정하기" : "다음") {
                    if page < 2 { withAnimation { page += 1 } } else { step = .permission }
                }
                .buttonStyle(OrotPrimaryButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .overlay(alignment: .topTrailing) {
            if page < 2 {
                Button("건너뛰기") { withAnimation { page = 2 } }
                    .font(OrotFont.regular(13)).foregroundStyle(OrotColor.textCaption)
                    .frame(minHeight: 44).padding(.horizontal, 24)
            }
        }
    }
}

// MARK: - 1-1 도시 불빛과 별
private struct IntroCityPage: View {
    var body: some View {
        // 불빛이 40초 주기로 천천히 꺼지고 별이 드러납니다.
        TimelineView(.periodic(from: .now, by: 2)) { context in
            let p = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 40) / 38
            ZStack(alignment: .bottom) {
                OrotColor.skyLate.ignoresSafeArea()
                StarFieldView(field: StarField(seed: 9, count: 40, x: 16...374, y: 60...420, maxSize: 2), baseSize: CGSize(width: 390, height: 844), progress: p, maxOpacity: 0.6)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 4), value: p)
                CityGlow(height: 300, opacity: 0.7 * (1 - p), color: Color(hex: 0x3D2E1C))
                    .animation(OrotMotion.sky, value: p)
                SkylineView(style: .portrait, progress: p, windowIntensity: 0.6)
                    .animation(OrotMotion.window, value: p)

                IntroText(
                    caption: "오롯 · 뽀모도로 집중 타이머",
                    title: "불빛이 꺼질수록\n별이 보여요",
                    message: "집중하는 동안 도시의 창문이 하나씩 꺼지고, 하늘이 어두워지며 별이 드러나요. 세션을 마치면 별 하나가 떠요."
                )
                .padding(.bottom, 240)
            }
        }
    }
}

// MARK: - 1-2 자리를 지킨 시간만 기록
private struct IntroMeasurePage: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            OrotColor.skyNight.ignoresSafeArea()
            StarFieldView(field: StarField(seed: 13, count: 22, x: 16...374, y: 40...140, maxSize: 1.8), baseSize: CGSize(width: 390, height: 844), progress: 0.5, maxOpacity: 0.4)
                .ignoresSafeArea()
            SkylineView(style: .portrait, progress: 0.5)

            VStack(spacing: 0) {
                exampleCard.padding(.top, 100)
                Spacer()
                IntroText(title: "자리를 지킨 시간만\n별빛이 돼요", message: "전면 카메라로 자리에 계신지 살펴요. 잠시 비운 시간은 빼고 남은 시간을 순수 집중으로 기록해요. 비율이 높을수록 밝은 별이 떠요.")
                    .padding(.bottom, 240)
            }
        }
    }

    private var exampleCard: some View {
        VStack(spacing: 18) {
            HStack {
                Text("정한 시간 25:00")
                Spacer()
                Text("학습")
            }
            .font(OrotFont.caption).tracking(0.5).foregroundStyle(OrotColor.textCaption)

            VStack(spacing: 8) {
                GeometryReader { geo in
                    HStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 2).fill(OrotColor.progressFill).frame(width: geo.size.width * 0.40)
                        RoundedRectangle(cornerRadius: 2).strokeBorder(OrotColor.starSlotEmpty).frame(width: geo.size.width * 0.08)
                        RoundedRectangle(cornerRadius: 2).fill(OrotColor.progressFill)
                    }
                }
                .frame(height: 10)
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        Text("집중").frame(width: geo.size.width * 0.40, alignment: .leading)
                        Text("자리 비움 2분").fixedSize().frame(width: geo.size.width * 0.08)
                        Spacer()
                        Text("집중")
                    }
                }
                .frame(height: 14)
                .font(OrotFont.regular(11)).foregroundStyle(OrotColor.textCaption)
            }

            Rectangle().fill(OrotColor.hairline).frame(height: 1)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("23:00").font(OrotFont.extraLight(40)).foregroundStyle(OrotColor.textPrimary)
                    Text("순수 집중 · 92%").font(OrotFont.caption).tracking(0.5).foregroundStyle(OrotColor.textSecondary)
                }
                Spacer()
                HStack(spacing: 10) {
                    StarDot(magnitude: 2)
                    Text("2등급 별").font(OrotFont.regular(13)).foregroundStyle(OrotColor.textSecondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(RoundedRectangle(cornerRadius: OrotRadius.lg).fill(OrotColor.skyNight.opacity(0.8)))
        .overlay(RoundedRectangle(cornerRadius: OrotRadius.lg).strokeBorder(OrotColor.hairline))
        .padding(.horizontal, 32)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 1-3 오롯의 약속
private struct IntroPromisePage: View {
    private let promises = [
        ("전송하지 않아요", "영상은 서버로 보내지 않아요. 모든 처리는 이 iPhone 안에서 끝나요."),
        ("저장하지 않아요", "사진도 영상도 남기지 않아요. 기록되는 건 시간뿐이에요."),
        ("자리와 눈만 확인해요", "자리에 계신지, 눈을 감고 있는지만 봐요. 누구인지 알아보거나 표정을 기록하지 않아요."),
        ("언제든 끌 수 있어요", "카메라 없이 타이머로만 써도 괜찮아요."),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            OrotColor.skyNight.ignoresSafeArea()
            SkylineView(style: .portrait, progress: 0.8)

            VStack(alignment: .leading, spacing: 0) {
                Text("오롯의 약속").font(OrotFont.caption).tracking(0.5).foregroundStyle(OrotColor.accent)
                Text("영상은 이 iPhone\n밖으로 나가지 않아요").font(OrotFont.light(28)).lineSpacing(4).foregroundStyle(OrotColor.textPrimary).padding(.top, 16)
                VStack(spacing: 0) {
                    ForEach(Array(promises.enumerated()), id: \.offset) { i, item in
                        HStack(alignment: .top, spacing: 0) {
                            Text(String(format: "%02d", i + 1)).font(OrotFont.caption).foregroundStyle(OrotColor.accent).frame(width: 32, alignment: .leading).padding(.top, 2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.0).font(OrotFont.body).foregroundStyle(OrotColor.textPrimary)
                                Text(item.1).font(OrotFont.regular(13)).lineSpacing(3).foregroundStyle(OrotColor.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 16)
                        .overlay(alignment: .top) { Rectangle().fill(OrotColor.hairline).frame(height: 1) }
                    }
                }
                .padding(.top, 28)
                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.top, 70)
        }
    }
}

// MARK: - Intro Text
private struct IntroText: View {
    var caption: String?
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let caption {
                Text(caption).font(OrotFont.caption).tracking(0.5).foregroundStyle(OrotColor.textCaption)
            }
            Text(title).font(OrotFont.light(28)).lineSpacing(4).foregroundStyle(OrotColor.textPrimary)
            Text(message).font(OrotFont.body).lineSpacing(6).foregroundStyle(OrotColor.textSecondary)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 32)
    }
}
