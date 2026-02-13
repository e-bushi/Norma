//
//  NomadWelcomeView.swift
//  Norma
//
//  Created by Claude on 2/9/26.
//

import SwiftUI
import CoreHaptics

struct NomadWelcomeView: View {
    let onContinue: () -> Void

    // Phase 1 — "Preparing your experience"
    @State private var showPhaseOne = false
    @State private var phaseOneOpacity: Double = 0

    // Static flag — lets other screens stop the ambient haptics
    static var ambientHapticsActive = false

    // Phase 2 — Main content
    @State private var showPhaseTwo = false
    @State private var animateHero = false
    @State private var animateSubtitle = false
    @State private var currentStatIndex: Int = -1
    @State private var statTextOpacity: Double = 0
    @State private var showContainer = false
    @State private var animateFooter = false
    @State private var animateButton = false
    @State private var hapticEngine: CHHapticEngine?

    private let stepNumber = 1
    private let totalSteps = 9

    private let accentColor = Color("NormaPastelPurple")
    private let secondaryColor = Color("NormaPastelTeal")

    private let stats: [String] = [
        "40M+ digital nomads worldwide and growing",
        "65+ countries now offer remote work visas",
        "The averagRe nomad juggles 3\u{2013}5 currencies at once",
        "14% of employed nomads work remotely without their employer knowing",
        "5% reported higher-than-expected costs in popular destinations",
        "46% earn through the creator economy with irregular income streams",
        "Average stay per destination: 6.4 weeks, up from 5.4 in 2023",
        "Average monthly spend: $1,875 across all costs"
    ]

