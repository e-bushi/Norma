//
//  NomadTypeView.swift
//  Norma
//
//  Created by Claude on 2/9/26.
//

import SwiftUI
import CoreHaptics

// MARK: - Nomad Type Definitions

enum NomadType: String, CaseIterable, Identifiable {
    case slowmad
    case explorer
    case baseTrips = "base_trips"
    case nomadFamily = "nomad_family"
    case expat

    var id: String { rawValue }

    var title: String {
        switch self {
        case .slowmad: return "Slowmad"
        case .explorer: return "Explorer"
        case .baseTrips: return "Base + Trips"
        case .nomadFamily: return "Nomad Family"
        case .expat: return "Expat"
        }
    }

    var subtitle: String {
        switch self {
        case .slowmad: return "I settle in for 3\u{2013}6 months at a time"
        case .explorer: return "I move every few weeks, always somewhere new"
        case .baseTrips: return "I have a home base but take extended trips regularly"
        case .nomadFamily: return "I travel with my partner or kids"
        case .expat: return "I relocated to another country for work"
        }
    }

    var icon: String {
        switch self {
        case .slowmad: return "house.and.flag"
        case .explorer: return "map"
        case .baseTrips: return "airplane.departure"
        case .nomadFamily: return "figure.2.and.child.holdinghands"
        case .expat: return "briefcase.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .slowmad: return Color("NormaPastelTeal")
        case .explorer: return Color("NormaPastelCoral")
        case .baseTrips: return Color("NormaPastelPurple")
        case .nomadFamily: return Color("NormaPastelPink")
        case .expat: return Color("NormaPastelYellow")
        }
    }
}

// MARK: - Main View

struct NomadTypeView: View {
    let onContinue: (String) -> Void

    @State private var selectedType: NomadType?
    @State private var animateHero = false
    @State private var animateTitle = false
    @State private var animateSubtitle = false
    @State private var animateCards = false
    @State private var animateButton = false
    @State private var hapticEngine: CHHapticEngine?

    private let stepNumber = 2
    private let totalSteps = 9

    @Environment(\.colorScheme) private var colorScheme

    // Silver coin gradient
    private let gradientTopDark = Color(red: 0.08, green: 0.08, blue: 0.10)
    private let gradientBottomDark = Color(red: 0.04, green: 0.04, blue: 0.05)
    private let gradientTopLight = Color(red: 0.92, green: 0.92, blue: 0.94)
    private let gradientBottomLight = Color(red: 0.96, green: 0.96, blue: 0.97)

    private let accentColor = Color(red: 0.75, green: 0.75, blue: 0.8) // silver

    private var subtitleText: String {
        selectedType?.subtitle ?? "This helps Norma adapt to your lifestyle"
    }

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    colorScheme == .dark ? gradientTopDark : gradientTopLight,
                    colorScheme == .dark ? gradientBottomDark : gradientBottomLight
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
                        with: .color(accentColor.opacity(opacity)),
                        lineWidth: 1
                    )
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Step indicator
                        OnboardingStepIndicator(currentStep: stepNumber, totalSteps: totalSteps)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)

                        Spacer()
                            .frame(height: 24)

                        // Hero - 3D coin with crossfade, centered
                        HStack {
                            Spacer()
                            CrossfadeView(
                                key: "norma-coin-silver",
                                duration: 0.45,
                                initialDelay: 0.7
                            ) { fileName in
                                FloatingCoin3DView(fileName: fileName)
                                    .id(fileName)
                                    .frame(width: 140, height: 140)
                            }
                            .frame(width: 140, height: 140)
                            .scaleEffect(animateHero ? 1.0 : 0.5)
                            .opacity(animateHero ? 1.0 : 0.0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.65), value: animateHero)
                            Spacer()
                        }

                        Spacer()
                            .frame(height: 24)

                        // Title — left-aligned, large
                        Text("How do you\nmove?")
                            .font(.custom(FontFamily.Rubik.bold, size: 48))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .scaleEffect(animateTitle ? 1.0 : 0.95, anchor: .leading)
                            .opacity(animateTitle ? 1.0 : 0.0)

                        Spacer()
                            .frame(height: 10)

                        // Subtitle — starts as default, wave-animates to selection description
                        WaveTextView(
                            text: subtitleText,
                            font: .custom(FontFamily.Rubik.regular, size: 16),
                            color: Color("NormaText").opacity(0.35),
                            isAnimating: animateSubtitle,
                            alignment: .leading
                        )
                        .id(subtitleText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)

                        Spacer()
                            .frame(height: 28)

                        // Type pills
                        OptionPillFlowLayout(spacing: 10) {
                            ForEach(Array(NomadType.allCases.enumerated()), id: \.element.id) { index, type in
                                OptionPill(
                                    title: type.title,
                                    isSelected: selectedType == type,
                                    accentColor: accentColor,
                                    onTap: {
                                        playSelectionHaptic()
                                        // Re-trigger subtitle wave animation
                                        animateSubtitle = false
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                            selectedType = type
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                            animateSubtitle = true
                                        }
                                    }
                                )
                                .scaleEffect(animateCards ? 1.0 : 0.8)
                                .opacity(animateCards ? 1.0 : 0.0)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.75).delay(Double(index) * 0.06),
                                    value: animateCards
                                )
                            }
                        }
                        .padding(.horizontal, 24)

                        Spacer(minLength: 32)

                        // Continue button — matches gradient
                        Button(action: {
                            guard let selected = selectedType else { return }
                            playHaptic(intensity: 0.6, sharpness: 0.5)
                            onContinue(selected.rawValue)
                        }) {
                            Text("Continue")
                                .font(.normaHeadline(16))
                                .foregroundColor(selectedType != nil ? .white : .secondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedType != nil ? gradientTopDark : Color("NormaSurface"))
                                )
                        }
                        .disabled(selectedType == nil)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                        .offset(y: animateButton ? 0 : 30)
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

    // MARK: - Animations

    private func startAnimations() {
        prepareHaptics()

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

        // Cards stagger in
        withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
            animateCards = true
        }

        // Staggered haptics per card
        for index in 0..<NomadType.allCases.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6 + (Double(index) * 0.1)) {
                playHaptic(intensity: 0.3, sharpness: 0.2)
            }
        }

        // Button
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(1.2)) {
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

    private func playSelectionHaptic() {
        playHaptic(intensity: 0.6, sharpness: 0.5)
    }
}

#Preview {
    NomadTypeView { selected in
        print("Selected: \(selected)")
    }
    .preferredColorScheme(.dark)
}
