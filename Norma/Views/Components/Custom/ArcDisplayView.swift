//
//  ArcDisplayView.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import SwiftUI
import SceneKit

struct ArcDisplayView: View {
    let arcCount: Double

    @State private var animateArcs: [Bool] = []
    @State private var animateFractional: Bool = false
    @State private var arcScene: SCNScene?

    private let arcSize: CGFloat = 40
    private let maxVisibleArcs = 5

    // Computed property for whole arc count
    private var wholeArcCount: Int {
        Int(arcCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if arcCount < 1 {
                // Fractional arc view - show progress toward first arc
                fractionalArcView
            } else {
                // Whole arcs view
                wholeArcsView
            }

            // Explainer text
            Text("Each arc = 1 billing cycle")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .padding(.vertical, 12)
        .onAppear {
            if arcCount < 1 {
                // Animate fractional view
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        animateFractional = true
                    }
                }
            } else {
                // Initialize animation states for whole arcs
                let visibleCount = min(wholeArcCount, maxVisibleArcs)
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
    }

    // MARK: - Fractional Arc View (for < 1 arc)
    private var fractionalArcView: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                // Background circle (track)
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)

                // Grayed-out coin in center
                Arc3DView()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .opacity(0.3)

                // Progress ring overlay
                Circle()
                    .trim(from: 0, to: animateFractional ? arcCount : 0)
                    .stroke(
                        Color("NormaPastelTeal"),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 60, height: 60)
            }
            .scaleEffect(animateFractional ? 1.0 : 0.5)
            .opacity(animateFractional ? 1.0 : 0.0)

            // Arc count text
            Text(String(format: "%.1f arcs", arcCount))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)

            // Progress text
            Text("\(Int(arcCount * 100))% to your first arc")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Whole Arcs View (for >= 1 arc)
    private var wholeArcsView: some View {
        HStack(spacing: 8) {
            // Show up to 5 individual arcs
            ForEach(0..<min(wholeArcCount, maxVisibleArcs), id: \.self) { index in
                arcImage(at: index)
            }

            // Show ellipsis badge if more than 5 arcs
            if wholeArcCount > maxVisibleArcs {
                ellipsisBadge(count: wholeArcCount - maxVisibleArcs)
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
        print("🔍 Attempting to load norma-coin.usdz")

        // Debug: list all USDZ files in bundle
        if let resourcePath = Bundle.main.resourcePath {
            let fileManager = FileManager.default
            if let files = try? fileManager.contentsOfDirectory(atPath: resourcePath) {
                let usdzFiles = files.filter { $0.hasSuffix(".usdz") }
                print("📁 USDZ files in bundle: \(usdzFiles)")
            }
        }

        guard let url = Bundle.main.url(forResource: "norma-coin", withExtension: "usdz") else {
            print("❌ Could not find norma-coin.usdz in bundle")
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

// 3D Arrow View using SceneKit for norma-arrow.usdz
struct Arrow3DView: UIViewRepresentable {

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.isOpaque = false
        // Disable default lighting to preserve original model colors
        scnView.autoenablesDefaultLighting = false
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

    private func addNeutralLighting(to scene: SCNScene) {
        // Add ambient light to evenly illuminate without color cast
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = UIColor.white
        ambientLight.light?.intensity = 500
        scene.rootNode.addChildNode(ambientLight)

        // Add a directional light from the front for depth
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.color = UIColor.white
        directionalLight.light?.intensity = 800
        directionalLight.position = SCNVector3(0, 5, 10)
        directionalLight.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(directionalLight)
    }

    private func createFallbackScene(into scnView: SCNView) {
        let fallbackScene = SCNScene()
        fallbackScene.background.contents = UIColor.clear

        // Create a simple arrow shape as placeholder
        let cone = SCNCone(topRadius: 0, bottomRadius: 0.3, height: 0.5)
        cone.firstMaterial?.diffuse.contents = UIColor(red: 0.4, green: 0.8, blue: 0.8, alpha: 1.0)
        cone.firstMaterial?.specular.contents = UIColor.white
        let coneNode = SCNNode(geometry: cone)
        coneNode.position = SCNVector3(0, 0.15, 0)

        let cylinder = SCNCylinder(radius: 0.1, height: 0.4)
        cylinder.firstMaterial?.diffuse.contents = UIColor(red: 0.4, green: 0.8, blue: 0.8, alpha: 1.0)
        cylinder.firstMaterial?.specular.contents = UIColor.white
        let cylinderNode = SCNNode(geometry: cylinder)
        cylinderNode.position = SCNVector3(0, -0.3, 0)

        let arrowNode = SCNNode()
        arrowNode.addChildNode(coneNode)
        arrowNode.addChildNode(cylinderNode)

        fallbackScene.rootNode.addChildNode(arrowNode)

        // Add neutral lighting
        addNeutralLighting(to: fallbackScene)

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
        arrowNode.runAction(SCNAction.repeatForever(rotation))

        scnView.scene = fallbackScene
        print("⚠️ Using fallback arrow placeholder scene")
    }

    private func loadScene(into scnView: SCNView) -> Bool {
        print("🔍 Attempting to load norma-arrow.usdz")

        guard let url = Bundle.main.url(forResource: "norma-arrow", withExtension: "usdz") else {
            print("❌ Could not find norma-arrow.usdz in bundle")
            return false
        }

        print("✅ Found arrow file at: \(url)")

        do {
            let loadedScene = try SCNScene(url: url)
            print("✅ Arrow scene loaded successfully")

            // Set up transparent background
            loadedScene.background.contents = UIColor.clear

            // Add neutral white lighting to preserve original colors
            addNeutralLighting(to: loadedScene)

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
            print("📏 Arrow model size: \(modelSize), max dimension: \(maxDimension)")

            // Check for zero-size model
            if maxDimension == 0 || maxDimension.isNaN {
                print("❌ Arrow model has invalid dimensions")
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
            print("❌ Error loading arrow scene: \(error)")
            return false
        }
    }
}

// 3D Bell View using SceneKit for bell.usdz
struct Bell3DView: UIViewRepresentable {

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.isOpaque = false
        scnView.autoenablesDefaultLighting = false
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

    private func addNeutralLighting(to scene: SCNScene) {
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = UIColor.white
        ambientLight.light?.intensity = 500
        scene.rootNode.addChildNode(ambientLight)

        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.color = UIColor.white
        directionalLight.light?.intensity = 800
        directionalLight.position = SCNVector3(0, 5, 10)
        directionalLight.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(directionalLight)
    }

    private func createFallbackScene(into scnView: SCNView) {
        let fallbackScene = SCNScene()
        fallbackScene.background.contents = UIColor.clear

        // Create a simple bell shape as placeholder
        let sphere = SCNSphere(radius: 0.3)
        sphere.firstMaterial?.diffuse.contents = UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
        sphere.firstMaterial?.specular.contents = UIColor.white
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = SCNVector3(0, 0.1, 0)

        let cylinder = SCNCylinder(radius: 0.35, height: 0.1)
        cylinder.firstMaterial?.diffuse.contents = UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
        cylinder.firstMaterial?.specular.contents = UIColor.white
        let cylinderNode = SCNNode(geometry: cylinder)
        cylinderNode.position = SCNVector3(0, -0.2, 0)

        let bellNode = SCNNode()
        bellNode.addChildNode(sphereNode)
        bellNode.addChildNode(cylinderNode)

        fallbackScene.rootNode.addChildNode(bellNode)

        addNeutralLighting(to: fallbackScene)

        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.camera?.usesOrthographicProjection = true
        camera.camera?.orthographicScale = 1.0
        camera.position = SCNVector3(0, 0, 3)
        fallbackScene.rootNode.addChildNode(camera)

        scnView.pointOfView = camera

        let rotation = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 6)
        bellNode.runAction(SCNAction.repeatForever(rotation))

        scnView.scene = fallbackScene
        print("⚠️ Using fallback bell placeholder scene")
    }

    private func loadScene(into scnView: SCNView) -> Bool {
        print("🔍 Attempting to load bell.usdz")

        guard let url = Bundle.main.url(forResource: "bell", withExtension: "usdz") else {
            print("❌ Could not find bell.usdz in bundle")
            return false
        }

        print("✅ Found bell file at: \(url)")

        do {
            let loadedScene = try SCNScene(url: url)
            print("✅ Bell scene loaded successfully")

            loadedScene.background.contents = UIColor.clear

            addNeutralLighting(to: loadedScene)

            let containerNode = SCNNode()
            containerNode.name = "container"

            var minBound = SCNVector3Zero
            var maxBound = SCNVector3Zero
            loadedScene.rootNode.__getBoundingBoxMin(&minBound, max: &maxBound)

            let modelSize = SCNVector3(
                maxBound.x - minBound.x,
                maxBound.y - minBound.y,
                maxBound.z - minBound.z
            )
            let maxDimension = max(modelSize.x, max(modelSize.y, modelSize.z))
            print("📏 Bell model size: \(modelSize), max dimension: \(maxDimension)")

            if maxDimension == 0 || maxDimension.isNaN {
                print("❌ Bell model has invalid dimensions")
                return false
            }

            let children = loadedScene.rootNode.childNodes
            for child in children {
                child.removeFromParentNode()
                containerNode.addChildNode(child)
            }

            let center = SCNVector3(
                (minBound.x + maxBound.x) / 2,
                (minBound.y + maxBound.y) / 2,
                (minBound.z + maxBound.z) / 2
            )
            containerNode.position = SCNVector3(-center.x, -center.y, -center.z)

            loadedScene.rootNode.addChildNode(containerNode)

            let camera = SCNNode()
            camera.camera = SCNCamera()
            camera.camera?.usesOrthographicProjection = true
            camera.camera?.orthographicScale = Double(maxDimension) * 0.6
            camera.position = SCNVector3(0, 0, maxDimension * 2)
            loadedScene.rootNode.addChildNode(camera)

            scnView.pointOfView = camera

            let rotation = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 6)
            let repeatRotation = SCNAction.repeatForever(rotation)
            containerNode.runAction(repeatRotation)

            scnView.scene = loadedScene
            return true
        } catch {
            print("❌ Error loading bell scene: \(error)")
            return false
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            Text("0.4 Arcs (Fractional)")
                .font(.headline)
            ArcDisplayView(arcCount: 0.4)

            Divider()

            Text("0.75 Arcs (Fractional)")
                .font(.headline)
            ArcDisplayView(arcCount: 0.75)

            Divider()

            Text("3 Arcs")
                .font(.headline)
            ArcDisplayView(arcCount: 3.0)

            Divider()

            Text("5 Arcs")
                .font(.headline)
            ArcDisplayView(arcCount: 5.0)

            Divider()

            Text("8 Arcs")
                .font(.headline)
            ArcDisplayView(arcCount: 8.0)

            Divider()

            Text("15 Arcs")
                .font(.headline)
            ArcDisplayView(arcCount: 15.0)
        }
        .padding()
    }
}
