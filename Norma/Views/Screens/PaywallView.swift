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
    @State private var selectedTier: SubscriptionTier = .pro
    @State private var isPurchasing = false
    @State private var showError = false
    
    enum BillingOption {
        case monthly
        case yearly
    }
    
    @State private var selectedBilling: BillingOption = .monthly
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        PaywallHeader()
                            .padding(.top)
                        
                        // Tier Picker
                        TierPicker(selection: $selectedTier)
                        
                        // Features
                        PaywallFeaturesBox(selectedTier: selectedTier)
                        
                        // Billing Option Cards
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
                        
                        // CTA Button
                        Button {
                            Task {
                                await purchaseSelectedProduct()
                            }
                        } label: {
                            VStack(spacing: 2) {
                                Text("Start 7-Day Free Trial")
                                    .font(.system(size: 16, weight: .semibold))
                                
                                Text("Then \(getPriceText())")
                                    .font(.system(size: 12))
                                    .opacity(0.9)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(selectedTier.color)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isPurchasing)
                        
                        // Footer Links
                        VStack(spacing: 12) {
                            Button("Restore Purchases") {
                                Task {
                                    await restorePurchases()
                                }
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.accentColor)
                            .disabled(isPurchasing)
                            
                            Text("Cancel anytime in Settings")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 12) {
                                Link("Terms", destination: URL(string: "https://norma.app/terms")!)
                                Text("•")
                                    .foregroundColor(.secondary)
                                Link("Privacy", destination: URL(string: "https://norma.app/privacy")!)
                            }
                            .font(.system(size: 12))
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
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            // Find the product based on selected tier and billing
            if let product = findProduct(for: selectedTier, isMonthly: selectedBilling == .monthly) {
                try await subscriptionManager.purchase(product)
                dismiss()
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


#Preview {
    PaywallView()
}
