//
//  PaywallView.swift
//  Norma
//
//  Editorial paywall. Three contexts share one component:
//   - .onboarding   → first-run trial offer at the end of onboarding
//   - .trialExpired → returning user whose trial lapsed
//   - .settings     → managerial entry from the settings sheet
//
//  Context drives copy (hero story, CTA, disclosure) and chrome
//  (dismissibility). Visual: dither shader backdrop, heavy editorial
//  typography that wave-fades in to match the rest of onboarding.
//

import SwiftUI
import RevenueCat

enum PaywallContext {
    case onboarding
    case trialExpired
    case settings
}

struct PaywallView: View {
    let context: PaywallContext

    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @SwiftUI.Environment(\.dismiss) private var dismiss

    @State private var isPurchasing = false
    @State private var showError = false
    @State private var showTermsOfUse = false
    @State private var showPrivacyPolicy = false

    // Entrance choreography
    @State private var headlineAppeared = false
    @State private var subheadAppeared = false
    @State private var plansAppeared = false
    @State private var ctaAppeared = false
    @State private var footerAppeared = false

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
    private var accentPurple: Color { NormaPalette.lavender }

    /// Spring used for every entrance on the page. Matches onboarding's
    /// design-system spring (stiffness 350, damping 50, initialVelocity 30).
    private static let pageSpring: Animation = .interpolatingSpring(
        mass: 1,
        stiffness: 350,
        damping: 50,
        initialVelocity: 30
    )

    init(context: PaywallContext = .settings) {
        self.context = context
    }

