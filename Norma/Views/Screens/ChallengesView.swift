//
//  ChallengesView.swift
//  Norma
//
//  Created by Claude on 12/22/25.
//

import SwiftUI
import SceneKit
import CoreHaptics

struct ChallengesView: View {
    @EnvironmentObject var challengeViewModel: ChallengeViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var showBirdCollection = false
    @State private var showInfoPopover = false

    // Loading coin animation states
    @State private var showLoadingCoin = true
    private let loadingDuration: TimeInterval = 4.0

    // Animation states
    @State private var heroAppeared = false
    @State private var statsAppeared = false
    @State private var calendarAppeared = false
    @State private var transactionsAppeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        if let challenge = challengeViewModel.activeChallenge {
                            ActiveChallengeContent(
                                challenge: challenge,
                                heroAppeared: $heroAppeared,
                                statsAppeared: $statsAppeared,
                                calendarAppeared: $calendarAppeared,
                                transactionsAppeared: $transactionsAppeared,
                                showBirdCollection: $showBirdCollection
                            )
                        } else if challengeViewModel.isLoading {
                            // Show skeleton only when we don't have a challenge yet
                            ActiveChallengeContentSkeleton()
                        } else {
                            EmptyChallengeContent()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                // Full-screen loading coin overlay (covers content completely)
                if showLoadingCoin, challengeViewModel.activeChallenge != nil {
                    ChallengeLoadingCoinOverlay(
                        onAnimationComplete: {
                            // Reset animation states so entrance animation plays fresh
                            heroAppeared = false
                            statsAppeared = false
                            calendarAppeared = false
                            transactionsAppeared = false

                            withAnimation(.easeOut(duration: 0.3)) {
                                showLoadingCoin = false
                            }

                            // Trigger entrance animations after overlay fades
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                triggerEntranceAnimations()
                            }
                        }
                    )
                }
            }
            .background {
                ZStack {
                    Color("NormaBackground")

                    // Show gradient + radar when no active challenge
                    if challengeViewModel.activeChallenge == nil && !challengeViewModel.isLoading {
                        let tierColor = challengeViewModel.currentTier.glowColor

                        LinearGradient(
                            colors: [
                                tierColor.opacity(colorScheme == .dark ? 0.15 : 0.12),
                                Color("NormaBackground")
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )

                        // Radar rings from top-left
                        Canvas { context, size in
                            let origin = CGPoint(x: 0, y: 0)
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
                                    with: .color(tierColor.opacity(opacity)),
                                    lineWidth: 1
                                )
                            }
                        }
                        .allowsHitTesting(false)
                    }
                }
                .ignoresSafeArea()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        showInfoPopover = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                    .popover(isPresented: $showInfoPopover, arrowEdge: .top) {
                        ChallengeInfoPopover()
                            .presentationCompactAdaptation(.popover)
                    }
                }

                ToolbarItem(placement: .principal) {
                    if let challenge = challengeViewModel.activeChallenge {
                        Text("\(profileViewModel.formatCurrency(challenge.amountTotal)) Challenge")
                            .font(.normaTitle(20))
                    } else {
                        Text("My Challenge")
                            .font(.normaTitle(20))
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if challengeViewModel.activeChallenge != nil {
                        Button {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            showBirdCollection = true
                        } label: {
                            SmallSpinningBird3DView(fileName: challengeViewModel.currentTier.fileName)
                                .frame(width: 32, height: 32)
                        }
                    }
                }
            }
            .refreshable {
                // Reset animation states before refresh
                heroAppeared = false
                statsAppeared = false
                calendarAppeared = false
                transactionsAppeared = false
                await challengeViewModel.refreshChallenge()
            }
            .task {
                // Load stats on appear
                await challengeViewModel.loadChallengeStats()
                // Recalculate amountRemaining based on actual expenses
                await challengeViewModel.recalculateAmountRemaining()
                // Run daily calculations and update contribution graph
                await challengeViewModel.runDailyCalculations()
                // Check if we should show daily recap (after data is loaded)
                challengeViewModel.checkForDailyRecap()
            }
            .onChange(of: challengeViewModel.isLoading) { _, isLoading in
                // Reset animation states when loading finishes
                if !isLoading {
                    heroAppeared = false
                    statsAppeared = false
                    calendarAppeared = false
                    transactionsAppeared = false
                }
            }
            .sheet(isPresented: $showBirdCollection) {
                BirdCollectionView(totalPoints: challengeViewModel.totalPoints)
            }
            .sheet(isPresented: $challengeViewModel.showDailyRecap) {
                if let recapData = challengeViewModel.dailyRecapData {
                    DailyRecapView(
                        recapData: recapData,
                        formatCurrency: { profileViewModel.formatCurrency($0) },
                        onDismiss: {
                            challengeViewModel.dismissDailyRecap()
                        }
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.hidden)
                }
            }
        }
    }

    private func triggerEntranceAnimations() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            heroAppeared = true
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
            statsAppeared = true
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
            calendarAppeared = true
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3)) {
            transactionsAppeared = true
        }
    }
}

