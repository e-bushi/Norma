//
//  SignUpView.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import SwiftUI
import UIKit

struct SignUpView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var agreedToTerms = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Animation states
    @State private var headerOpacity = 0.0
    @State private var titleOpacity = 0.0
    @State private var formOpacity = 0.0
    @State private var termsOpacity = 0.0
    @State private var buttonOpacity = 0.0
    @State private var signInLinkOpacity = 0.0
    
    // Loading animation states
    @State private var loadingRotation = 0.0
    @State private var loadingScale = 0.8
    @State private var loadingOpacity = 0.0
    
    @Binding var isAuthenticated: Bool
    @Binding var showSignUp: Bool
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with back button
            HStack {
                Button(action: {
                    showSignUp = false
                }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .opacity(headerOpacity)
            
            ScrollView {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 40)
                    
                    // Title
                    VStack(spacing: 8) {
                        Text("Create account")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Start managing your finances")
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 40)
                    .opacity(titleOpacity)
                    
                    // Form fields container
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(UIColor.systemBackground),
                                        Color.gray.opacity(0.02)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.gray.opacity(0.2),
                                                Color.gray.opacity(0.05)
                                            ]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 1
                                    )
                            )
                        
                        VStack(spacing: 20) {
                            // Name field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("FULL NAME")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .tracking(1.2)
                                
                                TextField("Enter your name", text: $name)
                                    .textFieldStyle(EnhancedTextFieldStyle())
                                    .textInputAutocapitalization(.words)
                            }
                            
                            // Email field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("EMAIL")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .tracking(1.2)
                                
                                TextField("Enter your email", text: $email)
                                    .textFieldStyle(EnhancedTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            }
                            
                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("PASSWORD")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .tracking(1.2)
                                
                                HStack {
                                    if showPassword {
                                        TextField("Create a password", text: $password)
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled()
                                    } else {
                                        SecureField("Create a password", text: $password)
                                    }
                                    
                                    Button(action: {
                                        showPassword.toggle()
                                    }) {
                                        Image(systemName: showPassword ? "eye.slash" : "eye")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 16))
                                    }
                                }
                                .textFieldStyle(EnhancedTextFieldStyle())
                            }
                            
                            // Confirm password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("CONFIRM PASSWORD")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .tracking(1.2)
                                
                                HStack {
                                    if showConfirmPassword {
                                        TextField("Confirm your password", text: $confirmPassword)
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled()
                                    } else {
                                        SecureField("Confirm your password", text: $confirmPassword)
                                    }
                                    
                                    Button(action: {
                                        showConfirmPassword.toggle()
                                    }) {
                                        Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 16))
                                    }
                                }
                                .textFieldStyle(EnhancedTextFieldStyle())
                            }
                        }
                        .padding(24)
                    }
                    .padding(.horizontal, 24)
                    .opacity(formOpacity)
                    
                    // Terms and conditions
                    HStack(alignment: .top, spacing: 12) {
                        Button(action: {
                            agreedToTerms.toggle()
                        }) {
                            Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                .font(.system(size: 20))
                                .foregroundColor(agreedToTerms ? .primary : .secondary)
                        }
                        
                        Text("I agree to the Terms of Service and Privacy Policy")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .opacity(termsOpacity)
                    
                    Spacer()
                        .frame(height: 40)
                    
                    // Sign up button
                    Button(action: {
                        handleSignUp()
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Create account")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .foregroundColor(Color(UIColor.systemBackground))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.primary)
                                .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
                        )
                    }
                    .disabled(isLoading || !isFormValid)
                    .opacity((isLoading || !isFormValid) ? 0.6 : 1)
                    .padding(.horizontal, 24)
                    .opacity(buttonOpacity)
                    
                    // Sign in link
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            showSignUp = false
                        }) {
                            Text("Sign in")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.top, 20)
                    .opacity(signInLinkOpacity)
                    
                    Spacer()
                        .frame(height: 40)
                }
            }
        }
        .background(Color(UIColor.systemBackground))
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
                                Image(systemName: "person.crop.circle.badge.plus")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(.primary)
                                    .scaleEffect(loadingScale)
                            }
                            
                            Text("Creating your account...")
                                .font(.system(size: 16, weight: .medium))
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
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // Trigger animations
            withAnimation(.easeOut(duration: 0.6)) {
                headerOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                titleOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                formOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.6)) {
                termsOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.8)) {
                buttonOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(1.0)) {
                signInLinkOpacity = 1.0
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        password.count >= 8 &&
        password == confirmPassword &&
        agreedToTerms
    }
    
    private func handleSignUp() {
        isLoading = true
        errorMessage = ""
        showError = false
        
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
        
        Task {
            do {
                try await onboardingViewModel.signUp(
                    email: email,
                    password: password,
                    fullName: name
                )
                await MainActor.run {
                    isLoading = false
                    
                    // Hide loading overlay
                    withAnimation(.easeOut(duration: 0.3)) {
                        loadingOpacity = 0.0
                        loadingScale = 0.8
                    }
                    
                    // Navigation is handled by AppCoordinator observing currentStep
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    
                    // Hide loading overlay
                    withAnimation(.easeOut(duration: 0.3)) {
                        loadingOpacity = 0.0
                        loadingScale = 0.8
                    }
                    
                    // Reset rotation
                    loadingRotation = 0
                    
                    errorMessage = error.localizedDescription
                    showError = true
                    
                    // Error haptic feedback
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.error)
                }
            }
        }
    }
}

#Preview {
    SignUpView(isAuthenticated: .constant(false), showSignUp: .constant(true))
        .environmentObject(OnboardingViewModel(sessionViewModel: SessionViewModel(dataManager: DataManager())))
}
