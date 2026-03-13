//
//  OnboardingQuestionView.swift
//  Norma
//
//  Created by Claude on 1/25/26.
//

import SwiftUI
import CoreHaptics
import SceneKit

// MARK: - Question Types

enum OnboardingQuestion: CaseIterable {
    case runwayCheck
    case nomadChallenges
    case moneyStoppedYou
    case winningLooksLike

    var title: String {
        switch self {
        case .runwayCheck:
            return "Be honest — how's your runway?"
        case .nomadChallenges:
            return "What's actually hard about money on the road?"
        case .moneyStoppedYou:
            return "Has money ever stopped you?"
        case .winningLooksLike:
            return "What does winning look like?"
        }
    }

    var allowsMultipleSelection: Bool {
        switch self {
        case .runwayCheck, .moneyStoppedYou:
            return false
        case .nomadChallenges, .winningLooksLike:
            return true
        }
    }

    var subtitle: String? {
        switch self {
        case .nomadChallenges, .winningLooksLike:
            return "Select all that apply"
        default:
            return nil
        }
    }

    var options: [QuestionOption] {
        switch self {
        case .runwayCheck:
            return [
                QuestionOption(id: "comfortable", title: "Comfortable", subtitle: "I've got months of buffer", icon: "checkmark.shield"),
                QuestionOption(id: "manageable", title: "Manageable", subtitle: "I know my numbers, it's tight but fine", icon: "scale.3d"),
                QuestionOption(id: "winging_it", title: "Winging it", subtitle: "I try not to look too closely", icon: "eyes"),
                QuestionOption(id: "stressed", title: "Stressed", subtitle: "I think about it constantly", icon: "brain.head.profile")
            ]
        case .nomadChallenges:
            return [
                QuestionOption(id: "mental_math", title: "The mental math", subtitle: "\"Can I afford this?\" on repeat", icon: "function"),
                QuestionOption(id: "currency_chaos", title: "Currency chaos", subtitle: "Money in 4 places, none of it makes sense", icon: "dollarsign.arrow.circlepath"),
                QuestionOption(id: "irregular_income", title: "Irregular income", subtitle: "Feast or famine, hard to plan", icon: "chart.line.downtrend.xyaxis"),
                QuestionOption(id: "no_safety_net", title: "No safety net", subtitle: "One emergency and I'm flying home", icon: "airplane.departure"),
                QuestionOption(id: "building_nothing", title: "Building nothing", subtitle: "Surviving but not growing wealth", icon: "arrow.trianglehead.counterclockwise.rotate.90")
            ]
        case .moneyStoppedYou:
            return [
                QuestionOption(id: "cut_trip_short", title: "Cut a trip short", subtitle: "Had to leave somewhere early", icon: "arrow.uturn.backward"),
                QuestionOption(id: "skipped_place", title: "Skipped a place", subtitle: "Couldn't afford to go where I wanted", icon: "map"),
                QuestionOption(id: "said_no", title: "Said no to something", subtitle: "Passed on experiences because of cost", icon: "hand.raised"),
                QuestionOption(id: "not_yet", title: "Not yet", subtitle: "But I've come close", icon: "exclamationmark.circle"),
                QuestionOption(id: "never", title: "Never", subtitle: "I make it work no matter what", icon: "flame")
            ]
        case .winningLooksLike:
            return [
                QuestionOption(id: "book_the_flight", title: "Book the flight", subtitle: "Without checking my balance first", icon: "airplane"),
                QuestionOption(id: "stay_longer", title: "Stay longer", subtitle: "Extend anywhere without stress", icon: "calendar.badge.plus"),
                QuestionOption(id: "build_wealth", title: "Build real wealth", subtitle: "Not just survive, actually grow", icon: "chart.line.uptrend.xyaxis"),
                QuestionOption(id: "feel_confident", title: "Feel confident", subtitle: "Know exactly what I can spend", icon: "sparkle"),
                QuestionOption(id: "safety_net", title: "Have a safety net", subtitle: "Emergencies don't end the dream", icon: "shield")
            ]
        }
    }

    var stepNumber: Int {
        switch self {
        case .runwayCheck: return 3
        case .nomadChallenges: return 4
        case .moneyStoppedYou: return 5
        case .winningLooksLike: return 6
        }
    }

    // MARK: - Hero Visual Properties

    var coinAsset: String {
        switch self {
        case .runwayCheck: return "norma-coin-teal-steel"
        case .nomadChallenges: return "norma-coin-opal"
        case .moneyStoppedYou: return "norma-coin-pink-panther"
        case .winningLooksLike: return "norma-coin-gold"
        }
    }