// MARK: - Challenge Info Popover

struct ChallengeInfoPopover: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "target")
                    .font(.system(size: 24))
                    .foregroundColor(Color("NormaPastelTeal"))

                Text("How Challenges Work")
                    .font(.custom(FontFamily.Rubik.semiBold, size: 18))
                    .foregroundColor(.primary)
            }

            // Explanation
            VStack(alignment: .leading, spacing: 12) {
                Text("Set a spending cap and challenge yourself to stay under it each day.")
                    .font(.normaInput(14))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("If you spend less than your daily cap, the extra rolls over to future days. If you go over, tomorrow's cap decreases.")
                    .font(.normaInput(14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            // Points section
            HStack(spacing: 10) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color("NormaPastelPurple"))

                Text("Earning Points")
                    .font(.custom(FontFamily.Rubik.medium, size: 15))
                    .foregroundColor(.primary)
            }

            Text("Stay under your daily cap to earn points and build streaks. Collect points to unlock new birds in your collection!")
                .font(.normaInput(14))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(width: 300)
        .background(Color("NormaBackground"))
    }
}

// MARK: - Challenge Loading Coin Overlay

/// Full-screen loading overlay with a device-motion coin that spins faster and disappears
struct ChallengeLoadingCoinOverlay: View {
    let onAnimationComplete: () -> Void

    @State private var coinOpacity: Double = 1.0
    @State private var textOpacity: Double = 1.0
    @State private var isSpinningOut = false

    // Device motion simulation - more dramatic values
    @State private var tiltX: Double = 0
    @State private var tiltY: Double = 0
    @State private var wobblePhase: Double = 0

    // Accelerating spin
    @State private var spinRotation: Double = 0
    @State private var spinSpeed: Double = 0.5

    // Core Haptics
    @State private var hapticEngine: CHHapticEngine?

    private let loadingDuration: TimeInterval = 4.0

    var body: some View {
        ZStack {
            // Background
            Color("NormaBackground")
                .ignoresSafeArea()

            // Large Royalty coin centered with device motion effect
            VStack(spacing: 24) {
                DeviceMotionCoinView(
                    fileName: "norma-coin-royalty",
                    tiltX: tiltX,
                    tiltY: tiltY,
                    spinRotation: spinRotation,
                    isSpinning: isSpinningOut
                )
                .frame(width: 220, height: 220)
                .opacity(coinOpacity)

                if !isSpinningOut {
                    Text("Loading your challenge...")
                        .font(.custom(FontFamily.Rubik.regular, size: 16))
                        .foregroundColor(.secondary)
                        .opacity(textOpacity)
                }
            }
        }
        .onAppear {
            prepareHaptics()
            startDeviceMotionSimulation()

            // After loading duration, start the spin-out animation
            DispatchQueue.main.asyncAfter(deadline: .now() + loadingDuration) {
                startSpinOut()
            }
        }
        .onDisappear {
            hapticEngine?.stop()
        }
        .allowsHitTesting(false)
    }

    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()

