//
//  PaywallView.swift
//  Norma
//
//  Created by Assistant on 7/31/25.
//

import SwiftUI
import RevenueCat

struct PaywallView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var showTermsOfUse = false
    @State private var showPrivacyPolicy = false

    enum BillingOption {
        case monthly
        case yearly
    }

    @State private var selectedBilling: BillingOption = .yearly
    @State private var scrollOffset: CGFloat = 0
    @State private var animateText = false
    @State private var showFeatures = false
    @State private var showPlans = false
    @State private var showCTA = false
    @State private var showEarlyAdopterInfo = false

    private let accentColor = Color("NormaPastelPurple")

    var body: some View {
        ZStack {
            // Full-bleed background image with parallax
            Image("wow-god-is-good")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .scaleEffect(1.3)
                .offset(y: -scrollOffset * 0.3)
                .ignoresSafeArea()

            // Gradient overlay for readability
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.clear, location: 0.0),
                    .init(color: Color("NormaPastelPink").opacity(0.5), location: 0.3),
                    .init(color: Color("NormaPastelPink").opacity(0.85), location: 0.5),
                    .init(color: Color("NormaPastelPink"), location: 0.65)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Spacer for hero area (let background image show through)
                    Spacer()
                        .frame(height: 180)

                    // Content below hero
                    VStack(spacing: 24) {
                        // Tagline
                        taglineSection

                        // Headline
                        headlineSection

                        // Feature cards
                        featureCardsSection

                        // Plan cards
                        planCardsSection

                        // CTA button
                        ctaButton

                        // Reassurance
                        reassuranceText

                        // Legal row
                        legalRow
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .scrollIndicators(.hidden)
            .scrollContentBackground(.hidden)
            .onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.y
            } action: { _, newValue in
                scrollOffset = newValue
            }

        }
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(subscriptionManager.purchaseError?.localizedDescription ?? "An error occurred")
        }
        .alert("Early Adopter Pricing", isPresented: $showEarlyAdopterInfo) {
            Button("Got it") { }
        } message: {
            Text("You're one of our first users! The price you see today is the lowest it'll ever be. Once you subscribe, that rate is yours to keep — even as prices go up for new members.")
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
        .onAppear {
            Task {
                if subscriptionManager.availableProducts.isEmpty {
                    await subscriptionManager.loadProducts()
                }
                await subscriptionManager.checkSubscriptionStatus()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateText = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                showFeatures = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                showPlans = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                showCTA = true
            }
        }
    }

    // MARK: - Tagline

    private var taglineSection: some View {
        WaveTextView(
            text: "Built for nomads, by nomads",
            font: .custom(FontFamily.Rubik.regular, size: 16),
            color: .black,
            isAnimating: animateText,
            alignment: .leading
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Headline

    private var headlineSection: some View {
        WaveTextView(
            text: "Your Money, Under Control",
            font: .custom(FontFamily.Rubik.bold, size: 56),
            color: .black,
            isAnimating: animateText,
            alignment: .leading
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Feature Cards

    private var featureCardsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                PaywallFeatureCard(
                    icon: "brain.head.profile",
                    iconColor: Color("NormaPastelPurple"),
                    title: "Financial AI Companion",
                    description: "Smart logging, insights, and answers\non tap"
                )
                .opacity(showFeatures ? 1 : 0)
                .offset(x: showFeatures ? 0 : 40)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.0), value: showFeatures)

                PaywallFeatureCard(
                    icon: "shield.lefthalf.filled",
                    iconColor: Color("NormaPastelPurple"),
                    title: "Build Arcs of Freedom",
                    description: "Stack arcs, cover bills, and build\nsafety"
                )
                .opacity(showFeatures ? 1 : 0)
                .offset(x: showFeatures ? 0 : 40)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.08), value: showFeatures)

                PaywallFeatureCard(
                    icon: "flame.fill",
                    iconColor: Color("NormaPastelPurple"),
                    title: "Spending Challenges",
                    description: "Daily caps, streaks, and birds to\ncollect"
                )
                .opacity(showFeatures ? 1 : 0)
                .offset(x: showFeatures ? 0 : 40)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.16), value: showFeatures)

                PaywallFeatureCard(
                    icon: "coloncurrencysign.arrow.trianglehead.counterclockwise.rotate.90",
                    iconColor: Color("NormaPastelPurple"),
                    title: "Currency Tools",
                    description: "Live rates, conversions, and local\ncontext"
                )
                .opacity(showFeatures ? 1 : 0)
                .offset(x: showFeatures ? 0 : 40)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.24), value: showFeatures)

                PaywallFeatureCard(
                    icon: "bell.badge.fill",
                    iconColor: Color("NormaPastelPurple"),
                    title: "Never Miss a Bill",
                    description: "Visual calendar, alerts, and due dates\ntracked"
                )
                .opacity(showFeatures ? 1 : 0)
                .offset(x: showFeatures ? 0 : 40)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.32), value: showFeatures)
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, -20)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Plan Cards

    private var planCardsSection: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 4)
            Button {
                showEarlyAdopterInfo = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 13))
                    Text("Early adopter pricing")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 14))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color("NormaPastelPurple").opacity(0.45))
                        .glassEffect(.clear, in: Capsule())
                )
            }
            .buttonStyle(PlanCardButtonStyle())
            .padding(.bottom, 4)
            .opacity(showPlans ? 1 : 0)
            .animation(.easeOut(duration: 0.4), value: showPlans)

            PaywallPlanCard(
                title: "Monthly",
                price: monthlyPriceText,
                isSelected: selectedBilling == .monthly
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedBilling = .monthly
                }
            }
            .opacity(showPlans ? 1 : 0)
            .offset(y: showPlans ? 0 : 24)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showPlans)

            PaywallPlanCard(
                title: "Annual",
                price: annualPriceText,
                badge: annualBadgeText,
                isSelected: selectedBilling == .yearly
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedBilling = .yearly
                }
            }
            .opacity(showPlans ? 1 : 0)
            .offset(y: showPlans ? 0 : 24)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.08), value: showPlans)
        }
    }

    // MARK: - CTA Button

    private var ctaButton: some View {
        Button {
            Task { await purchaseSelectedProduct() }
        } label: {
            Group {
                if isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if subscriptionManager.isLoadingProducts {
                    HStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        Text("Loading...")
                            .font(.custom(FontFamily.Rubik.regular, size: 14))
                    }
                } else if subscriptionManager.availableProducts.isEmpty {
                    Text("Tap to retry")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 17))
                } else if subscriptionManager.hasUsedFreeTrial && !subscriptionManager.isInFreeTrial {
                    Text("Subscribe Now")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 17))
                } else {
                    Text("Start 7-Day Free Trial")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 17))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                Capsule()
                    .fill(accentColor.opacity(0.45))
                    .glassEffect(.clear, in: Capsule())
            )
        }
        .disabled(isPurchasing || subscriptionManager.isLoadingProducts)
        .buttonStyle(PaywallPressButtonStyle())
        .opacity(showCTA ? 1 : 0)
        .scaleEffect(showCTA ? 1 : 0.9)
        .animation(.spring(response: 0.6, dampingFraction: 0.75), value: showCTA)
    }

    // MARK: - Reassurance

    private var reassuranceText: some View {
        Text("No payment now. Cancel anytime.")
            .font(.custom(FontFamily.Rubik.regular, size: 13))
            .foregroundColor(.black.opacity(0.6))
            .frame(maxWidth: .infinity)
            .opacity(showCTA ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.1), value: showCTA)
    }

    // MARK: - Legal Row

    private var legalRow: some View {
        HStack(spacing: 12) {
            Button("Terms") { showTermsOfUse = true }
            Text("·").foregroundColor(.black.opacity(0.4))
            Button("Privacy") { showPrivacyPolicy = true }
            Text("·").foregroundColor(.black.opacity(0.4))
            Button("Restore Purchases") {
                Task { await restorePurchases() }
            }
        }
        .font(.custom(FontFamily.Rubik.regular, size: 12))
        .foregroundColor(.black.opacity(0.5))
        .opacity(showCTA ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.2), value: showCTA)
    }

    // MARK: - Dynamic Pricing

    private var monthlyProduct: SubscriptionProduct? {
        subscriptionManager.availableProducts.first { $0.isMonthly }
    }

    private var annualProduct: SubscriptionProduct? {
        subscriptionManager.availableProducts.first { !$0.isMonthly }
    }

    private var monthlyPriceText: String {
        guard let product = monthlyProduct else { return "$9.99 per month, billed monthly" }
        return "\(product.priceString) per month, billed monthly"
    }

    private var annualPriceText: String {
        guard let product = annualProduct else { return "$8.33 per month, billed annually" }
        if let monthlyEquiv = product.monthlyEquivalentPrice {
            return "\(monthlyEquiv) per month, billed annually"
        }
        return "\(product.priceString) per year, billed annually"
    }

    private var annualBadgeText: String? {
        guard let annual = annualProduct else { return "Save 17%" }
        if let monthly = monthlyProduct {
            let monthlyPrice = (monthly.package.storeProduct.price as NSDecimalNumber).doubleValue
            let annualMonthly = (annual.package.storeProduct.price as NSDecimalNumber).doubleValue / 12
            let savings = ((monthlyPrice - annualMonthly) / monthlyPrice) * 100
            return savings > 0 ? "Save \(Int(savings.rounded()))%" : nil
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
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    PaywallView()
}
