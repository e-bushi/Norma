//
//  CrossfadeView.swift
//  Norma
//
//  Created by Claude on 12/31/24.
//

import SwiftUI

/// A view that crossfades between content when the key changes.
/// Old content fades out while new content fades in simultaneously.
/// Includes a soft blur effect during transitions for a polished look.
///
/// Use `initialDelay` to prevent crossfade animations until after an initial
/// appearance animation has completed (e.g., wait for a coin to pop in before
/// crossfading to a different tier).
struct CrossfadeView<Key: Equatable, Content: View>: View {
    let key: Key
    let duration: Double
    let initialDelay: Double
    @ViewBuilder let content: (Key) -> Content

    @State private var currentKey: Key
    @State private var previousKey: Key?
    @State private var currentOpacity: Double = 1.0
    @State private var previousOpacity: Double = 0.0
    @State private var isReadyForCrossfade: Bool = false
    @State private var pendingKey: Key?

    // Blur state for soft transition effect
    @State private var currentBlur: CGFloat = 0.0
    @State private var previousBlur: CGFloat = 0.0

    // Maximum blur radius during transition midpoint
    private let maxBlurRadius: CGFloat = 8.0

    init(
        key: Key,
        duration: Double = 0.45,
        initialDelay: Double = 0,
        @ViewBuilder content: @escaping (Key) -> Content
    ) {
        self.key = key
        self.duration = duration
        self.initialDelay = initialDelay
        self.content = content
        self._currentKey = State(initialValue: key)
    }

    var body: some View {
        ZStack {
            // Previous content (fading + blurring out)
            if let previous = previousKey {
                content(previous)
                    .blur(radius: previousBlur)
                    .opacity(previousOpacity)
            }

            // Current content (fading + blurring in)
            content(currentKey)
                .blur(radius: currentBlur)
                .opacity(currentOpacity)
        }
        .onAppear {
            // Start delay timer for crossfade readiness
            if initialDelay > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + initialDelay) {
                    isReadyForCrossfade = true
                    // If a key change was pending, execute it now
                    if let pending = pendingKey, pending != currentKey {
                        performCrossfade(from: currentKey, to: pending)
                        pendingKey = nil
                    }
                }
            } else {
                isReadyForCrossfade = true
            }
        }
        .onChange(of: key) { oldValue, newValue in
            guard oldValue != newValue else { return }

            if isReadyForCrossfade {
                // Ready for crossfade - animate the transition
                performCrossfade(from: oldValue, to: newValue)
            } else {
                // Not ready yet - store the pending key
                // We'll crossfade to it once the initial delay completes
                pendingKey = newValue
            }
        }
    }

    private func performCrossfade(from oldKey: Key, to newKey: Key) {
        // Setup for crossfade
        previousKey = oldKey
        previousOpacity = 1.0
        previousBlur = 0.0
        currentOpacity = 0.0
        currentBlur = maxBlurRadius  // New content starts blurred
        currentKey = newKey

        // Animate crossfade with blur
        withAnimation(.easeInOut(duration: duration)) {
            // Opacity transition
            previousOpacity = 0.0
            currentOpacity = 1.0

            // Blur transition: previous blurs out, current comes into focus
            previousBlur = maxBlurRadius
            currentBlur = 0.0
        }

        // Cleanup after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.05) {
            previousKey = nil
            previousBlur = 0.0
        }
    }
}

#Preview {
    CrossfadeView(key: "test", duration: 0.45) { key in
        Text(key)
    }
}
