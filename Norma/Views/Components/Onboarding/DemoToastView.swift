//
//  DemoToastView.swift
//  Norma
//
//  A demo toast notification for the onboarding money tasks feature.
//  Simulates a reminder notification appearing from the top.
//

import SwiftUI

struct DemoToastView: View {
    let title: String
    let message: String
    let icon: String
    @Binding var isVisible: Bool

    var body: some View {
        HStack(spacing: 12) {
            // App icon
            RoundedRectangle(cornerRadius: 10)
                .fill(Color("NormaPastelTeal"))
                .frame(width: 38, height: 38)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                )

            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)

                Text(message)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Time
            Text("now")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 5)
        )
        .padding(.horizontal, 8)
        .offset(y: isVisible ? 0 : -120)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isVisible)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var showToast = false

        var body: some View {
            ZStack(alignment: .top) {
                Color("NormaBackground")
                    .ignoresSafeArea()

                VStack {
                    DemoToastView(
                        title: "Norma",
                        message: "Reminder: Pay Rent is due tomorrow",
                        icon: "bell.fill",
                        isVisible: $showToast
                    )
                    .padding(.top, 50)

                    Spacer()

                    Button("Show Toast") {
                        showToast.toggle()
                    }
                    .padding(.bottom, 50)
                }
            }
        }
    }

    return PreviewWrapper()
}
