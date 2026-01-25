//
//  BirdCollectionView.swift
//  Norma
//
//  Created by Claude on 12/30/25.
//

import SwiftUI
import SceneKit

/// Grid view showing all challenge tier birds with locked/unlocked states
struct BirdCollectionView: View {
    let totalPoints: Int

    // Sheet state
    @State private var showInfoPopover = false

    // Staggered animation states
    @State private var heroVisible = false
    @State private var pointsVisible = false
    @State private var statsVisible = false
    @State private var gridHeaderVisible = false
    @State private var birdVisibility: [Bool] = Array(repeating: false, count: ChallengeTier.allCases.count)

    // Haptic generator
    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)

    // Current tier info
    private var currentTier: ChallengeTier {
        ChallengeTierService.currentTier(for: totalPoints)
    }

    private var pointsToNextTier: Int {
        ChallengeTierService.pointsToNextTier(for: totalPoints)
    }

    private var progressToNextTier: CGFloat {
        CGFloat(ChallengeTierService.progressToNextTier(for: totalPoints))
    }

    private var unlockedCount: Int {
        ChallengeTierService.unlockedTierCount(for: totalPoints)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero bird with glow and progress ring
                    VStack(spacing: 16) {
                        ZStack {
                            // Glow effect behind bird (color matches current tier)
                            Circle()
                                .fill(currentTier.glowColor.opacity(0.10))
                                .frame(width: 160, height: 160)
                                .blur(radius: 30)
                                .scaleEffect(heroVisible ? 1 : 0.5)
                                .opacity(heroVisible ? 1 : 0)

                            // Progress ring background
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                                .frame(width: 140, height: 140)
                                .scaleEffect(heroVisible ? 1 : 0.8)
                                .opacity(heroVisible ? 1 : 0)

                            // Progress ring foreground
                            Circle()
                                .trim(from: 0, to: heroVisible ? progressToNextTier : 0)
                                .stroke(
                                    currentTier.glowColor,
                                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                                )
                                .frame(width: 140, height: 140)
                                .rotationEffect(.degrees(-90))

                            // Spinning bird
                            HeroSpinningBird3DView(fileName: currentTier.fileName)
                                .id(currentTier.fileName)
                                .frame(width: 100, height: 100)
                                .scaleEffect(heroVisible ? 1 : 0)
                                .opacity(heroVisible ? 1 : 0)
                        }

                        // Points display
                        VStack(spacing: 12) {
                            Text("\(totalPoints)")
                                .font(.normaHeadline(56))
                                .foregroundColor(.primary)

                            Text("Total Points")
                                .font(.custom(FontFamily.Rubik.medium, size: 14))
                                .foregroundColor(.secondary)

                            // Progress capsule
                            if pointsToNextTier > 0 {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(currentTier.glowColor)
                                    Text("\(pointsToNextTier) pts to \(currentTier.nextTier?.displayName ?? "max")")
                                        .font(.normaInput(13))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color.gray.opacity(0.08))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.gray.opacity(0.12), lineWidth: 0.5)
                                )
                            } else {
                                Text("Max tier reached!")
                                    .font(.normaInput(13))
                                    .foregroundColor(currentTier.glowColor)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(currentTier.glowColor.opacity(0.12))
                                    )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
                    .opacity(pointsVisible ? 1 : 0)
                    .offset(y: pointsVisible ? 0 : 20)

                    // Stats section
                    VStack(spacing: 16) {
                        // Current Tier
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(currentTier.glowColor)
                                Text("Current Tier")
                                    .font(.normaInput(15))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(currentTier.displayName)
                                .font(.normaFinancial(16))
                                .foregroundColor(currentTier.glowColor)
                        }

                        // Unlocked Birds
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "lock.open.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color("NormaPastelTeal"))
                                Text("Birds Unlocked")
                                    .font(.normaInput(15))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("\(unlockedCount) of \(ChallengeTier.allCases.count)")
                                .font(.normaFinancial(16))
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.03))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
                    )
                    .opacity(statsVisible ? 1 : 0)
                    .offset(y: statsVisible ? 0 : 15)

                    // Bird grid section
                    VStack(spacing: 16) {
                        Text("Your Collection")
                            .font(.custom(FontFamily.Rubik.medium, size: 16))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .opacity(gridHeaderVisible ? 1 : 0)
                            .offset(y: gridHeaderVisible ? 0 : 10)

                        // Bird grid (3 columns like arc view)
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 20),
                            GridItem(.flexible(), spacing: 20),
                            GridItem(.flexible())
                        ], spacing: 24) {
                            ForEach(Array(ChallengeTier.allTiersInOrder.enumerated()), id: \.element) { index, tier in
                                BirdTierCard(
                                    tier: tier,
                                    isUnlocked: ChallengeTierService.isTierUnlocked(tier, for: totalPoints),
                                    isCurrent: currentTier == tier,
                                    isVisible: birdVisibility.indices.contains(index) ? birdVisibility[index] : false
                                )
                            }
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
            .background(Color("NormaBackground"))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
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
                        BirdCollectionInfoPopover()
                            .presentationCompactAdaptation(.popover)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("Bird Collection")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 20))
                        .foregroundColor(.primary)
                }
            }
        }
        .onAppear {
            // Prepare haptic generator
            impactGenerator.prepare()

            // Hero bird bounce in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.15)) {
                heroVisible = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                impactGenerator.impactOccurred(intensity: 1.0)
            }

            // Points text fade in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.5)) {
                pointsVisible = true
            }

            // Stats section fade in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.7)) {
                statsVisible = true
            }

            // Grid header
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.9)) {
                gridHeaderVisible = true
            }

            // Staggered bird grid animations with haptics
            for index in 0..<ChallengeTier.allCases.count {
                let delay = 1.1 + (Double(index) * 0.08)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    if birdVisibility.indices.contains(index) {
                        birdVisibility[index] = true
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.05) {
                    impactGenerator.impactOccurred(intensity: 0.3)
                }
            }
        }
    }
}

