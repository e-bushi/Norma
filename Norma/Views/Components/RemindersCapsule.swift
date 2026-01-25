//
//  RemindersCapsule.swift
//  Norma
//
//  Capsule button showing scheduled reminders count in nav bar
//

import SwiftUI

struct RemindersCapsule: View {
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 15))

                if count > 0 {
                    Text("\(count)")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 13))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color("NormaPastelCoral"))
                        )
                }
            }
            .foregroundColor(Color("NormaPastelCoral"))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color("NormaPastelCoral").opacity(0.15))
                    .glassEffect(in: Capsule())
            )
            .overlay(
                Capsule()
                    .stroke(Color("NormaPastelCoral").opacity(0.3), lineWidth: 0.5)
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
            RemindersCapsule(count: 0) {
                print("Tapped - empty")
            }

            RemindersCapsule(count: 3) {
                print("Tapped - with count")
            }
        }
    }
}