            // Restart engine if it stops
            hapticEngine?.resetHandler = { [self] in
                do {
                    try hapticEngine?.start()
                } catch {
                    print("Failed to restart haptic engine: \(error)")
                }
            }
        } catch {
            print("Failed to create haptic engine: \(error)")
        }
    }

    private func startDeviceMotionSimulation() {
        // Start the wobble haptics after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            playDeviceMotionHaptics()
        }

        // Smooth, flowing device motion simulation
        Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { timer in
            if isSpinningOut {
                timer.invalidate()
                return
            }

            wobblePhase += 0.012  // Slow, smooth phase

            // Gentle flowing motion with smooth sine waves
            let primaryX = sin(wobblePhase * 0.7) * 20
            let secondaryX = sin(wobblePhase * 1.3) * 8

            let primaryY = cos(wobblePhase * 0.5) * 16
            let secondaryY = cos(wobblePhase * 1.1) * 6

            // Smooth interpolation toward target values
            let targetX = primaryX + secondaryX
            let targetY = primaryY + secondaryY

            tiltX = tiltX + (targetX - tiltX) * 0.08
            tiltY = tiltY + (targetY - tiltY) * 0.08
        }
    }

    private func playDeviceMotionHaptics() {
        guard let engine = hapticEngine else { return }

        do {
            var events: [CHHapticEvent] = []
            var time: TimeInterval = 0

            // Create a looping pattern of subtle wobble haptics
            while time < loadingDuration {
                // Gentle oscillation
                let wobbleCycle = sin(time * 2.5) * 0.5 + 0.5  // 0 to 1 oscillation

                // Soft continuous rumble as coin shifts
                let thudIntensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(0.15 + wobbleCycle * 0.15))
                let thudSharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)

                let thud = CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [thudIntensity, thudSharpness],
                    relativeTime: time,
                    duration: 0.15
                )
                events.append(thud)

                // Subtle edge taps as coin rocks
                if Int(time * 10) % 4 == 0 {
                    let edgeIntensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(0.2 + wobbleCycle * 0.15))
                    let edgeSharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)

                    let edge = CHHapticEvent(
                        eventType: .hapticTransient,
                        parameters: [edgeIntensity, edgeSharpness],
                        relativeTime: time
                    )
                    events.append(edge)
                }

                // Occasional slightly heavier tap
                if Int(time * 100) % 67 == 0 {
                    let clunkIntensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.45)
                    let clunkSharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.25)

                    let clunk = CHHapticEvent(
                        eventType: .hapticTransient,
                        parameters: [clunkIntensity, clunkSharpness],
                        relativeTime: time
                    )
                    events.append(clunk)
                }

                time += 0.15
            }

            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)

        } catch {
            print("Failed to play device motion haptics: \(error)")
        }
    }

    private func playCatchHaptic() {
        guard let engine = hapticEngine else { return }

        do {
            // Sharp intense tap for the "catch" moment
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)

            let catch1 = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [intensity, sharpness],
                relativeTime: 0
            )

            // Quick follow-up for "settle"
            let settleIntensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6)
            let settleSharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)

            let settle = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [settleIntensity, settleSharpness],
                relativeTime: 0.05
            )

            let pattern = try CHHapticPattern(events: [catch1, settle], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)

        } catch {
            print("Failed to play catch haptic: \(error)")
        }
    }

    private func startSpinOut() {
        isSpinningOut = true

        // Fade out text immediately
        withAnimation(.easeOut(duration: 0.2)) {
            textOpacity = 0
        }

        // Start the accelerating haptic pattern
        playAcceleratingSpinHaptics()

        // Accelerating spin animation
        var currentSpeed = spinSpeed
        let acceleration = 1.12
        let maxSpeed = 30.0

        Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { timer in
            spinRotation += currentSpeed * (1/60) * 360

            // Accelerate
            currentSpeed = min(currentSpeed * acceleration, maxSpeed)

            // Start fading when spinning fast
            if currentSpeed > 8 {
                coinOpacity = max(0, coinOpacity - 0.025)
            }

            // Complete when fully faded
            if coinOpacity <= 0 {
                timer.invalidate()
                hapticEngine?.stop()
                onAnimationComplete()
            }
        }
    }

    private func playAcceleratingSpinHaptics() {
        guard let engine = hapticEngine else { return }

        do {
            // Create an accelerating haptic pattern
            var events: [CHHapticEvent] = []

            // Build a sequence of transient taps that get faster and more intense
            var time: TimeInterval = 0
            var interval: TimeInterval = 0.15  // Start slow
            var intensity: Float = 0.3
            var sharpness: Float = 0.3

            // Create ~40 haptic events that accelerate
            for i in 0..<40 {
                let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
                let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)

                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [intensityParam, sharpnessParam],
                    relativeTime: time
                )
                events.append(event)

                time += interval

                // Accelerate: decrease interval, increase intensity
                interval = max(0.02, interval * 0.88)
                intensity = min(1.0, intensity + 0.025)
                sharpness = min(1.0, sharpness + 0.02)

                // Add a continuous "whir" in the later part
                if i > 20 {
                    let continuousIntensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity * 0.4)
                    let continuousSharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)

                    let continuous = CHHapticEvent(
                        eventType: .hapticContinuous,
                        parameters: [continuousIntensity, continuousSharpness],
                        relativeTime: time,
                        duration: interval * 2
                    )
                    events.append(continuous)
                }
            }

            // Final burst - intense rapid taps
            for j in 0..<8 {
                let burstIntensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
                let burstSharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)

                let burst = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [burstIntensity, burstSharpness],
                    relativeTime: time + Double(j) * 0.015
                )
                events.append(burst)
            }

            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)

        } catch {
            print("Failed to play haptic pattern: \(error)")
        }
    }
}

