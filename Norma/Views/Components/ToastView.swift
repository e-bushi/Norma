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
                HStack(alignment: .top, spacing: 12) {
                    // Leading icon, rendered like an iOS notification app glyph.
                    // Image assets render bare with a rounded corner (the asset
                    // is its own visual); SF Symbols sit inside a tinted chip.
                    if let asset = toast.imageAsset {
                        Image(asset)
                            .resizable()
                            .renderingMode(.original)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 38, height: 38)
                            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    } else {
                        Image(systemName: toast.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(toast.iconColor)
                            .frame(width: 38, height: 38)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(toast.iconColor.opacity(0.18))
                            )
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(toast.message)
                            .font(.custom(FontFamily.Rubik.semiBold, size: 15))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        if let detail = toast.detail {
                            Text(detail)
                                .font(.custom(FontFamily.Rubik.regular, size: 13))
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.gray.opacity(0.08))
                        .glassEffect(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 18, x: 0, y: 8)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
                .onTapGesture {
                    toastManager.dismiss()
                }
            }

            Spacer()
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: toastManager.isShowing)
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
