//
//  VerifyCodeView.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import SwiftUI
import UIKit
import SceneKit
import CoreMotion

struct VerifyCodeView: View {
    @State private var codeDigits: [String] = Array(repeating: "", count: 6)
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var focusedField: Int?

    @State private var iconScale = 0.8
    @State private var iconOpacity = 0.0
    @State private var titleOpacity = 0.0
    @State private var codeFieldOpacity = 0.0
    @State private var buttonOpacity = 0.0
    @State private var resendOpacity = 0.0

    @State private var isResending = false
    @State private var resendSuccess = false
    @State private var resendCooldown = 0

    let email: String
    @Binding var isAuthenticated: Bool
    @Binding var showVerifyCode: Bool
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 60)
                    
                    // Icon with enhanced styling
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.clear)
                            .glassEffect(in: RoundedRectangle(cornerRadius: 20))
                            .frame(width: 100, height: 100)

                        Image(systemName: "envelope.badge.shield.half.filled")
                            .font(.system(size: 44))
                            .foregroundColor(.primary)
                    }
                    .padding(.bottom, 20)
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)
                    
                    // Title and description
                    VStack(spacing: 8) {
                        Text("Verify your email")
                            .font(.normaTitle(32))
                            .foregroundColor(.primary)

                        Text("We've sent a code to")
                            .font(.normaInput(17))
                            .foregroundColor(.secondary)

                        Text(email)
                            .font(.normaHeadline(17))
                            .foregroundColor(.primary)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 40)
                    .opacity(titleOpacity)
                    
                    // Code input container
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.clear)
                            .glassEffect(in: RoundedRectangle(cornerRadius: 20))

                        VStack(spacing: 16) {
                            Text("VERIFICATION CODE")
                                .font(.normaFinancial(11))
                                .foregroundColor(.secondary)
                                .tracking(1.2)
                            
                            HStack(spacing: 8) {
                                ForEach(0..<6, id: \.self) { index in
                                    CodeDigitField(
                                        text: $codeDigits[index],
                                        isActive: focusedField == index,
                                        onTextChange: { newValue in
                                            handleTextChange(at: index, newValue: newValue)
                                        }
                                    )
                                    .focused($focusedField, equals: index)
                                    .frame(width: 42, height: 52)
                                }
                            }
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    
                                    Button("Done") {
                                        focusedField = nil
                                    }
                                    .font(.normaHeadline(16))
                                    .foregroundColor(.primary)
                                }
                            }
                        }
                        .padding(.vertical, 24)
                        .padding(.horizontal, 16)
                    }
                    .frame(maxWidth: 350)
                    .opacity(codeFieldOpacity)
                    
                    // Error message
                    if showError {
                        Text(errorMessage)
                            .font(.normaInput(14))
                            .foregroundColor(.red)
                            .padding(.top, 8)
                    }
                    
                    Spacer()
                        .frame(height: 40)
                    
                    // Verify button
                    Button(action: {
                        handleVerification()
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Verify")
                                    .font(.normaHeadline(16))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color("NormaPastelTeal"),
                                            Color("NormaPastelTeal").opacity(0.8)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color("NormaPastelTeal").opacity(0.3), radius: 4, x: 0, y: 2)
                        )
                    }
                    .disabled(isLoading || !isCodeComplete)
                    .opacity((isLoading || !isCodeComplete) ? 0.6 : 1)
                    .opacity(buttonOpacity)
                    
                    // Resend code
                    VStack(spacing: 16) {
                        if resendSuccess {
                            Text("Code sent!")
                                .font(.normaInput(14))
                                .foregroundColor(.green)
                        } else {
                            Text("Didn't receive the code?")
                                .font(.normaInput(14))
                                .foregroundColor(.secondary)
                        }

                        Button(action: {
                            handleResendCode()
                        }) {
                            if isResending {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                            } else if resendCooldown > 0 {
                                Text("Resend in \(resendCooldown)s")
                                    .font(.normaHeadline(14))
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Resend code")
                                    .font(.normaHeadline(14))
                                    .foregroundColor(.primary)
                            }
                        }
                        .disabled(isResending || resendCooldown > 0)
                    }
                    .padding(.top, 24)
                    .opacity(resendOpacity)
                    
                    Spacer()
                        .frame(height: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .background(
            Color("NormaBackground")
                .ignoresSafeArea()
        )
        .onAppear {
            // Focus on first field when view appears
            focusedField = 0
            
            // Trigger animations
            withAnimation(.easeOut(duration: 0.6)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                titleOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                codeFieldOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.6)) {
                buttonOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.8)) {
                resendOpacity = 1.0
            }
        }
    }
    
    private var isCodeComplete: Bool {
        codeDigits.allSatisfy { !$0.isEmpty }
    }
    
    private var fullCode: String {
        codeDigits.joined()
    }
    
    private func handleTextChange(at index: Int, newValue: String) {
        // Handle paste
        if newValue.count > 1 {
            let pastedCode = newValue.prefix(6)
            for (i, char) in pastedCode.enumerated() {
                if i < 6 {
                    codeDigits[i] = String(char)
                }
            }
            focusedField = min(pastedCode.count, 5)
            return
        }
        
        // Regular input
        if newValue.count == 1 && index < 5 {
            focusedField = index + 1
        } else if newValue.isEmpty && index > 0 {
            focusedField = index - 1
        }
        
        // Clear error when user starts typing again
        if showError {
            showError = false
            errorMessage = ""
        }
    }
    
    private func handleVerification() {
        isLoading = true
        showError = false
        errorMessage = ""
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        Task {
            do {
                try await onboardingViewModel.verifyCode(email: email, code: fullCode)
                await MainActor.run {
                    // Success haptic feedback
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.success)

                    isLoading = false
                    onboardingViewModel.proceedToWelcome()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    showError = true
                    errorMessage = error.localizedDescription
                    
                    // Clear the code fields
                    codeDigits = Array(repeating: "", count: 6)
                    focusedField = 0
                    
                    // Error haptic feedback
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.error)
                }
            }
        }
    }
    
    private func handleResendCode() {
        isResending = true
        resendSuccess = false

        Task {
            do {
                try await onboardingViewModel.resendCode(email: email)
                await MainActor.run {
                    isResending = false
                    resendSuccess = true

                    // Haptic feedback
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.success)

                    // Start cooldown (60 seconds)
                    resendCooldown = 60
                    startCooldownTimer()

                    // Hide success message after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        resendSuccess = false
                    }
                }
            } catch {
                await MainActor.run {
                    isResending = false
                    showError = true
                    errorMessage = "Failed to resend code. Please try again."

                    // Error haptic feedback
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.error)
                }
            }
        }
    }

    private func startCooldownTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if resendCooldown > 0 {
                resendCooldown -= 1
            } else {
                timer.invalidate()
            }
        }
    }
}

