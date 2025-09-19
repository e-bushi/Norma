//
//  PaywallBillingCard.swift
//  Norma
//
//  Created by Assistant on 7/31/25.
//

import SwiftUI

struct PaywallBillingCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let price: String
    let subtitle: String
    var badge: String? = nil
    let isSelected: Bool
    let selectedTier: SubscriptionTier
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(iconColor)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        if let badge = badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .cornerRadius(4)
                        }
                    }
                    
                    HStack(spacing: 4) {
                        Text(price)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? selectedTier.color : .secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(UIColor.systemBackground),
                                isSelected ? selectedTier.color.opacity(0.05) : Color.gray.opacity(0.02)
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
                                        isSelected ? selectedTier.color.opacity(0.3) : Color.gray.opacity(0.2),
                                        isSelected ? selectedTier.color.opacity(0.1) : Color.gray.opacity(0.05)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}