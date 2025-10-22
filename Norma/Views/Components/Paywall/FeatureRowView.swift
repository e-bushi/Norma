//
//  FeatureRowView.swift
//  Norma
//
//  Created by Assistant on 7/31/25.
//

import SwiftUI

struct FeatureRowView: View {
    let feature: (icon: String, title: String, description: String)
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: feature.icon)
                .font(.system(size: 20))
                .foregroundColor(Color("NormaPastelPurple"))
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(.custom(FontFamily.Rubik.bold, size: 16))
                    .foregroundColor(.primary)

                Text(feature.description)
                    .font(.custom(FontFamily.Rubik.regular, size: 14))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(Color("NormaPastelPurple"))
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
}