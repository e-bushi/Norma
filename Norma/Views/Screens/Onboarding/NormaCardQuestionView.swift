//
//  NormaCardQuestionView.swift
//  Norma
//
//  Card-list question screen matching the Paper O3 / O3b / O3c / O4b / O4c
//  artboards. Lavender dither shader on dark canvas, heavy lowercase title,
//  radio-style cards with selected/unselected states, lavender continue pill.
//
//  Used for the five card-based onboarding questions:
//    triedBefore, messyMoney, writingFrequency, incomeShape, whatsWorking
//

import SwiftUI

// MARK: - Question model

struct NormaCardQuestion {
    let title: String
    let subtitle: String?
    let options: [Option]
    let allowsMultiSelect: Bool

    struct Option: Identifiable {
        let id: String
        let label: String
        let description: String
    }
}

extension NormaCardQuestion {
    static let triedBefore = NormaCardQuestion(
        title: "what have you tried before?",
        subtitle: "pick any that apply.",
        options: [
            .init(id: "budgeting_app", label: "a budgeting app", description: "mint, ynab, copilot"),
            .init(id: "spreadsheet",   label: "a spreadsheet",   description: "google sheets, excel"),
            .init(id: "notes_app",     label: "a notes app",     description: "apple notes, journal"),
            .init(id: "in_my_head",    label: "in my head",      description: "running totals, mental math")
        ],
        allowsMultiSelect: true
    )

    static let messyMoney = NormaCardQuestion(
        title: "what's the messiest part of money?",
        subtitle: "pick any that ring true.",
        options: [
            .init(id: "no_clue",        label: "i have no clue where it goes", description: "money disappears mid-month"),
            .init(id: "bills_surprise", label: "bills surprise me",            description: "due dates, renewals"),
            .init(id: "subs_creep",     label: "subscriptions creep",          description: "small charges add up"),
            .init(id: "decisions",      label: "decisions pile up",            description: "things i keep meaning to do")
        ],
        allowsMultiSelect: true
    )

    static let writingFrequency = NormaCardQuestion(
        title: "how often do you write things down?",
        subtitle: "notes, journals, anywhere — not just for norma.",
        options: [
            .init(id: "every_day",  label: "every day",          description: "like a journal"),
            .init(id: "few_week",   label: "a few times a week", description: "when something's on my mind"),
            .init(id: "sometimes",  label: "sometimes",          description: "when it's worth keeping"),
            .init(id: "almost_never", label: "almost never",     description: "i think more than i write")
        ],
        allowsMultiSelect: false
    )

    static let incomeShape = NormaCardQuestion(
        title: "how does your income show up?",
        subtitle: "this shapes how norma forecasts.",
        options: [
            .init(id: "steady",   label: "a steady paycheck",         description: "same amount, same time"),
            .init(id: "lumpy",    label: "lumpy or freelance",        description: "projects, gigs, bonuses"),
            .init(id: "mix",      label: "a mix of both",             description: "salary plus extras"),
            .init(id: "no_fixed", label: "no fixed income right now", description: "saving, transitioning")
        ],
        allowsMultiSelect: false
    )

    static let whatsWorking = NormaCardQuestion(
        title: "how would you know this app is really working for you?",
        subtitle: "we'll surface the right insights for you.",
        options: [
            .init(id: "less_anx",   label: "less anxious about money",     description: "having room to breathe"),
            .init(id: "not_behind", label: "not feeling behind on bills",  description: "due dates that don't surprise me"),
            .init(id: "decisions",  label: "deciding on things i meant to", description: "intentions that don't drift"),
            .init(id: "clarity",    label: "knowing what i actually have",  description: "no more guessing")
        ],
        allowsMultiSelect: false
    )

    // MARK: - Money-shaped thoughts (O3e/f/g)
    //
    // Three questions that probe the latent demand for catching money-related
    // thoughts. Each measures the same underlying gap from a different angle:
    // unwritten thoughts, stalled decisions, repeat-loop thoughts.

    static let moneyShapedThoughts = NormaCardQuestion(
        title: "in the last week, how many money-shaped thoughts crossed your mind that you didn't write down?",
        subtitle: nil,
        options: [
            .init(id: "few_3",   label: "3",                  description: "a quiet week"),
            .init(id: "many_7",  label: "7",                  description: "sounds about right"),
            .init(id: "lots_15", label: "15",                 description: "it's been a month"),
            .init(id: "uncount", label: "too many to count",  description: "")
        ],
        allowsMultiSelect: false
    )

    static let tabsCartsCameraRoll = NormaCardQuestion(
        title: "how many things are sitting in tabs, carts, or your camera roll right now, waiting for a decision?",
        subtitle: nil,
        options: [
            .init(id: "couple",    label: "a couple",              description: "tidy device"),
            .init(id: "handful",   label: "a handful",             description: "a small pile"),
            .init(id: "many",      label: "more than i want to admit", description: ""),
            .init(id: "lost",      label: "lost count",            description: "")
        ],
        allowsMultiSelect: false
    )

    static let thoughtsCameBack = NormaCardQuestion(
        title: "how many money thoughts came back twice because you didn't catch them the first time?",
        subtitle: nil,
        options: [
            .init(id: "once_twice", label: "once or twice",       description: "a quiet brain"),
            .init(id: "a_few",      label: "a few",               description: "the usual hum"),
            .init(id: "constant",   label: "constantly",          description: "a known loop"),
            .init(id: "not_notice", label: "i don't notice anymore", description: "")
        ],
        allowsMultiSelect: false
    )
}

// MARK: - View

