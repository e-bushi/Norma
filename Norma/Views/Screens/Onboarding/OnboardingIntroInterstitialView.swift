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
    let onContinue: () -> Void

    private let phases: [String] = [
        "first, a few questions.",
        "no wrong answers. just helps norma fit you."
    ]

    @State private var phaseIndex: Int = 0
    @State private var didFinish: Bool = false

    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)

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
                lineSpacing: 0
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