    var heroIcon: String {
        switch self {
        case .runwayCheck: return "airplane"
        case .nomadChallenges: return "globe.americas.fill"
        case .moneyStoppedYou: return "hand.raised.fill"
        case .winningLooksLike: return "flag.checkered"
        }
    }

    var heroAccentColor: Color {
        switch self {
        case .runwayCheck: return Color("NormaPastelTeal")                          // teal-steel coin
        case .nomadChallenges: return Color(red: 0.96, green: 0.87, blue: 0.70)     // opal coin (warm brownish)
        case .moneyStoppedYou: return Color("NormaPastelPink")                       // pink-panther coin
        case .winningLooksLike: return Color(red: 1.0, green: 0.84, blue: 0.0)      // gold coin
        }
    }

    var heroSecondaryColor: Color {
        switch self {
        case .runwayCheck: return Color("NormaPastelPurple")
        case .nomadChallenges: return Color(red: 0.82, green: 0.72, blue: 0.55)     // warm brown
        case .moneyStoppedYou: return Color("NormaPastelCoral")
        case .winningLooksLike: return Color(red: 0.96, green: 0.87, blue: 0.70)    // warm amber
        }
    }

    /// Gradient top color matched to coin palette
    var gradientTopColor: (dark: Color, light: Color) {
        switch self {
        case .runwayCheck:       // teal-steel coin
            return (Color(red: 0.04, green: 0.14, blue: 0.16), Color(red: 0.85, green: 0.95, blue: 0.95))
        case .nomadChallenges:   // opal coin (warm brownish)
            return (Color(red: 0.14, green: 0.11, blue: 0.06), Color(red: 0.96, green: 0.93, blue: 0.88))
        case .moneyStoppedYou:   // pink-panther coin
            return (Color(red: 0.16, green: 0.06, blue: 0.10), Color(red: 0.98, green: 0.90, blue: 0.93))
        case .winningLooksLike:  // gold coin
            return (Color(red: 0.16, green: 0.13, blue: 0.02), Color(red: 0.98, green: 0.95, blue: 0.85))
        }
    }

    /// Gradient bottom color matched to coin palette
    var gradientBottomColor: (dark: Color, light: Color) {
        switch self {
        case .runwayCheck:       // teal-steel coin
            return (Color(red: 0.02, green: 0.06, blue: 0.08), Color(red: 0.94, green: 0.97, blue: 0.97))
        case .nomadChallenges:   // opal coin (warm brownish)
            return (Color(red: 0.08, green: 0.06, blue: 0.03), Color(red: 0.97, green: 0.95, blue: 0.92))
        case .moneyStoppedYou:   // pink-panther coin
            return (Color(red: 0.08, green: 0.03, blue: 0.05), Color(red: 0.98, green: 0.95, blue: 0.96))
        case .winningLooksLike:  // gold coin
            return (Color(red: 0.08, green: 0.06, blue: 0.01), Color(red: 0.98, green: 0.97, blue: 0.92))
        }
    }
}

struct QuestionOption: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
}

// MARK: - Main View

struct OnboardingQuestionView: View {
    let question: OnboardingQuestion
    let onContinue: (String) -> Void

    @State private var selectedOptions: Set<String> = []
    @State private var titleAnimating = false
    @State private var animateSubtitle = false
    @State private var animateOptions = false
    @State private var animateButton = false
    @State private var animateHero = false
    @State private var hapticEngine: CHHapticEngine?

    private let totalSteps = 9

    private var hasSelection: Bool {
        !selectedOptions.isEmpty
    }

