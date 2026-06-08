//
//  OnboardingCelebrationView.swift
//  Norma
//
//  Milestone interstitial sprinkled between question groups. Dither shader
//  blooms outward from center while a line of copy waves in. Holds, then
//  either crossfades to the next phrase (multi-phrase callers like the
//  post-auth welcome) or collapses and hands off. Auto-advances; tap to skip.
//
//  One reusable view: pass a single `phrase` for the milestone screens, or
//  `phrases` for a phased sequence (e.g. the "hi, i'm norma" welcome).
//

import SwiftUI
import UIKit

struct OnboardingCelebrationView: View {
    let phrases: [String]
    let onContinue: () -> Void
    /// How long each phrase holds on screen before advancing / collapsing.
    var holdPerPhrase: Double = 2.0

    init(phrase: String, holdPerPhrase: Double = 2.0, onContinue: @escaping () -> Void) {
        self.phrases = [phrase]
        self.holdPerPhrase = holdPerPhrase
        self.onContinue = onContinue
    }

    init(phrases: [String], holdPerPhrase: Double = 2.0, onContinue: @escaping () -> Void) {
        self.phrases = phrases
        self.holdPerPhrase = holdPerPhrase
        self.onContinue = onContinue
    }

    /// Drives the dither shader's circular mask. Same idea as NoteCanvasView:
    /// 0 = collapsed, 1 = full coverage. We bloom from a near-collapsed value
    /// at appear, hold briefly, then collapse before handing off so the next
    /// screen lands on a dark canvas.
    @State private var waveScale: CGFloat = 0
    @State private var phraseIndex: Int = 0
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
                text: phrases[phraseIndex],
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
            .id(phraseIndex)
            .transition(.opacity)
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

        schedulePhase()
    }

    /// Hold the current phrase, then crossfade to the next one — or, on the
    /// last phrase, collapse the bloom and hand off.
    private func schedulePhase() {
        let snapshot = phraseIndex
        DispatchQueue.main.asyncAfter(deadline: .now() + holdPerPhrase) {
            guard !didFinish, phraseIndex == snapshot else { return }
            advance()
        }
    }

    private func advance() {
        guard !didFinish else { return }
        if phraseIndex < phrases.count - 1 {
            impactGenerator.impactOccurred()
            withAnimation(.easeInOut(duration: 0.35)) {
                phraseIndex += 1
            }
            schedulePhase()
        } else {
            collapseAndFinish()
        }
    }

    private func collapseAndFinish() {
        guard !didFinish else { return }
        // Collapse the bloom before handing off so the next screen doesn't
        // see a still-expanded dither field.
        withAnimation(.easeIn(duration: 0.55)) {
            waveScale = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            finish()
        }
    }

    private func skipForward() {
        guard !didFinish else { return }
        advance()
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
