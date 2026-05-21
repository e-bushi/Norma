//
//  OnboardingIntroInterstitialView.swift
//  Norma
//
//  Two-phase typographic interstitial. Each phase reveals its title with the
//  shared wave text animation, holds, then crossfades to the next phase.
//  After the second phase, hands off to the question flow. Tap anywhere to
//  skip forward (phase 1 → phase 2 → continue).
//

import SwiftUI
import UIKit

struct OnboardingIntroInterstitialView: View {
    let phases: [String]
    let onContinue: () -> Void

    /// Default phrases for the very first interstitial in the onboarding flow.
    /// New callers should pass their own phrases — the defaults stay for
    /// backwards compatibility with the existing `.intro` step.
    init(
        phases: [String] = [
            "first, a few questions.",
            "no wrong answers. just helps norma fit you."
        ],
        onContinue: @escaping () -> Void
    ) {
        self.phases = phases
        self.onContinue = onContinue
    }

    @State private var phaseIndex: Int = 0
    @State private var didFinish: Bool = false

    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)
    /// Soft tick that fires per word as the wave reveals it.
    private let wordHaptic = UIImpactFeedbackGenerator(style: .soft)

    var body: some View {
        ZStack {
            NormaPalette.canvas.ignoresSafeArea()

            // Tap anywhere to skip forward.
            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .onTapGesture { skipForward() }

            WaveTextView(
                text: phases[phaseIndex],
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
            .id(phaseIndex)
            .transition(.opacity)
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            impactGenerator.prepare()
            wordHaptic.prepare()
            schedulePhaseAdvance()
        }
    }

    // MARK: - Phase logic

    private func schedulePhaseAdvance() {
        // Wave-in finishes ~ (0.5 + (n - 1) * 0.06)s, plus a hold, then advance.
        let wordCount = phases[phaseIndex].split(separator: " ").count
        let inDuration = 0.5 + Double(max(0, wordCount - 1)) * 0.06
        let holdDuration: Double = 1.7
        let totalShow = inDuration + holdDuration

        let snapshotIndex = phaseIndex
        DispatchQueue.main.asyncAfter(deadline: .now() + totalShow) {
            guard !didFinish, phaseIndex == snapshotIndex else { return }
            advance()
        }
    }

    private func advance() {
        guard !didFinish else { return }
        if phaseIndex < phases.count - 1 {
            withAnimation(.easeInOut(duration: 0.35)) {
                phaseIndex += 1
            }
            schedulePhaseAdvance()
        } else {
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
        impactGenerator.impactOccurred()
        onContinue()
    }
}

#Preview {
    OnboardingIntroInterstitialView(onContinue: {})
}
