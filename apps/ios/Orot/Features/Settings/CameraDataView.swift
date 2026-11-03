//
//  CameraDataView.swift
//  Orot
//
//  카메라 데이터 처리 방식 (5-3)
//

import SwiftUI

struct CameraDataView: View {
    var body: some View {
        SettingsPage(title: "카메라 데이터 처리") {
            Text("영상은 저장하거나 전송하지 않고, 기기 안에서 얼굴이 있는지만 확인해요")
                .font(OrotFont.title).lineSpacing(4).foregroundStyle(OrotColor.textPrimary)
                .padding(.horizontal, 8)
            diagram
            facts
        }
    }

    private var diagram: some View {
        VStack(spacing: 14) {
            HStack {
                step("전면 카메라") {
                    Circle().strokeBorder(OrotColor.textSecondary, lineWidth: 1.5).frame(width: 18, height: 18)
                        .overlay(Circle().fill(OrotColor.textSecondary).frame(width: 6, height: 6))
                }
                arrow
                step("얼굴이\n있나요?") {
                    Ellipse().strokeBorder(OrotColor.accent, lineWidth: 1.5).frame(width: 20, height: 26)
                }
                arrow
                step("시간만\n기록") {
                    VStack(spacing: 2) {
                        Text("예").foregroundStyle(OrotColor.accent)
                        Text("아니오").foregroundStyle(OrotColor.textCaption)
                    }
                    .font(OrotFont.regular(11))
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 26)
            .padding(.bottom, 14)
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(OrotColor.accent.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
            .overlay(alignment: .topLeading) {
                Text("이 iPhone 안").font(OrotFont.regular(11)).tracking(0.4).foregroundStyle(OrotColor.accent)
                    .padding(.horizontal, 6).background(OrotColor.skyNight).offset(x: 12, y: -8)
            }

            HStack {
                ForEach([("저장", "저장 안 함"), ("전송", "전송 안 함"), ("얼굴", "알아보지 않음")], id: \.0) { glyph, title in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 10).strokeBorder(OrotColor.hairline).frame(width: 40, height: 40)
                            .overlay(Text(glyph).font(OrotFont.regular(11)).foregroundStyle(OrotColor.textCaption))
                            .overlay(Rectangle().fill(OrotColor.textSecondary).frame(width: 28, height: 1).rotationEffect(.degrees(-35)))
                        Text(title).font(OrotFont.caption).foregroundStyle(OrotColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 18)
        .overlay(RoundedRectangle(cornerRadius: OrotRadius.lg).strokeBorder(OrotColor.hairline))
        .padding(.horizontal, 8)
    }

    private func step(_ title: String, @ViewBuilder icon: () -> some View) -> some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 12).fill(OrotColor.surfaceRaised)
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(OrotColor.starSlotEmpty))
                .overlay(icon())
                .frame(width: 48, height: 48)
            Text(title).font(OrotFont.caption).multilineTextAlignment(.center).foregroundStyle(OrotColor.textPrimary)
        }
        .frame(width: 78)
    }

    private var arrow: some View {
        Text("→").font(OrotFont.regular(14)).foregroundStyle(OrotColor.textCaption).frame(maxWidth: .infinity)
    }

    private var facts: some View {
        VStack(spacing: 0) {
            ForEach(Array(Self.items.enumerated()), id: \.offset) { i, item in
                HStack(alignment: .top, spacing: 0) {
                    Text(String(format: "%02d", i + 1)).font(OrotFont.caption).foregroundStyle(OrotColor.accent).frame(width: 28, alignment: .leading).padding(.top, 2)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.0).font(OrotFont.regular(14)).foregroundStyle(OrotColor.textPrimary)
                        Text(item.1).font(OrotFont.caption).lineSpacing(3).foregroundStyle(OrotColor.textSecondary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 10)
                .overlay(alignment: .top) { Rectangle().fill(OrotColor.hairline).frame(height: 1) }
            }
        }
        .padding(.horizontal, 8)
    }

    private static let items = [
        ("영상은 메모리에서 바로 사라져요", "카메라 화면은 1초에 한 번 확인한 뒤 곧바로 버려요. 사진이나 영상 파일을 만들지 않아요."),
        ("남는 건 집중 상태와 시간뿐이에요", "기록에는 1초마다의 상태(집중 · 잠시 멈춤 · 미확인)와 시각만 저장돼요."),
        ("누구인지 알아보지 않아요", "얼굴이 누구인지 알아보지 않아요. 얼굴이 화면에 있는지와 눈을 감고 있는지만 봐요."),
        ("인터넷 없이도 똑같이 동작해요", "처리에 네트워크를 쓰지 않아요. 기록도 이 기기에만 남아요."),
    ]
}
