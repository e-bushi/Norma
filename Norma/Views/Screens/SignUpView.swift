//
//  SignUpView.swift
//  Norma
//
//  Brand-voice signup screen for new accounts. Dark canvas, 56pt lowercase
//  hero with lavender period, dark-surface fields with lavender focus accent,
//  lavender pill primary CTA. Mirrors LoginView's visual language.
//

import SwiftUI
import UIKit

struct SignUpView: View {
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    @Binding var isAuthenticated: Bool
    @Binding var showSignUp: Bool

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var agreedToTerms = false

    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    @State private var nameFocused = false
    @State private var emailFocused = false
    @State private var passwordFocused = false
    @State private var confirmFocused = false

    @State private var titleAppeared = false
    @State private var subtitleAppeared = false
    @State private var formAppeared = false
    @State private var termsAppeared = false
    @State private var ctaAppeared = false
    @State private var linkAppeared = false

    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        ZStack {
            NormaPalette.canvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    backButton
                        .padding(.top, 8)
                        .padding(.bottom, 48)

                    titleView
                        .opacity(titleAppeared ? 1 : 0)
                        .offset(y: titleAppeared ? 0 : 12)
                        .padding(.bottom, 12)

                    Text("name, email, password. that's all we need.")
                        .font(.system(size: 14))
                        .foregroundStyle(NormaPalette.inkSubtle)
                        .opacity(subtitleAppeared ? 1 : 0)
                        .offset(y: subtitleAppeared ? 0 : 8)
                        .padding(.bottom, 32)

                    formFields
                        .opacity(formAppeared ? 1 : 0)
                        .offset(y: formAppeared ? 0 : 12)

                    Spacer().frame(height: 18)

                    termsRow
                        .opacity(termsAppeared ? 1 : 0)

                    Spacer().frame(height: 24)

                    createButton
                        .opacity(ctaAppeared ? 1 : 0)
                        .offset(y: ctaAppeared ? 0 : 12)

                    Spacer().frame(height: 18)

                    signInLink
                        .opacity(linkAppeared ? 1 : 0)
                        .frame(maxWidth: .infinity)

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.hidden)

