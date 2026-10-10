//
//  OnboardingIntroInterstitialView.swift
//  Norma
//
//  Typographic beat between landing and the first question. Each phrase
//  waves in, holds, and crossfades to the next; after the last it hands
//  off. Tap anywhere to skip ahead. With VoiceOver on, the phrase is
//  announced and stays until the continue button.
//

import SwiftUI
import UIKit

struct OnboardingIntroInterstitialView: View {
    var phrases: [String] = [
        "first, how you get paid.",
        "then your bills. that's the whole setup.",
        "oh, and all your data stays on your device where it's safe.",
        "let's get started."
    ]
    /// How long each phrase lingers after its wave-in completes.
    var holdDuration: Double = 1.7
    let onContinue: () -> Void

    @State private var phraseIndex = 0
    @State private var didFinish = false
    /// Mirrors VoiceOver so an in-flight auto-advance can see it turn on.
    @State private var waitsForContinue = false

    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Soft tick that fires per word as the wave reveals it.
    private let wordHaptic = UIImpactFeedbackGenerator(style: .soft)

    var body: some View {
        ZStack {
            NormaPalette.canvas.ignoresSafeArea()

            if voiceOverEnabled {
                VoiceOverPhrasePrompt(phrase: phrases[phraseIndex], onContinue: advance)
            } else {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture(perform: advance)

                WaveTextView(
                    text: phrases[phraseIndex],
                    font: .system(size: 56, weight: .bold, relativeTo: .largeTitle),
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
        }
        .onAppear {
            waitsForContinue = voiceOverEnabled
            wordHaptic.prepare()
            if !voiceOverEnabled { scheduleAdvance() }
        }
        .onChange(of: voiceOverEnabled) { _, on in
            waitsForContinue = on
            if !on { scheduleAdvance() }
        }
    }

    // MARK: - Phrase timing

    /// The wave-in takes ~0.5s plus 0.06s per extra word; hold after that.
    /// Reduce Motion shows the phrase immediately, so only the hold remains.
    private func scheduleAdvance() {
        guard !voiceOverEnabled else { return }
        let wordCount = phrases[phraseIndex].split(separator: " ").count
        let waveIn = reduceMotion ? 0 : 0.5 + Double(max(0, wordCount - 1)) * 0.06
        let snapshot = phraseIndex
        DispatchQueue.main.asyncAfter(deadline: .now() + waveIn + holdDuration) {
            guard !waitsForContinue, phraseIndex == snapshot else { return }
            advance()
        }
    }

    private func advance() {
        guard !didFinish else { return }
        if phraseIndex < phrases.count - 1 {
            if reduceMotion {
                phraseIndex += 1
            } else {
                withAnimation(.easeInOut(duration: 0.35)) { phraseIndex += 1 }
            }
            if !voiceOverEnabled { scheduleAdvance() }
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
