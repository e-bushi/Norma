//
//  OnboardingInsightRubric.swift
//  Norma
//
//  Maps onboarding answers into a two-sentence capstone insight. The first
//  sentence is a persona mirror (priority-ordered pattern match across the
//  answer surface). The second is Norma's role, taken directly from the
//  whatsWorking choice.
//
//  Surface is intentionally narrow: the rubric is pure and side-effect-free
//  so it stays easy to tune without touching view code.
//

import Foundation

enum OnboardingInsightRubric {

    /// Result of running the rubric. Two sentences meant to be displayed as
    /// two animated phases on the capstone interstitial.
    struct Insight {
        let mirror: String
        let role: String
    }

    /// Inputs needed to compute the insight. Keeps the rubric independent
    /// of the live OnboardingViewModel so it's easy to test/preview.
    struct Inputs {
        let triedBefore: [String]
        let messyMoney: [String]
        let writingFrequency: String
        let moneyShapedThoughts: String
        let tabsCartsCameraRoll: String
        let thoughtsCameBack: String
        let incomeShape: String
        let whatsWorking: String
    }

    static func compute(_ inputs: Inputs) -> Insight {
        Insight(
            mirror: mirrorSentence(inputs),
            role: roleSentence(inputs)
        )
    }

    // MARK: - Mirror (persona-style)

    /// Priority-ordered cluster matching. The first cluster that matches the
    /// user's answers wins — most specific clusters sit at the top.
    private static func mirrorSentence(_ inputs: Inputs) -> String {
        // 1. Volatile improviser — irregular income + active money thinking.
        if (inputs.incomeShape == "lumpy" || inputs.incomeShape == "no_fixed") &&
            isHighClutter(inputs) {
            return "your income shows up in waves — and you've been forecasting in your head."
        }

        // 2. Buyer-thinker — pile of unmade decisions.
        if inputs.tabsCartsCameraRoll == "many" ||
            inputs.tabsCartsCameraRoll == "lost" ||
            inputs.messyMoney.contains("decisions") {
            return "your camera roll is full of decisions you haven't made yet."
        }

        // 3. Notes-app native — writes already, just not about money.
        if inputs.triedBefore.contains("notes_app") &&
            (inputs.writingFrequency == "every_day" || inputs.writingFrequency == "few_week") {
            return "you already write things down — your money just hasn't made it into the notes yet."
        }

        // 4. Bookkeeper that didn't stick — tried structure, structure broke.
        let triedStructured = inputs.triedBefore.contains("budgeting_app") ||
            inputs.triedBefore.contains("spreadsheet")
        let hasBillOrSubPain = inputs.messyMoney.contains("bills_surprise") ||
            inputs.messyMoney.contains("subs_creep")
        if triedStructured && hasBillOrSubPain {
            return "you tried the apps and the spreadsheets. they wanted you to maintain them — norma maintains itself."
        }

        // 5. Loop catcher — same thoughts keep returning.
        if inputs.thoughtsCameBack == "constant" {
            return "the same money thoughts keep looping back. that's the part norma was built for."
        }

        // 6. Default — running it in your head.
        return "you've been running the math in your head — and you're tired of it."
    }

    /// "High clutter" — at least one of the three thinking-about-money
    /// questions is on the heavier end. Used as a sub-gate for the volatile
    /// improviser cluster so it doesn't fire on someone with a quiet brain
    /// who just happens to have lumpy income.
    private static func isHighClutter(_ inputs: Inputs) -> Bool {
        let heavyThoughts = inputs.moneyShapedThoughts == "lots_15" ||
            inputs.moneyShapedThoughts == "uncount"
        let heavyTabs = inputs.tabsCartsCameraRoll == "many" ||
            inputs.tabsCartsCameraRoll == "lost"
        let heavyLoops = inputs.thoughtsCameBack == "constant" ||
            inputs.thoughtsCameBack == "a_few"
        return heavyThoughts || heavyTabs || heavyLoops
    }

    // MARK: - Role (from whatsWorking)

    private static func roleSentence(_ inputs: Inputs) -> String {
        switch inputs.whatsWorking {
        case "less_anx":
            return "norma's job: a smaller, quieter mental pile."
        case "not_behind":
            return "norma's job: bills that never sneak up again."
        case "decisions":
            return "norma's job: a place for the thinking to land, so intentions don't drift."
        case "clarity":
            return "norma's job: an honest picture of what you actually have."
        default:
            // Fallback when whatsWorking is unset (shouldn't happen, but be safe).
            return "norma's job: catch the money in your head before it disappears."
        }
    }
}
