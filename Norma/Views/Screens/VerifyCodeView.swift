//
//  VerifyCodeView.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import SwiftUI
import UIKit

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
    
    @State private var showTransition = false
    
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
                        Text("Didn't receive the code?")
                            .font(.normaInput(14))
                            .foregroundColor(.secondary)

                        Button(action: {
                            handleResendCode()
                        }) {
                            Text("Resend code")
                                .font(.normaHeadline(14))
                                .foregroundColor(.primary)
                        }
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
        .overlay(
            Group {
                if showTransition {
                    ZStack {
                        Color("NormaBackground")
                            .ignoresSafeArea()

                        VStack(spacing: 24) {
                            // Welcome message
                            VStack(spacing: 12) {
                                Image(systemName: "person.crop.circle.badge.checkmark")
                                    .font(.system(size: 48))
                                    .foregroundColor(.green)
                                    .symbolEffect(.bounce, value: showTransition)

                                Text("Welcome aboard!")
                                    .font(.normaTitle(24))
                                    .foregroundColor(.primary)

                                Text("Let's get to know you better...")
                                    .font(.normaInput(16))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                                    .padding(.top, 8)
                            }
                            .padding(40)
                        }
                    }
                    .transition(.opacity)
                }
            }
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
                    
                    // Show transition screen immediately
                    withAnimation(.easeIn(duration: 0.3)) {
                        showTransition = true
                    }
                    
                    // Navigate after transition is shown
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        isLoading = false
                        showTransition = false
                        // Now trigger navigation by updating currentStep
                        onboardingViewModel.proceedToWelcome()
                    }
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
        // Handle resend code logic
        print("Resending code to \(email)")
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

#Preview {
    VerifyCodeView(
        email: "user@example.com",
        isAuthenticated: .constant(false),
        showVerifyCode: .constant(true)
    )
    .environmentObject(OnboardingViewModel(sessionViewModel: SessionViewModel(dataManager: DataManager())))
    .preferredColorScheme(.dark)
}