struct CodeDigitField: View {
    @Binding var text: String
    let isActive: Bool
    let onTextChange: (String) -> Void
    
    var body: some View {
        TextField("", text: $text)
            .font(.system(size: 24, weight: .semibold))
            .multilineTextAlignment(.center)
            .keyboardType(.numberPad)
            .textFieldStyle(PlainTextFieldStyle())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isActive ? Color("NormaPastelTeal") : Color.gray.opacity(0.1),
                                lineWidth: isActive ? 2 : 1
                            )
                    )
            )
            .onChange(of: text) { oldValue, newValue in
                // Limit to single digit
                if newValue.count > 1 {
                    text = String(newValue.prefix(1))
                }
                
                // Only allow numbers
                if !newValue.isEmpty && !newValue.allSatisfy({ $0.isNumber }) {
                    text = oldValue
                    return
                }
                
                onTextChange(newValue)
            }
    }
}

// MARK: - Spinning 3D Coin View (With Tilt + Auto-Spin)
struct TiltSpinningCoin3DView: UIViewRepresentable {
    var fileName: String = "norma-coin-royalty"

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.isOpaque = false
        scnView.autoenablesDefaultLighting = true
        scnView.allowsCameraControl = false
        scnView.isUserInteractionEnabled = false
        scnView.antialiasingMode = .multisampling4X

        if !loadScene(into: scnView, coordinator: context.coordinator) {
            createFallbackScene(into: scnView, coordinator: context.coordinator)
        }

        context.coordinator.scnView = scnView
        context.coordinator.startMotionUpdates()
        context.coordinator.startSpinAnimation()

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

        // Create outer container for motion tilt
        let motionContainer = SCNNode()
        motionContainer.name = "motionContainer"

        // Create inner container for spin animation
        let spinContainer = SCNNode()
        spinContainer.name = "spinContainer"

        // Clone all child nodes from the loaded scene
        for childNode in scene.rootNode.childNodes {
            spinContainer.addChildNode(childNode.clone())
        }

        // Remove original nodes
        scene.rootNode.childNodes.forEach { $0.removeFromParentNode() }

        // Calculate bounding box and center the model
        let (minBound, maxBound) = spinContainer.boundingBox
        let centerX = (minBound.x + maxBound.x) / 2
        let centerY = (minBound.y + maxBound.y) / 2
        let centerZ = (minBound.z + maxBound.z) / 2
        spinContainer.position = SCNVector3(-centerX, -centerY, -centerZ)

        // Calculate model dimensions
        let width = maxBound.x - minBound.x
        let height = maxBound.y - minBound.y
        let depth = maxBound.z - minBound.z
        let maxDimension = max(width, max(height, depth))

