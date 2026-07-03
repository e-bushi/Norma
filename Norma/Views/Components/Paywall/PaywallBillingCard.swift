//
//  PaywallBillingCard.swift
//  Norma
//
//  Plan card for the paywall in D9/D10 dark editorial language.
//  Active = solid lavender border + tinted fill. Inactive = dashed border
//  on dim text — matches the dashed/solid capsule pattern used elsewhere.
//

import SwiftUI

struct PaywallPlanCard: View {
    let title: String
    let price: String
    var badge: String? = nil
    var strikethroughPrice: String? = nil
    let isSelected: Bool
    let action: () -> Void

    private let cream = Color(red: 0xF2/255, green: 0xED/255, blue: 0xE2/255)
    private let mutedText = Color(red: 0x7A/255, green: 0x76/255, blue: 0x70/255)
    private let dimText = Color(red: 0x5C/255, green: 0x58/255, blue: 0x52/255)
    private let onAccent = Color(red: 0x0E/255, green: 0x0E/255, blue: 0x10/255)
    private var accentPurple: Color { NormaPalette.lavender }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Radio indicator: filled lavender when active, dashed circle when not.
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(accentPurple)
                            .frame(width: 18, height: 18)
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(onAccent)
                    } else {
                        Circle()
                            .stroke(
                                mutedText.opacity(0.7),
                                style: StrokeStyle(lineWidth: 1, dash: [3, 3])
                            )
                            .frame(width: 18, height: 18)
                    }
                }
                .frame(width: 22)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title.lowercased())
                            .font(.custom(FontFamily.Rubik.semiBold, size: 15))
                            .foregroundStyle(cream)

                        if let badge = badge {
                            Text(badge.lowercased())
                                .font(.custom(FontFamily.Rubik.semiBold, size: 10))
                                .tracking(0.4)
                                .foregroundStyle(onAccent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(accentPurple))
                        }
                    }

                    HStack(spacing: 6) {
                        Text(price.lowercased())
                            .font(.custom(FontFamily.Rubik.regular, size: 13))
                            .foregroundStyle(mutedText)

                        if let strikethrough = strikethroughPrice {
                            Text(strikethrough.lowercased())
                                .font(.custom(FontFamily.Rubik.regular, size: 12))
                                .foregroundStyle(dimText)
                                .strikethrough(color: dimText)
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? accentPurple.opacity(0.06) : Color.clear)
            )
            .overlay(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(accentPurple.opacity(0.7), lineWidth: 1.2)
                    } else {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                mutedText.opacity(0.4),
                                style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                            )
                    }
                }
            )
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(PlanCardButtonStyle())
    }
}

// MARK: - Button Style

struct PlanCardButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
