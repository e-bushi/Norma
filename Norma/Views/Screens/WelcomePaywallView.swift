//
//  WelcomePaywallView.swift
//  Norma
//
//  Created by Assistant on 7/31/25.
//

import SwiftUI

struct WelcomePaywallView: View {
    @Environment(\.dismiss) private var dismiss
    let onStartTrial: () -> Void
    
    @State private var selectedBilling: BillingOption = .monthly
    
    enum BillingOption {
        case monthly
        case yearly
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        WelcomePaywallHeader()
                            .padding(.top)
                        
                        // Timeline
                        TrialTimeline()
                        
                        // Billing Option Cards
                        billingCards
                        
                        // CTA Buttons
                        ctaButtons
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
                
                // Close button overlay
                VStack {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: 32, height: 32)
                                .background(Color(.systemBackground))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        }
                        .padding(.leading, 20)
                        .padding(.top, 20)
                        
                        Spacer()
                        
                        Button("Restore") {
                            // Handle restore purchases
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.accentColor)
                        .padding(.trailing, 20)
                        .padding(.top, 20)
                    }
                    Spacer()
                }
            }
        }
    }
    
    private var billingCards: some View {
        VStack(spacing: 12) {
            PaywallBillingCard(
                icon: "calendar",
                iconColor: .blue,
                title: "Monthly",
                price: "$7.99",
                subtitle: "Billed monthly",
                isSelected: selectedBilling == .monthly,
                selectedTier: .base
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedBilling = .monthly
                }
            }
            
            PaywallBillingCard(
                icon: "calendar.badge.clock",
                iconColor: .green,
                title: "Yearly",
                price: "$79.99",
                subtitle: "Save 17%",
                badge: "BEST VALUE",
                isSelected: selectedBilling == .yearly,
                selectedTier: .base
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedBilling = .yearly
                }
            }
        }
    }
    
    private var ctaButtons: some View {
        VStack(spacing: 16) {
            // Start Trial Button
            Button {
                onStartTrial()
            } label: {
                VStack(spacing: 2) {
                    Text("Start 3-Day Free Trial")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("Then \(getPriceText())")
                        .font(.system(size: 12))
                        .opacity(0.9)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            // Maybe Later Button
            Button("Maybe Later") {
                dismiss()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.secondary)
            
            // Footer Links
            VStack(spacing: 12) {
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
    }
    
    private func getPriceText() -> String {
        switch selectedBilling {
        case .monthly:
            return "$7.99/month"
        case .yearly:
            return "$79.99/year"
        }
    }
}

struct WelcomePaywallHeader: View {
    var body: some View {
        VStack(spacing: 16) {
            // Icon with background
            Image(systemName: "sparkles")
                .font(.system(size: 36))
                .foregroundColor(.accentColor)
                .frame(width: 80, height: 80)
                .background(Color.accentColor.opacity(0.15))
                .clipShape(Circle())
            
            VStack(spacing: 8) {
                Text("How your free trial works")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Experience AI-powered financial assistance")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}


#Preview {
    WelcomePaywallView {
        print("Start trial tapped")
    }
}
