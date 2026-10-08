//
//  LandingPageView.swift
//  Norma
//
//  First screen. Dithered shader over the dark canvas, the n. logomark, the
//  promise in one line, and a begin button.
//

import SwiftUI

struct LandingPageView: View {
    let onBegin: () -> Void

    @State private var logoAppeared = false
    @State private var heroAppeared = false
    @State private var subtitleAppeared = false
    @State private var ctaAppeared = false

    var body: some View {
        ZStack {
            NormaPalette.canvas.ignoresSafeArea()

            DitherShaderView(intensity: 1.0)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            LinearGradient(
                stops: [
                    .init(color: NormaPalette.canvas.opacity(0),    location: 0.00),
                    .init(color: NormaPalette.canvas.opacity(0),    location: 0.18),
                    .init(color: NormaPalette.canvas.opacity(0.55), location: 0.40),
                    .init(color: NormaPalette.canvas.opacity(0.85), location: 0.62),
                    .init(color: NormaPalette.canvas,               location: 0.88)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                logoMark
                    .opacity(logoAppeared ? 1 : 0)
                    .offset(y: logoAppeared ? 0 : 8)
                    .padding(.bottom, 28)

                heroText
                    .opacity(heroAppeared ? 1 : 0)
                    .offset(y: heroAppeared ? 0 : 12)
                    .padding(.bottom, 18)

                Text("add your bills and your paycheck. norma shows what's left each month. no account, and nothing leaves your phone.")
                    .font(.system(size: 14))
                    .foregroundStyle(NormaPalette.inkSubtle)
                    .lineSpacing(2)
                    .frame(maxWidth: 320, alignment: .leading)
                    .opacity(subtitleAppeared ? 1 : 0)
                    .offset(y: subtitleAppeared ? 0 : 8)
                    .padding(.bottom, 28)

                beginButton
                    .opacity(ctaAppeared ? 1 : 0)
                    .offset(y: ctaAppeared ? 0 : 16)

                Spacer().frame(height: 56)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.10)) { logoAppeared = true }
            withAnimation(.easeOut(duration: 0.6).delay(0.25)) { heroAppeared = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.45)) { subtitleAppeared = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.60)) { ctaAppeared = true }
        }
    }

    private var logoMark: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(NormaPalette.canvas)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(NormaPalette.ink.opacity(0.08), lineWidth: 1)
                )

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("n")
                    .font(.system(size: 36, weight: .black))
                    .foregroundStyle(NormaPalette.ink)
                Text(".")
                    .font(.system(size: 36, weight: .black))
                    .foregroundStyle(NormaPalette.lavender)
            }
            .offset(x: -1, y: 4)
        }
        .frame(width: 52, height: 52)
    }

    private var heroText: some View {
        (Text("what's left\nafter bills").foregroundStyle(NormaPalette.ink)
            + Text(".").foregroundStyle(NormaPalette.lavender))
            .font(.system(size: 56, weight: .bold))
            .tracking(-1.5)
    }

    private var beginButton: some View {
        Button {
            Haptics.tap()
            onBegin()
        } label: {
            HStack(spacing: 8) {
                Text("begin")
                    .font(.system(size: 15, weight: .semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(NormaPalette.onAccent)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(Capsule().fill(NormaPalette.lavender))
            .shadow(color: NormaPalette.lavender.opacity(0.45), radius: 18, x: 0, y: 10)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

#Preview {
    LandingPageView(onBegin: {})
}
