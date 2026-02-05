//
//  DemoReminderCard.swift
//  Norma
//
//  A demo reminder card for the onboarding money tasks feature.
//  Shows a created reminder with title and schedule.
//

import SwiftUI

struct DemoReminderCard: View {
    let title: String
    let schedule: String
    let icon: String
    @Binding var animate: Bool

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            Circle()
                .fill(Color("NormaPastelTeal").opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(Color("NormaPastelTeal"))
                )
                .scaleEffect(animate ? 1.0 : 0.5)
                .opacity(animate ? 1.0 : 0.0)

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text(schedule)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .opacity(animate ? 1.0 : 0.0)
            .offset(x: animate ? 0 : -10)

            Spacer()

            // Checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(Color("NormaPastelTeal"))
                .scaleEffect(animate ? 1.0 : 0.0)
                .opacity(animate ? 1.0 : 0.0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color("NormaPastelTeal").opacity(0.3), lineWidth: 1)
                )
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: animate)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var animate = false

        var body: some View {
            VStack(spacing: 20) {
                DemoReminderCard(
                    title: "Pay Rent",
                    schedule: "1st of every month",
                    icon: "house.fill",
                    animate: $animate
                )

                Button("Animate") {
                    animate = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        animate = true
                    }
                }
            }
            .padding()
            .background(Color("NormaBackground"))
        }
    }

    return PreviewWrapper()
}
