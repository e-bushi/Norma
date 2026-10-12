//
//  OnboardingFlowView.swift
//  Norma
//
//  Landing → intro → "what's your rhythm" → welcome. Answers stay in memory until
//  the welcome finishes; only then is the profile saved, which flips
//  RootView over to home. Quitting mid-way leaves nothing behind.
//

import SwiftData
import SwiftUI

struct OnboardingFlowView: View {
    private enum Step { case landing, intro, rhythm, welcome }

    @Environment(\.modelContext) private var modelContext
    @State private var step: Step = .landing
    @State private var currency: String = {
        let local = Locale.current.currency?.identifier ?? "USD"
        return Money.currencies.contains { $0.code == local } ? local : "USD"
    }()
    @State private var amountText = ""
    @State private var cadence = CadenceDraft()

    var body: some View {
        ZStack {
            NormaPalette.canvas.ignoresSafeArea()

            switch step {
            case .landing:
                LandingPageView { advance(to: .intro) }
                    .transition(.opacity)
            case .intro:
                OnboardingIntroInterstitialView { advance(to: .rhythm) }
                    .transition(.opacity)
            case .rhythm:
                OnboardingCurrencyIncomeView(currency: $currency, amountText: $amountText, cadence: $cadence) {
                    advance(to: .welcome)
                }
                .transition(.opacity)
            case .welcome:
                OnboardingCelebrationView(
                    phrases: ["hi, i'm norma.", "tell me your bills.", "i'll show you what's left."],
                    onContinue: createProfile
                )
                .transition(.opacity)
            }
        }
    }

    private func advance(to next: Step) {
        withAnimation(.easeInOut(duration: 0.35)) { step = next }
    }

    private func createProfile() {
        let profile = UserProfile(
            currency: currency,
            incomeAmount: Money.parse(amountText) ?? 0,
            incomeCadence: cadence.cadence
        )
        modelContext.insert(profile)
        try? modelContext.save()
    }
}