// MARK: - Bird Collection Info Popover

struct BirdCollectionInfoPopover: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "bird.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color("NormaPastelTeal"))

                Text("Bird Collection")
                    .font(.custom(FontFamily.Rubik.semiBold, size: 18))
                    .foregroundColor(.primary)
            }

            // Explanation
            VStack(alignment: .leading, spacing: 12) {
                Text("Collect unique birds by earning points in your spending challenges.")
                    .font(.normaInput(14))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Stay under your daily cap to earn points. As you accumulate more points, you'll unlock new bird tiers — each one rarer than the last.")
                    .font(.normaInput(14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            // How to earn
            HStack(spacing: 10) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color("NormaPastelPurple"))

                Text("Earning Points")
                    .font(.custom(FontFamily.Rubik.medium, size: 15))
                    .foregroundColor(.primary)
            }

            Text("Complete challenge days under budget to earn points. Build streaks for bonus points and watch your collection grow!")
                .font(.normaInput(14))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(width: 300)
        .background(Color("NormaBackground"))
    }
}

// MARK: - Bird Tier Card

struct BirdTierCard: View {
    let tier: ChallengeTier
    let isUnlocked: Bool
    let isCurrent: Bool
    var isVisible: Bool = true

    // Spring animation for bird appearance
    private var birdAnimation: Animation {
        .spring(response: 0.7, dampingFraction: 0.6)
    }

    var body: some View {
        VStack(spacing: 4) {
            if isUnlocked {
                // Static 3D bird with glow effect
                ZStack {
                    // Glow effect behind bird
                    Circle()
                        .fill(tier.glowColor.opacity(0.10))
                        .frame(width: 80, height: 80)
                        .blur(radius: 15)
                        .scaleEffect(isVisible ? 1 : 0.3)
                        .opacity(isVisible ? 1 : 0)
                        .animation(birdAnimation, value: isVisible)

                    // Static 3D Bird
                    StaticBird3DView(fileName: tier.fileName)
                        .id(tier.fileName)
                        .frame(width: 64, height: 64)
                        .scaleEffect(isVisible ? 1 : 0)
                        .opacity(isVisible ? 1 : 0)
                        .animation(birdAnimation, value: isVisible)

                    // Current tier indicator
                    if isCurrent {
                        Circle()
                            .stroke(tier.glowColor, lineWidth: 2)
                            .frame(width: 70, height: 70)
                            .scaleEffect(isVisible ? 1 : 0)
                            .opacity(isVisible ? 1 : 0)
                            .animation(birdAnimation, value: isVisible)
                    }
                }
            } else {
                // Locked state - grayed out bird with lock
                ZStack {
                    // Grayed out bird
                    StaticBird3DView(fileName: tier.fileName)
                        .id("\(tier.fileName)-locked")
                        .frame(width: 64, height: 64)
                        .saturation(0)
                        .opacity(isVisible ? 0.4 : 0)
                        .scaleEffect(isVisible ? 1 : 0)
                        .animation(birdAnimation, value: isVisible)

                    // Lock overlay
                    Circle()
                        .fill(Color.black.opacity(0.3))
                        .frame(width: 64, height: 64)
                        .scaleEffect(isVisible ? 1 : 0)
                        .opacity(isVisible ? 1 : 0)
                        .animation(birdAnimation, value: isVisible)

                    Image(systemName: "lock.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.8))
                        .scaleEffect(isVisible ? 1 : 0)
                        .opacity(isVisible ? 1 : 0)
                        .animation(birdAnimation, value: isVisible)
                }
            }

            // Tier name and points
            VStack(spacing: 2) {
                Text(tier.displayName)
                    .font(.custom(FontFamily.Rubik.medium, size: 14))
                    .foregroundColor(isUnlocked ? .primary : .secondary)

                Text("\(tier.requiredPoints) pts")
                    .font(.custom(FontFamily.Rubik.regular, size: 11))
                    .foregroundColor(isUnlocked ? tier.glowColor : .secondary)
            }
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 5)
            .animation(birdAnimation, value: isVisible)
        }
    }
}

