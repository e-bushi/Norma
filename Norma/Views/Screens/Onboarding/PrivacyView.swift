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

    @State private var animateStepIndicator = false
    @State private var animateTitle = false
    @State private var animateSubtitle = false
    @State private var animateItems: [Bool] = [false, false, false, false]
    @State private var animateButton = false
    @State private var hapticEngine: CHHapticEngine?

    private let stepNumber = 7
    private let totalSteps = 9

    private let accentColor = Color("NormaPastelTeal")
    private let secondaryColor = Color("NormaPastelTeal")

    @Environment(\.colorScheme) private var colorScheme

    private let privacyItems = [
        (icon: "creditcard.fill", title: "Bills & due dates", description: "Encrypted and stored locally"),
        (icon: "cart.fill", title: "Expenses & transactions", description: "Never shared with third parties"),
        (icon: "banknote.fill", title: "Income & earnings", description: "Only you can see your numbers"),
        (icon: "bubble.left.and.bubble.right.fill", title: "Conversations with Norma", description: "Private and not used for training")
    ]

    var body: some View {
        ZStack {
            // Gradient background — teal tones
            LinearGradient(
                colors: [
                    colorScheme == .dark
                        ? Color(red: 0.04, green: 0.12, blue: 0.14)
                        : Color(red: 0.88, green: 0.96, blue: 0.96),
                    colorScheme == .dark
                        ? Color(red: 0.02, green: 0.05, blue: 0.06)
                        : Color(red: 0.94, green: 0.98, blue: 0.98)
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
                        Text("Your data\nis yours.")
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
                        Text("Everything you share is end-to-end\nencrypted. We never sell or share it.")
                            .font(.custom(FontFamily.Rubik.regular, size: 20))
                            .foregroundColor(Color("NormaText").opacity(0.35))
                            .multilineTextAlignment(.leading)
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .opacity(animateSubtitle ? 1.0 : 0.0)

                        Spacer()
                            .frame(height: 18)

                        // Privacy items — staggered, matching notification benefit rows
                        VStack(spacing: 0) {
                            ForEach(Array(privacyItems.enumerated()), id: \.element.title) { index, item in
                                HStack(spacing: 14) {
                                    Image(systemName: item.icon)
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(accentColor)
                                        .frame(width: 36, height: 36)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(accentColor.opacity(0.15))
                                                .glassEffect(in: RoundedRectangle(cornerRadius: 8))
                                        )

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.title)
                                            .font(.custom(FontFamily.Rubik.medium, size: 17))
                                            .foregroundColor(Color("NormaText").opacity(0.7))

                                        Text(item.description)
                                            .font(.custom(FontFamily.Rubik.regular, size: 14))
                                            .foregroundColor(Color("NormaText").opacity(0.35))
                                    }

                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .opacity(index < animateItems.count && animateItems[index] ? 1.0 : 0.0)
                                .offset(x: index < animateItems.count && animateItems[index] ? 0 : -20)
                            }
                        }
                        .padding(.horizontal, 24)

                        Spacer()
                            .frame(height: 24)

                        // Solid teal button
                        Button(action: {
                            playHaptic(intensity: 0.6, sharpness: 0.5)
                            onContinue()
                        }) {
                            Text("Continue")
                                .font(.normaHeadline(16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(accentColor)
                                )
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

        // Items stagger
        for i in 0..<animateItems.count {
            let delay = 0.6 + Double(i) * 0.1
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                playHaptic(intensity: 0.3, sharpness: 0.2)
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay)) {
                animateItems[i] = true
            }
        }

        // Button
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(1.1)) {
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
        } catch {}
    }
}

#Preview {
    PrivacyView {
        print("Continue tapped")
    }
    .preferredColorScheme(.dark)
}
