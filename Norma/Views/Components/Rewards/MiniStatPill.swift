//
//  MiniStatPill.swift
//  Norma
//
//  Shared component for reward celebrations
//

import SwiftUI

/// Mini stat pill for celebration overlays
struct MiniStatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(value)
                    .font(.normaFinancial(18))
            }
            .foregroundColor(color)

            Text(label)
                .font(.custom(FontFamily.Rubik.regular, size: 11))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(color.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        HStack(spacing: 16) {
            MiniStatPill(
                icon: "flame.fill",
                value: "5",
                label: "Streak",
                color: Color("NormaPastelCoral")
            )

            MiniStatPill(
                icon: "star.fill",
                value: "+10",
                label: "Points",
                color: Color("NormaPastelTeal")
            )
        }
    }
}
