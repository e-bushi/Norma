//
//  PaywallView.swift
//  Norma
//
//  D9/D10 dark editorial paywall: hero, feature list, plan cards, lavender
//  CTA capsule. Replaces the warm pastel + coin-radar background with the
//  flat dark language used by SettingsView, CalendarSheet, and BillsView.
//

import SwiftUI
import RevenueCat

struct PaywallView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @SwiftUI.Environment(\.dismiss) private var dismiss

    @State private var isPurchasing = false
    @State private var showError = false
    @State private var showTermsOfUse = false
    @State private var showPrivacyPolicy = false

    enum BillingOption {
        case monthly
        case yearly
    }

    @State private var selectedBilling: BillingOption = .yearly

    private let bg = Color(red: 0x16/255, green: 0x16/255, blue: 0x1A/255)
    private let cream = Color(red: 0xF2/255, green: 0xED/255, blue: 0xE2/255)
    private let mutedText = Color(red: 0x7A/255, green: 0x76/255, blue: 0x70/255)
    private let dimText = Color(red: 0x5C/255, green: 0x58/255, blue: 0x52/255)
    private let onAccent = Color(red: 0x0E/255, green: 0x0E/255, blue: 0x10/255)
    private let accentPurple = Color(red: 0x96/255, green: 0x76/255, blue: 0xD9/255)
    private let danger = Color(red: 0xE0/255, green: 0x7B/255, blue: 0x6F/255)

    private var heroFont: Font { .system(size: 56, weight: .heavy) }

    var body: some View {
        VStack(spacing: 0) {
            navBar

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    heroBlock

                    featureList

                    socialProofLabel

                    planCardsSection

                    ctaButton

                    reassuranceText

                    legalRow
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
        }
        .background(bg.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(subscriptionManager.purchaseError?.localizedDescription ?? "An error occurred")
        }
        .sheet(isPresented: $showTermsOfUse) {
            WebViewSheet(
                url: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/",
                title: "Terms of Use"
            )
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            WebViewSheet(
                url: "https://mauldin.xyz/norma/privacy",
                title: "Privacy Policy"
            )
        }
        .task {
            if subscriptionManager.availableProducts.isEmpty {
                await subscriptionManager.loadProducts()
            }
            await subscriptionManager.checkSubscriptionStatus()
        }
    }

    // MARK: - Nav

    private var navBar: some View {
        HStack {
            Spacer()
            Button {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(cream.opacity(0.85))
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }

    // MARK: - Hero

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("subscription")
                .font(.custom(FontFamily.Rubik.medium, size: 13))
                .foregroundStyle(mutedText)

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("norma pro")
                    .font(heroFont)
                    .tracking(-2.24)
                    .foregroundStyle(cream)
                Text(".")
                    .font(heroFont)
                    .tracking(-2.24)
                    .foregroundStyle(accentPurple)
            }

            Text("financial clarity for wherever you call home.")
                .font(.custom(FontFamily.Rubik.medium, size: 15))
                .foregroundStyle(mutedText)
                .padding(.top, 2)
        }
    }

    // MARK: - Feature list

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("what you get")
                .font(.custom(FontFamily.Rubik.semiBold, size: 11))
                .tracking(0.88)
                .textCase(.uppercase)
                .foregroundStyle(cream)
                .padding(.bottom, 4)

            PaywallFeatureRow(icon: "brain.head.profile", text: "ai companion for logging & insights")
            PaywallFeatureRow(icon: "shield.lefthalf.filled", text: "build arcs of financial safety")
            PaywallFeatureRow(icon: "flame.fill", text: "voice-driven note capture")
            PaywallFeatureRow(icon: "coloncurrencysign.arrow.trianglehead.counterclockwise.rotate.90", text: "live currency rates and conversions")
        }
    }

    // MARK: - Social proof

    private var socialProofLabel: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(accentPurple)
                .frame(width: 6, height: 6)
            Text("early adopter pricing · locked in forever")
                .font(.custom(FontFamily.Rubik.medium, size: 11))
                .tracking(0.44)
                .textCase(.uppercase)
                .foregroundStyle(mutedText)
        }
    }

    // MARK: - Plan cards

    private var planCardsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("choose a plan")
                .font(.custom(FontFamily.Rubik.semiBold, size: 11))
                .tracking(0.88)
                .textCase(.uppercase)
                .foregroundStyle(cream)
                .padding(.bottom, 2)

            PaywallPlanCard(
                title: "annual",
                price: annualPriceText,
                badge: annualBadgeText,
                strikethroughPrice: annualStrikethroughText,
                isSelected: selectedBilling == .yearly
            ) {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedBilling = .yearly
                }
            }

            PaywallPlanCard(
                title: "monthly",
                price: monthlyPriceText,
                isSelected: selectedBilling == .monthly
            ) {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedBilling = .monthly
                }
            }
        }
    }

    // MARK: - CTA

    private var ctaButton: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            Task { await purchaseSelectedProduct() }
        } label: {
            Group {
                if isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: onAccent))
                } else if subscriptionManager.isLoadingProducts {
                    HStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: onAccent))
                            .scaleEffect(0.8)
                        Text("loading…")
                            .font(.custom(FontFamily.Rubik.semiBold, size: 16))
                    }
                } else if subscriptionManager.availableProducts.isEmpty {
                    Text("tap to retry")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 16))
                } else if subscriptionManager.hasUsedFreeTrial && !subscriptionManager.isInFreeTrial {
                    Text("subscribe now")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 16))
                } else {
                    Text("start 7-day free trial")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 16))
                }
            }
            .foregroundStyle(onAccent)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Capsule().fill(accentPurple))
            .overlay(Capsule().stroke(accentPurple.opacity(0.7), lineWidth: 1))
            .shadow(color: accentPurple.opacity(0.35), radius: 18, x: 0, y: 0)
            .contentShape(Capsule())
        }
        .disabled(isPurchasing || subscriptionManager.isLoadingProducts)
        .buttonStyle(PaywallPressButtonStyle())
    }

    // MARK: - Reassurance

    private var reassuranceText: some View {
        Text("no payment now. cancel anytime.")
            .font(.custom(FontFamily.Rubik.regular, size: 12).italic())
            .foregroundStyle(dimText)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Legal

    private var legalRow: some View {
        HStack(spacing: 14) {
            Button("terms") { showTermsOfUse = true }
            Text("·").foregroundStyle(dimText)
            Button("privacy") { showPrivacyPolicy = true }
            Text("·").foregroundStyle(dimText)
            Button("restore purchases") {
                Task { await restorePurchases() }
            }
        }
        .font(.custom(FontFamily.Rubik.medium, size: 12))
        .foregroundStyle(mutedText)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Dynamic Pricing

    private var monthlyProduct: SubscriptionProduct? {
        subscriptionManager.availableProducts.first { $0.isMonthly }
    }

    private var annualProduct: SubscriptionProduct? {
        subscriptionManager.availableProducts.first { !$0.isMonthly }
    }

    private var monthlyPriceText: String {
        guard let product = monthlyProduct else { return "$9.99/mo" }
        return "\(product.priceString)/mo"
    }

    private var annualPriceText: String {
        guard let product = annualProduct else { return "$8.33/mo, billed annually" }
        if let monthlyEquiv = product.monthlyEquivalentPrice {
            return "\(monthlyEquiv)/mo, billed annually"
        }
        return "\(product.priceString)/yr"
    }

    /// The monthly price shown as a crossed-out reference on the annual card.
    private var annualStrikethroughText: String? {
        guard let monthly = monthlyProduct else { return "$9.99/mo" }
        return "\(monthly.priceString)/mo"
    }

    private var annualBadgeText: String? {
        guard let annual = annualProduct else { return "save 17%" }
        if let monthly = monthlyProduct {
            let monthlyPrice = (monthly.package.storeProduct.price as NSDecimalNumber).doubleValue
            let annualMonthly = (annual.package.storeProduct.price as NSDecimalNumber).doubleValue / 12
            let savings = ((monthlyPrice - annualMonthly) / monthlyPrice) * 100
            return savings > 0 ? "save \(Int(savings.rounded()))%" : nil
        }
        return annual.savingsPercentage
    }

    // MARK: - Actions

    private func findProduct(isMonthly: Bool) -> SubscriptionProduct? {
        subscriptionManager.availableProducts.first { $0.isMonthly == isMonthly }
    }

    private func purchaseSelectedProduct() async {
        if subscriptionManager.availableProducts.isEmpty {
            await subscriptionManager.loadProducts()
            if subscriptionManager.availableProducts.isEmpty {
                showError = true
                return
            }
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            if let product = findProduct(isMonthly: selectedBilling == .monthly) {
                try await subscriptionManager.purchase(product)
                try? await Task.sleep(nanoseconds: 500_000_000)
                if subscriptionManager.hasActiveSubscription {
                    dismiss()
                } else {
                    await subscriptionManager.checkSubscriptionStatus()
                    dismiss()
                }
            }
        } catch {
            showError = true
        }
    }

    private func restorePurchases() async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            try await subscriptionManager.restorePurchases()
            if subscriptionManager.hasActiveSubscription {
                dismiss()
            }
        } catch {
            showError = true
        }
    }
}

// MARK: - Button Style

struct PaywallPressButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    Color.black
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            PaywallView()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
}
