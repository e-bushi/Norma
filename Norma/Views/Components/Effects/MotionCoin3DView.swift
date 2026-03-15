//
//  MotionCoin3DView.swift
//  Norma
//
//  Motion-responsive 3D coin view using SceneKit and CoreMotion.
//

import SwiftUI
import SceneKit
import CoreMotion
import CoreHaptics

struct MotionCoin3DView: UIViewRepresentable {
    var fileName: String = "norma-coin"
    var hapticsEnabled: Bool = true

    // Base Y rotation angle (-5°)
    private let baseYRotation: Float = -5 * .pi / 180

    func makeCoordinator() -> Coordinator {
        Coordinator(baseYRotation: baseYRotation, hapticsEnabled: hapticsEnabled)
    }

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.isOpaque = false
        scnView.autoenablesDefaultLighting = true
        scnView.allowsCameraControl = false
        scnView.isUserInteractionEnabled = false
        scnView.antialiasingMode = .multisampling2X

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
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "usdz") else {
            return false
        }

        guard let scene = try? SCNScene(url: url, options: [.checkConsistency: true]) else {
            return false
        }

        scene.background.contents = UIColor.clear

        // Create container for the model
        let containerNode = SCNNode()
        containerNode.name = "coinContainer"

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

        // Set initial rotation to show front of coin
        containerNode.eulerAngles.y = baseYRotation

        scene.rootNode.addChildNode(containerNode)

        // Store reference for motion updates
        coordinator.containerNode = containerNode

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

    private func createFallbackScene(into scnView: SCNView, coordinator: Coordinator) {
        let fallbackScene = SCNScene()
        fallbackScene.background.contents = UIColor.clear

        let torus = SCNTorus(ringRadius: 0.4, pipeRadius: 0.15)
        torus.firstMaterial?.diffuse.contents = UIColor(red: 0.4, green: 0.8, blue: 0.8, alpha: 1.0)
        torus.firstMaterial?.specular.contents = UIColor.white
        let torusNode = SCNNode(geometry: torus)
        torusNode.name = "coinContainer"
        torusNode.eulerAngles.y = baseYRotation

        fallbackScene.rootNode.addChildNode(torusNode)
        coordinator.containerNode = torusNode

        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.camera?.usesOrthographicProjection = true
        camera.camera?.orthographicScale = 1.0
        camera.position = SCNVector3(0, 0, 3)
        fallbackScene.rootNode.addChildNode(camera)

        scnView.scene = fallbackScene
    }

    // MARK: - Coordinator for Motion Updates + Haptics
    class Coordinator: NSObject {
        var containerNode: SCNNode?
        var scnView: SCNView?
        private let motionManager = CMMotionManager()
        private let sensitivity: Float = 0.6
        private let baseYRotation: Float
        private let hapticsEnabled: Bool
        private var blendFactor: Float = 0.0
        private var startTime: Date?

        // CoreHaptics
        private var hapticEngine: CHHapticEngine?
        private var lastHapticPitch: Float = 0
        private var lastHapticRoll: Float = 0
        private let hapticThreshold: Float = 0.02  // Radians of tilt change to trigger haptic
        private var lastHapticTime: Date = .distantPast

        init(baseYRotation: Float, hapticsEnabled: Bool = true) {
            self.baseYRotation = baseYRotation
            self.hapticsEnabled = hapticsEnabled
            super.init()
            if hapticsEnabled {
                setupHaptics()
            }
        }

        private func setupHaptics() {
            guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

            do {
                hapticEngine = try CHHapticEngine()
                hapticEngine?.resetHandler = { [weak self] in
                    try? self?.hapticEngine?.start()
                }
                hapticEngine?.stoppedHandler = { _ in }
                try hapticEngine?.start()
            } catch {
                hapticEngine = nil
            }
        }

        private func playTiltHaptic(intensity: Float) {
            guard hapticsEnabled, let engine = hapticEngine else { return }

            // Throttle: at least 80ms between haptics
            guard Date().timeIntervalSince(lastHapticTime) > 0.08 else { return }
            lastHapticTime = Date()

            let clampedIntensity = min(max(intensity, 0.4), 0.9)

            let hapticEvent = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: clampedIntensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0
            )

            do {
                let pattern = try CHHapticPattern(events: [hapticEvent], parameters: [])
                let player = try engine.makePlayer(with: pattern)
                try player.start(atTime: CHHapticTimeImmediate)
            } catch {
                // Silently fail
            }
        }

        func startMotionUpdates() {
            guard motionManager.isDeviceMotionAvailable else { return }

            startTime = Date()

            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
                guard let self = self,
                      let motion = motion,
                      let node = self.containerNode else { return }

                // Gradually increase blend factor over 0.8 seconds (after 0.3s delay)
                if let startTime = self.startTime {
                    let elapsed = Float(Date().timeIntervalSince(startTime))
                    let delay: Float = 0.3
                    let rampDuration: Float = 0.8
                    if elapsed > delay {
                        self.blendFactor = min(1.0, (elapsed - delay) / rampDuration)
                    }
                }

                let targetPitch = -Float(motion.attitude.pitch - .pi / 4) * self.sensitivity
                let targetRoll = Float(motion.attitude.roll) * self.sensitivity

                // Blend from static angle to motion-based angle
                let currentPitch = targetPitch * self.blendFactor
                let currentYOffset = targetRoll * self.blendFactor

                node.eulerAngles = SCNVector3(
                    x: currentPitch,
                    y: self.baseYRotation - currentYOffset,
                    z: 0
                )

                // Trigger haptic when tilt crosses threshold
                if self.blendFactor > 0.2 {
                    let pitchDelta = abs(currentPitch - self.lastHapticPitch)
                    let rollDelta = abs(currentYOffset - self.lastHapticRoll)
                    let totalDelta = pitchDelta + rollDelta

                    if totalDelta > self.hapticThreshold {
                        self.playTiltHaptic(intensity: min(totalDelta * 2, 1.0))
                        self.lastHapticPitch = currentPitch
                        self.lastHapticRoll = currentYOffset
                    }
                }
            }
        }

        func stopMotionUpdates() {
            motionManager.stopDeviceMotionUpdates()
            hapticEngine?.stop()
        }
    }
}
