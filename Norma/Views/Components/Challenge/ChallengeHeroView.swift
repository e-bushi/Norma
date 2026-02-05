//
//  ChallengeHeroView.swift
//  Norma
//
//  Created by Claude on 12/30/25.
//

import SwiftUI
import SceneKit

/// Hero section for the Challenges view showing today's remaining budget
struct ChallengeHeroView: View {
    let challenge: Challenge
    let stats: ChallengeStats?
    let totalPoints: Int
    let tierFileName: String
    let todaysCap: Double
    let todaysRemaining: Double
    var onPointsTapped: (() -> Void)? = nil
    var triggerNumberAnimation: Bool = false  // Controlled by parent
    @EnvironmentObject var profileViewModel: ProfileViewModel

    @State private var hasAnimatedNumber = false

    private var displayedRemaining: Double {
        hasAnimatedNumber ? abs(todaysRemaining) : 0
    }

    private var formattedTodaysRemaining: String {
        profileViewModel.formatCurrency(displayedRemaining)
    }

    private var formattedTodaysCap: String {
        profileViewModel.formatCurrency(todaysCap)
    }

    private var isOverBudget: Bool {
        todaysRemaining < 0
    }

    var body: some View {
        VStack(spacing: 12) {
            // Today's cap capsule with cycling coin behind
            ZStack {
                // Cycling spinning coin behind capsule (centered)
                CyclingSpinningCoin3DView()
                    .frame(width: 65, height: 65)

                Text("Today's cap: \(formattedTodaysCap)")
                    .font(.custom(FontFamily.Rubik.medium, size: 14))
                    .foregroundColor(.primary.opacity(0.8))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.clear)
                            .glassEffect(in: Capsule())
                    )
            }

            // The big number with "Left" label
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(formattedTodaysRemaining)
                    .font(.normaHeadline(72))
                    .foregroundColor(isOverBudget ? Color("NormaPastelCoral") : .primary)
                    .shadow(color: (isOverBudget ? Color("NormaPastelCoral") : Color("NormaPastelTeal")).opacity(0.25), radius: 20, y: 4)
                    .contentTransition(.numericText())

                Text(isOverBudget ? "Over" : "Left")
                    .font(.custom(FontFamily.Rubik.regular, size: 22))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .onChange(of: triggerNumberAnimation) { _, shouldAnimate in
            if shouldAnimate && !hasAnimatedNumber {
                // Delay slightly for visual effect
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        hasAnimatedNumber = true
                    }
                }
            }
        }
    }
}

// MARK: - Cycling Spinning Coin 3D View

/// A spinning 3D coin that cycles through all coin tiers with crossfade
struct CyclingSpinningCoin3DView: View {
    private let coinTiers = CoinTier.allTiersInOrder
    @State private var currentTierIndex = 0
    @State private var timer: Timer?

    // Duration each coin is shown before fading to the next
    private let cycleDuration: TimeInterval = 3.0

    var body: some View {
        ZStack {
            ForEach(Array(coinTiers.enumerated()), id: \.element.id) { index, tier in
                SpinningCoin3DView(fileName: tier.fileName)
                    .opacity(index == currentTierIndex ? 1 : 0)
                    .animation(.easeInOut(duration: 0.8), value: currentTierIndex)
            }
        }
        .onAppear {
            startCycling()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    private func startCycling() {
        timer = Timer.scheduledTimer(withTimeInterval: cycleDuration, repeats: true) { _ in
            withAnimation {
                currentTierIndex = (currentTierIndex + 1) % coinTiers.count
            }
        }
    }
}

// MARK: - Spinning Coin 3D View

/// A spinning 3D coin for a specific tier
struct SpinningCoin3DView: UIViewRepresentable {
    var fileName: String

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

        scene.rootNode.addChildNode(containerNode)

        // Setup camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.camera?.orthographicScale = Double(maxDimension * 0.6)
        cameraNode.position = SCNVector3(0, 0, maxDimension * 2)
        scene.rootNode.addChildNode(cameraNode)

        // Slow rotation (8 seconds for full rotation)
        let rotation = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 8)
        let repeatRotation = SCNAction.repeatForever(rotation)
        containerNode.runAction(repeatRotation)

        scnView.scene = scene
        return true
    }

    private func createFallbackScene(into scnView: SCNView) {
        let fallbackScene = SCNScene()
        fallbackScene.background.contents = UIColor.clear

        let torus = SCNTorus(ringRadius: 0.4, pipeRadius: 0.15)
        torus.firstMaterial?.diffuse.contents = UIColor(red: 0.4, green: 0.8, blue: 0.8, alpha: 1.0)
        torus.firstMaterial?.specular.contents = UIColor.white
        let torusNode = SCNNode(geometry: torus)
        torusNode.eulerAngles.x = .pi / 4

        fallbackScene.rootNode.addChildNode(torusNode)

        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.camera?.usesOrthographicProjection = true
        camera.camera?.orthographicScale = 1.0
        camera.position = SCNVector3(0, 0, 3)
        fallbackScene.rootNode.addChildNode(camera)

        let rotation = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 8)
        torusNode.runAction(SCNAction.repeatForever(rotation))

        scnView.scene = fallbackScene
    }
}

#Preview {
    ChallengeHeroView(
        challenge: Challenge(
            userId: "test",
            amountTotal: 500,
            amountRemaining: 247,
            currency: "USD",
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())!,
            status: .active,
            difficulty: .medium
        ),
        stats: ChallengeStats(userId: "test", totalPoints: 42),
        totalPoints: 42,
        tierFileName: ChallengeTier.starter.fileName,
        todaysCap: 100,
        todaysRemaining: 68
    )
    .environmentObject(ProfileViewModel(
        dataManager: DataManager(),
        sessionViewModel: SessionViewModel(dataManager: DataManager())
    ))
}
