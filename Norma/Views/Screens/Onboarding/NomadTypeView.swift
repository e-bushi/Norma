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

    private let accentColor = Color("NormaPastelPurple")
    private let secondaryColor = Color("NormaPastelTeal")

    var body: some View {
        ZStack {
            // Lava lamp glass background
            NomadTypeBackground(accentColor: accentColor, secondaryColor: secondaryColor)

            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Step indicator
                        OnboardingStepIndicator(currentStep: stepNumber, totalSteps: totalSteps)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)

                        Spacer()
                            .frame(height: 32)

                        // Hero - 3D coin
                        HStack {
                            Spacer()
                            FloatingCoin3DView(fileName: "norma-coin-silver")
                                .frame(width: 140, height: 140)
                                .scaleEffect(animateHero ? 1.0 : 0.5)
                                .opacity(animateHero ? 1.0 : 0.0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.65), value: animateHero)
                            Spacer()
                        }

                        Spacer()
                            .frame(height: 24)

                        // Title
                        Text("How do you move?")
                            .font(.normaHeadline(28))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .scaleEffect(animateTitle ? 1.0 : 0.9)
                            .opacity(animateTitle ? 1.0 : 0.0)

                        Spacer()
                            .frame(height: 8)

                        // Subtitle
                        Text("This helps Norma adapt to your lifestyle")
                            .normaCaption()
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .opacity(animateSubtitle ? 1.0 : 0.0)

                        Spacer()
                            .frame(height: 28)

                        // Type cards
                        VStack(spacing: 12) {
                            ForEach(Array(NomadType.allCases.enumerated()), id: \.element.id) { index, type in
                                NomadTypeCard(
                                    type: type,
                                    isSelected: selectedType == type,
                                    onTap: {
                                        playSelectionHaptic()
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                            selectedType = type
                                        }
                                    }
                                )
                                .offset(y: animateCards ? 0 : 40)
                                .opacity(animateCards ? 1.0 : 0.0)
                                .animation(
                                    .spring(response: 0.6, dampingFraction: 0.75).delay(Double(index) * 0.08),
                                    value: animateCards
                                )
                            }
                        }
                        .padding(.horizontal, 24)

                        Spacer(minLength: 32)

                        // Continue button
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
                                    Group {
                                        if selectedType != nil {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color("NormaPastelTeal").opacity(0.25))
                                                .glassEffect(in: RoundedRectangle(cornerRadius: 12))
                                        } else {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color("NormaSurface"))
                                        }
                                    }
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            playHaptic(intensity: 0.4, sharpness: 0.3)
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15)) {
            animateTitle = true
        }

        // Subtitle
        withAnimation(.easeOut(duration: 0.4).delay(0.25)) {
            animateSubtitle = true
        }

        // Cards stagger in
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            animateCards = true
        }

        // Staggered haptics per card
        for index in 0..<NomadType.allCases.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + (Double(index) * 0.08)) {
                playHaptic(intensity: 0.3, sharpness: 0.2)
            }
        }

        // Button
        withAnimation(.easeOut(duration: 0.4).delay(0.6)) {
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

// MARK: - Nomad Type Card

struct NomadTypeCard: View {
    let type: NomadType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon with animated background
                ZStack {
                    Circle()
                        .fill(isSelected ? type.accentColor.opacity(0.15) : Color.clear)
                        .frame(width: 48, height: 48)

                    Image(systemName: type.icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? type.accentColor : .primary)
                }
                .animation(.easeInOut(duration: 0.2), value: isSelected)

                // Title + subtitle
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.title)
                        .font(.normaHeadline(17))
                        .foregroundColor(.primary)

                    Text(type.subtitle)
                        .normaCaption()
                        .foregroundColor(.secondary)
                        .lineSpacing(2)
                }

                Spacer()

                // Radio indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? type.accentColor : Color.secondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(type.accentColor)
                            .frame(width: 14, height: 14)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? type.accentColor.opacity(0.08) : Color("NormaSurface"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? type.accentColor : Color.clear, lineWidth: 2)
            )
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Glass Background

struct NomadTypeBackground: View {
    let accentColor: Color
    let secondaryColor: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color("NormaBackground")

                LavaOrb(
                    color: accentColor,
                    size: 220,
                    blur: 60,
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
                    color: Color("NormaPastelPink"),
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
    NomadTypeView { selected in
        print("Selected: \(selected)")
    }
    .preferredColorScheme(.dark)
}
