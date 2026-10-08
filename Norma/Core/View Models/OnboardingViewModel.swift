//
//  OnboardingViewModel.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
class OnboardingViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var currentStep: OnboardingStep = .landing

    // Collected Data
    @Published var collectedData = UserOnboardingData()

    // Onboarding answers (May 2026 — financial-journal positioning).
    @Published var triedBefore: [String] = []      // multi-select
    @Published var messyMoney: [String] = []        // multi-select
    @Published var writingFrequency: String = ""
    @Published var incomeShape: String = ""
    @Published var whatsWorking: String = ""

    // Money-shaped-thoughts questions (O3e/f/g).
    @Published var moneyShapedThoughts: String = ""
    @Published var tabsCartsCameraRoll: String = ""
    @Published var thoughtsCameBack: String = ""

    // MARK: - Dependencies

    private let sessionViewModel: SessionViewModel
    var modelContainer: ModelContainer?

    // MARK: - Initialization

    init(sessionViewModel: SessionViewModel) {
        self.sessionViewModel = sessionViewModel
    }

    // MARK: - Onboarding Flow Methods

    func startOnboardingFlow() {
        collectedData = UserOnboardingData()
        triedBefore = []
        messyMoney = []
        writingFrequency = ""
        incomeShape = ""
        whatsWorking = ""
        moneyShapedThoughts = ""
        tabsCartsCameraRoll = ""
        thoughtsCameBack = ""
        currentStep = .landing
    }

    func moveToNextStep() {
        withAnimation {
            currentStep = currentStep.next()
        }
    }

    /// Persists the answers once the last question is done, then shows the
    /// welcome interstitial. The app opens when that interstitial finishes.
    func saveProfileAndContinue() {
        saveProfile()
        hydrateLocalProfile()
        moveToNextStep()
    }

    func completeOnboarding() {
        AnalyticsService.shared.track(.onboardingCompleted(durationSeconds: 0))
        sessionViewModel.completeOnboarding()
    }

    // MARK: - Persistence

    private func saveProfile() {
        let settings = ProfileSettings(
            currency: collectedData.currency,
            monthlyIncome: collectedData.monthlyIncome,
            freedomFund: collectedData.freedomFund,
            painPoint: collectedData.painPoint
        )

        let insights = OnboardingInsights(
            triedBefore: triedBefore.isEmpty ? nil : triedBefore.joined(separator: ","),
            messyMoney: messyMoney.isEmpty ? nil : messyMoney.joined(separator: ","),
            writingFrequency: writingFrequency.isEmpty ? nil : writingFrequency,
            incomeShape: incomeShape.isEmpty ? nil : incomeShape,
            whatsWorking: whatsWorking.isEmpty ? nil : whatsWorking,
            moneyShapedThoughts: moneyShapedThoughts.isEmpty ? nil : moneyShapedThoughts,
            tabsCartsCameraRoll: tabsCartsCameraRoll.isEmpty ? nil : tabsCartsCameraRoll,
            thoughtsCameBack: thoughtsCameBack.isEmpty ? nil : thoughtsCameBack
        )

        let profile = Profile(
            id: LocalStore.userId,
            userId: LocalStore.userId,
            email: "",
            name: collectedData.name,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            monthlyIncome: collectedData.monthlyIncome,
            freedomFund: collectedData.freedomFund,
            painPoint: collectedData.painPoint,
            settings: settings,
            onboardingInsights: insights
        )
        sessionViewModel.updateUserProfile(profile)
    }

    /// Mirror onboarding answers into the local SwiftData UserProfile so the
    /// AI always has context about the user.
    private func hydrateLocalProfile() {
        guard let container = modelContainer else { return }
        let context = container.mainContext

        let descriptor = FetchDescriptor<UserProfile>()
        let profile: UserProfile
        if let existing = try? context.fetch(descriptor).first {
            profile = existing
        } else {
            profile = UserProfile()
            context.insert(profile)
        }

        profile.currency = collectedData.currency
        if collectedData.incomeAmountPerPaycheck > 0 {
            profile.incomeAmount = collectedData.incomeAmountPerPaycheck
            profile.setIncomeCadence(onboardingCadence())
        } else if collectedData.monthlyIncome > 0 {
            // Legacy path (no per-paycheck captured): treat as monthly.
            profile.incomeAmount = collectedData.monthlyIncome
            profile.setIncomeCadence(.monthly(day: 1))
        }

        let onboardingFacts = buildOnboardingFacts()
        profile.facts = profile.facts.filter { $0.source != "onboarding" } + onboardingFacts
        profile.updatedAt = Date()
        try? context.save()
    }

    /// Reconstruct an IncomeCadence from the onboarding choice. Exact day is
    /// defaulted here (refined later in the calendar/profile editor); the
    /// cadence *type* is what fixes the monthly math.
    private func onboardingCadence() -> IncomeCadence {
        switch collectedData.incomeCadenceRaw {
        case "weekly":      return .weekly(weekday: 6)          // Fri
        case "biweekly":    return .biweekly(anchor: Date())    // ~last payday
        case "semiMonthly": return .semiMonthly(day1: 15, day2: 31)
        case "irregular":   return .irregular
        default:            return .monthly(day: 1)
        }
    }

    private func buildOnboardingFacts() -> [FinancialFact] {
        var facts: [FinancialFact] = []
        let triedLabels: [String: String] = [
            "budgeting_app": "a budgeting app", "spreadsheet": "spreadsheets",
            "notes_app": "a notes app", "in_my_head": "mental math"
        ]
        let messyLabels: [String: String] = [
            "no_clue": "not knowing where money goes", "bills_surprise": "bills surprising them",
            "subs_creep": "subscriptions creeping up", "decisions": "decisions piling up"
        ]
        let freqLabels: [String: String] = [
            "every_day": "writes things down every day",
            "few_week": "writes things down a few times a week",
            "sometimes": "writes things down sometimes",
            "almost_never": "almost never writes things down"
        ]
        let shapeLabels: [String: String] = [
            "steady": "steady paycheck", "lumpy": "lumpy/freelance income",
            "mix": "mix of salary and extras", "no_fixed": "no fixed income right now"
        ]
        let workingLabels: [String: String] = [
            "less_anx": "feeling less anxious about money",
            "not_behind": "not feeling behind on bills",
            "decisions": "acting on intentions instead of drifting",
            "clarity": "knowing what they actually have"
        ]
        let thoughtsLabels: [String: String] = [
            "few_3": "~3", "many_7": "~7", "lots_15": "~15", "uncount": "too many to count"
        ]
        let tabsLabels: [String: String] = [
            "couple": "a couple", "handful": "a handful",
            "many": "many", "lost": "lost count of"
        ]
        let loopLabels: [String: String] = [
            "once_twice": "money thoughts rarely loop back",
            "a_few": "a few money thoughts loop back unresolved",
            "constant": "money thoughts constantly loop back",
            "not_notice": "doesn't notice money thoughts looping anymore"
        ]

        func fact(_ text: String) { facts.append(FinancialFact(fact: text, source: "onboarding")) }

        if !triedBefore.isEmpty {
            let labels = triedBefore.compactMap { triedLabels[$0] }
            if !labels.isEmpty { fact("has tried \(labels.joined(separator: ", ")) before") }
        }
        if !messyMoney.isEmpty {
            let labels = messyMoney.compactMap { messyLabels[$0] }
            if !labels.isEmpty { fact("messiest money issues: \(labels.joined(separator: ", "))") }
        }
        if let label = freqLabels[writingFrequency] { fact(label) }
        if let label = shapeLabels[incomeShape] { fact("income shape: \(label)") }
        if let label = workingLabels[whatsWorking] { fact("success = \(label)") }
        if let label = thoughtsLabels[moneyShapedThoughts] {
            fact("\(label) unwritten money thoughts per week")
        }
        if let label = tabsLabels[tabsCartsCameraRoll] {
            fact("\(label) undecided items sitting in tabs/carts")
        }
        if let label = loopLabels[thoughtsCameBack] { fact(label) }

        return facts
    }
}

