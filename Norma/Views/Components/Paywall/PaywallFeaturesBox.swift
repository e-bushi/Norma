//
//  PaywallFeaturesBox.swift
//  Norma
//
//  Created by Assistant on 7/31/25.
//

import SwiftUI

struct PaywallFeaturesBox: View {
    let selectedTier: SubscriptionTier
    
    // Animation state
    @State private var appearAnimation = false
    @State private var animationTrigger = UUID()
    
    struct Feature: Identifiable {
        let id: String
        let icon: String
        let title: String
        let description: String
    }
    
    private static let baseFeatures = [
        Feature(id: "base-1", icon: "message.fill", title: "AI Text Assistant", description: "Chat with your financial AI"),
        Feature(id: "base-2", icon: "brain", title: "Smart Expense Tracking", description: "Automatic categorization"),
        Feature(id: "base-3", icon: "bell.badge", title: "Bill Reminders", description: "Never miss a payment"),
        Feature(id: "base-4", icon: "chart.line.uptrend.xyaxis", title: "Spending Analytics", description: "Track your money flow"),
        Feature(id: "base-5", icon: "shield.fill", title: "Secure & Private", description: "Your data is encrypted")
    ]
    
    private static let proFeatures = [
        Feature(id: "pro-1", icon: "star.fill", title: "Everything in Basic", description: "All Basic features included"),
        Feature(id: "pro-2", icon: "mic.circle.fill", title: "Voice Agent", description: "Talk to your AI assistant")
    ]
    
    private static let proComingSoonFeatures = [
        Feature(id: "pro-coming-1", icon: "sparkles", title: "Advanced AI Analysis", description: "Deeper financial insights"),
        Feature(id: "pro-coming-2", icon: "chart.bar.doc.horizontal", title: "Pro Reports", description: "Detailed spending breakdowns"),
        Feature(id: "pro-coming-3", icon: "waveform.path.ecg", title: "Cash Flow Predictions", description: "Forecast your finances")
    ]
    
    private var features: [Feature] {
        selectedTier == .base ? Self.baseFeatures : Self.proFeatures
    }
    
    private var hasComingSoonSection: Bool {
        selectedTier == .pro
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Main features section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("\(selectedTier.displayName.uppercased()) FEATURES")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .tracking(1.2)
                    
                    Spacer()
                    
                    Text("\(features.count) features")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 16) {
                    ForEach(Array(features.enumerated()), id: \.element.id) { index, feature in
                        FeatureRowView(feature: (icon: feature.icon, title: feature.title, description: feature.description))
                            .offset(x: appearAnimation ? 0 : -20)
                            .scaleEffect(appearAnimation ? 1 : 0.95)
                            .opacity(appearAnimation ? 1 : 0)
                            .rotation3DEffect(
                                .degrees(appearAnimation ? 0 : -5),
                                axis: (x: 0.0, y: 1.0, z: 0.0)
                            )
                            .animation(
                                .spring(response: 0.4, dampingFraction: 0.65, blendDuration: 0.3)
                                .delay(0.08 + Double(index) * 0.06),
                                value: appearAnimation
                            )
                            .id("\(feature.id)-\(animationTrigger)")
                    }
                }
            }
            
            // Coming Soon section (only for Pro)
            if hasComingSoonSection {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("COMING SOON")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                            .tracking(1.2)
                        
                        Spacer()
                    }
                    
                    VStack(spacing: 16) {
                        ForEach(Array(Self.proComingSoonFeatures.enumerated()), id: \.element.id) { index, feature in
                            FeatureRowView(feature: (icon: feature.icon, title: feature.title, description: feature.description))
                                .opacity(0.6)  // Slightly faded to indicate coming soon
                                .offset(x: appearAnimation ? 0 : -20)
                                .scaleEffect(appearAnimation ? 1 : 0.95)
                                .rotation3DEffect(
                                    .degrees(appearAnimation ? 0 : -5),
                                    axis: (x: 0.0, y: 1.0, z: 0.0)
                                )
                                .animation(
                                    .spring(response: 0.4, dampingFraction: 0.65, blendDuration: 0.3)
                                    .delay(0.08 + Double(features.count + index) * 0.06),
                                    value: appearAnimation
                                )
                                .id("\(feature.id)-\(animationTrigger)")
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(UIColor.systemBackground),
                            Color.gray.opacity(0.02)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.gray.opacity(0.2),
                                    Color.gray.opacity(0.05)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
        )
        .onAppear {
            // Trigger initial animation when the view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    appearAnimation = true
                }
            }
        }
        .onChange(of: selectedTier) { _, _ in
            triggerAnimation()
        }
    }
    
    // Helper method to trigger a fresh animation when tier changes
    private func triggerAnimation() {
        // Reset animation state
        appearAnimation = false
        animationTrigger = UUID()
        
        // Small delay to ensure the state reset is processed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                appearAnimation = true
            }
        }
    }
}