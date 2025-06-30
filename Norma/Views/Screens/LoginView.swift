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
    @State private var signUpLinkOpacity = 0.0
    
    // Loading animation states
    @State private var loadingRotation = 0.0
    @State private var loadingScale = 0.8
    @State private var loadingOpacity = 0.0
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 60)
                    
                    // Logo/Icon with enhanced styling
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
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.primary)
                    }
                    .padding(.bottom, 20)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    
                    // Title
                    VStack(spacing: 8) {
                        Text("Welcome back")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Sign in to your account")
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 40)
                    .opacity(titleOpacity)
                    
                    // Error message if needed
                    if showError {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 14))
                            
                            Text(errorMessage)
                                .font(.system(size: 14))
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
                                        TextField("Enter your password", text: $password)
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled()
                                    } else {
                                        SecureField("Enter your password", text: $password)
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
                        }
                        .padding(24)
                    }
                    .padding(.horizontal, 24)
                    .opacity(formOpacity)
                    
                    // Forgot password
                    HStack {
                        Spacer()
                        Button(action: {
                            // Handle forgot password
                        }) {
                            Text("Forgot password?")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .opacity(formOpacity)
                    
                    Spacer()
                        .frame(height: 40)
                    
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
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                    .opacity((isLoading || email.isEmpty || password.isEmpty) ? 0.6 : 1)
                    .padding(.horizontal, 24)
                    .opacity(buttonOpacity)
                    
                    // Sign up link
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            showSignUp = true
                        }) {
                            Text("Sign up")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.top, 20)
                    .opacity(signUpLinkOpacity)
                    
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
                                Image(systemName: "person.badge.shield.checkmark")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(.primary)
                                    .scaleEffect(loadingScale)
                            }
                            
                            Text("Signing you in...")
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
        .onAppear {
            // Trigger animations
            withAnimation(.easeOut(duration: 0.6)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                titleOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                formOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.6)) {
                buttonOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.8)) {
                signUpLinkOpacity = 1.0
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
}

// Enhanced text field style matching app design
struct EnhancedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
            )
            .font(.system(size: 16))
    }
}

#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    let onboardingViewModel = OnboardingViewModel(sessionViewModel: sessionViewModel)
    
    return LoginView(isAuthenticated: .constant(false), showSignUp: .constant(false))
        .environmentObject(onboardingViewModel)
}
