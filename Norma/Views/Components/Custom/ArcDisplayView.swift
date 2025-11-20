//
//  ArcDisplayView.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import SwiftUI
import SceneKit

struct ArcDisplayView: View {
    let arcCount: Int

    @State private var animateArcs: [Bool] = []
    @State private var arcScene: SCNScene?

    private let arcSize: CGFloat = 40
    private let maxVisibleArcs = 5

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                // Show up to 5 individual arcs
                ForEach(0..<min(arcCount, maxVisibleArcs), id: \.self) { index in
                    arcImage(at: index)
                }

                // Show ellipsis badge if more than 5 arcs
                if arcCount > maxVisibleArcs {
                    ellipsisBadge(count: arcCount - maxVisibleArcs)
                }
            }

            // Explainer text
            Text("Each arc = 1 billing cycle")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .padding(.vertical, 12)
        .onAppear {
            // Initialize animation states
            let visibleCount = min(arcCount, maxVisibleArcs)
            animateArcs = Array(repeating: false, count: visibleCount)

            // Trigger staggered animations
            for index in 0..<visibleCount {
                let delay = Double(index) * 0.1 // 100ms delay between each arc
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        if index < animateArcs.count {
                            animateArcs[index] = true
                        }
                    }
                }
            }
        }
    }

    private func arcImage(at index: Int) -> some View {
        let isAnimated = index < animateArcs.count && animateArcs[index]

        return Arc3DView()
            .frame(width: arcSize, height: arcSize)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            .scaleEffect(isAnimated ? 1.0 : 0.3)
            .opacity(isAnimated ? 1.0 : 0.0)
    }

    private func ellipsisBadge(count: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: arcSize, height: arcSize)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)

            Text("[...\(count)]")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

// 3D Arc View using SceneKit with UIViewRepresentable for better control
struct Arc3DView: UIViewRepresentable {

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.isOpaque = false
        scnView.autoenablesDefaultLighting = true
        scnView.allowsCameraControl = false
        scnView.isUserInteractionEnabled = false
        scnView.antialiasingMode = .multisampling4X

        if !loadScene(into: scnView) {
            // Fallback: create a simple placeholder
            createFallbackScene(into: scnView)
        }

        // Critical: must be set to true for SceneKit to render
        scnView.isPlaying = true

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        // No updates needed
    }

    private func createFallbackScene(into scnView: SCNView) {
        let fallbackScene = SCNScene()
        fallbackScene.background.contents = UIColor.clear

        // Create a simple teal torus as placeholder
        let torus = SCNTorus(ringRadius: 0.4, pipeRadius: 0.15)
        torus.firstMaterial?.diffuse.contents = UIColor(red: 0.4, green: 0.8, blue: 0.8, alpha: 1.0)
        torus.firstMaterial?.specular.contents = UIColor.white
        let torusNode = SCNNode(geometry: torus)

        // Rotate to show it better
        torusNode.eulerAngles.x = .pi / 4

        fallbackScene.rootNode.addChildNode(torusNode)

        // Add camera
        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.camera?.usesOrthographicProjection = true
        camera.camera?.orthographicScale = 1.0
        camera.position = SCNVector3(0, 0, 3)
        fallbackScene.rootNode.addChildNode(camera)

        scnView.pointOfView = camera

        // Add rotation
        let rotation = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 6)
        torusNode.runAction(SCNAction.repeatForever(rotation))

        scnView.scene = fallbackScene
        print("⚠️ Using fallback placeholder scene")
    }

    private func loadScene(into scnView: SCNView) -> Bool {
        print("🔍 Attempting to load norma-arc.usdz")

        // Debug: list all USDZ files in bundle
        if let resourcePath = Bundle.main.resourcePath {
            let fileManager = FileManager.default
            if let files = try? fileManager.contentsOfDirectory(atPath: resourcePath) {
                let usdzFiles = files.filter { $0.hasSuffix(".usdz") }
                print("📁 USDZ files in bundle: \(usdzFiles)")
            }
        }

        guard let url = Bundle.main.url(forResource: "norma-arc", withExtension: "usdz") else {
            print("❌ Could not find norma-arc.usdz in bundle")
            return false
        }

        print("✅ Found file at: \(url)")

        do {
            let loadedScene = try SCNScene(url: url)
            print("✅ Scene loaded successfully")

            // Set up transparent background
            loadedScene.background.contents = UIColor.clear

            // Create a container node for rotation
            let containerNode = SCNNode()
            containerNode.name = "container"

            // Calculate bounding box
            var minBound = SCNVector3Zero
            var maxBound = SCNVector3Zero
            loadedScene.rootNode.__getBoundingBoxMin(&minBound, max: &maxBound)

            let modelSize = SCNVector3(
                maxBound.x - minBound.x,
                maxBound.y - minBound.y,
                maxBound.z - minBound.z
            )
            let maxDimension = max(modelSize.x, max(modelSize.y, modelSize.z))
            print("📏 Model size: \(modelSize), max dimension: \(maxDimension)")

            // Check for zero-size model
            if maxDimension == 0 || maxDimension.isNaN {
                print("❌ Model has invalid dimensions")
                return false
            }

            // Move all children to container
            let children = loadedScene.rootNode.childNodes
            for child in children {
                child.removeFromParentNode()
                containerNode.addChildNode(child)
            }

            // Center the container
            let center = SCNVector3(
                (minBound.x + maxBound.x) / 2,
                (minBound.y + maxBound.y) / 2,
                (minBound.z + maxBound.z) / 2
            )
            containerNode.position = SCNVector3(-center.x, -center.y, -center.z)

            loadedScene.rootNode.addChildNode(containerNode)

            // Add camera
            let camera = SCNNode()
            camera.camera = SCNCamera()
            camera.camera?.usesOrthographicProjection = true
            camera.camera?.orthographicScale = Double(maxDimension) * 0.6
            camera.position = SCNVector3(0, 0, maxDimension * 2)
            loadedScene.rootNode.addChildNode(camera)

            // Set the point of view
            scnView.pointOfView = camera

            // Add auto-rotation to container
            let rotation = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 6)
            let repeatRotation = SCNAction.repeatForever(rotation)
            containerNode.runAction(repeatRotation)

            scnView.scene = loadedScene
            return true
        } catch {
            print("❌ Error loading scene: \(error)")
            return false
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("3 Arcs")
            .font(.headline)
        ArcDisplayView(arcCount: 3)

        Divider()

        Text("5 Arcs")
            .font(.headline)
        ArcDisplayView(arcCount: 5)

        Divider()

        Text("8 Arcs")
            .font(.headline)
        ArcDisplayView(arcCount: 8)

        Divider()

        Text("15 Arcs")
            .font(.headline)
        ArcDisplayView(arcCount: 15)
    }
    .padding()
}
