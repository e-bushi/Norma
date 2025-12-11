//
//  NavBarArcDisplay.swift
//  Norma
//
//  Created by Claude on 12/5/25.
//

import SwiftUI
import SceneKit

/// Compact arc display for navigation bar showing 3D norma coins
struct NavBarArcDisplay: View {
    let arcCount: Int

    private let coinSize: CGFloat = 20

    var body: some View {
        if arcCount == 0 {
            // Show placeholder for 0 arcs
            zeroArcsView
        } else {
            // Show single coin with multiplier in glass capsule
            HStack(spacing: 4) {
                NavBarCoin3DView()
                    .frame(width: coinSize, height: coinSize)

                Text("x \(arcCount)")
                    .font(.normaFinancial(12))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(.clear)
                    .glassEffect(in: Capsule())
            )
            .overlay(
                Capsule()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
            )
        }
    }

    private var zeroArcsView: some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 10))
            Text("0 arcs")
                .font(.normaFinancial(12))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color("NormaPastelCoral").opacity(0.2))
        )
        .foregroundColor(Color("NormaPastelCoral"))
    }
}

/// Compact 3D coin view for navigation bar
struct NavBarCoin3DView: UIViewRepresentable {

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
        guard let url = Bundle.main.url(forResource: "norma-coin", withExtension: "usdz") else {
            print("⚠️ NavBarCoin3DView: Could not find norma-coin.usdz")
            return false
        }

        guard let scene = try? SCNScene(url: url, options: [.checkConsistency: true]) else {
            print("⚠️ NavBarCoin3DView: Failed to load scene from URL")
            return false
        }

        scene.background.contents = UIColor.clear

        // Create container for the model
        let containerNode = SCNNode()

        // Clone all child nodes from the loaded scene
        for childNode in scene.rootNode.childNodes {
            containerNode.addChildNode(childNode.clone())
        }

        // Remove original nodes to prevent static coin overlay
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

        // Slower rotation for nav bar (8 seconds)
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
    VStack(spacing: 20) {
        HStack {
            Text("0 arcs:")
            NavBarArcDisplay(arcCount: 0)
        }
        HStack {
            Text("1 arc:")
            NavBarArcDisplay(arcCount: 1)
        }
        HStack {
            Text("3 arcs:")
            NavBarArcDisplay(arcCount: 3)
        }
        HStack {
            Text("5 arcs:")
            NavBarArcDisplay(arcCount: 5)
        }
        HStack {
            Text("8 arcs:")
            NavBarArcDisplay(arcCount: 8)
        }
    }
    .padding()
}
