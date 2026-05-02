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
        subtitle: "no judgement. helps norma tune the experience.",
        options: [
            .init(id: "budgeting_app", label: "a budgeting app", description: "mint, ynab, copilot"),
            .init(id: "spreadsheet",   label: "a spreadsheet",   description: "google sheets, excel"),
            .init(id: "notes_app",     label: "a notes app",     description: "apple notes, journal"),
            .init(id: "in_my_head",    label: "in my head",      description: "running totals, mental math")
        ],
        allowsMultiSelect: false
    )

    static let messyMoney = NormaCardQuestion(
        title: "what's the messiest part of money?",
        subtitle: "pick any that ring true.",
        options: [
            .init(id: "no_clue",        label: "i have no clue where it goes", description: "money disappears mid-month"),
            .init(id: "cash_lost",      label: "cash gets lost",               description: "no card trail"),
            .init(id: "bills_surprise", label: "bills surprise me",            description: "due dates, renewals"),
            .init(id: "subs_creep",     label: "subscriptions creep",          description: "small charges add up")
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
        title: "what would 'this is working' feel like?",
        subtitle: "we'll surface the right insights for you.",
        options: [
            .init(id: "knowing",   label: "knowing where money went",         description: "no more black holes"),
            .init(id: "less_anx",  label: "less anxious about money",         description: "having room to breathe"),
            .init(id: "catching",  label: "catching myself before i overspend", description: "awareness in the moment"),
            .init(id: "not_behind", label: "not feeling behind on bills",     description: "due dates that don't surprise me")
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

    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)

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
                    .opacity(cardsAppeared ? 1 : 0)
                    .offset(y: cardsAppeared ? 0 : 12)

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
            withAnimation(.easeOut(duration: 0.5).delay(0.55)) { cardsAppeared = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.70)) { ctaAppeared = true }
        }
    }

    private var titleView: some View {
        WaveTextView(
            text: question.title,
            font: .system(size: 38, weight: .bold),
            color: NormaPalette.ink,
            isAnimating: true,
            alignment: .leading,
            tracking: -1.2,
            wordSpacing: 8,
            lineSpacing: 0
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var cardsView: some View {
        VStack(spacing: 10) {
            ForEach(question.options) { option in
                cardRow(option)
            }
        }
    }

    private func cardRow(_ option: NormaCardQuestion.Option) -> some View {
        let isSelected = selected.contains(option.id)
        return Button(action: { toggle(option.id) }) {
            HStack(alignment: .center, spacing: 12) {
                radioIndicator(isSelected: isSelected)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(option.label)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(NormaPalette.ink)
                    Text(option.description)
                        .font(.system(size: 12))
                        .foregroundStyle(NormaPalette.inkSubtle)
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
        Button(action: {
            impactGenerator.impactOccurred()
            onContinue(selected)
        }) {
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
        .disabled(selected.isEmpty)
        .buttonStyle(.plain)
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
