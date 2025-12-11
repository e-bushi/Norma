//
//  ArcDetailPopover.swift
//  Norma
//
//  Created by Claude on 12/5/25.
//

import SwiftUI
import SceneKit

struct ArcDetailPopover: View {
    @Binding var isPresented: Bool
    let arcCount: Int
    let freedomFund: Double
    let totalMonthlyBills: Double
    let currency: String

    @State private var appeared = false

    // Staggered animation states
    @State private var headerVisible = false
    @State private var explanationVisible = false
    @State private var progressVisible = false
    @State private var monthsLabelVisible = false
    @State private var monthCardsVisible = false
    @State private var summaryVisible = false

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

                // Arc explanation
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(Color("NormaPastelTeal"))

                        Text("What is an Arc?")
                            .font(.custom(FontFamily.Rubik.medium, size: 15))
                            .foregroundColor(.primary)
                    }

                    Text("1 arc = 1 complete billing cycle. It means you have enough in your Freedom Fund to cover all your bills for one month.")
                        .font(.custom(FontFamily.Rubik.regular, size: 14))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("NormaPastelTeal").opacity(0.1))
                )
                .opacity(explanationVisible ? 1 : 0)
                .offset(y: explanationVisible ? 0 : 20)

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

                // Current status summary
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Freedom Fund")
                            .font(.custom(FontFamily.Rubik.regular, size: 12))
                            .foregroundColor(.secondary)
                        Text(formatCurrency(freedomFund))
                            .font(.custom(FontFamily.Rubik.semiBold, size: 16))
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Monthly Bills")
                            .font(.custom(FontFamily.Rubik.regular, size: 12))
                            .foregroundColor(.secondary)
                        Text(formatCurrency(totalMonthlyBills))
                            .font(.custom(FontFamily.Rubik.semiBold, size: 16))
                            .foregroundColor(.primary)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.05))
                )
                .opacity(summaryVisible ? 1 : 0)
                .offset(y: summaryVisible ? 0 : 20)
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
                explanationVisible = true
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
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.8)) {
                summaryVisible = true
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

// MARK: - Static 3D Coin View
struct StaticCoin3DView: UIViewRepresentable {

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
        guard let url = Bundle.main.url(forResource: "norma-coin", withExtension: "usdz") else {
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

        // Rotate coin to face directly forward
        containerNode.eulerAngles.y = -.pi / 8 - .pi / 6  // Adjust Y rotation to face front (-52.5°)

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
        torusNode.eulerAngles.x = .pi / 4

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
