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

        // CoreHaptics — continuous pattern
        private var hapticEngine: CHHapticEngine?
        private var continuousPlayer: CHHapticAdvancedPatternPlayer?
        private var currentIntensity: Float = 0

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
                    self?.startContinuousHaptic()
                }
                hapticEngine?.stoppedHandler = { _ in }
                try hapticEngine?.start()
                startContinuousHaptic()
            } catch {
                hapticEngine = nil
            }
        }

        private func startContinuousHaptic() {
            guard let engine = hapticEngine else { return }

            // Start at a small non-zero intensity so the engine fully engages
            let continuousEvent = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.01),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
                ],
                relativeTime: 0,
                duration: 300
            )

            do {
                let pattern = try CHHapticPattern(events: [continuousEvent], parameters: [])
                continuousPlayer = try engine.makeAdvancedPlayer(with: pattern)
                try continuousPlayer?.start(atTime: CHHapticTimeImmediate)
            } catch {
                print("Haptic player failed to start: \(error)")
            }
        }

        private func updateHapticIntensity(_ tiltMagnitude: Float) {
            guard hapticsEnabled, let player = continuousPlayer else { return }

            // Map tilt velocity to intensity — amplify so gentle tilts are felt
            let target = min(tiltMagnitude * 6.0, 1.0)
            // Fast rise, gradual decay
            let smoothing: Float = target > currentIntensity ? 0.6 : 0.25
            currentIntensity += (target - currentIntensity) * smoothing

            // Perceptible range — continuous haptics need strong values
            let finalIntensity: Float
            if currentIntensity > 0.01 {
                finalIntensity = 0.15 + currentIntensity * 0.65 // floor of 0.15 so you always feel it when moving
            } else {
                finalIntensity = 0
            }
            // Low sharpness = warm and round, not buzzy
            let sharpness: Float = 0.05 + currentIntensity * 0.1

            do {
                try player.sendParameters([
                    CHHapticDynamicParameter(parameterID: .hapticIntensityControl, value: finalIntensity, relativeTime: 0),
                    CHHapticDynamicParameter(parameterID: .hapticSharpnessControl, value: sharpness, relativeTime: 0)
                ], atTime: CHHapticTimeImmediate)
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

                // Update continuous haptic based on tilt velocity
                if self.blendFactor > 0.2 {
                    let pitchRate = abs(Float(motion.rotationRate.x))
                    let rollRate = abs(Float(motion.rotationRate.y))
                    let tiltMagnitude = (pitchRate + rollRate) * 0.5
                    self.updateHapticIntensity(tiltMagnitude)
                }
            }
        }

        func stopMotionUpdates() {
            motionManager.stopDeviceMotionUpdates()
            try? continuousPlayer?.stop(atTime: CHHapticTimeImmediate)
            continuousPlayer = nil
            hapticEngine?.stop()
        }
    }
}
