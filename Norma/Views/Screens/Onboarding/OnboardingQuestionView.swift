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
        case .runwayCheck: return Color("NormaPastelTeal")
        case .nomadChallenges: return Color("NormaPastelPurple")
        case .moneyStoppedYou: return Color("NormaPastelCoral")
        case .winningLooksLike: return Color("NormaPastelPink")
        }
    }

    var heroSecondaryColor: Color {
        switch self {
        case .runwayCheck: return Color("NormaPastelPurple")
        case .nomadChallenges: return Color("NormaPastelTeal")
        case .moneyStoppedYou: return Color("NormaPastelPink")
        case .winningLooksLike: return Color("NormaPastelTeal")
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
            // Glass background with floating orbs
            OnboardingGlassBackground(question: question)

            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Step indicator
                        OnboardingStepIndicator(currentStep: question.stepNumber, totalSteps: totalSteps)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)

                        // Hero visual
                        HStack {
                            Spacer()
                            QuestionHeroVisual(question: question, isAnimating: animateHero)
                            Spacer()
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 16)

                        // Question title - wave animation
                        WaveTextView(
                        text: question.title,
                        font: .normaHeadline(42),
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
                                .normaCaption()
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 24)
                                .padding(.top, 8)
                                .offset(y: animateSubtitle ? 0 : 20)
                                .opacity(animateSubtitle ? 1.0 : 0.0)
                        }

                        // Options list
                        VStack(spacing: 12) {
                            ForEach(Array(question.options.enumerated()), id: \.element.id) { index, option in
                                OptionRow(
                                    option: option,
                                    isSelected: selectedOptions.contains(option.id),
                                    isMultiSelect: question.allowsMultipleSelection,
                                    onTap: {
                                        // Haptic feedback on selection
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
                                .offset(y: animateOptions ? 0 : 40)
                                .opacity(animateOptions ? 1.0 : 0.0)
                                .animation(
                                    .spring(response: 0.6, dampingFraction: 0.75).delay(Double(index) * 0.06),
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
                                .animation(.easeOut(duration: 0.4).delay(0.5), value: animateOptions)
                        }

                        Spacer(minLength: 24)

                        // Continue button
                        Button(action: {
                            let selected = selectedOptions.joined(separator: ",")
                            onContinue(selected)
                        }) {
                            Text("Continue")
                                .font(.normaHeadline(16))
                                .foregroundColor(hasSelection ? .primary : .secondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    Group {
                                        if hasSelection {
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
        // Prepare haptic engine
        prepareHaptics()

        // Hero visual pops in first
        animateHero = true
        playHaptic(intensity: 0.6, sharpness: 0.4)

        // Title wave starts slightly after
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            titleAnimating = true
            playHaptic(intensity: 0.5, sharpness: 0.3)
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
            animateSubtitle = true
        }

        // Options animate in with staggered haptics
        withAnimation(.easeOut(duration: 0.5).delay(0.25)) {
            animateOptions = true
        }

        // Staggered light haptics as each option appears
        for index in 0..<question.options.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 + (Double(index) * 0.06)) {
                playHaptic(intensity: 0.3, sharpness: 0.2)
            }
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
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
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon with animated background
                ZStack {
                    Circle()
                        .fill(isSelected ? Color("NormaPastelTeal").opacity(0.15) : Color.clear)
                        .frame(width: 44, height: 44)

                    Image(systemName: option.icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? Color("NormaPastelTeal") : .primary)
                }
                .animation(.easeInOut(duration: 0.2), value: isSelected)

                VStack(alignment: .leading, spacing: 3) {
                    Text(option.title)
                        .font(.normaHeadline(17))
                        .foregroundColor(.primary)

                    Text(option.subtitle)
                        .normaCaption()
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Selection indicator
                ZStack {
                    if isMultiSelect {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isSelected ? Color("NormaPastelTeal") : Color.secondary.opacity(0.3), lineWidth: 2)
                            .frame(width: 24, height: 24)

                        if isSelected {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color("NormaPastelTeal"))
                                .frame(width: 16, height: 16)
                                .transition(.scale.combined(with: .opacity))
                        }
                    } else {
                        Circle()
                            .stroke(isSelected ? Color("NormaPastelTeal") : Color.secondary.opacity(0.3), lineWidth: 2)
                            .frame(width: 24, height: 24)

                        if isSelected {
                            Circle()
                                .fill(Color("NormaPastelTeal"))
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
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color("NormaPastelTeal").opacity(0.08) : Color("NormaSurface"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color("NormaPastelTeal") : Color.clear, lineWidth: 2)
            )
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Glass Background

struct OnboardingGlassBackground: View {
    let question: OnboardingQuestion

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color("NormaBackground")

                // Lava lamp orbs
                LavaOrb(
                    color: question.heroAccentColor,
                    size: 220,
                    blur: 60,
                    opacity: 0.18,
                    bounds: geometry.size,
                    speed: 4.0
                )

                LavaOrb(
                    color: question.heroSecondaryColor,
                    size: 200,
                    blur: 50,
                    opacity: 0.15,
                    bounds: geometry.size,
                    speed: 5.0
                )

                LavaOrb(
                    color: question.heroAccentColor,
                    size: 150,
                    blur: 45,
                    opacity: 0.12,
                    bounds: geometry.size,
                    speed: 6.0
                )
            }
        }
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
        FloatingCoin3DView(fileName: question.coinAsset)
            .frame(width: 120, height: 120)
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
    @State private var currentIndex = 0

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
