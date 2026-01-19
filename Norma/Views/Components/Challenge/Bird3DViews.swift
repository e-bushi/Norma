//
//  Bird3DViews.swift
//  Norma
//
//  Created by Claude on 12/30/25.
//

import SwiftUI
import SceneKit
import CoreMotion

// MARK: - Static Bird 3D View

/// A static 3D bird view that doesn't respond to device motion
struct StaticBird3DView: UIViewRepresentable {
    var fileName: String = "challenge-bird-starter"

    // Base rotation for birds (adjust as needed for your 3D models)
    private var yRotation: Float {
        -5 * .pi / 180  // -5° default rotation
    }

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
        containerNode.name = "birdContainer"

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

        // Set rotation
        containerNode.eulerAngles.y = yRotation

        scene.rootNode.addChildNode(containerNode)

        // Setup camera (smaller orthographicScale = larger bird)
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.camera?.orthographicScale = Double(maxDimension * 0.45)
        cameraNode.position = SCNVector3(0, 0, maxDimension * 2)
        scene.rootNode.addChildNode(cameraNode)

        scnView.scene = scene
        return true
    }

    private func createFallbackScene(into scnView: SCNView) {
        let fallbackScene = SCNScene()
        fallbackScene.background.contents = UIColor.clear

        // Fallback bird shape (sphere for body)
        let sphere = SCNSphere(radius: 0.3)
        sphere.firstMaterial?.diffuse.contents = UIColor(red: 0.4, green: 0.8, blue: 0.8, alpha: 1.0)
        sphere.firstMaterial?.specular.contents = UIColor.white
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.name = "birdContainer"
        sphereNode.eulerAngles.y = yRotation

        fallbackScene.rootNode.addChildNode(sphereNode)

        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.camera?.usesOrthographicProjection = true
        camera.camera?.orthographicScale = 1.0
        camera.position = SCNVector3(0, 0, 3)
        fallbackScene.rootNode.addChildNode(camera)

        scnView.scene = fallbackScene
    }
}

// MARK: - Motion Bird 3D View

/// A 3D bird view that tilts with device motion
struct MotionBird3DView: UIViewRepresentable {
    var fileName: String = "challenge-bird-starter"

    // Base Y rotation angle (-5°)
    private let baseYRotation: Float = -5 * .pi / 180

    func makeCoordinator() -> Coordinator {
        Coordinator(baseYRotation: baseYRotation)
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
        containerNode.name = "birdContainer"

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

        // Set initial rotation
        containerNode.eulerAngles.y = baseYRotation

        scene.rootNode.addChildNode(containerNode)

        // Store reference for motion updates
        coordinator.containerNode = containerNode

        // Setup camera (smaller orthographicScale = larger bird)
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.camera?.orthographicScale = Double(maxDimension * 0.45)
        cameraNode.position = SCNVector3(0, 0, maxDimension * 2)
        scene.rootNode.addChildNode(cameraNode)

        scnView.scene = scene
        return true
    }

    private func createFallbackScene(into scnView: SCNView, coordinator: Coordinator) {
        let fallbackScene = SCNScene()
        fallbackScene.background.contents = UIColor.clear

        // Fallback bird shape (sphere for body)
        let sphere = SCNSphere(radius: 0.3)
        sphere.firstMaterial?.diffuse.contents = UIColor(red: 0.4, green: 0.8, blue: 0.8, alpha: 1.0)
        sphere.firstMaterial?.specular.contents = UIColor.white
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.name = "birdContainer"
        sphereNode.eulerAngles.y = baseYRotation

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
        private let sensitivity: Float = 0.6
        private let baseYRotation: Float
        private var blendFactor: Float = 0.0
        private var startTime: Date?

        init(baseYRotation: Float) {
            self.baseYRotation = baseYRotation
            super.init()
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

                // Blend from static angle (0, baseY, 0) to motion-based angle
                let currentPitch = targetPitch * self.blendFactor
                let currentYOffset = targetRoll * self.blendFactor

                node.eulerAngles = SCNVector3(
                    x: currentPitch,
                    y: self.baseYRotation - currentYOffset,
                    z: 0
                )
            }
        }

        func stopMotionUpdates() {
            motionManager.stopDeviceMotionUpdates()
        }
    }
}

// MARK: - Nav Bar Bird 3D View

/// Compact 3D bird view for navigation bar with slow rotation
struct NavBarBird3DView: UIViewRepresentable {
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

        scene.rootNode.addChildNode(containerNode)

        // Setup camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.camera?.orthographicScale = Double(maxDimension * 0.5)
        cameraNode.position = SCNVector3(0, 0, maxDimension * 2)
        scene.rootNode.addChildNode(cameraNode)

        // Slow rotation for nav bar (10 seconds per rotation)
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
    VStack(spacing: 40) {
        Text("Static Bird")
            .font(.headline)
        StaticBird3DView(fileName: "challenge-bird-starter")
            .frame(width: 120, height: 120)

        Text("Motion Bird")
            .font(.headline)
        MotionBird3DView(fileName: "challenge-bird-starter")
            .frame(width: 120, height: 120)

        Text("NavBar Bird")
            .font(.headline)
        NavBarBird3DView(fileName: "challenge-bird-starter")
            .frame(width: 24, height: 24)
    }
    .padding()
}
