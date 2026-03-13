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
    @State private var animateTitle = false
    @State private var animateSubtitle = false
    @State private var animateButton = false
    @State private var hapticEngine: CHHapticEngine?

    // Haptic tick tracking — fires ticks at intervals proportional to spin speed
    @State private var lastTickTime: CFTimeInterval = 0
    @State private var spinFinished = false

    private let stepNumber = 8
    private let totalSteps = 9

    private let accentColor = Color("NormaPastelTeal")
    private let secondaryColor = Color("NormaPastelPink")

    var body: some View {
        ZStack {
            // Lava lamp glass background
            WelcomeGlassBackground(accentColor: accentColor, secondaryColor: secondaryColor)

            // Radar rings from top-right
            Canvas { context, size in
                let origin = CGPoint(x: size.width, y: 0)
                let ringCount = 8
                let maxRadius: CGFloat = 320
                let ringSpacing = maxRadius / CGFloat(ringCount)

                for i in 1...ringCount {
                    let radius = CGFloat(i) * ringSpacing
                    let opacity = 0.12 * (1.0 - CGFloat(i) / CGFloat(ringCount))
                    let rect = CGRect(
                        x: origin.x - radius,
                        y: origin.y - radius,
                        width: radius * 2,
                        height: radius * 2
                    )
                    context.stroke(
                        Path(ellipseIn: rect),
                        with: .color(accentColor.opacity(opacity)),
                        lineWidth: 1
                    )
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // Radar rings from bottom-left
            Canvas { context, size in
                let origin = CGPoint(x: 0, y: size.height)
                let ringCount = 6
                let maxRadius: CGFloat = 240
                let ringSpacing = maxRadius / CGFloat(ringCount)

                for i in 1...ringCount {
                    let radius = CGFloat(i) * ringSpacing
                    let opacity = 0.10 * (1.0 - CGFloat(i) / CGFloat(ringCount))
                    let rect = CGRect(
                        x: origin.x - radius,
                        y: origin.y - radius,
                        width: radius * 2,
                        height: radius * 2
                    )
                    context.stroke(
                        Path(ellipseIn: rect),
                        with: .color(secondaryColor.opacity(opacity)),
                        lineWidth: 1
                    )
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                // Step indicator
                OnboardingStepIndicator(currentStep: stepNumber, totalSteps: totalSteps)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                Spacer()

                // Solo royalty coin with glow
                ZStack {
                    Circle()
                        .fill(CoinTier.royalty.glowColor.opacity(0.15))
                        .frame(width: 200, height: 200)
                        .blur(radius: 30)

                    DecelerateCoin3DView(
                        fileName: "norma-coin-royalty",
                        onVelocityUpdate: { velocity in
                            handleSpinVelocity(velocity)
                        }
                    )
                    .frame(width: 180, height: 180)
                }
                .scaleEffect(coinVisible ? 1 : 0.3)
                .opacity(coinVisible ? 1 : 0)

                Spacer()
                    .frame(height: 36)

                // Title
                Text("You're all set")
                    .font(.custom(FontFamily.Rubik.bold, size: 44))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .scaleEffect(animateTitle ? 1.0 : 0.8)
                    .opacity(animateTitle ? 1.0 : 0.0)

                Spacer()
                    .frame(height: 14)

                // Subtitle
                Text("You just made one of the best decisions\nfor your financial peace of mind.")
                    .font(.custom(FontFamily.Rubik.regular, size: 18))
                    .foregroundColor(Color("NormaText").opacity(0.4))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
                    .opacity(animateSubtitle ? 1.0 : 0.0)

                Spacer()

                // Solid teal button
                Button(action: {
                    playHaptic(intensity: 0.7, sharpness: 0.5)
                    onContinue()
                }) {
                    Text("Let's go")
                        .font(.normaHeadline(16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("NormaPastelPurple"))
                        )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .scaleEffect(animateButton ? 1.0 : 0.9)
                .opacity(animateButton ? 1.0 : 0.0)
            }
        }
        .onAppear {
            NomadWelcomeView.ambientHapticsActive = false
            startAnimations()
        }
    }

    private func startAnimations() {
        prepareHaptics()

        // Coin pops in — spin starts immediately via DecelerateCoin3DView
        withAnimation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.1)) {
            coinVisible = true
        }

        // Initial slam haptic when coin appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            playSpinStartHaptic()
        }

        // Title appears as spin winds down (~2.5s in)
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(2.5)) {
            animateTitle = true
        }

        // Subtitle
        withAnimation(.easeOut(duration: 0.5).delay(2.9)) {
            animateSubtitle = true
        }

        // Button
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(3.3)) {
            animateButton = true
        }
    }

    // MARK: - Spin Haptics

    /// Called every frame with the current angular velocity.
    /// Fires haptic ticks at intervals inversely proportional to speed —
    /// fast spin = rapid ticks, slow spin = sparse ticks, stopped = silence.
    private func handleSpinVelocity(_ velocity: Float) {
        guard velocity > 0.5, !spinFinished else {
            if velocity <= 0 && !spinFinished {
                spinFinished = true
                playSuccessHaptic()
            }
            return
        }

        let now = CACurrentMediaTime()

        // Tick interval: faster spin = shorter interval
        // At max velocity (~30), interval ≈ 0.03s (rapid buzz)
        // At low velocity (~1), interval ≈ 0.25s (slow clicks)
        let interval = Double(0.8 / velocity)
        let clampedInterval = max(0.03, min(0.25, interval))

        if now - lastTickTime >= clampedInterval {
            lastTickTime = now

            // Intensity scales with velocity
            let normalizedVelocity = min(velocity / 30.0, 1.0)
            let intensity = 0.15 + normalizedVelocity * 0.55
            let sharpness: Float = 0.3 + normalizedVelocity * 0.4

            playHaptic(intensity: intensity, sharpness: sharpness)
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
            // Silently fail — haptics are non-critical
        }
    }

    /// Heavy initial slam when the spin starts
    private func playSpinStartHaptic() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = hapticEngine else { return }

        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)

        let event1 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        let event2 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0.05)

        do {
            let pattern = try CHHapticPattern(events: [event1, event2], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {}
    }

    /// Satisfying double-tap when the coin comes to rest
    private func playSuccessHaptic() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = hapticEngine else { return }

        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
        let intensity1 = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8)
        let intensity2 = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6)

        let event1 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity1, sharpness], relativeTime: 0)
        let event2 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity2, sharpness], relativeTime: 0.1)

        do {
            let pattern = try CHHapticPattern(events: [event1, event2], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {}
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
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            var allFallen = true

            for i in particles.indices {
                particles[i].position.y += particles[i].velocity
                particles[i].position.x += particles[i].horizontalDrift

                particles[i].horizontalDrift += CGFloat.random(in: -0.1...0.1)
                particles[i].horizontalDrift = max(-2, min(2, particles[i].horizontalDrift))

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
