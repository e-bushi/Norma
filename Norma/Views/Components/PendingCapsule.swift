//
//  PendingCapsule.swift
//  Norma
//
//  Capsule button showing pending transaction count in nav bar
//

import SwiftUI

struct PendingCapsule: View {
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "doc.text.image")
                    .font(.system(size: 15))

                Text("Pending")
                    .font(.custom(FontFamily.Rubik.medium, size: 15))

                Text("\(count)")
                    .font(.custom(FontFamily.Rubik.semiBold, size: 13))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(NormaPalette.lavender)
                    )
            }
            .foregroundColor(NormaPalette.lavender)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(NormaPalette.lavender.opacity(0.15))
                    .glassEffect(in: Capsule())
            )
            .overlay(
                Capsule()
                    .stroke(NormaPalette.lavender.opacity(0.3), lineWidth: 0.5)
            )
        }
        .buttonStyle(CapsulePressStyle())
    }
}

#Preview {
    ZStack {
        Color("NormaBackground")
            .ignoresSafeArea()

        HStack(spacing: 12) {
            PendingCapsule(count: 0) {
                print("Tapped - empty")
            }

            PendingCapsule(count: 3) {
                print("Tapped - with count")
            }
        }
    }
}
