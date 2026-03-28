//
//  LoginView.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import SwiftUI
import UIKit

struct LoginView: View {
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showPassword = false
    @State private var showError = false
    @State private var errorMessage = ""
    @Binding var isAuthenticated: Bool
    @Binding var showSignUp: Bool
    
    // Animation states
    @State private var logoScale = 0.8
    @State private var logoOpacity = 0.0
    @State private var titleOpacity = 0.0
    @State private var formOpacity = 0.0
    @State private var buttonOpacity = 0.0
    
    // Enhanced animation states
    @State private var logoRotation = 0.0
    @State private var formOffset: CGFloat = 20
    @State private var buttonScale = 0.95
    @State private var isTextFieldFocused = false
    @State private var emailFieldFocused = false
    @State private var passwordFieldFocused = false
    @State private var floatingOffset: CGFloat = 0
    
    // Loading animation states
    @State private var loadingRotation = 0.0
    @State private var loadingScale = 0.8
    @State private var loadingOpacity = 0.0
    @State private var isAppleSignInLoading = false
    @State private var isGoogleSignInLoading = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Spacer()
                        .frame(height: 20)

                    // Error message if needed
                    if showError {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 14))
                            
                            Text(errorMessage)
                                .font(.normaInput(14))
                                .foregroundColor(.red)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 24)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Form fields container
                    VStack(spacing: 16) {
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("EMAIL")
                                .font(.normaFinancial(11))
                                .foregroundColor(.secondary)
                                .tracking(1.2)
                            
                            TextField("Enter your email", text: $email, onEditingChanged: { editing in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    emailFieldFocused = editing
                                    isTextFieldFocused = editing || passwordFieldFocused
                                }
                            })
                            .textFieldStyle(EnhancedTextFieldStyle(isFocused: emailFieldFocused))
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        }
                        
                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PASSWORD")
                                .font(.normaFinancial(11))
                                .foregroundColor(.secondary)
                                .tracking(1.2)
                            
                            HStack {
                                if showPassword {
                                    TextField("Enter your password", text: $password, onEditingChanged: { editing in
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            passwordFieldFocused = editing
                                            isTextFieldFocused = editing || emailFieldFocused
                                        }
                                    })
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                } else {
                                    SecureField("Enter your password", text: $password, onCommit: {
                                        if !email.isEmpty && !password.isEmpty {
                                            handleLogin()
                                        }
                                    })
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            passwordFieldFocused = true
                                            isTextFieldFocused = true
                                        }
                                    }
                                }
                                
                                Button(action: {
                                    showPassword.toggle()
                                }) {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 16))
                                }
                            }
                            .textFieldStyle(EnhancedTextFieldStyle(isFocused: passwordFieldFocused))
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.clear)
                            .glassEffect(in: RoundedRectangle(cornerRadius: 20))
                    )
                    .padding(.horizontal, 24)
                    .opacity(formOpacity)
                    .offset(y: formOffset)
                    .scaleEffect(isTextFieldFocused ? 1.02 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isTextFieldFocused)
                    
                    // Forgot password
                    HStack {
                        Spacer()
                        Button(action: {
                            // Handle forgot password
                        }) {
                            Text("Forgot password?")
                                .font(.normaInput(14))
                                .foregroundColor(.secondary)
                                .underline(color: Color.secondary.opacity(0.4))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
                    .opacity(formOpacity)
                    
                    Spacer()
                        .frame(height: 20)
                    
                    // Sign in button
                    Button(action: {
                        handleLogin()
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Sign in")
                                    .font(.normaHeadline(18))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color("NormaPastelPurple").opacity(0.7))
                                .glassEffect(in: RoundedRectangle(cornerRadius: 14))
                        )
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                    .opacity((isLoading || email.isEmpty || password.isEmpty) ? 0.6 : 1)
                    .padding(.horizontal, 24)
                    .opacity(buttonOpacity)
                    .scaleEffect(buttonScale)
                    .onHover { hovering in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            buttonScale = hovering ? 1.02 : 0.95
                        }
                    }

                    // Divider
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(height: 1)
                        Text("or")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        Rectangle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .opacity(buttonOpacity)

                    // Sign in with Apple button
                    Button(action: {
                        handleAppleSignIn()
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black)
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)

                            HStack(spacing: 12) {
                                if isAppleSignInLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "apple.logo")
                                        .font(.system(size: 20, weight: .semibold))
                                    Text("Sign in with Apple")
                                        .font(.normaHeadline(16))
                                }
                            }
                            .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                    }
                    .disabled(isAppleSignInLoading)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .opacity(buttonOpacity)

                    // Sign in with Google button
                    Button(action: {
                        handleGoogleSignIn()
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                            HStack(spacing: 12) {
                                if isGoogleSignInLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                        .scaleEffect(0.8)
                                } else {
                                    GoogleLogoView()
                                        .frame(width: 20, height: 20)
                                    Text("Sign in with Google")
                                        .font(.normaHeadline(16))
                                }
                            }
                            .foregroundColor(.black.opacity(0.87))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                    }
                    .disabled(isGoogleSignInLoading)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .opacity(buttonOpacity)

                    Spacer()
                        .frame(height: 40)
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showSignUp = false
                        onboardingViewModel.currentStep = .landing
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
            }
            .background(
                ZStack {
                    LinearGradient(
                        colors: [
                            colorScheme == .dark
                                ? Color(red: 0.10, green: 0.06, blue: 0.16)
                                : Color(red: 0.93, green: 0.90, blue: 0.98),
                            colorScheme == .dark
                                ? Color(red: 0.04, green: 0.02, blue: 0.08)
                                : Color(red: 0.96, green: 0.94, blue: 0.98)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    DotGridPattern()
                }
                .ignoresSafeArea()
            )
            .overlay(
                Group {
                    if isLoading {
                        ZStack {
                            // Background blur
                            Color.black.opacity(0.3)
                                .ignoresSafeArea()
                                .blur(radius: 5)
                            
                            // Loading content
                            VStack(spacing: 24) {
                                // Animated circle loader
                                ZStack {
                                    // Background circle
                                    Circle()
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                                        .frame(width: 60, height: 60)
                                    
                                    // Animated progress circle
                                    Circle()
                                        .trim(from: 0, to: 0.8)
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.primary,
                                                    Color.primary.opacity(0.5)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                                        )
                                        .frame(width: 60, height: 60)
                                        .rotationEffect(Angle(degrees: loadingRotation))
                                    
                                    // Center icon
                                    Image(systemName: "person.badge.shield.checkmark")
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(.primary)
                                        .scaleEffect(loadingScale)
                                }
                                
                                Text("Signing you in...")
                                    .font(.normaHeadline(16))
                                    .foregroundColor(.primary)
                            }
                            .padding(40)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(UIColor.systemBackground))
                                    .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                            )
                            .scaleEffect(loadingScale)
                            .opacity(loadingOpacity)
                        }
                    }
                }
            )
            .onAppear {
                // Trigger animations
                withAnimation(.easeOut(duration: 0.6)) {
                    titleOpacity = 1.0
                }
                
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4)) {
                    formOpacity = 1.0
                    formOffset = 0
                }
                
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6)) {
                    buttonOpacity = 1.0
                    buttonScale = 1.0
                }
            }
        }
    }
    
    private func handleLogin() {
        // Clear any previous errors
        withAnimation {
            showError = false
        }
        
        isLoading = true
        
        // Start loading animations
        withAnimation(.easeInOut(duration: 0.3)) {
            loadingOpacity = 1.0
            loadingScale = 1.0
        }
        
        // Start rotation animation
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            loadingRotation = 360
        }
        
        // Pulse animation for center icon
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            loadingScale = 1.1
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Perform actual login
        Task {
            let success = await onboardingViewModel.signIn(email: email, password: password)
            
            await MainActor.run {
                // Hide loading overlay
                withAnimation(.easeOut(duration: 0.3)) {
                    loadingOpacity = 0.0
                    loadingScale = 0.8
                }
                
                // Reset rotation
                loadingRotation = 0
                
                isLoading = false
                
                if success {
                    // Login successful - the app coordinator will handle navigation
                    isAuthenticated = true
                } else {
                    // Show error
                    withAnimation {
                        errorMessage = "Invalid email or password. Please try again."
                        showError = true
                    }
                    
                    // Auto-hide error after 5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        withAnimation {
                            showError = false
                        }
                    }
                }
            }
        }
    }

    private func handleAppleSignIn() {
        // Clear any previous errors
        withAnimation {
            showError = false
        }

        isAppleSignInLoading = true

        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        Task {
            let success = await onboardingViewModel.signInWithApple(fromPreviewMode: false)

            await MainActor.run {
                isAppleSignInLoading = false

                if success {
                    isAuthenticated = true
                } else {
                    // Error is shown by OnboardingViewModel via alert
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.error)
                }
            }
        }
    }

    private func handleGoogleSignIn() {
        // Clear any previous errors
        withAnimation {
            showError = false
        }

        isGoogleSignInLoading = true

        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        Task {
            let success = await onboardingViewModel.signInWithGoogle(fromPreviewMode: false)

            await MainActor.run {
                isGoogleSignInLoading = false

                if success {
                    isAuthenticated = true
                } else {
                    // Error is shown by OnboardingViewModel via alert
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.error)
                }
            }
        }
    }
}