    var body: some View {
        ZStack {
            // Gradient background
            OnboardingGradientBackground(question: question)

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
                        with: .color(question.heroAccentColor.opacity(opacity)),
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
                        with: .color(question.heroSecondaryColor.opacity(opacity)),
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
                        OnboardingStepIndicator(currentStep: question.stepNumber, totalSteps: totalSteps)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)

                        // Hero visual — centered
                        HStack {
                            Spacer()
                            QuestionHeroVisual(question: question, isAnimating: animateHero)
                            Spacer()
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 16)

                        // Question title - wave animation, larger
                        WaveTextView(
                            text: question.title,
                            font: .custom(FontFamily.Rubik.bold, size: 48),
                            color: .primary,
                            isAnimating: titleAnimating,
                            alignment: .leading
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                        // Subtitle for multi-select
                        if let subtitle = question.subtitle {
                            Text(subtitle)
                                .font(.custom(FontFamily.Rubik.regular, size: 16))
                                .foregroundColor(Color("NormaText").opacity(0.35))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 24)
                                .padding(.top, 10)
                                .offset(y: animateSubtitle ? 0 : 20)
                                .opacity(animateSubtitle ? 1.0 : 0.0)
                        }

                        // Options — pill flow layout
                        OptionPillFlowLayout(spacing: 10) {
                            ForEach(Array(question.options.enumerated()), id: \.element.id) { index, option in
                                OptionPill(
                                    title: option.title,
                                    isSelected: selectedOptions.contains(option.id),
                                    accentColor: question.heroAccentColor,
                                    onTap: {
                                        playSelectionHaptic()

                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                            if question.allowsMultipleSelection {
                                                if selectedOptions.contains(option.id) {
                                                    selectedOptions.remove(option.id)
                                                } else {
                                                    selectedOptions.insert(option.id)
                                                }
                                            } else {
                                                selectedOptions = [option.id]
                                            }
                                        }
                                    }
                                )
                                .scaleEffect(animateOptions ? 1.0 : 0.8)
                                .opacity(animateOptions ? 1.0 : 0.0)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.75).delay(Double(index) * 0.06),
                                    value: animateOptions
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 28)

                        // Help box for runway question
                        if question == .runwayCheck {
                            RunwayHelpBox()
                                .padding(.horizontal, 24)
                                .padding(.top, 16)
                                .offset(y: animateOptions ? 0 : 20)
                                .opacity(animateOptions ? 1.0 : 0.0)
                                .animation(.easeOut(duration: 0.4).delay(0.6), value: animateOptions)
                        }

                        Spacer(minLength: 24)

                        // Continue button — matches gradient
                        Button(action: {
                            let selected = selectedOptions.joined(separator: ",")
                            onContinue(selected)
                        }) {
                            Text("Continue")
                                .font(.normaHeadline(16))
                                .foregroundColor(hasSelection ? .white : .secondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(hasSelection ? question.gradientTopColor.dark : Color("NormaSurface"))
                                )
                        }
                        .disabled(!hasSelection)
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

    private func startAnimations() {
        prepareHaptics()

        // Hero visual pops in first
        animateHero = true
        playHaptic(intensity: 0.6, sharpness: 0.4)

        // Title wave starts after hero
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            titleAnimating = true
            playHaptic(intensity: 0.5, sharpness: 0.4)
        }

        // Subtitle
        withAnimation(.easeOut(duration: 0.45).delay(0.45)) {
            animateSubtitle = true
        }

        // Options stagger in
        withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
            animateOptions = true
        }

        // Staggered haptics per option
        for index in 0..<question.options.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6 + (Double(index) * 0.1)) {
                playHaptic(intensity: 0.3, sharpness: 0.2)
            }
        }

        // Button
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(1.2)) {
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

    private func playSelectionHaptic() {
        playHaptic(intensity: 0.6, sharpness: 0.5)
    }
}

// MARK: - Option Row

struct OptionRow: View {
    let option: QuestionOption
    let isSelected: Bool
    var isMultiSelect: Bool = false
    var accentColor: Color = Color("NormaPastelTeal")
    let onTap: () -> Void

    @State private var stripesVisible = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon with animated background
                ZStack {
                    Circle()
                        .fill(isSelected ? accentColor.opacity(0.15) : Color.clear)
                        .frame(width: 44, height: 44)

                    Image(systemName: option.icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? accentColor : .primary)
                }
                .animation(.easeInOut(duration: 0.2), value: isSelected)

                VStack(alignment: .leading, spacing: 3) {
                    Text(option.title)
                        .font(.custom(FontFamily.Rubik.medium, size: 17))
                        .foregroundColor(.primary)

                    Text(option.subtitle)
                        .font(.custom(FontFamily.Rubik.regular, size: 13))
                        .foregroundColor(Color("NormaText").opacity(0.4))
                }

                Spacer()

