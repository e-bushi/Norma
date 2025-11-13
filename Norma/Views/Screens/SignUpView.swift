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
    
    // Enhanced animation states
    @State private var logoScale = 0.8
    @State private var logoOpacity = 0.0
    @State private var logoRotation = 0.0
    @State private var formOffset: CGFloat = 20
    @State private var buttonScale = 0.95
    @State private var isTextFieldFocused = false
    @State private var nameFieldFocused = false
    @State private var emailFieldFocused = false
    @State private var passwordFieldFocused = false
    @State private var confirmPasswordFieldFocused = false
    @State private var floatingOffset: CGFloat = 0
    
    // Loading animation states
    @State private var loadingRotation = 0.0
    @State private var loadingScale = 0.8
    @State private var loadingOpacity = 0.0
    
    @Binding var isAuthenticated: Bool
    @Binding var showSignUp: Bool
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    Spacer()
                        .frame(height: 20)

                    formFields

                    // Terms and conditions
                    HStack(alignment: .top, spacing: 12) {
                        Button(action: {
                            agreedToTerms.toggle()
                        }) {
                            Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                .font(.system(size: 20))
                                .foregroundColor(agreedToTerms ? Color("NormaPastelTeal") : .secondary)
                                .scaleEffect(agreedToTerms ? 1.1 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: agreedToTerms)
                        }

                        Text("I agree to the Terms of Service and Privacy Policy")
                            .font(.normaInput(14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
                    .opacity(termsOpacity)
                    
                    Spacer()
                        .frame(height: 20)
                    
                    // Sign up button
                    Button(action: {
                        handleSignUp()
                    }) {
                        ZStack {
                            // Gradient background that animates
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
                                .shadow(color: Color("NormaPastelTeal").opacity(0.3), radius: buttonScale > 1 ? 8 : 4, x: 0, y: buttonScale > 1 ? 4 : 2)

                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Create account")
                                        .font(.normaHeadline(16))
                                }
                            }
                            .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                    }
                    .disabled(isLoading || !isFormValid)
                    .opacity((isLoading || !isFormValid) ? 0.6 : 1)
                    .padding(.horizontal, 24)
                    .opacity(buttonOpacity)
                    .scaleEffect(buttonScale)
                    .onHover { hovering in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            buttonScale = hovering ? 1.02 : 0.95
                        }
                    }
                    
                    // Sign in link
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .font(.normaInput(14))
                            .foregroundColor(.secondary)

                        Button(action: {
                            showSignUp = false
                        }) {
                            Text("Sign in")
                                .font(.normaHeadline(14))
                                .foregroundColor(.primary)
                                .underline()
                        }
                    }
                    .padding(.top, 16)
                    .opacity(signInLinkOpacity)
                    
                    Spacer()
                }
            }
            .navigationTitle("Sign Up")
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
        .background(Color("NormaBackground"))
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
            
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            
            // Logo rotation animation
            withAnimation(.easeInOut(duration: 0.8).delay(0.4)) {
                logoRotation = 360
            }
            
            // Floating animation
            withAnimation(.easeInOut(duration: 2.0).delay(1.2).repeatForever(autoreverses: true)) {
                floatingOffset = -10
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                titleOpacity = 1.0
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5)) {
                formOpacity = 1.0
                formOffset = 0
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.7)) {
                termsOpacity = 1.0
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.9)) {
                buttonOpacity = 1.0
                buttonScale = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(1.1)) {
                signInLinkOpacity = 1.0
            }
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

    private var formFields: some View {
        VStack(spacing: 16) {
            // Name field
            VStack(alignment: .leading, spacing: 8) {
                Text("FULL NAME")
                    .font(.normaFinancial(11))
                    .foregroundColor(.secondary)
                    .tracking(1.2)

                TextField("Enter your name", text: $name, onEditingChanged: { editing in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        nameFieldFocused = editing
                        isTextFieldFocused = editing || emailFieldFocused || passwordFieldFocused || confirmPasswordFieldFocused
                    }
                })
                    .textFieldStyle(EnhancedTextFieldStyle(isFocused: nameFieldFocused))
                    .textInputAutocapitalization(.words)
            }

            // Email field
            VStack(alignment: .leading, spacing: 8) {
                Text("EMAIL")
                    .font(.normaFinancial(11))
                    .foregroundColor(.secondary)
                    .tracking(1.2)

                TextField("Enter your email", text: $email, onEditingChanged: { editing in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        emailFieldFocused = editing
                        isTextFieldFocused = editing || nameFieldFocused || passwordFieldFocused || confirmPasswordFieldFocused
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
                        TextField("Create a password", text: $password, onEditingChanged: { editing in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                passwordFieldFocused = editing
                                isTextFieldFocused = editing || nameFieldFocused || emailFieldFocused || confirmPasswordFieldFocused
                            }
                        })
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } else {
                        SecureField("Create a password", text: $password)
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

            // Confirm password field
            VStack(alignment: .leading, spacing: 8) {
                Text("CONFIRM PASSWORD")
                    .font(.normaFinancial(11))
                    .foregroundColor(.secondary)
                    .tracking(1.2)

                HStack {
                    if showConfirmPassword {
                        TextField("Confirm your password", text: $confirmPassword, onEditingChanged: { editing in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                confirmPasswordFieldFocused = editing
                                isTextFieldFocused = editing || nameFieldFocused || emailFieldFocused || passwordFieldFocused
                            }
                        })
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } else {
                        SecureField("Confirm your password", text: $confirmPassword)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    confirmPasswordFieldFocused = true
                                    isTextFieldFocused = true
                                }
                            }
                    }

                    Button(action: {
                        showConfirmPassword.toggle()
                    }) {
                        Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                    }
                }
                .textFieldStyle(EnhancedTextFieldStyle(isFocused: confirmPasswordFieldFocused))

                // Password validation indicator
                if !confirmPassword.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: password == confirmPassword ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(password == confirmPassword ? .green : .red)

                        Text(password == confirmPassword ? "Passwords match" : "Passwords do not match")
                            .font(.normaInput(12))
                            .foregroundColor(password == confirmPassword ? Color("NormaPastelTeal") : .red)
                    }
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .scale))
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: password == confirmPassword)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.clear)
                .glassEffect(in: RoundedRectangle(cornerRadius: 20))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 24)
        .opacity(formOpacity)
        .offset(y: formOffset)
        .scaleEffect(isTextFieldFocused ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isTextFieldFocused)
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
