//
//  OnboardingIntroInterstitialView.swift
//  Norma
//
//  Typographic beat between landing and the first question. Each phrase
//  waves in, holds, and crossfades to the next; after the last it hands
//  off. Tap anywhere to skip ahead.
//

import SwiftUI
import UIKit

struct OnboardingIntroInterstitialView: View {
    var phrases: [String] = [
        "first, how you get paid.",
        "then your bills. that's the whole setup.",
        "oh, and all your data stays on your device where it's safe.",
        "let's get started.",
    ]
    /// How long each phrase lingers after its wave-in completes.
    var holdDuration: Double = 1.7
    let onContinue: () -> Void

    @State private var phraseIndex = 0
    @State private var didFinish = false

    /// Soft tick that fires per word as the wave reveals it.
    private let wordHaptic = UIImpactFeedbackGenerator(style: .soft)

    var body: some View {
        ZStack {
            NormaPalette.canvas.ignoresSafeArea()

            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .onTapGesture(perform: advance)

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
            .allowsHitTesting(false)
        }
        .onAppear {
            wordHaptic.prepare()
            scheduleAdvance()
        }
    }

    // MARK: - Phrase timing

    /// The wave-in takes ~0.5s plus 0.06s per extra word; hold after that.
    private func scheduleAdvance() {
        let wordCount = phrases[phraseIndex].split(separator: " ").count
        let waveIn = 0.5 + Double(max(0, wordCount - 1)) * 0.06
        let snapshot = phraseIndex
        DispatchQueue.main.asyncAfter(deadline: .now() + waveIn + holdDuration) {
            guard phraseIndex == snapshot else { return }
            advance()
        }
    }

    private func advance() {
        guard !didFinish else { return }
        if phraseIndex < phrases.count - 1 {
            withAnimation(.easeInOut(duration: 0.35)) { phraseIndex += 1 }
            scheduleAdvance()
        } else {
            didFinish = true
            Haptics.tap()
            onContinue()
        }
    }
}

#Preview {
    OnboardingIntroInterstitialView(onContinue: {})
}
