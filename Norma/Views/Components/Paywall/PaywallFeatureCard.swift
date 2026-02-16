//
//  PaywallFeatureCard.swift
//  Norma
//
//  Created by Assistant on 2/15/26.
//

import SwiftUI

struct PaywallFeatureCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .padding(.bottom, 4)

            Text(title)
                .font(.custom(FontFamily.Rubik.semiBold, size: 15))
                .foregroundColor(.black)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)

            Text(description)
                .font(.custom(FontFamily.Rubik.regular, size: 13))
                .foregroundColor(.black.opacity(0.6))
                .lineSpacing(2)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .frame(maxWidth: 275, alignment: .leading)
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
}
