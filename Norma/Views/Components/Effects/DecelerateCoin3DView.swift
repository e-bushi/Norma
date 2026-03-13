//
//  DecelerateCoin3DView.swift
//  Norma
//
//  Physics-based spinning coin that starts fast and decelerates realistically.
//

import SwiftUI
import SceneKit

struct DecelerateCoin3DView: UIViewRepresentable {
    var fileName: String = "norma-coin-royalty"

    /// Initial angular velocity in radians/second.
    /// Default is calibrated so total rotation = exact multiple of 2π (lands front-facing).
    /// Formula: v₀ = friction * fullRotations * 2π
    var initialVelocity: Float = 1.0 * 8 * 2 * .pi  // ≈ 50.3 rad/s, 8 full rotations

    /// Friction coefficient — lower = longer spin. 1.0 gives ~4-5s wind-down.
    var friction: Float = 1.0

    /// Called each frame with the current angular velocity (0...initialVelocity).
    /// Use this to drive haptics proportional to spin speed.
    var onVelocityUpdate: ((Float) -> Void)?

    private let baseYRotation: Float = -5 * .pi / 180

    func makeCoordinator() -> Coordinator {
        Coordinator(
            baseYRotation: baseYRotation,
            initialVelocity: initialVelocity,
            friction: friction,
            onVelocityUpdate: onVelocityUpdate
        )
    }

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.isOpaque = false
        scnView.autoenablesDefaultLighting = true
        scnView.allowsCameraControl = false
        scnView.isUserInteractionEnabled = false
        scnView.antialiasingMode = .multisampling2X
        // Use a render loop so we can drive rotation per-frame
        scnView.rendersContinuously = true
        scnView.delegate = context.coordinator

        if !loadScene(into: scnView, coordinator: context.coordinator) {
            createFallbackScene(into: scnView, coordinator: context.coordinator)
        }

        context.coordinator.scnView = scnView

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}

    static func dismantleUIView(_ uiView: SCNView, coordinator: Coordinator) {
        uiView.rendersContinuously = false
        uiView.delegate = nil
    }

    // MARK: - Scene loading

    private func loadScene(into scnView: SCNView, coordinator: Coordinator) -> Bool {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "usdz"),
              let scene = try? SCNScene(url: url, options: [.checkConsistency: true]) else {
            return false
        }

        scene.background.contents = UIColor.clear

        let containerNode = SCNNode()
        containerNode.name = "coinContainer"

        for childNode in scene.rootNode.childNodes {
            containerNode.addChildNode(childNode.clone())
        }
        scene.rootNode.childNodes.forEach { $0.removeFromParentNode() }

        let (minBound, maxBound) = containerNode.boundingBox
        let centerX = (minBound.x + maxBound.x) / 2
        let centerY = (minBound.y + maxBound.y) / 2
        let centerZ = (minBound.z + maxBound.z) / 2
        containerNode.position = SCNVector3(-centerX, -centerY, -centerZ)

        let width = maxBound.x - minBound.x
        let height = maxBound.y - minBound.y
        let depth = maxBound.z - minBound.z
        let maxDimension = max(width, max(height, depth))

        containerNode.eulerAngles.y = baseYRotation

        scene.rootNode.addChildNode(containerNode)
        coordinator.containerNode = containerNode

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

    // MARK: - Coordinator (per-frame physics)

    class Coordinator: NSObject, SCNSceneRendererDelegate {
        var containerNode: SCNNode?
        var scnView: SCNView?

        private let baseYRotation: Float
        private let initialVelocity: Float
        private let friction: Float
        private let onVelocityUpdate: ((Float) -> Void)?

        /// Accumulated angle from the spin (radians)
        private var accumulatedAngle: Float = 0

        /// Time the spin started
        private var spinStartTime: CFTimeInterval?

        /// Whether we've already stopped the render loop
        private var hasStopped = false

        /// Velocity threshold below which we consider the coin stopped
        private let stopThreshold: Float = 0.05

        init(baseYRotation: Float, initialVelocity: Float, friction: Float, onVelocityUpdate: ((Float) -> Void)?) {
            self.baseYRotation = baseYRotation
            self.initialVelocity = initialVelocity
            self.friction = friction
            self.onVelocityUpdate = onVelocityUpdate
            super.init()
        }

        // Called every frame by SceneKit
        func renderer(_ renderer: any SCNSceneRenderer, updateAtTime time: TimeInterval) {
            guard !hasStopped, let node = containerNode else { return }

            // Lazily capture start time on first frame
            if spinStartTime == nil {
                spinStartTime = time
            }

            let t = Float(time - spinStartTime!)

            // Exponential decay: v(t) = v0 * e^(-k*t)
            let currentVelocity = initialVelocity * exp(-friction * t)

            // Integral of v(t) = (v0/k) * (1 - e^(-k*t))
            accumulatedAngle = (initialVelocity / friction) * (1.0 - exp(-friction * t))

            node.eulerAngles.y = baseYRotation + accumulatedAngle

            // Report velocity for haptics (on main thread)
            DispatchQueue.main.async { [weak self] in
                self?.onVelocityUpdate?(currentVelocity)
            }

            // Stop when velocity is negligible
            if currentVelocity < stopThreshold {
                hasStopped = true
                DispatchQueue.main.async { [weak self] in
                    self?.onVelocityUpdate?(0)
                    self?.scnView?.rendersContinuously = false
                }
            }
        }
    }
}
