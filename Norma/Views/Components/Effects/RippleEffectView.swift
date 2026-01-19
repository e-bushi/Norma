//
//  RippleEffectView.swift
//  Norma
//
//  Displays an expanding ripple/shockwave effect using a Metal shader.
//  Creates smooth animated waves that distort a gradient background.
//

import SwiftUI

/// A view that displays an animated ripple effect using Metal shaders.
/// The ripple distorts a gradient background to create a water-like wave effect.
struct RippleEffectView: View {
    /// Binding that triggers the ripple when set to true
    @Binding var trigger: Bool

    /// Color tint for the ripple gradient (typically the coin's glow color)
    let tintColor: Color

    /// Size of the ripple area
    let size: CGSize

    // Animation state
    @State private var animationTime: CGFloat = 0
    @State private var isAnimating: Bool = false

    // Effect parameters
    private let duration: Double = 1.2
    private let noiseScale: CGFloat = 4.0
    private let strength: CGFloat = 2.0

    var body: some View {
        // Gradient background that will be distorted by the ripple shader
        RadialGradient(
            gradient: Gradient(colors: [
                tintColor.opacity(0.6),
                tintColor.opacity(0.3),
                tintColor.opacity(0.1),
                .clear
            ]),
            center: .center,
            startRadius: 0,
            endRadius: size.width * 0.5
        )
        .frame(width: size.width, height: size.height)
        .layerEffect(
            ShaderLibrary.coinRipple(
                .boundingRect,
                .float(animationTime),
                .float(noiseScale),
                .float(strength)
            ),
            maxSampleOffset: CGSize(width: 50, height: 50),
            isEnabled: isAnimating
        )
        .opacity(isAnimating ? 1 : 0)
        .onChange(of: trigger) { oldValue, newValue in
            if newValue && !oldValue {
                startRipple()
            }
        }
    }

    private func startRipple() {
        // Reset
        animationTime = 0
        isAnimating = true

        // Haptic feedback at start
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        // Animate time from 0 to 1
        withAnimation(.easeOut(duration: duration)) {
            animationTime = 1.0
        }

        // Disable after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) {
            isAnimating = false
            animationTime = 0
        }
    }
}

/// Convenience modifier to add ripple effect to any view
extension View {
    /// Adds a ripple effect overlay that triggers when the binding becomes true
    func rippleEffect(
        trigger: Binding<Bool>,
        tintColor: Color,
        size: CGSize
    ) -> some View {
        self.overlay {
            RippleEffectView(
                trigger: trigger,
                tintColor: tintColor,
                size: size
            )
        }
    }
}

// MARK: - Preview

#Preview("Ripple Effect") {
    struct PreviewWrapper: View {
        @State private var showRipple = false

        var body: some View {
            ZStack {
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 40) {
                    ZStack {
                        // Ripple effect layer
                        RippleEffectView(
                            trigger: $showRipple,
                            tintColor: CoinTier.gold.glowColor,
                            size: CGSize(width: 200, height: 200)
                        )

                        // Placeholder for coin
                        Circle()
                            .fill(CoinTier.gold.glowColor.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .scaleEffect(showRipple ? 1 : 0.3)
                            .opacity(showRipple ? 1 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showRipple)
                    }
                    .frame(width: 200, height: 200)

                    Button("Trigger Ripple") {
                        showRipple = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showRipple = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    return PreviewWrapper()
}
