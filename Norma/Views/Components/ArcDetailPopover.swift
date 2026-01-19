//
//  ArcDetailPopover.swift
//  Norma
//
//  Created by Claude on 12/5/25.
//

import SwiftUI
import SceneKit
import CoreMotion

struct ArcDetailPopover: View {
    @Binding var isPresented: Bool
    let arcCount: Int
    let freedomFund: Double
    let totalMonthlyBills: Double
    let currency: String

    @State private var appeared = false

    // Staggered animation states
    @State private var headerVisible = false
    @State private var summaryVisible = false
    @State private var progressVisible = false
    @State private var monthsLabelVisible = false
    @State private var monthCardsVisible = false

    // Calculate amount needed for next arc
    private var amountToNextArc: Double {
        guard totalMonthlyBills > 0 else { return 0 }
        let nextArcTarget = Double(arcCount + 1) * totalMonthlyBills
        return max(0, nextArcTarget - freedomFund)
    }

    // Get months starting from next month
    private var upcomingMonths: [(name: String, shortName: String, isCovered: Bool)] {
        let calendar = Calendar.current
        let now = Date()

        return (1...12).map { offset in
            guard let futureDate = calendar.date(byAdding: .month, value: offset, to: now) else {
                return (name: "", shortName: "", isCovered: false)
            }

            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM"
            let fullName = formatter.string(from: futureDate)

            formatter.dateFormat = "MMM"
            let shortName = formatter.string(from: futureDate)

            // A month is covered if its position (1-indexed) <= arcCount
            let isCovered = offset <= arcCount

            return (name: fullName, shortName: shortName, isCovered: isCovered)
        }
    }

    private var currencySymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.currencySymbol ?? "$"
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(currencySymbol)\(Int(value))"
    }

    var body: some View {
        ZStack {
            // Dismiss overlay
            Color.black.opacity(appeared ? 0.4 : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Popover content
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Text("Your Arcs")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 20))
                        .foregroundColor(.primary)

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                }
                .opacity(headerVisible ? 1 : 0)
                .offset(y: headerVisible ? 0 : 20)

                // Freedom Fund summary (moved to top)
                VStack(spacing: 8) {
                    Text("Freedom Fund")
                        .font(.custom(FontFamily.Rubik.regular, size: 12))
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        Text(formatCurrency(freedomFund))
                            .font(.normaHeadline(48))
                            .foregroundColor(.primary)

                        Text("/")
                            .font(.normaHeadline(36))
                            .foregroundColor(.secondary)

                        Text(formatCurrency(totalMonthlyBills))
                            .font(.normaHeadline(48))
                            .foregroundColor(Color("NormaPastelTeal"))
                    }
                }
                .frame(maxWidth: .infinity)
                .opacity(summaryVisible ? 1 : 0)
                .offset(y: summaryVisible ? 0 : 20)

                // Conversational stats row
                ArcStatsRow(
                    arcCount: arcCount,
                    freedomFund: freedomFund,
                    totalMonthlyBills: totalMonthlyBills,
                    amountToNextArc: amountToNextArc,
                    currency: currency
                )
                .opacity(summaryVisible ? 1 : 0)
                .offset(y: summaryVisible ? 0 : 20)

                // Progress to next arc
                if totalMonthlyBills > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Progress to Arc \(arcCount + 1)")
                                .font(.custom(FontFamily.Rubik.medium, size: 14))
                                .foregroundColor(.primary)

                            Spacer()

                            Text(formatCurrency(amountToNextArc) + " to go")
                                .font(.custom(FontFamily.Rubik.semiBold, size: 14))
                                .foregroundColor(Color("NormaPastelPurple"))
                        }

                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color("NormaPastelTeal"))
                                    .frame(width: geometry.size.width * progressToNextArc, height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                    .opacity(progressVisible ? 1 : 0)
                    .offset(y: progressVisible ? 0 : 20)
                }

                // Months covered visual
                VStack(alignment: .leading, spacing: 12) {
                    Text("Months Covered")
                        .font(.custom(FontFamily.Rubik.medium, size: 14))
                        .foregroundColor(.primary)
                        .opacity(monthsLabelVisible ? 1 : 0)

                    // Month grid (4 columns x 3 rows)
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(Array(upcomingMonths.enumerated()), id: \.offset) { index, month in
                            MonthCoverageCard(
                                monthName: month.shortName,
                                isCovered: month.isCovered,
                                monthNumber: index + 1
                            )
                            .opacity(monthCardsVisible ? 1 : 0)
                            .scaleEffect(monthCardsVisible ? 1 : 0.5)
                            .animation(
                                .spring(response: 0.4, dampingFraction: 0.8)
                                .delay(0.3 + Double(index) * 0.04),
                                value: monthCardsVisible
                            )
                        }
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.clear)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 24))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
            )
            .padding(.horizontal, 24)
            .scaleEffect(appeared ? 1 : 0.9)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                appeared = true
            }

            // Staggered element animations
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.0)) {
                headerVisible = true
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.1)) {
                summaryVisible = true
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.2)) {
                progressVisible = true
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.25)) {
                monthsLabelVisible = true
            }
            // Month cards animate individually via their own animation modifier
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                monthCardsVisible = true
            }
        }
    }

    private var progressToNextArc: CGFloat {
        guard totalMonthlyBills > 0 else { return 0 }
        let currentArcProgress = freedomFund.truncatingRemainder(dividingBy: totalMonthlyBills)
        return CGFloat(currentArcProgress / totalMonthlyBills)
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            appeared = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isPresented = false
        }
    }
}

