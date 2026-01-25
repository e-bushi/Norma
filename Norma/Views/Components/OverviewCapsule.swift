//
//  OverviewCapsule.swift
//  Norma
//
//  Capsule button for accessing financial overview from nav bar
//

import SwiftUI

struct OverviewCapsule: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 15))

                Text("Overview")
                    .font(.custom(FontFamily.Rubik.medium, size: 15))
            }
            .foregroundColor(Color("NormaPastelTeal"))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color("NormaPastelTeal").opacity(0.15))
                    .glassEffect(in: Capsule())
            )
            .overlay(
                Capsule()
                    .stroke(Color("NormaPastelTeal").opacity(0.3), lineWidth: 0.5)
            )
        }
        .buttonStyle(CapsulePressStyle())
    }
}

#Preview {
    ZStack {
        Color("NormaBackground")
            .ignoresSafeArea()

        OverviewCapsule {
            print("Tapped overview")
        }
    }
}
