//
//  NotificationPermissionView.swift
//  Norma
//
//  Created by Claude on 8/5/25.
//

import SwiftUI
import UserNotifications
import CoreHaptics

struct NotificationPermissionView: View {
    let onPermissionGranted: () -> Void
    let onSkip: () -> Void

    @State private var animateHero = false
    @State private var animateTitle = false
    @State private var animateContent = false
    @State private var animateButton = false
    @State private var isLoading = false
    @State private var hapticEngine: CHHapticEngine?

    private let stepNumber = 7
    private let totalSteps = 7

    private let accentColor = Color("NormaPastelTeal")
    private let secondaryColor = Color("NormaPastelPurple")

    var body: some View {
        ZStack {
            // Lava lamp glass background
            NotificationGlassBackground(accentColor: accentColor, secondaryColor: secondaryColor)

            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Progress bar
                        OnboardingProgressBar(currentStep: stepNumber, totalSteps: totalSteps)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)

                        Spacer()
                            .frame(height: 40)

                        // Hero visual - Bell with glow
                        NotificationHeroVisual(isAnimating: animateHero, accentColor: accentColor, secondaryColor: secondaryColor)

                        Spacer()
                            .frame(height: 28)

                        // Title
                        Text("Stay on Track")
                            .font(.normaHeadline(32))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .scaleEffect(animateTitle ? 1.0 : 0.9)
                            .opacity(animateTitle ? 1.0 : 0.0)

                        Spacer()
                            .frame(height: 12)

                        // Subtitle
                        Text("Get timely reminders and never\nmiss what matters.")
                            .normaBody()
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 32)
                            .opacity(animateTitle ? 1.0 : 0.0)

                        Spacer()
                            .frame(height: 32)

                        // Benefits list
                        VStack(spacing: 14) {
                            NotificationBenefitRow(
                                icon: "calendar.badge.clock",
                                title: "Bill reminders",
                                description: "Alerts before bills are due"
                            )

                            NotificationBenefitRow(
                                icon: "chart.bar.fill",
                                title: "Budget alerts",
                                description: "Know when you're close to limits"
                            )

                            NotificationBenefitRow(
                                icon: "sparkles",
                                title: "Weekly insights",
                                description: "Your spending at a glance"
                            )
                        }
                        .padding(.horizontal, 24)
                        .offset(y: animateContent ? 0 : 30)
                        .opacity(animateContent ? 1.0 : 0.0)

                        Spacer(minLength: 40)

                        // Buttons
                        VStack(spacing: 16) {
                            // Enable button with glass effect
                            Button(action: {
                                playHaptic(intensity: 0.7, sharpness: 0.5)
                                requestNotificationPermission()
                            }) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("Enable Notifications")
                                            .font(.normaHeadline(16))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(accentColor.opacity(0.25))
                                        .glassEffect(in: RoundedRectangle(cornerRadius: 12))
                                )
                            }
                            .disabled(isLoading)

                            // Skip button
                            Button(action: {
                                playHaptic(intensity: 0.4, sharpness: 0.3)
                                onSkip()
                            }) {
                                Text("Not Now")
                                    .font(.normaHeadline(14))
                                    .foregroundColor(.secondary)
                            }
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

        // Content
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3)) {
            animateContent = true
        }

        // Staggered haptics for benefit rows
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35 + Double(i) * 0.08) {
                playHaptic(intensity: 0.3, sharpness: 0.2)
            }
        }

        // Button
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.55)) {
            animateButton = true
        }
    }

    private func requestNotificationPermission() {
        isLoading = true

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                isLoading = false

                if granted {
                    playSuccessHaptic()
                    onPermissionGranted()
                } else {
                    // User denied permission, still continue
                    onPermissionGranted()
                }
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
        } catch {
            print("Haptic playback error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Notification Glass Background

struct NotificationGlassBackground: View {
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
                    opacity: 0.14,
                    bounds: geometry.size,
                    speed: 5.5
                )

                LavaOrb(
                    color: secondaryColor,
                    size: 200,
                    blur: 55,
                    opacity: 0.1,
                    bounds: geometry.size,
                    speed: 6.5
                )

                LavaOrb(
                    color: Color("NormaPastelPink"),
                    size: 160,
                    blur: 50,
                    opacity: 0.08,
                    bounds: geometry.size,
                    speed: 7.5
                )
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Notification Hero Visual

struct NotificationHeroVisual: View {
    let isAnimating: Bool
    let accentColor: Color
    let secondaryColor: Color

    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0
    @State private var glowPulse = false
    @State private var floatOffset: CGFloat = 0
    @State private var bellRing: Double = 0

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

            // Bell icon with ring animation
            Image(systemName: "bell.fill")
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [accentColor, secondaryColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .rotationEffect(.degrees(bellRing))
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

        // Bell ring animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.1).repeatCount(6, autoreverses: true)) {
                bellRing = 15
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeOut(duration: 0.2)) {
                    bellRing = 0
                }
            }
        }

        // Start floating animation
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(1.0)) {
            floatOffset = -8
        }

        // Start glow pulse
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.3)) {
            glowPulse = true
        }
    }
}

// MARK: - Benefit Row

struct NotificationBenefitRow: View {
    let icon: String
    let title: String
    let description: String

    private let accentColor = Color("NormaPastelTeal")

    var body: some View {
        HStack(spacing: 16) {
            // Icon with background
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(accentColor)
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.normaHeadline(16))
                    .foregroundColor(.primary)

                Text(description)
                    .normaCaption()
                    .foregroundColor(.secondary)
            }

            Spacer()
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
    NotificationPermissionView(
        onPermissionGranted: { print("Permission granted") },
        onSkip: { print("Skipped") }
    )
    .preferredColorScheme(.dark)
}
