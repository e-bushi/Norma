//
//  StartYourFreeTrialView.swift
//  Norma
//
//  Created by Assistant on 10/22/25.
//

import SwiftUI

struct StartYourFreeTrialView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTier: SubscriptionTier = .base
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var showTerms = false
    @State private var showPrivacy = false

    private var trialEndDate: Date {
        Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
    }

    private var reminderDate: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }

    var body: some View {
        ZStack {
            // Solid background
            Color("NormaPastelPurple")
                .ignoresSafeArea()

            ScrollView {
                Spacer()
                    .frame(height: 32)
                
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Claim your free trial")
                            .font(.normaTitle(36))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text("No payment today. Cancel anytime.")
                            .font(.normaBody(16))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)

                    // Timeline
                    VStack(alignment: .leading, spacing: 0) {
                        FreeTrialTimelineItem(
                            number: 1,
                            title: "Today",
                            subtitle: "No charge, full access for 3 days",
                            isLast: false
                        )

                        FreeTrialTimelineItem(
                            number: 2,
                            title: "In 1 day (\(formatDate(reminderDate)))",
                            subtitle: "Email reminder 2 days before trial ends",
                            isLast: false
                        )

                        FreeTrialTimelineItem(
                            number: 3,
                            title: "In 3 days (\(formatDate(trialEndDate)))",
                            subtitle: "Trial ends, subscription starts. You can cancel anytime",
                            isLast: true
                        )
                    }
                    .padding(.horizontal, 24)

                    // Tier Cards
                    HStack(spacing: 12) {
                        FreeTrialTierCard(
                            icon: "star.fill",
                            title: "Basic",
                            price: "$7.99/mo",
                            isSelected: selectedTier == .base,
                            showBadge: false
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedTier = .base
                            }
                        }

                        FreeTrialTierCard(
                            icon: "sparkles",
                            title: "Pro",
                            price: "Coming Soon",
                            isSelected: selectedTier == .pro,
                            showBadge: false
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedTier = .pro
                            }
                        }
                    }
                    .padding(.horizontal)

                    // No payment today text
                    Text("No payment today. Cancel anytime")
                        .font(.normaBody(17))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // CTA Button
                    Button {
                        Task {
                            if selectedTier == .base {
                                await purchaseSubscription()
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if isPurchasing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color("NormaPastelPurple")))
                            } else {
                                Text(selectedTier == .base ? "START FREE TRIAL" : "COMING SOON")
                                    .font(.normaHeadline(17))
                                    .foregroundColor(Color("NormaPastelPurple"))

                                if selectedTier == .base {
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color("NormaPastelPurple"))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            Capsule()
                                .fill(Color.white)
                        )
                    }
                    .disabled(selectedTier == .pro || isPurchasing)
                    .padding(.horizontal)

                    // Footer Links
                    HStack(spacing: 20) {
                        Button("Terms") {
                            showTerms = true
                        }

                        Button("Privacy") {
                            showPrivacy = true
                        }

                        Button("Restore") {
                            Task {
                                await restorePurchases()
                            }
                        }

                        Button("Login") {
                            // Handle login
                        }
                    }
                    .font(.normaMicro(13))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 24)
                }
            }
        }
        .sheet(isPresented: $showTerms) {
            WebViewSheet(
                url: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/",
                title: "Terms of Use"
            )
        }
        .sheet(isPresented: $showPrivacy) {
            WebViewSheet(
                url: "https://mauldin.xyz/norma/privacy",
                title: "Privacy Policy"
            )
        }
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(subscriptionManager.purchaseError?.localizedDescription ?? "An error occurred")
        }
        .onAppear {
            Task {
                if subscriptionManager.availableProducts.isEmpty {
                    await subscriptionManager.loadProducts()
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: date)
    }

    private func purchaseSubscription() async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            if let product = subscriptionManager.availableProducts.first(where: { $0.tier == .base && $0.isMonthly }) {
                try await subscriptionManager.purchase(product)

                if subscriptionManager.hasActiveSubscription {
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

// MARK: - Timeline Item Component
struct FreeTrialTimelineItem: View {
    let number: Int
    let title: String
    let subtitle: String
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline indicator - using ZStack to overlap
            ZStack(alignment: .top) {
                // Connecting line positioned behind circle
                if !isLast {
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: 40) // Circle height
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 2, height: 60)
                    }
                    .frame(width: 40)
                }

                // Circle on top
                VStack(spacing: 0) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text("\(number)")
                                .font(.normaFinancial(16))
                                .foregroundColor(Color("NormaPastelPurple"))
                        )

                    if !isLast {
                        Spacer()
                            .frame(height: 60)
                    }
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.normaHeadline(18))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.normaBody(15))
                    .foregroundColor(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 8)

            Spacer()
        }
    }
}

// MARK: - Tier Card Component
struct FreeTrialTierCard: View {
    let icon: String
    let title: String
    let price: String
    let isSelected: Bool
    let showBadge: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 36))
                    .foregroundColor(.white)

                Text(title)
                    .font(.normaHeadline(20))
                    .foregroundColor(.white)

                Text(price)
                    .font(.normaFinancial(20))
                    .foregroundColor(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        Color.white.opacity(isSelected ? 0.25 : 0.15)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                Color.white.opacity(isSelected ? 0.6 : 0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    StartYourFreeTrialView()
}