                // Selection indicator
                ZStack {
                    if isMultiSelect {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isSelected ? accentColor : Color.secondary.opacity(0.3), lineWidth: 2)
                            .frame(width: 24, height: 24)

                        if isSelected {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(accentColor)
                                .frame(width: 16, height: 16)
                                .transition(.scale.combined(with: .opacity))
                        }
                    } else {
                        Circle()
                            .stroke(isSelected ? accentColor : Color.secondary.opacity(0.3), lineWidth: 2)
                            .frame(width: 24, height: 24)

                        if isSelected {
                            Circle()
                                .fill(accentColor)
                                .frame(width: 14, height: 14)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? accentColor.opacity(0.1) : Color.white.opacity(0.05))
                        .glassEffect(in: RoundedRectangle(cornerRadius: 16))

                    // Diagonal stripes on selected
                    if isSelected {
                        OptionStripesPattern(
                            lineColor: accentColor.opacity(0.07),
                            spacing: 10,
                            lineWidth: 0.8
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .opacity(stripesVisible ? 1 : 0)
                        .mask(
                            GeometryReader { geo in
                                Rectangle()
                                    .frame(width: stripesVisible ? geo.size.width : 0)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        )
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? accentColor.opacity(0.5) : Color.white.opacity(0.15), lineWidth: 1.5)
            )
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
        .onChange(of: isSelected) { _, selected in
            if selected {
                stripesVisible = false
                withAnimation(.easeOut(duration: 0.45).delay(0.05)) {
                    stripesVisible = true
                }
            } else {
                stripesVisible = false
            }
        }
    }
}

// MARK: - Option Pill

struct OptionPill: View {
    let title: String
    let isSelected: Bool
    var accentColor: Color = Color("NormaPastelTeal")
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.custom(FontFamily.Rubik.medium, size: 16))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(isSelected ? accentColor : Color.white.opacity(0.05))
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? accentColor : Color.white.opacity(0.15), lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Flow Layout

struct OptionPillFlowLayout: Layout {
    var spacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)

        for (index, position) in result.positions.enumerated() {
            guard index < subviews.count else { break }
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX - spacing)
        }

        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}

// MARK: - Option Stripes Pattern

private struct OptionStripesPattern: View {
    var lineColor: Color = .gray
    var spacing: CGFloat = 10
    var lineWidth: CGFloat = 0.8

    var body: some View {
        Canvas { context, size in
            let totalLines = Int((size.width + size.height) / spacing) + 1

            for i in 0..<totalLines {
                let offset = CGFloat(i) * spacing

                var path = Path()
                let startX = offset
                let startY: CGFloat = 0
                let endX = offset - size.height
                let endY = size.height

                path.move(to: CGPoint(x: startX, y: startY))
                path.addLine(to: CGPoint(x: endX, y: endY))

                context.stroke(
                    path,
                    with: .color(lineColor),
                    lineWidth: lineWidth
                )
            }
        }
    }
}

// MARK: - Gradient Background

struct OnboardingGradientBackground: View {
    let question: OnboardingQuestion
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LinearGradient(
            colors: [
                colorScheme == .dark
                    ? question.gradientTopColor.dark
                    : question.gradientTopColor.light,
                colorScheme == .dark
                    ? question.gradientBottomColor.dark
                    : question.gradientBottomColor.light
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}


// MARK: - Hero Visual

struct QuestionHeroVisual: View {
    let question: OnboardingQuestion
    let isAnimating: Bool

    @State private var coinScale: CGFloat = 0.5
    @State private var coinOpacity: Double = 0
    @State private var floatOffset: CGFloat = 0

    var body: some View {
        CrossfadeView(
            key: question.coinAsset,
            duration: 0.45,
            initialDelay: 0.7
        ) { fileName in
            FloatingCoin3DView(fileName: fileName)
                .id(fileName)
                .frame(width: 140, height: 140)
        }
        .frame(width: 140, height: 140)
        .scaleEffect(coinScale)
        .opacity(coinOpacity)
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
            coinScale = 1.0
            coinOpacity = 1.0
        }

        // Start floating animation
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(0.5)) {
            floatOffset = -8
        }
    }
}

// MARK: - Floating 3D Coin View

struct FloatingCoin3DView: UIViewRepresentable {
    var fileName: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.isOpaque = false
        scnView.autoenablesDefaultLighting = true
        scnView.allowsCameraControl = false
        scnView.isUserInteractionEnabled = false
        scnView.antialiasingMode = .multisampling4X

        if !loadScene(into: scnView, coordinator: context.coordinator) {
            createFallbackScene(into: scnView, coordinator: context.coordinator)
        }