// MARK: - Hero Spinning Bird 3D View

struct HeroSpinningBird3DView: UIViewRepresentable {
    var fileName: String = "challenge-bird-starter"

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.isOpaque = false
        scnView.autoenablesDefaultLighting = true
        scnView.allowsCameraControl = false
        scnView.isUserInteractionEnabled = false
        scnView.antialiasingMode = .multisampling4X

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

        scene.rootNode.addChildNode(containerNode)

        // Setup camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.camera?.orthographicScale = Double(maxDimension * 0.6)
        cameraNode.position = SCNVector3(0, 0, maxDimension * 2)
        scene.rootNode.addChildNode(cameraNode)

        // Slow rotation for hero bird (10 seconds for full rotation)
        let rotation = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 10)
        let repeatRotation = SCNAction.repeatForever(rotation)
        containerNode.runAction(repeatRotation)

        scnView.scene = scene
        return true
    }

    private func createFallbackScene(into scnView: SCNView) {
        let fallbackScene = SCNScene()
        fallbackScene.background.contents = UIColor.clear

        let sphere = SCNSphere(radius: 0.4)
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

// MARK: - Compact teaser for the main view

struct BirdCollectionTeaser: View {
    let totalPoints: Int
    let pointsToNextTier: Int
    @Binding var showCollection: Bool

    private var unlockedCount: Int {
        ChallengeTierService.unlockedTierCount(for: totalPoints)
    }

    private var currentTier: ChallengeTier {
        ChallengeTierService.currentTier(for: totalPoints)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Progress header
            HStack {
                if pointsToNextTier > 0, let nextTier = currentTier.nextTier {
                    Text("\(pointsToNextTier) pts to \(nextTier.displayName)")
                        .font(.custom(FontFamily.Rubik.medium, size: 14))
                        .foregroundColor(.primary)
                } else {
                    Text("Max tier reached!")
                        .font(.custom(FontFamily.Rubik.medium, size: 14))
                        .foregroundColor(Color("NormaPastelTeal"))
                }

                Spacer()

                Text("\(unlockedCount)/\(ChallengeTier.allCases.count)")
                    .font(.custom(FontFamily.Rubik.regular, size: 13))
                    .foregroundColor(.secondary)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 6)

                    // Progress
                    let progress = ChallengeTierService.progressToNextTier(for: totalPoints)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(currentTier.glowColor)
                        .frame(width: geo.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)

            // Mini bird icons row
            HStack(spacing: 4) {
                ForEach(ChallengeTier.allTiersInOrder, id: \.self) { tier in
                    Circle()
                        .fill(
                            ChallengeTierService.isTierUnlocked(tier, for: totalPoints)
                                ? tier.glowColor
                                : Color.gray.opacity(0.2)
                        )
                        .frame(width: 8, height: 8)
                }
                Spacer()
            }

            // View collection button
            Button {
                showCollection = true
            } label: {
                HStack {
                    Text("View Collection")
                        .font(.custom(FontFamily.Rubik.medium, size: 13))
                        .foregroundColor(Color("NormaPastelTeal"))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color("NormaPastelTeal"))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("NormaPastelTeal").opacity(0.08))
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
                )
        )
    }
}

#Preview {
    BirdCollectionView(totalPoints: 42)
}
