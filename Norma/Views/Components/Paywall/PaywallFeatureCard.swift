//
//  PaywallFeatureCard.swift
//  Norma
//
//  Created by Assistant on 2/15/26.
//

import SwiftUI

struct PaywallFeatureRow: View {
    let icon: String
    let text: String

    private let accentColor = Color("NormaPastelPurple")

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(accentColor)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(accentColor.opacity(0.1))
                )

            Text(text)
                .font(.custom(FontFamily.Rubik.medium, size: 15))
                .foregroundColor(Color("NormaText").opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
    }
}
