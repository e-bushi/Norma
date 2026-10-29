//
//  OnboardingCurrencyIncomeView.swift
//  Norma
//
//  "what's your rhythm" — currency, take-home per paycheck, and when pay
//  lands. The payday detail matters: a biweekly month can hold two
//  paychecks or three, and what's left depends on which.
//

import SwiftUI

struct OnboardingCurrencyIncomeView: View {
    @Binding var currency: String
    @Binding var amountText: String
    @Binding var cadence: CadenceDraft
    let onContinue: () -> Void

    @FocusState private var amountFocused: Bool
    @State private var appeared = false

    /// The form starts staggering in as the title's wave is finishing.
    private let formDelay = 0.5
    private let staggerStep = 0.07

    private var canProceed: Bool { Money.parse(amountText, currency: currency) != nil }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                titleView
                    .padding(.top, 56)
                    .padding(.bottom, 36)

                VStack(alignment: .leading, spacing: 28) {
                    currencyField
                        .staggeredAppear(appeared, index: 0, baseDelay: formDelay, step: staggerStep)
                    amountField
                        .staggeredAppear(appeared, index: 1, baseDelay: formDelay, step: staggerStep)
                    CadencePicker(
                        draft: $cadence,
                        isRevealed: appeared,
                        revealDelay: formDelay + 2 * staggerStep
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollDismissesKeyboard(.interactively)
        // The decimal pad has no return key, so tapping anywhere outside the
        // amount row dismisses it. Child buttons and the row's own focus tap win.
        .contentShape(Rectangle())
        .onTapGesture { amountFocused = false }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "continue", systemImage: "arrow.right", isEnabled: canProceed) {
                amountFocused = false
                onContinue()
            }
            .staggeredAppear(appeared, index: 4, baseDelay: formDelay, step: staggerStep)
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .background(NormaPalette.canvas)
        }
        .onAppear { appeared = true }
    }

    // MARK: - Subviews

    private var titleView: some View {
        WaveTextView(
            text: "what's your rhythm",
            font: .system(size: 56, weight: .bold),
            color: NormaPalette.ink,
            isAnimating: true,
            alignment: .leading,
            accentSuffix: ".",
            accentColor: NormaPalette.lavender,
            tracking: -1.5,
            wordSpacing: 12,
            lineSpacing: 0
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var currencyField: some View {
        VStack(alignment: .leading, spacing: 10) {
            FieldLabel("currency")

            Menu {
                Picker("currency", selection: $currency) {
                    ForEach(Money.currencies) { entry in
                        Text("\(entry.flag) \(entry.code)").tag(entry.code)
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Text(Money.flag(for: currency))
                        .font(.system(size: 18))
                    Text(currency)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(NormaPalette.ink)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(NormaPalette.ink.opacity(0.7))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Capsule().fill(NormaPalette.lavender.opacity(0.10)))
                .overlay(Capsule().strokeBorder(NormaPalette.lavender.opacity(0.45), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private var amountField: some View {
        VStack(alignment: .leading, spacing: 10) {
            FieldLabel(cadence.kind == .irregular ? "about how much a month, after tax" : "amount per paycheck, after tax")

            MoneyAmountField(
                currency: currency,
                text: $amountText,
                amountFont: .system(size: 56, weight: .bold),
                symbolFont: .system(size: 56, weight: .bold),
                tracking: -1.2,
                isFocused: $amountFocused
            )
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    OnboardingCurrencyIncomeView(
        currency: .constant("USD"),
        amountText: .constant(""),
        cadence: .constant(CadenceDraft()),
        onContinue: {}
    )
    .background(NormaPalette.canvas)
}
