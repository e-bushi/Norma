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
    @State private var selectedTier: SubscriptionTier = .base
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var showTermsOfUse = false
    @State private var showPrivacyPolicy = false
    
    enum BillingOption {
        case monthly
        case yearly
    }
    
    @State private var selectedBilling: BillingOption = .monthly
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("NormaBackground")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        PaywallHeader()
                            .padding(.top)
                        
                        // Tier Picker
                        TierPicker(selection: $selectedTier)
                            .padding(.horizontal)
                        
                        // Features
                        PaywallFeaturesBox(selectedTier: selectedTier)
                        
                        // Billing Option Cards (only show for base tier)
                        if selectedTier == .base {
                            VStack(spacing: 12) {
                                PaywallBillingCard(
                                    icon: "calendar",
                                    iconColor: .blue,
                                    title: "Monthly",
                                    price: selectedTier == .base ? "$7.99" : "$14.99",
                                    subtitle: "Billed monthly",
                                    isSelected: selectedBilling == .monthly,
                                    selectedTier: selectedTier
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        selectedBilling = .monthly
                                    }
                                }

                                PaywallBillingCard(
                                    icon: "calendar.badge.clock",
                                    iconColor: .green,
                                    title: "Yearly",
                                    price: selectedTier == .base ? "$79.99" : "$149.99",
                                    subtitle: "Save 17%",
                                    badge: "BEST VALUE",
                                    isSelected: selectedBilling == .yearly,
                                    selectedTier: selectedTier
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        selectedBilling = .yearly
                                    }
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                        }
                        
                        // CTA Button
                        Button {
                            Task {
                                // Only allow purchase for base tier
                                if selectedTier == .base {
                                    await purchaseSelectedProduct()
                                }
                            }
                        } label: {
                            if selectedTier == .pro {
                                // Show Coming Soon for Pro tier
                                VStack(spacing: 2) {
                                    Text("Coming Soon")
                                        .font(.custom(FontFamily.Rubik.medium, size: 17))

                                    Text("Pro features in development")
                                        .font(.custom(FontFamily.Rubik.regular, size: 13))
                                        .opacity(0.9)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    Capsule()
                                        .fill(Color.gray.opacity(0.5))
                                )
                                .foregroundColor(.white)
                            } else if isPurchasing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                                    .background(
                                        Capsule()
                                            .fill(selectedTier.color.opacity(0.7))
                                    )
                                    .foregroundColor(.white)
                            } else if subscriptionManager.isLoadingProducts {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                    Text("Loading products...")
                                        .font(.custom(FontFamily.Rubik.regular, size: 14))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    Capsule()
                                        .fill(Color.gray.opacity(0.7))
                                )
                                .foregroundColor(.white)
                            } else if subscriptionManager.availableProducts.isEmpty {
                                VStack(spacing: 2) {
                                    Text("Products unavailable")
                                        .font(.custom(FontFamily.Rubik.medium, size: 17))
                                    Text("Tap to retry")
                                        .font(.custom(FontFamily.Rubik.regular, size: 13))
                                        .opacity(0.9)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    Capsule()
                                        .fill(Color("NormaPastelCoral"))
                                )
                                .foregroundColor(.white)
                            } else {
                                VStack(spacing: 2) {
                                    // Show different text if user already used their trial
                                    if subscriptionManager.hasUsedFreeTrial && !subscriptionManager.isInFreeTrial {
                                        Text("Subscribe Now")
                                            .font(.custom(FontFamily.Rubik.medium, size: 17))

                                        Text(getPriceText())
                                            .font(.custom(FontFamily.Rubik.regular, size: 13))
                                            .opacity(0.9)
                                    } else {
                                        Text("Start 3-Day Free Trial")
                                            .font(.custom(FontFamily.Rubik.medium, size: 17))

                                        Text("Then \(getPriceText())")
                                            .font(.custom(FontFamily.Rubik.regular, size: 13))
                                            .opacity(0.9)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    Capsule()
                                        .fill(selectedTier.color)
                                )
                                .foregroundColor(.white)
                            }
                        }
                        .disabled(selectedTier == .pro || isPurchasing || subscriptionManager.isLoadingProducts)
                        
                        // Agreement text and links
                        VStack(spacing: 4) {
                            Text("By subscribing you agree to our")
                                .font(.custom(FontFamily.Rubik.regular, size: 12))
                                .foregroundColor(.secondary)

                            HStack(spacing: 12) {
                                Button("Terms of Use") {
                                    showTermsOfUse = true
                                }
                                Text("•")
                                    .foregroundColor(.secondary)
                                Button("Privacy Policy") {
                                    showPrivacyPolicy = true
                                }
                            }
                            .font(.custom(FontFamily.Rubik.regular, size: 12))
                            .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 4)
                        
                        // Footer Links
                        VStack(spacing: 12) {
                            Button("Restore Purchases") {
                                Task {
                                    await restorePurchases()
                                }
                            }
                            .font(.custom(FontFamily.Rubik.medium, size: 14))
                            .foregroundColor(Color("NormaPastelPurple"))
                            .disabled(isPurchasing)

                            Text("Cancel anytime in Settings")
                                .font(.custom(FontFamily.Rubik.regular, size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
                
                // Close button overlay
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: 32, height: 32)
                                .background(Color(.systemBackground))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 20)
                    }
                    Spacer()
                }
            }
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
            print("📱 PaywallView appeared - Loading products...")
            Task {
                if subscriptionManager.availableProducts.isEmpty {
                    await subscriptionManager.loadProducts()
                }
                await subscriptionManager.checkSubscriptionStatus()
                print("📱 Products loaded: \(subscriptionManager.availableProducts.count)")
            }
        }
    }
    
    private func getPriceText() -> String {
        switch (selectedTier, selectedBilling) {
        case (.base, .monthly):
            return "$7.99/month"
        case (.base, .yearly):
            return "$79.99/year"
        case (.pro, .monthly):
            return "$14.99/month"
        case (.pro, .yearly):
            return "$149.99/year"
        }
    }
    
    
    private func findProduct(for tier: SubscriptionTier, isMonthly: Bool) -> SubscriptionProduct? {
        subscriptionManager.availableProducts.first { product in
            product.tier == tier && product.isMonthly == isMonthly
        }
    }
    
    private func purchaseSelectedProduct() async {
        print("🛒 Purchase button tapped - selectedBilling: \(selectedBilling)")
        print("🛒 Available products count: \(subscriptionManager.availableProducts.count)")
        
        // Check if products are loaded
        if subscriptionManager.availableProducts.isEmpty {
            print("❌ No products loaded from RevenueCat yet, loading now...")
            await subscriptionManager.loadProducts()
            
            // If still empty after loading, show error
            if subscriptionManager.availableProducts.isEmpty {
                print("❌ Failed to load products from RevenueCat")
                showError = true
                return
            }
        }
        
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            // Find the product based on selected tier and billing
            if let product = findProduct(for: selectedTier, isMonthly: selectedBilling == .monthly) {
                print("✅ Found product: \(product.tier.rawValue), isMonthly: \(product.isMonthly)")
                try await subscriptionManager.purchase(product)
                
                // Wait a moment for the subscription status to update
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                // Check if the subscription is now active before dismissing
                if subscriptionManager.hasActiveSubscription {
                    print("✅ Purchase successful, subscription is active")
                    dismiss()
                } else {
                    print("⚠️ Purchase completed but subscription not yet active, checking status...")
                    await subscriptionManager.checkSubscriptionStatus()
                    dismiss()
                }
            } else {
                print("❌ Product not found for tier: \(selectedTier.rawValue), isMonthly: \(selectedBilling == .monthly)")
                print("Available products: \(subscriptionManager.availableProducts.map { "\($0.tier.rawValue)-\($0.isMonthly)" })")
            }
        } catch {
            print("❌ Purchase error: \(error)")
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


#Preview {
    PaywallView()
}