// MARK: - Device Motion Coin View

/// A 3D coin that responds to simulated device motion with tilt and optional spin
struct DeviceMotionCoinView: UIViewRepresentable {
    var fileName: String
    var tiltX: Double
    var tiltY: Double
    var spinRotation: Double
    var isSpinning: Bool

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.isOpaque = false
        scnView.autoenablesDefaultLighting = true
        scnView.allowsCameraControl = false
        scnView.isUserInteractionEnabled = false
        scnView.antialiasingMode = .multisampling4X

        if !loadScene(into: scnView, context: context) {
            createFallbackScene(into: scnView, context: context)
        }

        scnView.isPlaying = true
        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        guard let containerNode = context.coordinator.containerNode else { return }

        // Apply tilt (device motion) or spin rotation
        if isSpinning {
            // During spin-out, rotate on Y axis
            containerNode.eulerAngles = SCNVector3(
                Float(tiltX * .pi / 180),
                Float(spinRotation * .pi / 180),
                Float(tiltY * .pi / 180)
            )
        } else {
            // During loading, apply smooth device motion tilt
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.15
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            containerNode.eulerAngles = SCNVector3(
                Float(tiltX * .pi / 180),
                0,
                Float(tiltY * .pi / 180)
            )
            SCNTransaction.commit()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var containerNode: SCNNode?
    }

    private func loadScene(into scnView: SCNView, context: Context) -> Bool {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "usdz") else {
            return false
        }

        guard let scene = try? SCNScene(url: url, options: [.checkConsistency: true]) else {
            return false
        }

        scene.background.contents = UIColor.clear

        // Create container for the model
        let containerNode = SCNNode()
        context.coordinator.containerNode = containerNode

        // Clone all child nodes from the loaded scene
        for childNode in scene.rootNode.childNodes {
            containerNode.addChildNode(childNode.clone())
        }

        // Remove original nodes
        scene.rootNode.childNodes.forEach { $0.removeFromParentNode() }

        // Calculate bounding box and center the model
        let (minBound, maxBound) = containerNode.boundingBox
        let centerX = (minBound.x + maxBound.x) / 2
        let centerY = (minBound.y + maxBound.y) / 2
        let centerZ = (minBound.z + maxBound.z) / 2
        containerNode.position = SCNVector3(-centerX, -centerY, -centerZ)

        // Calculate model dimensions
        let width = maxBound.x - minBound.x
        let height = maxBound.y - minBound.y
        let depth = maxBound.z - minBound.z
        let maxDimension = max(width, max(height, depth))

        scene.rootNode.addChildNode(containerNode)

        // Setup camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.camera?.orthographicScale = Double(maxDimension * 0.6)
        cameraNode.position = SCNVector3(0, 0, maxDimension * 2)
        scene.rootNode.addChildNode(cameraNode)

