//
//  AppearanceAnimations.swift
//  Norma
//
//  Created by Claude on 4/27/26.
//
//  Reusable staggered appearance modifiers. Drive a single @State Bool that
//  flips to true onAppear; each modifier reads it and animates with a delay
//  so components land in sequence.
//

import SwiftUI

struct AppearTransition: ViewModifier {
    let appeared: Bool
    let delay: Double
    var rise: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : rise)
            .animation(
                .spring(response: 0.55, dampingFraction: 0.85).delay(delay),
                value: appeared
            )
    }
}

struct PopAppearTransition: ViewModifier {
    let appeared: Bool
    var delay: Double = 0

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.55)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.68).delay(delay),
                value: appeared
            )
    }
}

extension View {
    func appears(_ appeared: Bool, delay: Double = 0, rise: CGFloat = 12) -> some View {
        modifier(AppearTransition(appeared: appeared, delay: delay, rise: rise))
    }

    func popAppears(_ appeared: Bool, delay: Double = 0) -> some View {
        modifier(PopAppearTransition(appeared: appeared, delay: delay))
    }
}
