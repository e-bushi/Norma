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

    private var canProceed: Bool { Money.parse(amountText) != nil }

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
        // The number pad has no return key, so tapping anywhere outside the
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
            font: .system(size: 56, weight: .bold, relativeTo: .largeTitle),
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
                        .font(.system(size: 18, relativeTo: .body))
                    Text(currency)
                        .font(.system(size: 16, weight: .semibold, relativeTo: .body))
                        .foregroundStyle(NormaPalette.ink)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold, relativeTo: .caption))
                        .foregroundStyle(NormaPalette.inkSubtle)
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

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(Money.symbol(for: currency))
                    .font(.system(size: 56, weight: .bold, relativeTo: .largeTitle))
                    .foregroundStyle(NormaPalette.inkMuted)

                ZStack(alignment: .leading) {
                    if amountText.isEmpty {
                        Text("0")
                            .font(.system(size: 56, weight: .bold, relativeTo: .largeTitle))
                            .foregroundStyle(NormaPalette.inkMuted)
                            .allowsHitTesting(false)
                    }
                    TextField("", text: $amountText)
                        .font(.system(size: 56, weight: .bold, relativeTo: .largeTitle))
                        .foregroundStyle(NormaPalette.ink)
                        .tint(NormaPalette.lavender)
                        .keyboardType(.numberPad)
                        .focused($amountFocused)
                        .onChange(of: amountText) { _, newValue in
                            let digits = newValue.filter(\.isNumber)
                            let formatted = Double(digits).map(Self.grouped) ?? ""
                            if formatted != amountText { amountText = formatted }
                        }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .tracking(-1.2)
            // An empty TextField has almost no hit area, so the whole row
            // focuses it — including the "0" placeholder and the symbol.
            .contentShape(Rectangle())
            .onTapGesture { amountFocused = true }
        }
    }

    private static func grouped(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
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