        scnView.scene = scene
        return true
    }

    private func createFallbackScene(into scnView: SCNView, context: Context) {
        let fallbackScene = SCNScene()
        fallbackScene.background.contents = UIColor.clear

        let containerNode = SCNNode()
        context.coordinator.containerNode = containerNode

        let torus = SCNTorus(ringRadius: 0.4, pipeRadius: 0.15)
        torus.firstMaterial?.diffuse.contents = UIColor(red: 0.6, green: 0.4, blue: 0.8, alpha: 1.0)
        torus.firstMaterial?.specular.contents = UIColor.white
        let torusNode = SCNNode(geometry: torus)
        containerNode.addChildNode(torusNode)

        fallbackScene.rootNode.addChildNode(containerNode)

        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.camera?.usesOrthographicProjection = true
        camera.camera?.orthographicScale = 1.0
        camera.position = SCNVector3(0, 0, 3)
        fallbackScene.rootNode.addChildNode(camera)

        scnView.scene = fallbackScene
    }
}

// MARK: - Small Spinning Bird 3D View

/// A small spinning 3D bird for the nav bar
struct SmallSpinningBird3DView: UIViewRepresentable {
    var fileName: String = "challenge-bird-starter"

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.isOpaque = false
        scnView.autoenablesDefaultLighting = true
        scnView.allowsCameraControl = false
        scnView.isUserInteractionEnabled = false
        scnView.antialiasingMode = .multisampling2X

        if !loadScene(into: scnView) {
            createFallbackScene(into: scnView)
        }

        scnView.isPlaying = true

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        // No updates needed
    }

    private func loadScene(into scnView: SCNView) -> Bool {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "usdz") else {
            return false
        }

        guard let scene = try? SCNScene(url: url, options: [.checkConsistency: true]) else {
            return false
        }

        scene.background.contents = UIColor.clear

        // Create container for the model
        let containerNode = SCNNode()

        // Clone all child nodes from the loaded scene
        for childNode in scene.rootNode.childNodes {
            containerNode.addChildNode(childNode.clone())
        }

        // Remove original nodes
        scene.rootNode.childNodes.forEach { $0.removeFromParentNode() }

        // Calculate bounding box and center the model
        let (minBound, maxBound) = containerNode.boundingBox
        let centerX = (minBound.x + maxBound.x) / 2
        let centerY = (minBound.y + maxBound.y) / 2
        let centerZ = (minBound.z + maxBound.z) / 2
        containerNode.position = SCNVector3(-centerX, -centerY, -centerZ)

        // Calculate model dimensions
        let width = maxBound.x - minBound.x
        let height = maxBound.y - minBound.y
        let depth = maxBound.z - minBound.z
        let maxDimension = max(width, max(height, depth))

        // Set base rotation
        containerNode.eulerAngles.y = -5 * .pi / 180

        scene.rootNode.addChildNode(containerNode)

        // Setup camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.camera?.orthographicScale = Double(maxDimension * 0.45)
        cameraNode.position = SCNVector3(0, 0, maxDimension * 2)
        scene.rootNode.addChildNode(cameraNode)

        // Slow rotation (10 seconds for full rotation)
        let rotation = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 10)
        let repeatRotation = SCNAction.repeatForever(rotation)
        containerNode.runAction(repeatRotation)

        scnView.scene = scene
        return true
    }

    private func createFallbackScene(into scnView: SCNView) {
        let fallbackScene = SCNScene()
        fallbackScene.background.contents = UIColor.clear

        let sphere = SCNSphere(radius: 0.3)
        sphere.firstMaterial?.diffuse.contents = UIColor(red: 0.4, green: 0.8, blue: 0.8, alpha: 1.0)
        sphere.firstMaterial?.specular.contents = UIColor.white
        let sphereNode = SCNNode(geometry: sphere)

        fallbackScene.rootNode.addChildNode(sphereNode)

        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.camera?.usesOrthographicProjection = true
        camera.camera?.orthographicScale = 1.0
        camera.position = SCNVector3(0, 0, 3)
        fallbackScene.rootNode.addChildNode(camera)

        let rotation = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 10)
        sphereNode.runAction(SCNAction.repeatForever(rotation))

        scnView.scene = fallbackScene
    }
}

#Preview {
    ChallengesView()
        .environmentObject(ChallengeViewModel(
            dataManager: DataManager(),
            sessionViewModel: SessionViewModel(dataManager: DataManager())
        ))
        .environmentObject(ProfileViewModel(
            dataManager: DataManager(),
            sessionViewModel: SessionViewModel(dataManager: DataManager())
        ))
}