// MARK: - Supporting Types

enum OnboardingStep: CaseIterable {
    case landing

    // Brief animated interstitial after L1 "begin" — sets expectations
    // before peppering the user with questions.
    case intro

    // Card-based questions. Order here drives flow order via `next()`.
    case triedBefore           // O3  — "what have you tried before?"
    case messyMoney            // O3c — "what's the messiest part of money?" (multi-select)
    case writingFrequency      // O3b — "how often do you write things down?"

    // Milestone celebration #1 — after 3 questions. Dither pulse + a single
    // line of celebratory copy; auto-advances.
    case celebrationOne

    case moneyShapedThoughts   // O3e — "money-shaped thoughts you didn't write down"
    case tabsCartsCameraRoll   // O3f — "tabs, carts, camera roll waiting for a decision"
    case thoughtsCameBack      // O3g — "money thoughts that came back twice"

    // Milestone celebration #2 — after 6 questions.
    case celebrationTwo

    case incomeShape           // O4b — "how does your income show up?"
    case whatsWorking          // O4c — "what would 'this is working' feel like?"

    // Quantitative questions.
    case currencyIncome        // O4  — currency + monthly take-home (after tax)

    // Welcome — "hi, i'm norma" + "tell me your bills, i'll show you how long
    // your money lasts". The last screen before the app.
    case readyToStart

    case complete

    func next() -> OnboardingStep {
        let allCases = OnboardingStep.allCases
        guard let currentIndex = allCases.firstIndex(of: self),
              currentIndex < allCases.count - 1 else {
            return .complete
        }
        return allCases[currentIndex + 1]
    }
}
