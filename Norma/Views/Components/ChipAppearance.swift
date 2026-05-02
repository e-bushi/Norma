//
//  ChipAppearance.swift
//  Norma
//
//  Created by Claude on 4/27/26.
//
//  Shared appearance/disappearance animations for chip-style elements
//  (inline chips, the fanned capsule stack). Tunes to a calm spring with
//  low bounce — chips arrive after extraction without distracting from
//  the prose the user is writing.
//

import SwiftUI

extension AnyTransition {
    /// Soft fade + scale + slight upward rise. Used by inline chips and the
    /// stack's front card. Asymmetric so removal is gentler than insertion.
    static var chipAppear: AnyTransition {
        .modifier(
            active: ChipAppearModifier(progress: 0, anchor: .trailing),
            identity: ChipAppearModifier(progress: 1, anchor: .trailing)
        )
    }

    /// Same as chipAppear but anchored to the bottom — used by stack cards
    /// so the back cards visually "rise" into place behind the front.
    static var stackCardAppear: AnyTransition {
        .modifier(
            active: ChipAppearModifier(progress: 0, anchor: .bottom),
            identity: ChipAppearModifier(progress: 1, anchor: .bottom)
        )
    }
}

private struct ChipAppearModifier: ViewModifier {
    let progress: Double
    let anchor: UnitPoint

    func body(content: Content) -> some View {
        content
            .opacity(progress)
            .scaleEffect(0.94 + 0.06 * progress, anchor: anchor)
            .offset(y: (1.0 - progress) * 6)
    }
}

enum ChipAnimation {
    /// Used wherever chips appear/disappear in response to extraction results.
    static let spring: Animation = .spring(response: 0.45, dampingFraction: 0.82)
}
