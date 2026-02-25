//
//  PrivacyView.swift
//  Norma
//
//  Created by Claude on 1/31/26.
//

import SwiftUI
import CoreHaptics

struct PrivacyView: View {
    let onContinue: () -> Void

    @State private var animateHero = false
    @State private var animateTitle = false
    @State private var animateSubtitle = false
    @State private var animateItems: [Bool] = [false, false, false, false]
    @State private var animateFooter = false
    @State private var animateButton = false
    @State private var hapticEngine: CHHapticEngine?

    private let stepNumber = 7
    private let totalSteps = 9

    private let encryptedItems = [
        EncryptedItem(icon: "creditcard", title: "Your bills", description: "Due dates, amounts, everything"),
        EncryptedItem(icon: "cart", title: "Your expenses", description: "Every transaction, fully private"),
        EncryptedItem(icon: "banknote", title: "Your income", description: "What you earn stays yours"),
        EncryptedItem(icon: "bubble.left.and.bubble.right", title: "Your conversations", description: "Every chat with Norma")
    ]

    private let accentColor = Color("NormaPastelTeal")
    private let secondaryColor = Color("NormaPastelPurple")

    var body: some View {
        ZStack {
            // Lava lamp glass background
            PrivacyGlassBackground(accentColor: accentColor, secondaryColor: secondaryColor)

            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Step indicator
                        OnboardingStepIndicator(currentStep: stepNumber, totalSteps: totalSteps)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)

                        Spacer()
                            .frame(height: 32)

                        // Hero visual - Shield with glow
                        PrivacyHeroVisual(isAnimating: animateHero, accentColor: accentColor, secondaryColor: secondaryColor)

                        Spacer()
                            .frame(height: 28)

                        // Title
                        Text("Your data is yours")
                            .font(.normaHeadline(32))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .scaleEffect(animateTitle ? 1.0 : 0.9)
                            .opacity(animateTitle ? 1.0 : 0.0)

                        Spacer()
                            .frame(height: 12)

                        // Subtitle
                        Text("Freedom means knowing you're safe.\nEverything you share is encrypted.")
                            .normaBody()
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 32)
                            .opacity(animateSubtitle ? 1.0 : 0.0)

                        Spacer()
                            .frame(height: 36)

                        // Encrypted items
                        VStack(spacing: 14) {
                            ForEach(Array(encryptedItems.enumerated()), id: \.element.title) { index, item in
                                EncryptedItemRow(item: item, accentColor: accentColor)
                                    .offset(x: index < animateItems.count && animateItems[index] ? 0 : -30)
                                    .opacity(index < animateItems.count && animateItems[index] ? 1.0 : 0.0)
                            }
                        }
                        .padding(.horizontal, 24)

                        Spacer()
                            .frame(height: 28)

                        // Footer message
                        Text("We don't sell your data. We don't share it.\nThis is about helping you achieve freedom.")
                            .normaCaption()
                            .foregroundColor(.secondary.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 40)
                            .opacity(animateFooter ? 1.0 : 0.0)

                        Spacer(minLength: 32)

                        // Continue button with glass effect
                        Button(action: {
                            playHaptic(intensity: 0.6, sharpness: 0.5)
                            onContinue()
                        }) {
                            Text("I feel safe")
                                .font(.normaHeadline(16))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(accentColor.opacity(0.25))
                                        .glassEffect(in: RoundedRectangle(cornerRadius: 12))
                                )
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                        .scaleEffect(animateButton ? 1.0 : 0.9)
                        .opacity(animateButton ? 1.0 : 0.0)
                    }
                    .frame(minHeight: geometry.size.height)
                }
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        // Prepare haptics
        prepareHaptics()

        // Hero pops in first
        animateHero = true
        playHaptic(intensity: 0.6, sharpness: 0.4)

        // Title
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            playHaptic(intensity: 0.4, sharpness: 0.3)
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15)) {
            animateTitle = true
        }

        // Subtitle
        withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
            animateSubtitle = true
        }

        // Items stagger with haptics
        for i in 0..<animateItems.count {
            let delay = 0.45 + Double(i) * 0.08
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                playHaptic(intensity: 0.3, sharpness: 0.2)
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay)) {
                animateItems[i] = true
            }
        }

        // Footer
        withAnimation(.easeOut(duration: 0.4).delay(0.85)) {
            animateFooter = true
        }

        // Button
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(1.0)) {
            animateButton = true
        }
    }

    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Haptic engine error: \(error.localizedDescription)")
        }
    }

    private func playHaptic(intensity: Float, sharpness: Float) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = hapticEngine else { return }

        let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensityParam, sharpnessParam], relativeTime: 0)

        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Haptic playback error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Privacy Glass Background

struct PrivacyGlassBackground: View {
    let accentColor: Color
    let secondaryColor: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color("NormaBackground")

                // Lava lamp orbs
                LavaOrb(
                    color: accentColor,
                    size: 240,
                    blur: 65,
                    opacity: 0.16,
                    bounds: geometry.size,
                    speed: 5.0
                )

                LavaOrb(
                    color: secondaryColor,
                    size: 200,
                    blur: 55,
                    opacity: 0.12,
                    bounds: geometry.size,
                    speed: 6.0
                )

                LavaOrb(
                    color: accentColor,
                    size: 160,
                    blur: 50,
                    opacity: 0.1,
                    bounds: geometry.size,
                    speed: 7.0
                )
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Privacy Hero Visual

struct PrivacyHeroVisual: View {
    let isAnimating: Bool
    let accentColor: Color
    let secondaryColor: Color

    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0
    @State private var glowPulse = false
    @State private var floatOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            accentColor.opacity(0.25),
                            accentColor.opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .scaleEffect(glowPulse ? 1.15 : 1.0)

            // Glass circle background
            Circle()
                .fill(accentColor.opacity(0.12))
                .frame(width: 100, height: 100)
                .overlay(
                    Circle()
                        .stroke(accentColor.opacity(0.3), lineWidth: 1)
                )
                .glassEffect(in: Circle())

            // Shield icon
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [accentColor, secondaryColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .scaleEffect(iconScale)
        .opacity(iconOpacity)
        .offset(y: floatOffset)
        .onChange(of: isAnimating) { _, newValue in
            if newValue {
                startAnimations()
            }
        }
        .onAppear {
            if isAnimating {
                startAnimations()
            }
        }
    }

    private func startAnimations() {
        // Pop in animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }

        // Start floating animation
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(0.5)) {
            floatOffset = -8
        }

        // Start glow pulse
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.3)) {
            glowPulse = true
        }
    }
}

// MARK: - Supporting Types

struct EncryptedItem {
    let icon: String
    let title: String
    let description: String
}

struct EncryptedItemRow: View {
    let item: EncryptedItem
    var accentColor: Color = Color("NormaPastelTeal")

    var body: some View {
        HStack(spacing: 16) {
            // Icon with background
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: item.icon)
                    .font(.system(size: 22))
                    .foregroundColor(accentColor)
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.normaHeadline(16))
                    .foregroundColor(.primary)

                Text(item.description)
                    .normaCaption()
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Lock indicator
            Image(systemName: "lock.fill")
                .font(.system(size: 14))
                .foregroundColor(accentColor.opacity(0.6))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("NormaSurface").opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    PrivacyView {
        print("Continue tapped")
    }
    .preferredColorScheme(.dark)
}
