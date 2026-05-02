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
    let onBack: () -> Void

    @State private var currencyCode: String = "USD"
    @State private var incomeText: String = ""
    @FocusState private var incomeFocused: Bool

    @State private var subtitleAppeared = false
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
                backButton
                    .padding(.top, 8)
                    .padding(.bottom, 24)

                titleView
                    .padding(.bottom, 12)

                Text("just helps norma show useful numbers. skip anything you'd rather not share.")
                    .font(.system(size: 14))
                    .foregroundStyle(NormaPalette.inkSubtle)
                    .lineSpacing(2)
                    .opacity(subtitleAppeared ? 1 : 0)
                    .offset(y: subtitleAppeared ? 0 : 8)
                    .padding(.bottom, 36)

                currencyField
                    .opacity(formAppeared ? 1 : 0)
                    .offset(y: formAppeared ? 0 : 12)
                    .padding(.bottom, 28)

                incomeField
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
            if onboardingViewModel.collectedData.monthlyIncome > 0 {
                incomeText = formattedNumber(onboardingViewModel.collectedData.monthlyIncome)
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.40)) { subtitleAppeared = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.55)) { formAppeared = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.70)) { ctaAppeared = true }
        }
    }

    // MARK: - Subviews

    private var backButton: some View {
        Button(action: {
            impactGenerator.impactOccurred()
            onBack()
        }) {
            Image(systemName: "chevron.left")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(NormaPalette.ink)
                .frame(width: 36, height: 36)
                .background(Circle().fill(NormaPalette.ink.opacity(0.05)))
                .overlay(Circle().strokeBorder(NormaPalette.ink.opacity(0.10), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var titleView: some View {
        WaveTextView(
            text: "what's the rhythm",
            font: .system(size: 38, weight: .bold),
            color: NormaPalette.ink,
            isAnimating: true,
            alignment: .leading,
            accentSuffix: "?",
            accentColor: NormaPalette.lavender,
            tracking: -1.2,
            wordSpacing: 6,
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
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("monthly take-home")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(0.8)
                    .foregroundStyle(NormaPalette.inkSubtle)
                Text("· optional")
                    .font(.system(size: 11))
                    .tracking(0.8)
                    .foregroundStyle(NormaPalette.inkMuted)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(currencySymbol(currencyCode))
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(NormaPalette.inkMuted)

                ZStack(alignment: .leading) {
                    if incomeText.isEmpty {
                        Text("0")
                            .font(.system(size: 56, weight: .bold))
                            .foregroundStyle(NormaPalette.inkMuted.opacity(0.5))
                    }
                    TextField("", text: $incomeText)
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(NormaPalette.ink)
                        .tint(NormaPalette.lavender)
                        .keyboardType(.numberPad)
                        .focused($incomeFocused)
                        .fixedSize(horizontal: true, vertical: false)
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
            }
            .tracking(-1.2)

            Text("helps norma show what's left after bills.")
                .font(.system(size: 12))
                .foregroundStyle(NormaPalette.inkMuted)
        }
    }

    private var continueBlock: some View {
        VStack(spacing: 14) {
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
                .background(Capsule().fill(NormaPalette.lavender))
                .shadow(color: NormaPalette.lavender.opacity(0.40), radius: 18, x: 0, y: 10)
            }
            .buttonStyle(.plain)

            Button(action: {
                impactGenerator.impactOccurred()
                skip()
            }) {
                Text("skip for now")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(NormaPalette.inkSubtle)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Actions

    private func saveAndContinue() {
        onboardingViewModel.collectedData.currency = currencyCode
        let parsed = Double(incomeText.filter(\.isNumber)) ?? 0
        onboardingViewModel.collectedData.monthlyIncome = parsed
        incomeFocused = false
        onContinue()
    }

    private func skip() {
        // Currency still defaults; income remains 0.
        onboardingViewModel.collectedData.currency = currencyCode
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
    OnboardingCurrencyIncomeView(onContinue: {}, onBack: {})
        .environmentObject(OnboardingViewModel(sessionViewModel: SessionViewModel(dataManager: DataManager())))
}
