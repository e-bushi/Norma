//
//  PaywallFeatureCard.swift
//  Norma
//
//  Feature row for the paywall, in D9/D10 dark editorial language.
//

import SwiftUI

struct PaywallFeatureRow: View {
    let icon: String
    let text: String

    private let cream = Color(red: 0xF2/255, green: 0xED/255, blue: 0xE2/255)
    private let mutedText = Color(red: 0x7A/255, green: 0x76/255, blue: 0x70/255)
    private var accentPurple: Color { NormaPalette.lavender }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(accentPurple)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(accentPurple.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(accentPurple.opacity(0.25), lineWidth: 1)
                )

            Text(text)
                .font(.custom(FontFamily.Rubik.medium, size: 14))
                .foregroundStyle(cream)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
}