        // Add spin container to motion container
        motionContainer.addChildNode(spinContainer)
        scene.rootNode.addChildNode(motionContainer)

        // Store references for updates
        coordinator.motionContainer = motionContainer
        coordinator.spinContainer = spinContainer

        // Setup camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.camera?.orthographicScale = Double(maxDimension * 0.6)
        cameraNode.position = SCNVector3(0, 0, maxDimension * 2)
        scene.rootNode.addChildNode(cameraNode)

        // Add ambient light for better visibility
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 400
        ambientLight.light?.color = UIColor.white
        scene.rootNode.addChildNode(ambientLight)

        // Add directional light for shininess
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.intensity = 800
        directionalLight.light?.color = UIColor.white
        directionalLight.eulerAngles = SCNVector3(-Float.pi / 4, Float.pi / 4, 0)
        scene.rootNode.addChildNode(directionalLight)

        scnView.scene = scene
        return true
    }

    private func createFallbackScene(into scnView: SCNView, coordinator: Coordinator) {
        let fallbackScene = SCNScene()
        fallbackScene.background.contents = UIColor.clear

        let motionContainer = SCNNode()
        motionContainer.name = "motionContainer"

        let spinContainer = SCNNode()
        spinContainer.name = "spinContainer"

        let cylinder = SCNCylinder(radius: 0.5, height: 0.08)
        cylinder.firstMaterial?.diffuse.contents = UIColor(red: 0.6, green: 0.4, blue: 0.8, alpha: 1.0)
        cylinder.firstMaterial?.specular.contents = UIColor.white
        let coinNode = SCNNode(geometry: cylinder)
        coinNode.eulerAngles.x = Float.pi / 2

        spinContainer.addChildNode(coinNode)
        motionContainer.addChildNode(spinContainer)
        fallbackScene.rootNode.addChildNode(motionContainer)

        coordinator.motionContainer = motionContainer
        coordinator.spinContainer = spinContainer

        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.camera?.usesOrthographicProjection = true
        camera.camera?.orthographicScale = 1.2
        camera.position = SCNVector3(0, 0, 3)
        fallbackScene.rootNode.addChildNode(camera)

        scnView.scene = fallbackScene
    }

    // MARK: - Coordinator for Motion & Spin Updates
    class Coordinator: NSObject {
        var motionContainer: SCNNode?
        var spinContainer: SCNNode?
        var scnView: SCNView?
        private let motionManager = CMMotionManager()
        private let sensitivity: Float = 0.4
        private var blendFactor: Float = 0.0
        private var startTime: Date?
        private var displayLink: CADisplayLink?
        private var spinAngle: Float = 0.0

        override init() {
            super.init()
        }

        func startMotionUpdates() {
            guard motionManager.isDeviceMotionAvailable else { return }

            startTime = Date()

            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
                guard let self = self,
                      let motion = motion,
                      let node = self.motionContainer else { return }

                // Gradually increase blend factor over 0.8 seconds (after 0.3s delay)
                if let startTime = self.startTime {
                    let elapsed = Float(Date().timeIntervalSince(startTime))
                    let delay: Float = 0.3
                    let rampDuration: Float = 0.8
                    if elapsed > delay {
                        self.blendFactor = min(1.0, (elapsed - delay) / rampDuration)
                    }
                }

                // Apply device tilt to motion container
                let targetPitch = -Float(motion.attitude.pitch - .pi / 4) * self.sensitivity
                let targetRoll = Float(motion.attitude.roll) * self.sensitivity * 0.5

                let currentPitch = targetPitch * self.blendFactor
                let currentRoll = targetRoll * self.blendFactor

                node.eulerAngles = SCNVector3(
                    x: currentPitch,
                    y: currentRoll,
                    z: 0
                )
            }
        }

        func startSpinAnimation() {
            // Use display link for smooth continuous spin
            displayLink = CADisplayLink(target: self, selector: #selector(updateSpin))
            displayLink?.add(to: .main, forMode: .common)
        }

        @objc private func updateSpin() {
            guard let spinContainer = spinContainer else { return }

            // Spin speed: complete rotation every ~4 seconds
            spinAngle += Float.pi / 120.0

            // Apply continuous Y rotation to spin container
            spinContainer.eulerAngles.y = spinAngle
        }

        func stopMotionUpdates() {
            motionManager.stopDeviceMotionUpdates()
            displayLink?.invalidate()
            displayLink = nil
        }
    }
}

#Preview("Verify Code") {
    VerifyCodeView(
        email: "user@example.com",
        isAuthenticated: .constant(true),
        showVerifyCode: .constant(false)
    )
    .environmentObject(OnboardingViewModel(sessionViewModel: SessionViewModel(dataManager: DataManager())))
    .preferredColorScheme(.dark)
}