// MARK: - Arc Stats Row
/// A conversational row showing arc stats with inline colored SF symbols
struct ArcStatsRow: View {
    let arcCount: Int
    let freedomFund: Double
    let totalMonthlyBills: Double
    let amountToNextArc: Double
    let currency: String

    private var boldFont: Font { Font.custom(FontFamily.Rubik.semiBold, size: 19) }
    private var infoFont: Font { Font.custom(FontFamily.Rubik.medium, size: 14) }

    private var currencySymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.currencySymbol ?? "$"
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(currencySymbol)\(Int(value))"
    }

    // Arc color: gray if zero, teal if has arcs
    private var arcColor: Color {
        arcCount > 0 ? Color("NormaPastelTeal") : Color.gray
    }

    private var savedText: Text {
        Text("You have ").font(boldFont)
        + Text(Image(systemName: "banknote.fill")).foregroundColor(Color("NormaPastelTeal"))
        + Text(" \(formatCurrency(freedomFund))").font(boldFont).foregroundColor(Color("NormaPastelTeal"))
        + Text(" saved against ").font(boldFont)
        + Text(Image(systemName: "list.clipboard.fill")).foregroundColor(Color("NormaPastelCoral"))
        + Text(" \(formatCurrency(totalMonthlyBills))/mo").font(boldFont).foregroundColor(Color("NormaPastelCoral"))
        + Text(" in bills, giving you ").font(boldFont)
        + Text(Image(systemName: "circle.circle.fill")).foregroundColor(arcColor)
        + Text(" \(arcCount) arc\(arcCount == 1 ? "" : "s")").font(boldFont).foregroundColor(arcColor)
        + Text(" of coverage.").font(boldFont)
    }

    private var infoText: String {
        if arcCount >= 12 {
            return "You've covered a full year!"
        } else if amountToNextArc > 0 {
            return "Save \(formatCurrency(amountToNextArc)) more for the next arc. You lose 1 arc each month."
        } else {
            return "You lose 1 arc each month."
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Main stats text
            savedText
                .multilineTextAlignment(.center)
                .lineSpacing(7)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)

            // Info container
            Text(infoText)
                .font(infoFont)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
                )

            // Space below
            Spacer()
                .frame(height: 8)
        }
    }
}

// MARK: - Month Coverage Card
struct MonthCoverageCard: View {
    let monthName: String
    let isCovered: Bool
    let monthNumber: Int

    var body: some View {
        VStack(spacing: 4) {
            if isCovered {
                // Static 3D coin replaces the circle entirely
                StaticCoin3DView()
                    .frame(width: 44, height: 44)
            } else {
                // Uncovered month shows gray circle with number
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Text("\(monthNumber)")
                        .font(.custom(FontFamily.Rubik.medium, size: 14))
                        .foregroundColor(.secondary)
                }
            }

            // Month name
            Text(monthName)
                .font(.custom(FontFamily.Rubik.regular, size: 11))
                .foregroundColor(isCovered ? .primary : .secondary)
        }
    }
}

// MARK: - Static 3D Coin View (No Motion)
struct StaticCoin3DView: UIViewRepresentable {
    var fileName: String = "norma-coin"

    // norma-coin has a different base orientation than variant coins
    private var yRotation: Float {
        if fileName == "norma-coin" {
            return -.pi / 8 - .pi / 6  // -52.5° for original coin
        } else {
            return -5 * .pi / 180  // -5° for variant coins
        }
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

        // Set rotation based on coin type (norma-coin has different base orientation)
        containerNode.eulerAngles.y = yRotation

        scene.rootNode.addChildNode(containerNode)

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

    private func createFallbackScene(into scnView: SCNView) {
        let fallbackScene = SCNScene()
        fallbackScene.background.contents = UIColor.clear

        let torus = SCNTorus(ringRadius: 0.4, pipeRadius: 0.15)
        torus.firstMaterial?.diffuse.contents = UIColor(red: 0.4, green: 0.8, blue: 0.8, alpha: 1.0)
        torus.firstMaterial?.specular.contents = UIColor.white
        let torusNode = SCNNode(geometry: torus)
        torusNode.name = "coinContainer"
        torusNode.eulerAngles.y = yRotation

        fallbackScene.rootNode.addChildNode(torusNode)

        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.camera?.usesOrthographicProjection = true
        camera.camera?.orthographicScale = 1.0
        camera.position = SCNVector3(0, 0, 3)
        fallbackScene.rootNode.addChildNode(camera)

        scnView.scene = fallbackScene
    }
}

// MARK: - Motion 3D Coin View (With Tilt)
struct MotionCoin3DView: UIViewRepresentable {
    var fileName: String = "norma-coin"

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

        // Set initial rotation to show front of coin (-52.5° on Y axis)
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

#Preview {
    ZStack {
        Color("NormaBackground")
            .ignoresSafeArea()

        ArcDetailPopover(
            isPresented: .constant(true),
            arcCount: 3,
            freedomFund: 4500,
            totalMonthlyBills: 1500,
            currency: "USD"
        )
    }
}
