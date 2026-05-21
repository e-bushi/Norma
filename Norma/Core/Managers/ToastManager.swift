//
//  ToastManager.swift
//  Norma
//
//  Created by Claude on 1/18/26.
//

import Foundation
import SwiftUI

/// Manages toast notifications displayed from the top of the screen
@MainActor
class ToastManager: ObservableObject {
    static let shared = ToastManager()

    @Published var currentToast: Toast?
    @Published var isShowing = false

    private var dismissTask: Task<Void, Never>?

    private init() {}

    /// Show a toast notification
    /// - Parameter toast: The toast to display
    func show(_ toast: Toast) {
        // Cancel any existing dismiss task
        dismissTask?.cancel()

        // Update toast
        currentToast = toast

        // Animate in
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isShowing = true
        }

        // Schedule auto-dismiss
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(toast.duration))
            guard !Task.isCancelled else { return }
            dismiss()
        }
    }

    /// Dismiss the current toast
    func dismiss() {
        dismissTask?.cancel()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isShowing = false
        }

        // Clear toast after animation completes
        Task {
            try? await Task.sleep(for: .milliseconds(350))
            currentToast = nil
        }
    }
}

// MARK: - Toast Model

struct Toast: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let detail: String?
    let icon: String
    let iconColor: Color
    let duration: Double
    /// Optional asset-catalog image name. When set, the toast renders this
    /// image in the leading icon slot instead of the SF Symbol in `icon`.
    /// Used for Norma-branded toasts (e.g. note-processing) where the logo
    /// reads better than a system glyph.
    let imageAsset: String?

    init(
        message: String,
        detail: String? = nil,
        icon: String,
        iconColor: Color,
        duration: Double,
        imageAsset: String? = nil
    ) {
        self.message = message
        self.detail = detail
        self.icon = icon
        self.iconColor = iconColor
        self.duration = duration
        self.imageAsset = imageAsset
    }

    static func == (lhs: Toast, rhs: Toast) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Factory Methods

    /// Toast shown when freedom fund is deducted after paying a bill
    static func freedomFundDeducted(
        amount: Double,
        arcsRemaining: Int,
        currency: String
    ) -> Toast {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        let amountString = formatter.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"

        let arcText = arcsRemaining == 1 ? "1 arc left" : "\(arcsRemaining) arcs left"

        return Toast(
            message: "-\(amountString) from Freedom Fund",
            detail: arcText,
            icon: "arrow.down.circle.fill",
            iconColor: Color("NormaPastelCoral"),
            duration: 3.0
        )
    }

    /// Toast shown when freedom fund reaches zero after payment
    static func freedomFundDepleted(amount: Double, currency: String) -> Toast {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        let amountString = formatter.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"

        return Toast(
            message: "-\(amountString) from Freedom Fund",
            detail: "Add funds to rebuild",
            icon: "exclamationmark.circle.fill",
            iconColor: Color("NormaPastelCoral"),
            duration: 3.5
        )
    }

    /// Toast shown when user has no freedom fund set up
    static func freedomFundEmpty() -> Toast {
        return Toast(
            message: "No Freedom Fund",
            detail: "Add funds to get started",
            icon: "plus.circle.fill",
            iconColor: Color("NormaPastelTeal"),
            duration: 3.0
        )
    }

    /// Generic informational toast
    static func info(message: String, detail: String? = nil) -> Toast {
        return Toast(
            message: message,
            detail: detail,
            icon: "info.circle.fill",
            iconColor: Color("NormaPastelTeal"),
            duration: 2.5
        )
    }

    /// Success toast
    static func success(message: String, detail: String? = nil) -> Toast {
        return Toast(
            message: message,
            detail: detail,
            icon: "checkmark.circle.fill",
            iconColor: Color("NormaPastelTeal"),
            duration: 2.5
        )
    }

    /// "Norma is processing your note" — shown after a voice-dictation
    /// transcript is appended to a note from the list. Stays on screen
    /// longer than the standard success toast so the user can read the
    /// note title before it dismisses.
    static func noteProcessing(noteTitle: String? = nil) -> Toast {
        let trimmed = noteTitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        let detail: String
        if let trimmed, !trimmed.isEmpty {
            detail = "norma is processing '\(trimmed)' in the background"
        } else {
            detail = "norma is processing your note in the background"
        }
        return Toast(
            message: "added to your note",
            detail: detail,
            icon: "sparkles", // fallback if image is missing at runtime
            iconColor: Color(red: 0.588, green: 0.463, blue: 0.851), // lavender
            duration: 5.0,
            imageAsset: "norma-logo"
        )
    }
}
