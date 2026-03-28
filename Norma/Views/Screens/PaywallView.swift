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
    @EnvironmentObject private var coinColorViewModel: CoinColorViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var showTermsOfUse = false
    @State private var showPrivacyPolicy = false
    @State private var showHeader = false
    @State private var showFeatures = false
    @State private var showSocialProof = false
    @State private var showPlans = false
    @State private var showCTA = false
    @State private var shimmerOffset: CGFloat = -1.0

    enum BillingOption {
        case monthly
        case yearly
    }

    @State private var selectedBilling: BillingOption = .yearly

    private let accentColor = Color("NormaPastelPurple")

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Coin gradient background + radar rings
            ZStack(alignment: .topTrailing) {
                CoinGradientBackground(coinColor: coinColorViewModel.coinColor, colorScheme: colorScheme)

                Canvas { context, size in
                    let origin = CGPoint(x: size.width, y: 0)
                    let ringCount = 8
                    let maxRadius: CGFloat = 320
                    let ringSpacing = maxRadius / CGFloat(ringCount)
                    let tierColor = UIColor(coinColorViewModel.coinColor)
                    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                    tierColor.getRed(&r, green: &g, blue: &b, alpha: &a)

                    for i in 1...ringCount {
                        let radius = CGFloat(i) * ringSpacing
                        let opacity = 0.12 * (1.0 - CGFloat(i) / CGFloat(ringCount))
                        let rect = CGRect(
                            x: origin.x - radius,
                            y: origin.y - radius,
                            width: radius * 2,
                            height: radius * 2
                        )
                        context.stroke(
                            Path(ellipseIn: rect),
                            with: .color(Color(red: r, green: g, blue: b).opacity(opacity)),
                            lineWidth: 1
                        )
                    }
                }
                .allowsHitTesting(false)
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    headerSection

                    featureList

                    socialProofLabel

                    planCardsSection

                    ctaButton

                    reassuranceText

                    legalRow
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)

            // Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color("NormaText").opacity(0.5))
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color("NormaCard").opacity(0.8))
                    )
            }
            .padding(.top, 16)
            .padding(.trailing, 20)
        }
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
        .onAppear {
            Task {
                if subscriptionManager.availableProducts.isEmpty {
                    await subscriptionManager.loadProducts()
                }
                await subscriptionManager.checkSubscriptionStatus()
            }
            withAnimation(.easeOut(duration: 0.45).delay(0.1)) {
                showHeader = true
            }
            withAnimation(.easeOut(duration: 0.45).delay(0.25)) {
                showFeatures = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.4)) {
                showSocialProof = true
            }
            withAnimation(.easeOut(duration: 0.45).delay(0.5)) {
                showPlans = true
            }
            withAnimation(.easeOut(duration: 0.45).delay(0.65)) {
                showCTA = true
            }
            // Single CTA shimmer after content settles
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    shimmerOffset = 1.0
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 0) {
                Text("Norma ")
                    .font(.custom(FontFamily.Rubik.bold, size: 52))
                    .foregroundColor(Color("NormaText"))

                Text("Pro")
                    .font(.custom(FontFamily.Rubik.bold, size: 52))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color("NormaPastelPurple"),
                                Color("NormaPastelCoral")
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }

            Text("Financial clarity for\nwherever you call home.")
                .font(.custom(FontFamily.Rubik.medium, size: 20))
                .foregroundColor(Color("NormaText").opacity(0.6))
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
        .opacity(showHeader ? 1 : 0)
        .offset(y: showHeader ? 0 : 16)
    }

    // MARK: - Feature List

    private var featureList: some View {
        VStack(spacing: 8) {
            PaywallFeatureRow(
                icon: "brain.head.profile",
                text: "AI companion for logging & insights"
            )
            PaywallFeatureRow(
                icon: "shield.lefthalf.filled",
                text: "Build Arcs of financial safety"
            )
            PaywallFeatureRow(
                icon: "flame.fill",
                text: "Spending challenges, streaks & rewards"
            )
            PaywallFeatureRow(
                icon: "coloncurrencysign.arrow.trianglehead.counterclockwise.rotate.90",
                text: "Live currency rates and conversions"
            )
        }
        .opacity(showFeatures ? 1 : 0)
        .offset(y: showFeatures ? 0 : 16)
    }

    // MARK: - Social Proof

    private var socialProofLabel: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock.fill")
                .font(.system(size: 11))
            Text("Early adopter pricing — locked in forever")
                .font(.custom(FontFamily.Rubik.medium, size: 13))
        }
        .foregroundColor(accentColor)
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(showSocialProof ? 1 : 0)
        .offset(y: showSocialProof ? 0 : 10)
    }

    // MARK: - Plan Cards

    private var planCardsSection: some View {
        VStack(spacing: 10) {
            PaywallPlanCard(
                title: "Annual",
                price: annualPriceText,
                badge: annualBadgeText,
                strikethroughPrice: annualStrikethroughText,
                isSelected: selectedBilling == .yearly
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedBilling = .yearly
                }
            }

            PaywallPlanCard(
                title: "Monthly",
                price: monthlyPriceText,
                isSelected: selectedBilling == .monthly
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedBilling = .monthly
                }
            }
        }
        .opacity(showPlans ? 1 : 0)
        .offset(y: showPlans ? 0 : 16)
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
                            .font(.custom(FontFamily.Rubik.regular, size: 15))
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
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(accentColor)

                    // Shimmer overlay
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: .white.opacity(0), location: 0),
                                    .init(color: .white.opacity(0.25), location: 0.5),
                                    .init(color: .white.opacity(0), location: 1)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .mask(
                            RoundedRectangle(cornerRadius: 14)
                        )
                        .offset(x: shimmerOffset * 200)
                        .clipped()
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isPurchasing || subscriptionManager.isLoadingProducts)
        .buttonStyle(PaywallPressButtonStyle())
        .opacity(showCTA ? 1 : 0)
        .offset(y: showCTA ? 0 : 16)
    }

    // MARK: - Reassurance

    private var reassuranceText: some View {
        Text("No payment now. Cancel anytime.")
            .font(.custom(FontFamily.Rubik.regular, size: 13))
            .foregroundColor(Color("NormaText").opacity(0.4))
            .frame(maxWidth: .infinity)
            .opacity(showCTA ? 1 : 0)
    }

    // MARK: - Legal Row

    private var legalRow: some View {
        HStack(spacing: 12) {
            Button("Terms") { showTermsOfUse = true }
            Text("·").foregroundColor(Color("NormaText").opacity(0.3))
            Button("Privacy") { showPrivacyPolicy = true }
            Text("·").foregroundColor(Color("NormaText").opacity(0.3))
            Button("Restore Purchases") {
                Task { await restorePurchases() }
            }
        }
        .font(.custom(FontFamily.Rubik.regular, size: 12))
        .foregroundColor(Color("NormaText").opacity(0.4))
        .opacity(showCTA ? 1 : 0)
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

    /// The monthly price shown as a crossed-out reference on the annual card
    private var annualStrikethroughText: String? {
        guard let monthly = monthlyProduct else { return "$9.99/mo" }
        return "\(monthly.priceString)/mo"
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
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    PaywallView()
}
