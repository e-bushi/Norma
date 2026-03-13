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

    private let stepNumber = 9
    private let totalSteps = 9

    @State private var animateStepIndicator = false
    @State private var animateSubtitle = false
    @State private var animateBenefits: [Bool] = [false, false, false]

    private let accentColor = Color("NormaPastelPurple")
    private let secondaryColor = Color("NormaPastelPurple")

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Gradient background — purple tones
            LinearGradient(
                colors: [
                    colorScheme == .dark
                        ? Color(red: 0.10, green: 0.04, blue: 0.14)
                        : Color(red: 0.94, green: 0.90, blue: 0.98),
                    colorScheme == .dark
                        ? Color(red: 0.04, green: 0.02, blue: 0.06)
                        : Color(red: 0.97, green: 0.95, blue: 0.99)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Radar rings from top-right
            Canvas { context, size in
                let origin = CGPoint(x: size.width, y: 0)
                let ringCount = 10
                let maxRadius: CGFloat = 360
                let ringSpacing = maxRadius / CGFloat(ringCount)

                for i in 1...ringCount {
                    let radius = CGFloat(i) * ringSpacing
                    let opacity = 0.18 * (1.0 - CGFloat(i) / CGFloat(ringCount))
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
                let ringCount = 8
                let maxRadius: CGFloat = 300
                let ringSpacing = maxRadius / CGFloat(ringCount)

                for i in 1...ringCount {
                    let radius = CGFloat(i) * ringSpacing
                    let opacity = 0.16 * (1.0 - CGFloat(i) / CGFloat(ringCount))
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

            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Step indicator
                        OnboardingStepIndicator(currentStep: stepNumber, totalSteps: totalSteps)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                            .opacity(animateStepIndicator ? 1.0 : 0.0)
                            .offset(y: animateStepIndicator ? 0 : -10)

                        Spacer()

                        // Title — left-aligned, large
                        Text("Stay on\ntrack.")
                            .font(.custom(FontFamily.Rubik.bold, size: 64))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .scaleEffect(animateTitle ? 1.0 : 0.95, anchor: .leading)
                            .opacity(animateTitle ? 1.0 : 0.0)

                        Spacer()
                            .frame(height: 12)

                        // Subtitle
                        Text("Timely reminders so you never\nmiss what matters.")
                            .font(.custom(FontFamily.Rubik.regular, size: 20))
                            .foregroundColor(Color("NormaText").opacity(0.35))
                            .multilineTextAlignment(.leading)
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .opacity(animateSubtitle ? 1.0 : 0.0)

                        Spacer()
                            .frame(height: 18)

                        // Benefits list — staggered
                        VStack(spacing: 0) {
                            NotificationBenefitRow(
                                icon: "calendar.badge.clock",
                                title: "Bill reminders",
                                description: "Alerts before bills are due",
                                accentColor: accentColor
                            )
                            .opacity(animateBenefits[0] ? 1.0 : 0.0)
                            .offset(x: animateBenefits[0] ? 0 : -20)

                            NotificationBenefitRow(
                                icon: "chart.bar.fill",
                                title: "Budget alerts",
                                description: "Know when you're close to limits",
                                accentColor: accentColor
                            )
                            .opacity(animateBenefits[1] ? 1.0 : 0.0)
                            .offset(x: animateBenefits[1] ? 0 : -20)

                            NotificationBenefitRow(
                                icon: "sparkles",
                                title: "Weekly insights",
                                description: "Your spending at a glance",
                                accentColor: accentColor
                            )
                            .opacity(animateBenefits[2] ? 1.0 : 0.0)
                            .offset(x: animateBenefits[2] ? 0 : -20)
                        }
                        .padding(.horizontal, 24)

                        Spacer()
                            .frame(height: 24)

                        // Buttons
                        VStack(spacing: 16) {
                            // Enable button — solid purple
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
                                        .fill(Color("NormaPastelPurple"))
                                )
                            }
                            .disabled(isLoading)

                            // Skip button
                            Button(action: {
                                playHaptic(intensity: 0.4, sharpness: 0.3)
                                onSkip()
                            }) {
                                Text("Not Now")
                                    .font(.custom(FontFamily.Rubik.medium, size: 14))
                                    .foregroundColor(Color("NormaText").opacity(0.35))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                        .offset(y: animateButton ? 0 : 60)
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
        prepareHaptics()

        // Step indicator
        withAnimation(.easeOut(duration: 0.4).delay(0.05)) {
            animateStepIndicator = true
        }

        // Hero pops in
        animateHero = true
        playHaptic(intensity: 0.6, sharpness: 0.4)

        // Title
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            playHaptic(intensity: 0.5, sharpness: 0.4)
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
            animateTitle = true
        }

        // Subtitle
        withAnimation(.easeOut(duration: 0.45).delay(0.45)) {
            animateSubtitle = true
        }

        // Benefits stagger
        for i in 0..<animateBenefits.count {
            let delay = 0.6 + Double(i) * 0.1
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                playHaptic(intensity: 0.3, sharpness: 0.2)
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay)) {
                animateBenefits[i] = true
            }
        }

        // Button
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(1.1)) {
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
    var accentColor: Color = Color("NormaPastelTeal")

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(accentColor)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(accentColor.opacity(0.15))
                        .glassEffect(in: RoundedRectangle(cornerRadius: 8))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom(FontFamily.Rubik.medium, size: 17))
                    .foregroundColor(Color("NormaText").opacity(0.7))

                Text(description)
                    .font(.custom(FontFamily.Rubik.regular, size: 14))
                    .foregroundColor(Color("NormaText").opacity(0.35))
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NotificationPermissionView(
        onPermissionGranted: { print("Permission granted") },
        onSkip: { print("Skipped") }
    )
    .preferredColorScheme(.dark)
}
