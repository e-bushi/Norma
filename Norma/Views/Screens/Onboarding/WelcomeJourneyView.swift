//
//  WelcomeJourneyView.swift
//  Norma
//
//  Created by Claude on 1/31/26.
//

import SwiftUI
import CoreHaptics

struct WelcomeJourneyView: View {
    let onContinue: () -> Void

    // Animation states
    @State private var coinVisible = false
    @State private var orbitCoinVisibility: [Bool] = Array(repeating: false, count: 8)
    @State private var startHovering = false
    @State private var animateTitle = false
    @State private var animateSubtitle = false
    @State private var animateMessage = false
    @State private var animateButton = false
    @State private var showConfetti = false
    @State private var hapticEngine: CHHapticEngine?

    private let stepNumber = 8
    private let totalSteps = 9

    // Orbiting coins (all tiers for celebration)
    private let orbitingCoins: [CoinTier] = [
        .starter, .basic, .silver, .tealSteel, .gold, .skyBeige, .pinkPanther, .opal
    ]

    private let accentColor = Color("NormaPastelTeal")
    private let secondaryColor = Color("NormaPastelPink")

    var body: some View {
        ZStack {
            // Lava lamp glass background
            WelcomeGlassBackground(accentColor: accentColor, secondaryColor: secondaryColor)

            GeometryReader { geometry in
                ZStack {
                    // Confetti overlay
                    if showConfetti {
                        ConfettiView()
                            .ignoresSafeArea()
                            .allowsHitTesting(false)
                    }

                    VStack(spacing: 0) {
                        // Step indicator
                        OnboardingStepIndicator(currentStep: stepNumber, totalSteps: totalSteps)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)

                        Spacer()

                        // Coin celebration orbit
                        TimelineView(.animation(paused: !startHovering)) { timeline in
                            let time = startHovering ? timeline.date.timeIntervalSinceReferenceDate : 0

                            ZStack {
                                // Orbiting smaller coins with hover effect
                                ForEach(Array(orbitingCoins.enumerated()), id: \.element.id) { index, coin in
                                    let angleOffset = (360.0 / Double(orbitingCoins.count)) * Double(index)
                                    let isVisible = index < orbitCoinVisibility.count && orbitCoinVisibility[index]
                                    let phaseOffset = Double(index) * 0.4
                                    let individualHover = sin(time * 1.5 + phaseOffset) * 6

                                    ZStack {
                                        // Glow effect behind coin
                                        Circle()
                                            .fill(coin.glowColor.opacity(0.2))
                                            .frame(width: 50, height: 50)
                                            .blur(radius: 12)

                                        StaticCoin3DView(fileName: coin.fileName)
                                            .frame(width: 44, height: 44)
                                    }
                                    .offset(
                                        x: cos(angleOffset * .pi / 180) * 110,
                                        y: sin(angleOffset * .pi / 180) * 110 + individualHover
                                    )
                                    .scaleEffect(isVisible ? 1 : 0)
                                    .opacity(isVisible ? 1 : 0)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isVisible)
                                }

                                // Center royalty coin with glow
                                ZStack {
                                    // Glow effect behind royalty coin
                                    Circle()
                                        .fill(CoinTier.royalty.glowColor.opacity(0.15))
                                        .frame(width: 160, height: 160)
                                        .blur(radius: 25)

                                    MotionCoin3DView(fileName: "norma-coin-royalty")
                                        .frame(width: 140, height: 140)
                                }
                                .scaleEffect(coinVisible ? 1 : 0.3)
                                .opacity(coinVisible ? 1 : 0)
                            }
                        }
                        .frame(width: 280, height: 280)

                        Spacer()
                            .frame(height: 40)

                        // Title
                        Text("Welcome to the journey")
                            .font(.normaHeadline(32))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .scaleEffect(animateTitle ? 1.0 : 0.8)
                            .opacity(animateTitle ? 1.0 : 0.0)

                        Spacer()
                            .frame(height: 16)

                        // Subtitle
                        Text("You just made one of the best decisions\nfor your financial freedom.")
                            .normaBody()
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 32)
                            .opacity(animateSubtitle ? 1.0 : 0.0)

                        Spacer()
                            .frame(height: 24)

                        // Encouraging message
                        VStack(spacing: 8) {
                            Text("This is where it changes.")
                                .font(.normaHeadline(18))
                                .foregroundColor(accentColor)

                            Text("Norma is here to help you every step of the way.")
                                .normaCaption()
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 32)
                        .opacity(animateMessage ? 1.0 : 0.0)

                        Spacer()

                        // Continue button with glass effect
                        Button(action: {
                            playHaptic(intensity: 0.7, sharpness: 0.5)
                            onContinue()
                        }) {
                            Text("Let's go")
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
                }
            }
        }
        .onAppear {
            NomadWelcomeView.ambientHapticsActive = false
            startAnimations()
        }
    }

    private func startAnimations() {
        // Prepare haptics
        prepareHaptics()

        // Center coin pops in first
        withAnimation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.1)) {
            coinVisible = true
        }

        // Trigger success haptic when coin appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            playSuccessHaptic()
        }

        // Stagger orbiting coins with haptics
        let staggerDelay = 0.08
        let startDelay = 0.3
        for index in 0..<orbitingCoins.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + startDelay + (Double(index) * staggerDelay)) {
                playHaptic(intensity: 0.5, sharpness: 0.3)
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    orbitCoinVisibility[index] = true
                }
            }
        }

        // Start confetti after coins appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showConfetti = true
            playSuccessHaptic()
        }

        // Start continuous hover animation after all coins appear
        let totalHoverDelay = startDelay + (Double(orbitingCoins.count) * staggerDelay) + 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + totalHoverDelay) {
            startHovering = true
        }

        // Title
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            playHaptic(intensity: 0.4, sharpness: 0.3)
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.7)) {
            animateTitle = true
        }

        // Subtitle
        withAnimation(.easeOut(duration: 0.5).delay(0.9)) {
            animateSubtitle = true
        }

        // Message
        withAnimation(.easeOut(duration: 0.5).delay(1.1)) {
            animateMessage = true
        }

        // Button
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(1.3)) {
            animateButton = true
        }
    }

    // MARK: - Haptics

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

    private func playSuccessHaptic() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = hapticEngine else { return }

        // Create a celebratory double-tap pattern
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
        let intensity1 = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8)
        let intensity2 = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6)

        let event1 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity1, sharpness], relativeTime: 0)
        let event2 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity2, sharpness], relativeTime: 0.1)

        do {
            let pattern = try CHHapticPattern(events: [event1, event2], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Haptic playback error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Welcome Glass Background

struct WelcomeGlassBackground: View {
    let accentColor: Color
    let secondaryColor: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color("NormaBackground")

                // Subtle lava lamp orbs (more muted to not compete with coins)
                LavaOrb(
                    color: accentColor,
                    size: 280,
                    blur: 80,
                    opacity: 0.1,
                    bounds: geometry.size,
                    speed: 6.0
                )

                LavaOrb(
                    color: secondaryColor,
                    size: 220,
                    blur: 70,
                    opacity: 0.08,
                    bounds: geometry.size,
                    speed: 7.0
                )

                LavaOrb(
                    color: Color("NormaPastelPurple"),
                    size: 180,
                    blur: 60,
                    opacity: 0.06,
                    bounds: geometry.size,
                    speed: 8.0
                )
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    private let colors: [Color] = [
        Color("NormaPastelTeal"),
        Color("NormaPastelPurple"),
        Color("NormaPastelCoral"),
        Color("NormaPastelPink"),
        .yellow,
        .orange,
        .green
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                animateParticles(screenHeight: geometry.size.height)
            }
        }
    }

    private func createParticles(in size: CGSize) {
        particles = (0..<80).map { _ in
            ConfettiParticle(
                color: colors.randomElement() ?? .white,
                size: CGFloat.random(in: 6...12),
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: -100...(-20))
                ),
                velocity: CGFloat.random(in: 2...5),
                horizontalDrift: CGFloat.random(in: -1.5...1.5),
                opacity: 1.0
            )
        }
    }

    private func animateParticles(screenHeight: CGFloat) {
        // Continuous animation loop
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            var allFallen = true

            for i in particles.indices {
                particles[i].position.y += particles[i].velocity
                particles[i].position.x += particles[i].horizontalDrift

                // Add some wavering
                particles[i].horizontalDrift += CGFloat.random(in: -0.1...0.1)
                particles[i].horizontalDrift = max(-2, min(2, particles[i].horizontalDrift))

                // Fade out near bottom
                if particles[i].position.y > screenHeight - 100 {
                    particles[i].opacity = max(0, particles[i].opacity - 0.02)
                }

                if particles[i].position.y < screenHeight + 50 && particles[i].opacity > 0 {
                    allFallen = false
                }
            }

            if allFallen {
                timer.invalidate()
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var velocity: CGFloat
    var horizontalDrift: CGFloat
    var opacity: Double
}

#Preview {
    WelcomeJourneyView {
        print("Continue tapped")
    }
    .preferredColorScheme(.dark)
}