        context.coordinator.scnView = scnView
        context.coordinator.startSlowSpin()

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        // No updates needed
    }

    static func dismantleUIView(_ uiView: SCNView, coordinator: Coordinator) {
        coordinator.stopAnimations()
    }

    private func loadScene(into scnView: SCNView, coordinator: Coordinator) -> Bool {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "usdz") else {
            return false
        }

        guard let scene = try? SCNScene(url: url, options: [.checkConsistency: true]) else {
            return false
        }

        scene.background.contents = UIColor.clear

        // Create container for spin animation
        let spinContainer = SCNNode()
        spinContainer.name = "spinContainer"

        // Clone all child nodes from the loaded scene
        for childNode in scene.rootNode.childNodes {
            spinContainer.addChildNode(childNode.clone())
        }

        // Remove original nodes
        scene.rootNode.childNodes.forEach { $0.removeFromParentNode() }

        // Calculate bounding box and center the model
        let (minBound, maxBound) = spinContainer.boundingBox
        let centerX = (minBound.x + maxBound.x) / 2
        let centerY = (minBound.y + maxBound.y) / 2
        let centerZ = (minBound.z + maxBound.z) / 2
        spinContainer.position = SCNVector3(-centerX, -centerY, -centerZ)

        // Calculate model dimensions
        let width = maxBound.x - minBound.x
        let height = maxBound.y - minBound.y
        let depth = maxBound.z - minBound.z
        let maxDimension = max(width, max(height, depth))

        scene.rootNode.addChildNode(spinContainer)

        // Store reference for updates
        coordinator.spinContainer = spinContainer

        // Setup camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.camera?.orthographicScale = Double(maxDimension * 0.6)
        cameraNode.position = SCNVector3(0, 0, maxDimension * 2)
        scene.rootNode.addChildNode(cameraNode)

        // Add ambient light for better visibility
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 400
        ambientLight.light?.color = UIColor.white
        scene.rootNode.addChildNode(ambientLight)

        // Add directional light for shininess
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.intensity = 800
        directionalLight.light?.color = UIColor.white
        directionalLight.eulerAngles = SCNVector3(-Float.pi / 4, Float.pi / 4, 0)
        scene.rootNode.addChildNode(directionalLight)

        scnView.scene = scene
        return true
    }

    private func createFallbackScene(into scnView: SCNView, coordinator: Coordinator) {
        let fallbackScene = SCNScene()
        fallbackScene.background.contents = UIColor.clear

        let spinContainer = SCNNode()
        spinContainer.name = "spinContainer"

        let cylinder = SCNCylinder(radius: 0.5, height: 0.08)
        cylinder.firstMaterial?.diffuse.contents = UIColor(red: 0.6, green: 0.4, blue: 0.8, alpha: 1.0)
        cylinder.firstMaterial?.specular.contents = UIColor.white
        let coinNode = SCNNode(geometry: cylinder)
        coinNode.eulerAngles.x = Float.pi / 2

        spinContainer.addChildNode(coinNode)
        fallbackScene.rootNode.addChildNode(spinContainer)

        coordinator.spinContainer = spinContainer

        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.camera?.usesOrthographicProjection = true
        camera.camera?.orthographicScale = 1.2
        camera.position = SCNVector3(0, 0, 3)
        fallbackScene.rootNode.addChildNode(camera)

        scnView.scene = fallbackScene
    }

    // MARK: - Coordinator for Slow Spin Animation
    class Coordinator: NSObject {
        var spinContainer: SCNNode?
        var scnView: SCNView?
        private var displayLink: CADisplayLink?
        private var spinAngle: Float = 0.0

        override init() {
            super.init()
        }

        func startSlowSpin() {
            displayLink = CADisplayLink(target: self, selector: #selector(updateSpin))
            displayLink?.add(to: .main, forMode: .common)
        }

        @objc private func updateSpin() {
            guard let spinContainer = spinContainer else { return }

            // Slow spin: complete rotation every ~8 seconds
            spinAngle += Float.pi / 240.0

            // Apply continuous Y rotation
            spinContainer.eulerAngles.y = spinAngle
        }

        func stopAnimations() {
            displayLink?.invalidate()
            displayLink = nil
        }
    }
}

// MARK: - Runway Help Box

struct RunwayHelpBox: View {
    @State private var isExpanded = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 16))
                        .foregroundColor(Color("NormaPastelTeal"))

                    Text("I'm not sure what runway is?")
                        .normaCaption()
                        .foregroundColor(.secondary)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.6))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }

                if isExpanded {
                    Text("Runway is how long you could last if income stopped. If you have $6,000 and spend $2,000/month, you have 3 months of runway.")
                        .normaCaption()
                        .foregroundColor(.primary.opacity(0.85))
                        .lineSpacing(4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("NormaSurface").opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview Helper

private struct OnboardingQuestionPreview: View {
    @State private var currentIndex = 1

    private var currentQuestion: OnboardingQuestion {
        OnboardingQuestion.allCases[currentIndex]
    }

    var body: some View {
        OnboardingQuestionView(question: currentQuestion) { selected in
            print("Selected: \(selected)")
        }
        .id(currentIndex)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                currentIndex = (currentIndex + 1) % OnboardingQuestion.allCases.count
            }
        }
    }
}

#Preview {
    OnboardingQuestionPreview()
        .preferredColorScheme(.dark)
}
