//
//  ChatEmptyStateView.swift
//  Norma
//
//  Created by Claude on 5/10/25.
//

import SwiftUI
import SceneKit
import CoreMotion

struct ChatEmptyStateView: View {
    var onFlowerTap: () -> Void = {}

    @State private var visibleWords: Int = 0
    @State private var showTooltip: Bool = false
    @AppStorage("hasSeenFlowerTooltip") private var hasSeenTooltip: Bool = false

    private let words = ["How", "can", "I", "help", "with", "your", "finances?"]

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 16) {
                ZStack {
                    StaticFlower3DView(onTap: {
                        dismissTooltip()
                        onFlowerTap()
                    })
                    .frame(width: 120, height: 120)

                    // One-time tooltip
                    if showTooltip {
                        FlowerTooltip(onDismiss: dismissTooltip)
                            .offset(x: 70, y: -30)
                            .transition(.scale(scale: 0.8, anchor: .bottomLeading).combined(with: .opacity))
                    }
                }

                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        ForEach(Array(words[0...3].enumerated()), id: \.offset) { index, word in
                            Text(word)
                                .font(.normaHeadline())
                                .tracking(-1)
                                .fixedSize()
                                .opacity(index < visibleWords ? 1 : 0)
                                .scaleEffect(index < visibleWords ? 1 : 0.3)
                                .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(Double(index) * 0.1), value: visibleWords)
                        }
                    }
                    .fixedSize()

                    HStack(spacing: 8) {
                        ForEach(Array(words[4...6].enumerated()), id: \.offset) { index, word in
                            Text(word)
                                .font(.normaHeadline())
                                .tracking(-1)
                                .fixedSize()
                                .opacity((index + 4) < visibleWords ? 1 : 0)
                                .scaleEffect((index + 4) < visibleWords ? 1 : 0.3)
                                .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(Double(index + 4) * 0.1), value: visibleWords)
                        }
                    }
                    .fixedSize()
                }
                .padding(.horizontal, 40)
                .onAppear {
                    // Reset to 0 first to ensure animation plays
                    visibleWords = 0
                    // Trigger animation after a brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        visibleWords = words.count
                    }

                    // Show tooltip if first time
                    if !hasSeenTooltip {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                showTooltip = true
                            }
                        }
                    }
                }
                .onDisappear {
                    // Reset when view disappears
                    visibleWords = 0
                    showTooltip = false
                }
            }
            .frame(width: geometry.size.width)
            .position(x: geometry.size.width / 2, y: (geometry.size.height / 2) - 80)
        }
    }

    private func dismissTooltip() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showTooltip = false
        }
        hasSeenTooltip = true
    }
}

// MARK: - Flower Tooltip
struct FlowerTooltip: View {
    let onDismiss: () -> Void

    var body: some View {
        Button(action: onDismiss) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .medium))
                Text("Tap for insights")
                    .font(.custom(FontFamily.Rubik.medium, size: 13))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.75))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Motion-Responsive 3D Flower View
struct StaticFlower3DView: UIViewRepresentable {
    var onTap: () -> Void = {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.isOpaque = false
        scnView.autoenablesDefaultLighting = true
        scnView.allowsCameraControl = false
        scnView.isUserInteractionEnabled = true
        scnView.antialiasingMode = .multisampling2X

        // Add tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)

        if !loadScene(into: scnView, coordinator: context.coordinator) {
            createFallbackScene(into: scnView, coordinator: context.coordinator)
        }

        context.coordinator.scnView = scnView
        context.coordinator.startMotionUpdates()

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        // No updates needed
    }

    static func dismantleUIView(_ uiView: SCNView, coordinator: Coordinator) {
        coordinator.stopMotionUpdates()
    }

    private func loadScene(into scnView: SCNView, coordinator: Coordinator) -> Bool {
        guard let url = Bundle.main.url(forResource: "norma-flower", withExtension: "usdz") else {
            return false
        }

        guard let scene = try? SCNScene(url: url, options: [.checkConsistency: true]) else {
            return false
        }

        scene.background.contents = UIColor.clear

        // Create container for the model
        let containerNode = SCNNode()
        containerNode.name = "flowerContainer"

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

        // Store reference for motion updates
        coordinator.containerNode = containerNode

        // Setup camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.camera?.orthographicScale = Double(maxDimension * 0.4)
        cameraNode.position = SCNVector3(0, 0, maxDimension * 2)
        scene.rootNode.addChildNode(cameraNode)

        scnView.scene = scene
        return true
    }

    private func createFallbackScene(into scnView: SCNView, coordinator: Coordinator) {
        let fallbackScene = SCNScene()
        fallbackScene.background.contents = UIColor.clear

        let sphere = SCNSphere(radius: 0.4)
        sphere.firstMaterial?.diffuse.contents = UIColor(red: 0.4, green: 0.8, blue: 0.8, alpha: 1.0)
        sphere.firstMaterial?.specular.contents = UIColor.white
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.name = "flowerContainer"

        fallbackScene.rootNode.addChildNode(sphereNode)
        coordinator.containerNode = sphereNode

        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.camera?.usesOrthographicProjection = true
        camera.camera?.orthographicScale = 1.0
        camera.position = SCNVector3(0, 0, 3)
        fallbackScene.rootNode.addChildNode(camera)

        scnView.scene = fallbackScene
    }

    // MARK: - Coordinator for Motion Updates
    class Coordinator: NSObject {
        var containerNode: SCNNode?
        var scnView: SCNView?
        private let motionManager = CMMotionManager()
        private let sensitivity: Float = 0.8
        private let onTap: () -> Void

        init(onTap: @escaping () -> Void) {
            self.onTap = onTap
            super.init()
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()

            // Animate scale down
            guard let node = containerNode else { return }
            let originalScale = node.scale

            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.15
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
            node.scale = SCNVector3(
                originalScale.x * 0.85,
                originalScale.y * 0.85,
                originalScale.z * 0.85
            )
            SCNTransaction.commit()

            // Animate scale back up with bounce
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.3
                SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
                node.scale = originalScale
                SCNTransaction.commit()

                // Trigger callback
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self?.onTap()
                }
            }
        }

        func startMotionUpdates() {
            guard motionManager.isDeviceMotionAvailable else { return }

            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
                guard let self = self,
                      let motion = motion,
                      let node = self.containerNode else { return }

                let pitch = Float(motion.attitude.pitch - .pi / 4) * self.sensitivity
                let roll = Float(motion.attitude.roll) * self.sensitivity

                // Apply rotation based on device tilt
                node.eulerAngles = SCNVector3(
                    x: pitch,
                    y: -roll,
                    z: 0
                )
            }
        }

        func stopMotionUpdates() {
            motionManager.stopDeviceMotionUpdates()
        }
    }
}

#Preview {
    ChatEmptyStateView()
        .background(Color("NormaBackground"))
}
