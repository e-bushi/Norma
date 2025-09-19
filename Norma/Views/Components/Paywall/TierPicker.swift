//
//  TierPicker.swift
//  Norma
//
//  Created by Assistant on 7/31/25.
//

import SwiftUI

struct TierPicker: View {
    @Binding var selection: SubscriptionTier
    
    var body: some View {
        ZStack {
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
            
            HStack(spacing: 0) {
                ForEach(SubscriptionTier.allCases, id: \.self) { tier in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selection = tier
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: tier.icon)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(selection == tier ? tier.color : .secondary)
                            
                            Text(tier.displayName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(selection == tier ? tier.color : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            ZStack {
                                if selection == tier {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(tier.color.opacity(0.08))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(tier.color.opacity(0.2), lineWidth: 1)
                                        )
                                        .transition(.asymmetric(
                                            insertion: .scale.combined(with: .opacity),
                                            removal: .scale.combined(with: .opacity)
                                        ))
                                }
                            }
                        )
                        .padding(.horizontal, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(4)
        }
        .frame(height: 48)
    }
}

// Extend SubscriptionTier to add picker-specific properties
extension SubscriptionTier {
    var icon: String {
        switch self {
        case .base:
            return "star"
        case .pro:
            return "sparkles"
        }
    }
    
    var color: Color {
        switch self {
        case .base:
            return .blue
        case .pro:
            return .purple
        }
    }
}