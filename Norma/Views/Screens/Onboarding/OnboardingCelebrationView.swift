//
//  OnboardingCelebrationView.swift
//  Norma
//
//  Milestone interstitial sprinkled between question groups. Dither shader
//  blooms outward from center as a single line of celebratory copy waves
//  in. Auto-advances after the bloom completes; tap to skip forward.
//
//  Designed as one reusable view that takes its phrase via init — keeps the
//  three milestone screens identical in mechanics but distinct in copy.
//

import SwiftUI
import UIKit

struct OnboardingCelebrationView: View {
    let phrase: String
    let onContinue: () -> Void

    /// Drives the dither shader's circular mask. Same idea as NoteCanvasView:
    /// 0 = collapsed, 1 = full coverage. We bloom from a near-collapsed value
    /// at appear, hold briefly, then collapse before handing off so the next
    /// screen lands on a dark canvas.
    @State private var waveScale: CGFloat = 0
    @State private var didFinish: Bool = false

    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)
    /// Soft tick that fires per word as the celebration phrase waves in.
    private let wordHaptic = UIImpactFeedbackGenerator(style: .soft)

    var body: some View {
        ZStack {
            NormaPalette.canvas.ignoresSafeArea()

            DitherShaderView(intensity: 1.0)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .mask(
                    GeometryReader { geo in
                        let diameter = hypot(geo.size.width, geo.size.height) * 2
                        Circle()
                            .frame(width: diameter, height: diameter)
                            .scaleEffect(waveScale)
                            .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    }
                    .ignoresSafeArea()
                )

            // Light vignette so the headline reads cleanly over the bloom.
            RadialGradient(
                colors: [
                    NormaPalette.canvas.opacity(0),
                    NormaPalette.canvas.opacity(0.55)
                ],
                center: .center,
                startRadius: 80,
                endRadius: 360
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .onTapGesture { skipForward() }

            WaveTextView(
                text: phrase,
                font: .system(size: 56, weight: .bold),
                color: NormaPalette.ink,
                isAnimating: true,
                alignment: .leading,
                tracking: -1.5,
                wordSpacing: 12,
                lineSpacing: 0,
                onWordAppear: { _ in
                    wordHaptic.impactOccurred(intensity: 0.55)
                    wordHaptic.prepare()
                }
            )
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
        .onAppear { runChoreography() }
    }

    // MARK: - Choreography

    private func runChoreography() {
        impactGenerator.prepare()
        wordHaptic.prepare()

        // Bloom out from center.
        withAnimation(.easeOut(duration: 0.7)) {
            waveScale = 1.0
        }

        // Small thump as the bloom peaks.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            impactGenerator.impactOccurred()
        }

        // Hold, then collapse the bloom before handing off so the next screen
        // doesn't see a still-expanded dither field.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeIn(duration: 0.55)) {
                waveScale = 0
            }
        }

        // Hand off to the next step after the collapse finishes.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.65) {
            finish()
        }
    }

    private func skipForward() {
        guard !didFinish else { return }
        finish()
    }

    private func finish() {
        guard !didFinish else { return }
        didFinish = true
        onContinue()
    }
}

#Preview {
    OnboardingCelebrationView(
        phrase: "nice. norma's starting to know you.",
        onContinue: {}
    )
}
