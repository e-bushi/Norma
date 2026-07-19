//
//  OnboardingCurrencyIncomeView.swift
//  Norma
//
//  O4 — "what's the rhythm?". Default currency picker (lavender pill) +
//  optional monthly take-home input (huge bold number with lavender caret).
//  Save & continue or skip-for-now.
//

import SwiftUI
import UIKit

struct OnboardingCurrencyIncomeView: View {
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    let onContinue: () -> Void

    @State private var currencyCode: String = "USD"
    @State private var incomeText: String = ""
    @State private var cadence: CadenceChoice = .monthly
    @FocusState private var incomeFocused: Bool

    // Onboarding captures the cadence *type* + amount; exact day is refined
    // later in the calendar/profile editor. Mirrors IncomeCadence.
    private enum CadenceChoice: String, CaseIterable {
        case weekly, biweekly, semiMonthly, monthly, irregular
        var label: String {
            switch self {
            case .weekly:      return "weekly"
            case .biweekly:    return "every 2 weeks"
            case .semiMonthly: return "twice a month"
            case .monthly:     return "monthly"
            case .irregular:   return "it varies"
            }
        }
        /// Average paydays per month — converts the per-paycheck amount to the
        /// monthly figure settings needs. Keep in sync with IncomeCadence.
        var occurrencesPerMonth: Double {
            switch self {
            case .weekly:      return 52.0 / 12.0
            case .biweekly:    return 26.0 / 12.0
            case .semiMonthly: return 2
            case .monthly, .irregular: return 1
            }
        }
    }