// Google logo view - uses image asset if available, otherwise draws a stylized "G"
struct GoogleLogoView: View {
    var body: some View {
        if let uiImage = UIImage(named: "google-ios") {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
        } else {
            // Fallback: Draw a simple Google-style "G"
            ZStack {
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.91, green: 0.26, blue: 0.21), // Red
                                Color(red: 0.98, green: 0.74, blue: 0.18), // Yellow
                                Color(red: 0.20, green: 0.66, blue: 0.33), // Green
                                Color(red: 0.26, green: 0.52, blue: 0.96), // Blue
                                Color(red: 0.91, green: 0.26, blue: 0.21)  // Red again
                            ]),
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        lineWidth: 3
                    )

                Text("G")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(red: 0.26, green: 0.52, blue: 0.96))
            }
        }
    }
}

// Enhanced text field style matching app design
struct EnhancedTextFieldStyle: TextFieldStyle {
    var isFocused: Bool = false

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(isFocused ? 0.08 : 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isFocused ? Color("NormaPastelTeal").opacity(0.3) : Color.gray.opacity(0.1),
                                lineWidth: isFocused ? 1.5 : 1
                            )
                    )
            )
            .font(.system(size: 16))
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isFocused)
    }
}

#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    let onboardingViewModel = OnboardingViewModel(sessionViewModel: sessionViewModel)
    
    return LoginView(isAuthenticated: .constant(false), showSignUp: .constant(false))
        .environmentObject(onboardingViewModel)
}
