//
//  PaywallBillingCard.swift
//  Norma
//
//  Created by Assistant on 7/31/25.
//

import SwiftUI

struct PaywallPlanCard: View {
    let title: String
    let price: String
    var badge: String? = nil
    let isSelected: Bool
    let action: () -> Void

    private let accentColor = Color("NormaPastelPurple")

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Left: title, price, badge
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.custom(FontFamily.Rubik.semiBold, size: 16))
                            .foregroundColor(.black)

                        if let badge = badge {
                            Text(badge)
                                .font(.custom(FontFamily.Rubik.semiBold, size: 10))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule().fill(accentColor)
                                )
                        }
                    }

                    Text(price)
                        .font(.custom(FontFamily.Rubik.regular, size: 14))
                        .foregroundColor(.black.opacity(0.6))
                }

                Spacer()

                // Right: radio indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? accentColor : Color.black.opacity(0.3), lineWidth: 2)
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("NormaPastelPurple").opacity(0.15))
                    .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 16))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color("NormaPastelPurple").opacity(0.3), lineWidth: 1)
            )
            
        }
        .buttonStyle(PlanCardButtonStyle())
    }
}

struct PlanCardButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