    var body: some View {
        ZStack {
            NormaPalette.canvas.ignoresSafeArea()

            // Dither shader + bottom-fade gradient — same backdrop the
            // onboarding question screens use, so the paywall reads as a
            // continuation of that language rather than a separate sheet.
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

            VStack(spacing: 0) {
                navBar

                // Push everything below toward the lower half of the screen.
                // The flexible Spacer absorbs slack on tall phones; a minHeight
                // keeps the hero off the status bar/notch on compact ones.
                Spacer(minLength: 24)

                VStack(alignment: .leading, spacing: 28) {
                    heroStory
                    planCardsSection
                    ctaButton
                    disclosureText
                    legalRow
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
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
        .onAppear { runEntranceAnimation() }
    }

    // MARK: - Nav

    @ViewBuilder
    private var navBar: some View {
        // Only the settings context is dismissible. Onboarding + trial-expired
        // are hard walls — the only way past is purchase or restore.
        if context == .settings {
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
        } else {
            Spacer().frame(height: 36)
        }
    }

    // MARK: - Hero story

    /// Editorial story block. Three context-aware lines (two headline beats
    /// + a subhead) that establish what the user gets and why.
    private var heroStory: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(storyHeadline.line1)
                .font(.system(size: 48, weight: .bold))
                .tracking(-1.3)
                .lineSpacing(0)
                .foregroundStyle(cream)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(headlineAppeared ? 1 : 0)
                .offset(y: headlineAppeared ? 0 : 14)
                .animation(Self.pageSpring, value: headlineAppeared)

            Text(storyHeadline.line2)
                .font(.system(size: 48, weight: .bold))
                .tracking(-1.3)
                .lineSpacing(0)
                .foregroundStyle(cream)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(headlineAppeared ? 1 : 0)
                .offset(y: headlineAppeared ? 0 : 14)
                .animation(Self.pageSpring.delay(0.08), value: headlineAppeared)

            Text(storyHeadline.subhead)
                .font(.custom(FontFamily.Rubik.medium, size: 16))
                .foregroundStyle(cream.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
                .opacity(subheadAppeared ? 1 : 0)
                .offset(y: subheadAppeared ? 0 : 10)
                .animation(Self.pageSpring, value: subheadAppeared)
        }
    }

    /// Context-aware copy. The onboarding context mirrors what the user
    /// just did in the voice practice — they wrote sentences and watched
    /// norma extract structure — so the pitch lands on the act they
    /// already performed rather than a generic feature list.
    private var storyHeadline: (line1: String, line2: String, subhead: String) {
        switch context {
        case .onboarding:
            return (
                "you wrote a",
                "few sentences",
                "norma turned them into bills, plans, and reminders. this is the part you don't have to do anymore."
            )
        case .trialExpired:
            return (
                "your trial",
                "wrapped up",
                "ready to keep going? pick a plan and norma stays right where you left it."
            )
        case .settings:
            return (
                "norma",
                "pro",
                "everything in one place — for what's due, what's coming, and what you keep meaning to buy."
            )
        }
    }

    // MARK: - Plan cards

    private var planCardsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
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
        .opacity(plansAppeared ? 1 : 0)
        .offset(y: plansAppeared ? 0 : 12)
        .animation(Self.pageSpring, value: plansAppeared)
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
                } else {
                    Text(ctaCopy)
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
        .opacity(ctaAppeared ? 1 : 0)
        .offset(y: ctaAppeared ? 0 : 12)
        .animation(Self.pageSpring, value: ctaAppeared)
    }

    /// CTA copy depends on whether the user is eligible for the free trial.
    /// Onboarding + first-time trial-eligible users see "Start for $0.00".
    /// Returning users who've already burned their trial see "Subscribe."
    private var ctaCopy: String {
        if subscriptionManager.hasUsedFreeTrial && !subscriptionManager.isInFreeTrial {
            return "subscribe"
        }
        return "start for $0.00"
    }

    // MARK: - Disclosure

    private var disclosureText: some View {
        Text(disclosureCopy)
            .font(.custom(FontFamily.Rubik.regular, size: 12))
            .foregroundStyle(dimText)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .opacity(ctaAppeared ? 1 : 0)
            .animation(Self.pageSpring.delay(0.05), value: ctaAppeared)
    }

    /// Apple requires the price terms visible whenever a free-trial CTA is
    /// shown. We surface them here as a single quiet line under the CTA.
    private var disclosureCopy: String {
        guard let product = findProduct(isMonthly: selectedBilling == .monthly) else {
            return "3 days free, then auto-renews. cancel anytime."
        }
        let price = product.priceString
        let cadence = product.isMonthly ? "month" : "year"

        if subscriptionManager.hasUsedFreeTrial && !subscriptionManager.isInFreeTrial {
            return "auto-renews at \(price)/\(cadence). cancel anytime."
        }
        return "3 days free, then \(price)/\(cadence). cancel anytime."
    }

    // MARK: - Legal

    private var legalRow: some View {
        HStack(spacing: 14) {
            Button("terms") { showTermsOfUse = true }
            Text("·").foregroundStyle(dimText)
            Button("privacy") { showPrivacyPolicy = true }
            Text("·").foregroundStyle(dimText)
            Button("restore") {
                Task { await restorePurchases() }
            }
        }
        .font(.custom(FontFamily.Rubik.medium, size: 12))
        .foregroundStyle(mutedText)
        .frame(maxWidth: .infinity)
        .opacity(footerAppeared ? 1 : 0)
        .animation(Self.pageSpring, value: footerAppeared)
    }

    // MARK: - Dynamic Pricing

    private var monthlyProduct: SubscriptionProduct? {
        subscriptionManager.availableProducts.first { $0.isMonthly }
    }

    private var annualProduct: SubscriptionProduct? {
        subscriptionManager.availableProducts.first { !$0.isMonthly }
    }

    private var monthlyPriceText: String {
        guard let product = monthlyProduct else { return "$3.99/mo" }
        return "\(product.priceString)/mo"
    }

    private var annualPriceText: String {
        guard let product = annualProduct else { return "$3.33/mo, billed annually" }
        if let monthlyEquiv = product.monthlyEquivalentPrice {
            return "\(monthlyEquiv)/mo, billed annually"
        }
        return "\(product.priceString)/yr"
    }

    private var annualStrikethroughText: String? {
        guard let monthly = monthlyProduct else { return "$3.99/mo" }
        return "\(monthly.priceString)/mo"
    }

    private var annualBadgeText: String? {
        guard let annual = annualProduct else { return "save 16%" }
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
                    handleSuccessfulPurchase()
                } else {
                    await subscriptionManager.checkSubscriptionStatus()
                    if subscriptionManager.hasActiveSubscription {
                        handleSuccessfulPurchase()
                    }
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
                handleSuccessfulPurchase()
            }
        } catch {
            showError = true
        }
    }

    /// Settings dismisses the sheet on success. Onboarding/trial-expired
    /// are gates — the parent observes hasActiveSubscription and removes
    /// the gate itself, so we just need the status to flip.
    private func handleSuccessfulPurchase() {
        if context == .settings {
            dismiss()
        }
    }

    // MARK: - Entrance

    private func runEntranceAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) { headlineAppeared = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) { subheadAppeared = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { plansAppeared = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.70) { ctaAppeared = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) { footerAppeared = true }
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

#Preview("onboarding") {
    PaywallView(context: .onboarding)
}

#Preview("trial expired") {
    PaywallView(context: .trialExpired)
}

#Preview("settings") {
    Color.black
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            PaywallView(context: .settings)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
}