    @State private var formAppeared = false
    @State private var ctaAppeared = false

    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)

    // Common currencies surfaced in the picker. CurrencyData has the full set;
    // these are the popular ones for the menu. The user can pick any of these.
    private let popularCurrencies: [(code: String, flag: String)] = [
        ("USD", "🇺🇸"),
        ("EUR", "🇪🇺"),
        ("GBP", "🇬🇧"),
        ("CAD", "🇨🇦"),
        ("AUD", "🇦🇺"),
        ("JPY", "🇯🇵"),
        ("CNY", "🇨🇳"),
        ("INR", "🇮🇳"),
        ("THB", "🇹🇭"),
        ("MXN", "🇲🇽"),
        ("BRL", "🇧🇷"),
        ("SGD", "🇸🇬"),
        ("HKD", "🇭🇰"),
        ("KRW", "🇰🇷"),
        ("CHF", "🇨🇭"),
    ]

    var body: some View {
        ZStack {
            NormaPalette.canvas.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 56)

                titleView
                    .padding(.bottom, 36)

                currencyField
                    .opacity(formAppeared ? 1 : 0)
                    .offset(y: formAppeared ? 0 : 12)
                    .padding(.bottom, 28)

                incomeField
                    .opacity(formAppeared ? 1 : 0)
                    .offset(y: formAppeared ? 0 : 12)
                    .padding(.bottom, 24)

                cadenceField
                    .opacity(formAppeared ? 1 : 0)
                    .offset(y: formAppeared ? 0 : 12)

                Spacer(minLength: 24)

                continueBlock
                    .opacity(ctaAppeared ? 1 : 0)
                    .offset(y: ctaAppeared ? 0 : 12)
                    .frame(maxWidth: .infinity)

                Spacer().frame(height: 36)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            impactGenerator.prepare()
            currencyCode = onboardingViewModel.collectedData.currency.isEmpty
                ? "USD"
                : onboardingViewModel.collectedData.currency
            let seed = onboardingViewModel.collectedData.incomeAmountPerPaycheck > 0
                ? onboardingViewModel.collectedData.incomeAmountPerPaycheck
                : onboardingViewModel.collectedData.monthlyIncome
            if seed > 0 { incomeText = formattedNumber(seed) }
            if let saved = CadenceChoice(rawValue: onboardingViewModel.collectedData.incomeCadenceRaw) {
                cadence = saved
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.55)) { formAppeared = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.70)) { ctaAppeared = true }
        }
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
            Text("default currency")
                .font(.system(size: 11, weight: .medium))
                .tracking(0.8)
                .foregroundStyle(NormaPalette.inkSubtle)

            Menu {
                ForEach(popularCurrencies, id: \.code) { entry in
                    Button(action: {
                        impactGenerator.impactOccurred()
                        currencyCode = entry.code
                    }) {
                        HStack {
                            Text("\(entry.flag) \(entry.code)")
                            if currencyCode == entry.code {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Text(flagForCode(currencyCode))
                        .font(.system(size: 18))
                    Text(currencyCode)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(NormaPalette.ink)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(NormaPalette.ink.opacity(0.7))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Capsule().fill(NormaPalette.lavender.opacity(0.10))
                )
                .overlay(
                    Capsule().strokeBorder(NormaPalette.lavender.opacity(0.45), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var incomeField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("amount per paycheck (after taxes)")
                .font(.system(size: 11, weight: .medium))
                .tracking(0.8)
                .foregroundStyle(NormaPalette.inkSubtle)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(currencySymbol(currencyCode))
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(NormaPalette.inkMuted)

                ZStack(alignment: .leading) {
                    if incomeText.isEmpty {
                        Text("0")
                            .font(.system(size: 56, weight: .bold))
                            .foregroundStyle(NormaPalette.inkMuted.opacity(0.5))
                            .allowsHitTesting(false)
                    }
                    TextField("", text: $incomeText)
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(NormaPalette.ink)
                        .tint(NormaPalette.lavender)
                        .keyboardType(.numberPad)
                        .focused($incomeFocused)
                        .onChange(of: incomeText) { _, newValue in
                            // Strip non-digits, then re-format with commas.
                            let digits = newValue.filter(\.isNumber)
                            if digits.isEmpty {
                                incomeText = ""
                            } else if let n = Double(digits) {
                                let formatted = formattedNumber(n)
                                if formatted != incomeText {
                                    incomeText = formatted
                                }
                            }
                        }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .tracking(-1.2)
            // Make the whole row a focus target so taps anywhere on it (incl.
            // the visible "0" placeholder or whitespace next to the symbol)
            // bring up the keyboard. Without this, an empty TextField had ~0pt
            // hit area and a currency change could shift the tap zone away
            // from where the user expected it.
            .contentShape(Rectangle())
            .onTapGesture { incomeFocused = true }

            Text("helps norma show what's left after bills.")
                .font(.system(size: 12))
                .foregroundStyle(NormaPalette.inkMuted)
        }
    }

    private var cadenceField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("how often do you get paid?")
                .font(.system(size: 11, weight: .medium))
                .tracking(0.8)
                .foregroundStyle(NormaPalette.inkSubtle)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(CadenceChoice.allCases, id: \.self) { choice in
                    cadenceChip(choice)
                }
            }
        }
    }

    private func cadenceChip(_ choice: CadenceChoice) -> some View {
        let active = cadence == choice
        return Button {
            impactGenerator.impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { cadence = choice }
        } label: {
            Text(choice.label)
                .font(.system(size: 14, weight: active ? .semibold : .medium))
                .foregroundStyle(active ? NormaPalette.canvas : NormaPalette.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity)
                .background {
                    if active { Capsule().fill(NormaPalette.lavender) }
                }
                .overlay(
                    Capsule().strokeBorder(
                        active ? NormaPalette.lavender : NormaPalette.ink.opacity(0.28),
                        style: active ? StrokeStyle(lineWidth: 1) : StrokeStyle(lineWidth: 1, dash: [3, 3])
                    )
                )
        }
        .buttonStyle(.plain)
    }

    private var continueBlock: some View {
        Button(action: {
            impactGenerator.impactOccurred()
            saveAndContinue()
        }) {
            HStack(spacing: 8) {
                Text("save and continue")
                    .font(.system(size: 15, weight: .semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(NormaPalette.canvas)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Capsule().fill(canProceed ? NormaPalette.lavender : NormaPalette.lavender.opacity(0.40)))
            .shadow(color: NormaPalette.lavender.opacity(canProceed ? 0.40 : 0), radius: 18, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .disabled(!canProceed)
    }

    /// Income is now required — the user must enter at least one digit before
    /// continue unlocks. Currency defaults to USD so it always validates.
    private var canProceed: Bool {
        let digits = incomeText.filter(\.isNumber)
        return !digits.isEmpty
    }

    // MARK: - Actions

    private func saveAndContinue() {
        onboardingViewModel.collectedData.currency = currencyCode
        let perPaycheck = Double(incomeText.filter(\.isNumber)) ?? 0
        onboardingViewModel.collectedData.incomeAmountPerPaycheck = perPaycheck
        onboardingViewModel.collectedData.incomeCadenceRaw = cadence.rawValue
        // Derived monthly figure for settings (forecast/calendar read this).
        onboardingViewModel.collectedData.monthlyIncome = perPaycheck * cadence.occurrencesPerMonth
        incomeFocused = false
        onContinue()
    }

    // MARK: - Helpers

    private func flagForCode(_ code: String) -> String {
        popularCurrencies.first(where: { $0.code == code })?.flag ?? "🏳️"
    }

    private func currencySymbol(_ code: String) -> String {
        NormaPalette.currencySymbol(for: code)
    }

    private func formattedNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }
}

#Preview {
    OnboardingCurrencyIncomeView(onContinue: {})
        .environmentObject(OnboardingViewModel(sessionViewModel: SessionViewModel(dataManager: DataManager())))
}
