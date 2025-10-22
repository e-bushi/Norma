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
    @Environment(\.colorScheme) var colorScheme
    
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
                            .font(.custom(FontFamily.Rubik.medium, size: 17))
                            .foregroundColor(.primary)

                        if let badge = badge {
                            Text(badge)
                                .font(.custom(FontFamily.Rubik.semiBold, size: 10))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color("NormaPastelPurple"))
                                )
                        }
                    }

                    HStack(spacing: 4) {
                        Text(price)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)

                        Text("•")
                            .font(.custom(FontFamily.Rubik.regular, size: 14))
                            .foregroundColor(.secondary)

                        Text(subtitle)
                            .font(.custom(FontFamily.Rubik.regular, size: 14))
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
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: colorScheme == .dark ? [
                                isSelected ? Color(red: 0.180, green: 0.145, blue: 0.118) : Color(red: 0.160, green: 0.128, blue: 0.102),
                                isSelected ? Color(red: 0.200, green: 0.165, blue: 0.138) : Color(red: 0.180, green: 0.145, blue: 0.118)
                            ] : [
                                Color(UIColor.systemBackground),
                                isSelected ? selectedTier.color.opacity(0.05) : Color.gray.opacity(0.02)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
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