            if isLoading {
                loadingOverlay
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
        .alert("error", isPresented: $showError) {
            Button("ok", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            impactGenerator.prepare()
            withAnimation(.easeOut(duration: 0.5).delay(0.10)) { titleAppeared = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.25)) { subtitleAppeared = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.40)) { formAppeared = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.55)) { termsAppeared = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.65)) { ctaAppeared = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.80)) { linkAppeared = true }
        }
    }

    // MARK: - Subviews

    private var backButton: some View {
        Button(action: {
            impactGenerator.impactOccurred()
            // In the new flow, email signup is reached from .saveAnswers.
            // Back returns there rather than to the landing.
            withAnimation {
                onboardingViewModel.currentStep = .saveAnswers
            }
        }) {
            Image(systemName: "chevron.left")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(NormaPalette.ink)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(NormaPalette.ink.opacity(0.05))
                )
                .overlay(
                    Circle()
                        .strokeBorder(NormaPalette.ink.opacity(0.10), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var titleView: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("let's begin")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(NormaPalette.ink)
            Text(".")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(NormaPalette.lavender)
        }
        .tracking(-1.5)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var formFields: some View {
        VStack(spacing: 12) {
            fieldContainer(label: "your name", isFocused: nameFocused) {
                TextField("", text: $name, onEditingChanged: { editing in
                    withAnimation(.easeOut(duration: 0.2)) {
                        nameFocused = editing
                    }
                })
                .textInputAutocapitalization(.words)
                .foregroundStyle(NormaPalette.ink)
                .font(.system(size: 16))
                .tint(NormaPalette.lavender)
            }

            fieldContainer(label: "email", isFocused: emailFocused) {
                TextField("", text: $email, onEditingChanged: { editing in
                    withAnimation(.easeOut(duration: 0.2)) {
                        emailFocused = editing
                    }
                })
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(NormaPalette.ink)
                .font(.system(size: 16))
                .tint(NormaPalette.lavender)
            }

            fieldContainer(
                label: "password",
                isFocused: passwordFocused,
                trailing: AnyView(
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .font(.system(size: 14))
                            .foregroundStyle(NormaPalette.inkSubtle)
                    }
                    .buttonStyle(.plain)
                )
            ) {
                Group {
                    if showPassword {
                        TextField("", text: $password, onEditingChanged: { editing in
                            withAnimation(.easeOut(duration: 0.2)) {
                                passwordFocused = editing
                            }
                        })
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    } else {
                        SecureField("", text: $password)
                            .onTapGesture {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    passwordFocused = true
                                }
                            }
                    }
                }
                .foregroundStyle(NormaPalette.ink)
                .font(.system(size: 16))
                .tint(NormaPalette.lavender)
            }

            fieldContainer(
                label: "confirm password",
                isFocused: confirmFocused,
                trailing: AnyView(
                    Button(action: { showConfirmPassword.toggle() }) {
                        Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                            .font(.system(size: 14))
                            .foregroundStyle(NormaPalette.inkSubtle)
                    }
                    .buttonStyle(.plain)
                )
            ) {
                Group {
                    if showConfirmPassword {
                        TextField("", text: $confirmPassword, onEditingChanged: { editing in
                            withAnimation(.easeOut(duration: 0.2)) {
                                confirmFocused = editing
                            }
                        })
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    } else {
                        SecureField("", text: $confirmPassword)
                            .onTapGesture {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    confirmFocused = true
                                }
                            }
                    }
                }
                .foregroundStyle(NormaPalette.ink)
                .font(.system(size: 16))
                .tint(NormaPalette.lavender)
            }

            if !confirmPassword.isEmpty {
                passwordMatchIndicator
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeOut(duration: 0.2), value: confirmPassword.isEmpty)
        .animation(.easeOut(duration: 0.2), value: password == confirmPassword)
    }

    @ViewBuilder
    private func fieldContainer<Content: View>(
        label: String,
        isFocused: Bool,
        trailing: AnyView? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(NormaPalette.inkSubtle)
                .tracking(0.8)

            HStack(spacing: 8) {
                content()
                if let trailing = trailing {
                    trailing
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.11, green: 0.11, blue: 0.125))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isFocused ? NormaPalette.lavender : NormaPalette.ink.opacity(0.06),
                        lineWidth: 1
                    )
            )
        }
    }

    private var passwordMatchIndicator: some View {
        let matches = password == confirmPassword
        let warn = Color(red: 0.95, green: 0.55, blue: 0.55)
        let color = matches ? NormaPalette.lavender : warn
        return HStack(spacing: 6) {
            Image(systemName: matches ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 11))
            Text(matches ? "passwords match" : "passwords do not match")
                .font(.system(size: 12))
        }
        .foregroundStyle(color)
        .padding(.top, 2)
    }

    private var termsRow: some View {
        Button(action: {
            impactGenerator.impactOccurred()
            agreedToTerms.toggle()
        }) {
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(agreedToTerms ? NormaPalette.lavender : Color.clear)
                    RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(
                            agreedToTerms ? NormaPalette.lavender : NormaPalette.ink.opacity(0.30),
                            lineWidth: 1.5
                        )
                    if agreedToTerms {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(NormaPalette.canvas)
                    }
                }
                .frame(width: 18, height: 18)

                Text("i agree to the terms of service and privacy policy")
                    .font(.system(size: 13))
                    .foregroundStyle(NormaPalette.inkSubtle)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
    }

    private var isFormValid: Bool {
        !name.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        password.count >= 8 &&
        password == confirmPassword &&
        agreedToTerms
    }

    private var canSubmit: Bool {
        isFormValid && !isLoading
    }

    private var createButton: some View {
        Button(action: {
            impactGenerator.impactOccurred()
            handleSignUp()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: NormaPalette.canvas))
                        .scaleEffect(0.85)
                } else {
                    Text("create account")
                        .font(.system(size: 15, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .semibold))
                }
            }
            .foregroundStyle(NormaPalette.canvas)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule().fill(canSubmit
                    ? NormaPalette.lavender
                    : NormaPalette.lavender.opacity(0.40))
            )
            .shadow(
                color: NormaPalette.lavender.opacity(canSubmit ? 0.40 : 0),
                radius: 18, x: 0, y: 10
            )
        }
        .disabled(!canSubmit)
        .buttonStyle(.plain)
    }

    private var signInLink: some View {
        HStack(spacing: 6) {
            Text("already have an account?")
                .font(.system(size: 13))
                .foregroundStyle(NormaPalette.inkMuted)
            Button(action: {
                showSignUp = false
            }) {
                Text("sign in")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(NormaPalette.ink)
            }
            .buttonStyle(.plain)
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            NormaPalette.canvas.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: NormaPalette.lavender))
                    .scaleEffect(1.1)

                Text("creating your account...")
                    .font(.system(size: 14))
                    .foregroundStyle(NormaPalette.ink)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.11, green: 0.11, blue: 0.125))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(NormaPalette.ink.opacity(0.08), lineWidth: 1)
            )
        }
    }

    // MARK: - Actions

    private func handleSignUp() {
        isLoading = true
        errorMessage = ""
        showError = false

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        Task {
            do {
                try await onboardingViewModel.signUp(
                    email: email,
                    password: password,
                    fullName: name
                )
                await MainActor.run {
                    isLoading = false
                    // Navigation handled by AppCoordinator observing currentStep
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true

                    let notification = UINotificationFeedbackGenerator()
                    notification.notificationOccurred(.error)
                }
            }
        }
    }
}

#Preview {
    SignUpView(isAuthenticated: .constant(false), showSignUp: .constant(true))
        .environmentObject(OnboardingViewModel(sessionViewModel: SessionViewModel(dataManager: DataManager())))
}