    var body: some View {
        ZStack {
            // Lava lamp glass background
            NomadWelcomeBackground(accentColor: accentColor, secondaryColor: secondaryColor)

            // Phase 1 — Centered "Preparing your experience" wave text
            if showPhaseOne {
                VStack {
                    Spacer()
                    WaveTextView(
                        text: "Preparing your experience",
                        font: .normaHeadline(36),
                        color: .primary,
                        isAnimating: true
                    )
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 32)
                    .opacity(phaseOneOpacity)
                    Spacer()
                }
                .transition(.opacity)
            }

            // Phase 2 — Main content
            if showPhaseTwo {
                GeometryReader { geometry in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            // Step indicator
                            OnboardingStepIndicator(currentStep: stepNumber, totalSteps: totalSteps)
                                .padding(.horizontal, 24)
                                .padding(.top, 16)

                            Spacer()
                                .frame(height: 32)

                            // Hero — spinning royalty coin with tilt
                            HStack {
                                Spacer()
                                TiltSpinningCoin3DView(fileName: "norma-coin-royalty")
                                    .frame(width: 180, height: 180)
                                    .scaleEffect(animateHero ? 1.0 : 0.3)
                                    .opacity(animateHero ? 1.0 : 0.0)
                                Spacer()
                            }

                            Spacer()
                                .frame(height: 28)

                            // Subtitle
                            Text("A few things worth knowing while we get ready")
                                .normaBody()
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .opacity(animateSubtitle ? 1.0 : 0.0)

                            Spacer()
                                .frame(height: 36)

                            // Glass container — stays visible, text cycles inside
                            VStack(spacing: 16) {
                                ZStack {
                                    if currentStatIndex >= 0 && currentStatIndex < stats.count {
                                        WaveTextView(
                                            text: stats[currentStatIndex],
                                            font: .normaHeadline(20),
                                            color: .primary,
                                            isAnimating: true
                                        )
                                        .id(currentStatIndex)
                                        .opacity(statTextOpacity)
                                    }
                                }
                                .frame(minHeight: 70)

                                // Dot indicators
                                HStack(spacing: 8) {
                                    ForEach(0..<stats.count, id: \.self) { index in
                                        Circle()
                                            .fill(index <= currentStatIndex ? accentColor : Color.secondary.opacity(0.3))
                                            .frame(width: 8, height: 8)
                                            .animation(.easeInOut(duration: 0.3), value: currentStatIndex)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 24)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.clear)
                                    .glassEffect(in: RoundedRectangle(cornerRadius: 16))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                            )
                            .padding(.horizontal, 24)
                            .scaleEffect(showContainer ? 1.0 : 0.95)
                            .opacity(showContainer ? 1.0 : 0.0)

                            Spacer()
                                .frame(height: 28)

                            // Footer message
                            Text("Finally — an app that gets how you live.")
                                .font(.normaHeadline(16))
                                .foregroundColor(secondaryColor)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .opacity(animateFooter ? 1.0 : 0.0)

                            Spacer(minLength: 32)

                            // Continue button — full-width glass style
                            Button(action: {
                                playHaptic(intensity: 0.6, sharpness: 0.5)
                                onContinue()
                            }) {
                                Text("Get started")
                                    .font(.normaHeadline(16))
                                    .foregroundColor(.white)
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
                .transition(.opacity)
            }
        }
        .onAppear {
            Self.ambientHapticsActive = true
            startAnimations()
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        prepareHaptics()

        // === Phase 1: "Preparing your experience" wave text ===
        showPhaseOne = true
        withAnimation(.easeIn(duration: 0.5)) {
            phaseOneOpacity = 1.0
        }
        playHaptic(intensity: 0.5, sharpness: 0.4)

        // Calculate wave duration for the title text
        let titleWordCount = "Preparing your experience".split(separator: " ").count
        let titleWaveDuration = Double(titleWordCount) * 0.06 + 0.5
        let titleDwellTime = 1.5
        let phaseOneDuration = titleWaveDuration + titleDwellTime

        // Fade out Phase 1
        DispatchQueue.main.asyncAfter(deadline: .now() + phaseOneDuration) {
            withAnimation(.easeOut(duration: 0.6)) {
                phaseOneOpacity = 0
            }

            // Transition to Phase 2
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation(.easeIn(duration: 0.3)) {
                    showPhaseOne = false
                    showPhaseTwo = true
                }
                startPhaseTwo()
            }
        }
    }

    private func startPhaseTwo() {
        // 1. Hero coin springs in
        withAnimation(.spring(response: 0.8, dampingFraction: 0.65)) {
            animateHero = true
        }
        playHaptic(intensity: 0.6, sharpness: 0.4)

        // 2. Subtitle
        withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
            animateSubtitle = true
        }

        // 3. Glass container appears
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.8)) {
            showContainer = true
        }

        // 4. Start cycling stats inside the container
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            showStat(at: 0)
        }
    }

    private func showStat(at index: Int) {
        guard Self.ambientHapticsActive else { return }
        let wrappedIndex = index % stats.count

        // Show footer + button after first full cycle
        if index == stats.count && !animateFooter {
            withAnimation(.easeOut(duration: 0.6)) {
                animateFooter = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5)) {
                animateButton = true
            }
            playHaptic(intensity: 0.5, sharpness: 0.5)
        }

        // Set new stat and fade text in
        currentStatIndex = wrappedIndex
        withAnimation(.easeIn(duration: 0.4)) {
            statTextOpacity = 1.0
        }
        playHaptic(intensity: 0.4, sharpness: 0.3)

        // Calculate how long the wave animation takes
        let wordCount = stats[wrappedIndex].split(separator: " ").count
        let waveDuration = Double(wordCount) * 0.06 + 0.5
        let dwellTime = 1.8

        // After wave + dwell, fade out text and cycle to next
        DispatchQueue.main.asyncAfter(deadline: .now() + waveDuration + dwellTime) {
            withAnimation(.easeOut(duration: 0.4)) {
                statTextOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                showStat(at: index + 1)
            }
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
}

// MARK: - Glass Background

struct NomadWelcomeBackground: View {
    let accentColor: Color
    let secondaryColor: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color("NormaBackground")

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
                    color: Color("NormaPastelCoral"),
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

#Preview {
    NomadWelcomeView {
        print("Continue tapped")
    }
    .preferredColorScheme(.dark)
}
