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
        Feature(id: "base-1", icon: "brain", title: "AI Bill & Expense Tracking", description: "Smart categorization and insights"),
        Feature(id: "base-2", icon: "bell.badge", title: "Smart Notifications", description: "Never miss a payment"),
        Feature(id: "base-3", icon: "chart.line.uptrend.xyaxis", title: "Basic Analytics", description: "Track spending patterns"),
        Feature(id: "base-4", icon: "shield.fill", title: "Data Encryption", description: "Your data is secure"),
        Feature(id: "base-5", icon: "globe", title: "Multi-currency Support", description: "Track expenses in any currency")
    ]
    
    private static let proFeatures = [
        Feature(id: "pro-1", icon: "star.fill", title: "Everything in Basic", description: "All features from the Basic tier"),
        Feature(id: "pro-2", icon: "sparkles", title: "Financial Mind AI", description: "Personal finance analyst"),
        Feature(id: "pro-3", icon: "chart.bar.doc.horizontal", title: "Advanced Insights", description: "Deep spending analysis"),
        Feature(id: "pro-4", icon: "waveform.path.ecg", title: "Cash Flow Predictions", description: "Forecast your finances")
    ]
    
    private var features: [Feature] {
        selectedTier == .base ? Self.baseFeatures : Self.proFeatures
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
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
                        // Apply multiple transformations for appearance animation
                        .offset(x: appearAnimation ? 0 : -20)
                        .scaleEffect(appearAnimation ? 1 : 0.95)
                        .opacity(appearAnimation ? 1 : 0)
                        // Add slight rotation for a more dynamic effect
                        .rotation3DEffect(
                            .degrees(appearAnimation ? 0 : -5),
                            axis: (x: 0.0, y: 1.0, z: 0.0)
                        )
                        // Use a spring animation with staggered delay based on index
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.65, blendDuration: 0.3)
                            .delay(0.08 + Double(index) * 0.06),
                            value: appearAnimation
                        )
                        .id("\(feature.id)-\(animationTrigger)")
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