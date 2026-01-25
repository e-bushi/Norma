//
//  ChallengesView.swift
//  Norma
//
//  Created by Claude on 12/22/25.
//

import SwiftUI
import SceneKit

struct ChallengesView: View {
    @EnvironmentObject var challengeViewModel: ChallengeViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showBirdCollection = false
    @State private var showInfoPopover = false

    // Skeleton timer - always show skeleton briefly on appear
    @State private var showSkeleton = true
    private let skeletonDuration: TimeInterval = 0.8

    // Animation states
    @State private var heroAppeared = false
    @State private var statsAppeared = false
    @State private var calendarAppeared = false
    @State private var transactionsAppeared = false

    /// Whether to show skeleton (either timed skeleton or actual loading)
    private var shouldShowSkeleton: Bool {
        showSkeleton || challengeViewModel.isLoading
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    if shouldShowSkeleton && challengeViewModel.activeChallenge != nil {
                        // Show skeleton for active challenge state
                        ActiveChallengeContentSkeleton()
                    } else if let challenge = challengeViewModel.activeChallenge {
                        ActiveChallengeContent(
                            challenge: challenge,
                            heroAppeared: $heroAppeared,
                            statsAppeared: $statsAppeared,
                            calendarAppeared: $calendarAppeared,
                            transactionsAppeared: $transactionsAppeared,
                            showBirdCollection: $showBirdCollection
                        )
                    } else if shouldShowSkeleton {
                        // Show skeleton while we don't know if there's a challenge yet
                        ActiveChallengeContentSkeleton()
                    } else {
                        EmptyChallengeContent()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color("NormaBackground"))
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
                // Reset states before refresh
                showSkeleton = true
                heroAppeared = false
                statsAppeared = false
                calendarAppeared = false
                transactionsAppeared = false
                await challengeViewModel.refreshChallenge()
                // Hide skeleton after duration
                try? await Task.sleep(for: .seconds(skeletonDuration))
                showSkeleton = false
            }
            .task {
                // Start skeleton timer
                Task {
                    try? await Task.sleep(for: .seconds(skeletonDuration))
                    withAnimation(.easeOut(duration: 0.2)) {
                        showSkeleton = false
                    }
                }

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