struct NormaCardQuestionView: View {
    let question: NormaCardQuestion
    let onContinue: (Set<String>) -> Void

    @State private var selected: Set<String> = []
    @State private var subtitleAppeared = false
    @State private var cardsAppeared = false
    @State private var ctaAppeared = false
    @State private var isDismissing = false

    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)

    /// Choice appearance/disappearance spring. Matches the design spec
    /// (CASpringAnimation: stiffness 350, damping 50, initial velocity 30).
    /// Overdamped — fast settle, no overshoot.
    private static let choiceSpring: Animation = .interpolatingSpring(
        mass: 1,
        stiffness: 350,
        damping: 50,
        initialVelocity: 30
    )

    /// Time the dismiss animation needs to settle before we hand off to the
    /// next step. All cards animate together, so this is just the spring's
    /// approximate settle duration.
    private var dismissHandoffDelay: Double { 0.5 }

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

                titleView
                    .padding(.bottom, 12)

                if let subtitle = question.subtitle {
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(NormaPalette.inkSubtle)
                        .opacity(subtitleAppeared ? 1 : 0)
                        .offset(y: subtitleAppeared ? 0 : 8)
                        .padding(.bottom, 24)
                }

                cardsView

                Spacer().frame(height: 28)

                continueButton
                    .opacity(ctaAppeared ? 1 : 0)
                    .offset(y: ctaAppeared ? 0 : 12)

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            impactGenerator.prepare()
            withAnimation(.easeOut(duration: 0.5).delay(0.40)) { subtitleAppeared = true }
            // Cards drive themselves via the per-row .animation modifier;
            // we just flip the boolean after a beat so they enter on cue.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                cardsAppeared = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.70)) { ctaAppeared = true }
        }
    }

    private var titleView: some View {
        WaveTextView(
            text: question.title,
            font: .system(size: 38, weight: .heavy),
            color: NormaPalette.ink,
            isAnimating: true,
            alignment: .leading,
            tracking: -1.2,
            wordSpacing: 8,
            lineSpacing: 0
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        // Fade out in lockstep with the choices on dismiss. The title's
        // entrance is owned by WaveTextView; this opacity only flips when
        // we kick off the dismiss path.
        .opacity(isDismissing ? 0 : 1)
        .animation(Self.choiceSpring, value: isDismissing)
    }

    private var cardsView: some View {
        VStack(spacing: 10) {
            ForEach(question.options) { option in
                cardRow(option)
                    .opacity(cardsAppeared ? 1 : 0)
                    .offset(y: cardsAppeared ? 0 : 12)
                    .animation(Self.choiceSpring, value: cardsAppeared)
            }
        }
    }

    private func cardRow(_ option: NormaCardQuestion.Option) -> some View {
        let isSelected = selected.contains(option.id)
        return Button(action: { toggle(option.id) }) {
            HStack(alignment: .center, spacing: 12) {
                radioIndicator(isSelected: isSelected)

                VStack(alignment: .leading, spacing: 3) {
                    Text(option.label)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(NormaPalette.ink)
                    if !option.description.isEmpty {
                        Text(option.description)
                            .font(.system(size: 12))
                            .foregroundStyle(NormaPalette.inkSubtle)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? NormaPalette.lavender.opacity(0.10) : Color(red: 0.11, green: 0.11, blue: 0.125))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isSelected ? NormaPalette.lavender : NormaPalette.ink.opacity(0.06),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func radioIndicator(isSelected: Bool) -> some View {
        ZStack {
            if isSelected {
                Circle()
                    .fill(NormaPalette.lavender)
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(NormaPalette.canvas)
            } else {
                Circle()
                    .strokeBorder(NormaPalette.ink.opacity(0.30), lineWidth: 1.5)
            }
        }
        .frame(width: 16, height: 16)
    }

    private var continueButton: some View {
        Button(action: dismissAndContinue) {
            HStack(spacing: 8) {
                Text("continue")
                    .font(.system(size: 15, weight: .semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(NormaPalette.canvas)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(
                Capsule().fill(selected.isEmpty
                    ? NormaPalette.lavender.opacity(0.40)
                    : NormaPalette.lavender)
            )
            .shadow(
                color: NormaPalette.lavender.opacity(selected.isEmpty ? 0 : 0.40),
                radius: 18, x: 0, y: 10
            )
        }
        .disabled(selected.isEmpty || isDismissing)
        .buttonStyle(.plain)
    }

    /// Plays the disappearance animation in reverse-stagger order, then
    /// hands off to the parent. We don't want the parent to swap us out
    /// instantly — the choices should *leave* using the same spring they
    /// arrived with.
    private func dismissAndContinue() {
        guard !isDismissing else { return }
        isDismissing = true
        impactGenerator.impactOccurred()

        // Cards exit on the same spring + per-index delay. Subtitle and CTA
        // fade out lightly so the screen breathes out as one motion.
        cardsAppeared = false
        withAnimation(.easeIn(duration: 0.25)) {
            subtitleAppeared = false
            ctaAppeared = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + dismissHandoffDelay) {
            onContinue(selected)
        }
    }

    private func toggle(_ id: String) {
        impactGenerator.impactOccurred()
        if question.allowsMultiSelect {
            if selected.contains(id) {
                selected.remove(id)
            } else {
                selected.insert(id)
            }
        } else {
            selected = [id]
        }
    }
}

#Preview("triedBefore") {
    NormaCardQuestionView(question: .triedBefore) { _ in }
}

#Preview("messyMoney (multi)") {
    NormaCardQuestionView(question: .messyMoney) { _ in }
}
