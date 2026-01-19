//
//  ToastView.swift
//  Norma
//
//  Created by Claude on 1/18/26.
//

import SwiftUI

/// Toast notification view that slides in from the top - styled like a text notification
struct ToastView: View {
    @StateObject private var toastManager = ToastManager.shared

    var body: some View {
        VStack {
            if toastManager.isShowing, let toast = toastManager.currentToast {
                HStack(spacing: 10) {
                    // Icon
                    Image(systemName: toast.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(toast.iconColor)

                    // Message text
                    Text(toast.message)
                        .font(.custom(FontFamily.Rubik.medium, size: 14))
                        .foregroundColor(.primary)

                    // Detail text (if any)
                    if let detail = toast.detail {
                        Text("·")
                            .foregroundColor(.secondary)
                        Text(detail)
                            .font(.custom(FontFamily.Rubik.regular, size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.gray.opacity(0.08))
                        .glassEffect(in: Capsule())
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.9)),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
                .onTapGesture {
                    toastManager.dismiss()
                }
            }

            Spacer()
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: toastManager.isShowing)
    }
}

/// View modifier to add toast overlay to any view
struct ToastOverlayModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                ToastView()
            }
    }
}

extension View {
    /// Adds toast notification overlay to the view
    func toastOverlay() -> some View {
        modifier(ToastOverlayModifier())
    }
}

#Preview("Toast - Deducted") {
    ZStack {
        Color("NormaBackground")
            .ignoresSafeArea()

        VStack {
            Text("Main Content")
                .font(.title)
        }
    }
    .toastOverlay()
    .onAppear {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            ToastManager.shared.show(.freedomFundDeducted(amount: 150, arcsRemaining: 4, currency: "USD"))
        }
    }
}

#Preview("Toast - Depleted") {
    ZStack {
        Color("NormaBackground")
            .ignoresSafeArea()

        VStack {
            Text("Main Content")
                .font(.title)
        }
    }
    .toastOverlay()
    .onAppear {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            ToastManager.shared.show(.freedomFundDepleted(amount: 100, currency: "USD"))
        }
    }
}

#Preview("Toast - Empty") {
    ZStack {
        Color("NormaBackground")
            .ignoresSafeArea()

        VStack {
            Text("Main Content")
                .font(.title)
        }
    }
    .toastOverlay()
    .onAppear {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            ToastManager.shared.show(.freedomFundEmpty())
        }
    }
}
