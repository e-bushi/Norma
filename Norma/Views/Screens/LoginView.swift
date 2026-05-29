//
//  LoginView.swift
//  Norma
//
//  O2-style sign-in screen for returning users. Lavender-dithered shader on
//  dark canvas, lowercase title, dark-surface fields with lavender focus
//  accent, lavender pill primary CTA, and dark-surface apple/google buttons.
//

import SwiftUI
import UIKit

struct LoginView: View {
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    @Binding var isAuthenticated: Bool
    @Binding var showSignUp: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false

    @State private var isLoading = false
    @State private var isAppleSignInLoading = false
    @State private var isGoogleSignInLoading = false

    @State private var showError = false
    @State private var errorMessage = ""

    @State private var emailFocused = false
    @State private var passwordFocused = false

    @State private var titleAppeared = false
    @State private var subtitleAppeared = false
    @State private var formAppeared = false
    @State private var ctaAppeared = false
    @State private var altAppeared = false

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

                    Text("pick up where you left off.")
                        .font(.system(size: 14))
                        .foregroundStyle(NormaPalette.inkSubtle)
                        .opacity(subtitleAppeared ? 1 : 0)
                        .offset(y: subtitleAppeared ? 0 : 8)
                        .padding(.bottom, 32)

                    if showError {
                        errorBanner
                            .padding(.bottom, 12)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    formFields
                        .opacity(formAppeared ? 1 : 0)
                        .offset(y: formAppeared ? 0 : 12)

                    Spacer().frame(height: 14)

                    forgotPassword
                        .opacity(formAppeared ? 1 : 0)

                    Spacer().frame(height: 24)

                    signInButton
                        .opacity(ctaAppeared ? 1 : 0)
                        .offset(y: ctaAppeared ? 0 : 12)

                    Spacer().frame(height: 28)

                    divider
                        .opacity(altAppeared ? 1 : 0)
                        .padding(.bottom, 16)

                    appleButton
                        .opacity(altAppeared ? 1 : 0)
                        .offset(y: altAppeared ? 0 : 8)
                        .padding(.bottom, 10)

                    googleButton
                        .opacity(altAppeared ? 1 : 0)
                        .offset(y: altAppeared ? 0 : 8)

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
        .onAppear {
            impactGenerator.prepare()
            withAnimation(.easeOut(duration: 0.5).delay(0.10)) { titleAppeared = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.25)) { subtitleAppeared = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.40)) { formAppeared = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.55)) { ctaAppeared = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.70)) { altAppeared = true }
        }
    }

    // MARK: - Subviews

    private var backButton: some View {
        Button(action: {
            impactGenerator.impactOccurred()
            showSignUp = false
            onboardingViewModel.currentStep = .landing
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
        VStack(alignment: .leading, spacing: 0) {
            Text("welcome")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(NormaPalette.ink)
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("back")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(NormaPalette.ink)
                Text(".")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(NormaPalette.lavender)
            }
        }
        .tracking(-1.5)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var formFields: some View {
        VStack(spacing: 12) {
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
                        SecureField("", text: $password, onCommit: {
                            if !email.isEmpty && !password.isEmpty {
                                handleLogin()
                            }
                        })
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
        }
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

    private var forgotPassword: some View {
        HStack {
            Spacer()
            Button(action: {
                // forgot password — placeholder
            }) {
                Text("forgot password?")
                    .font(.system(size: 13))
                    .foregroundStyle(NormaPalette.inkSubtle)
            }
            .buttonStyle(.plain)
        }
    }

    private var canSubmit: Bool {
        !email.isEmpty && !password.isEmpty && !isLoading
    }

    private var signInButton: some View {
        Button(action: {
            impactGenerator.impactOccurred()
            handleLogin()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: NormaPalette.canvas))
                        .scaleEffect(0.85)
                } else {
                    Text("sign in")
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

    private var divider: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(NormaPalette.ink.opacity(0.10))
                .frame(height: 1)
            Text("or")
                .font(.system(size: 12))
                .foregroundStyle(NormaPalette.inkSubtle)
            Rectangle()
                .fill(NormaPalette.ink.opacity(0.10))
                .frame(height: 1)
        }
    }

    private var appleButton: some View {
        Button(action: {
            impactGenerator.impactOccurred()
            handleAppleSignIn()
        }) {
            HStack(spacing: 10) {
                if isAppleSignInLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: NormaPalette.ink))
                        .scaleEffect(0.85)
                } else {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 16, weight: .semibold))
                    Text("continue with apple")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundStyle(NormaPalette.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.11, green: 0.11, blue: 0.125))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(NormaPalette.ink.opacity(0.10), lineWidth: 1)
            )
        }
        .disabled(isAppleSignInLoading)
        .buttonStyle(.plain)
    }

    private var googleButton: some View {
        Button(action: {
            impactGenerator.impactOccurred()
            handleGoogleSignIn()
        }) {
            HStack(spacing: 10) {
                if isGoogleSignInLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: NormaPalette.ink))
                        .scaleEffect(0.85)
                } else {
                    GoogleLogoView()
                        .frame(width: 16, height: 16)
                    Text("continue with google")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundStyle(NormaPalette.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.11, green: 0.11, blue: 0.125))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(NormaPalette.ink.opacity(0.10), lineWidth: 1)
            )
        }
        .disabled(isGoogleSignInLoading)
        .buttonStyle(.plain)
    }

    private var errorBanner: some View {
        let warn = Color(red: 0.95, green: 0.55, blue: 0.55)
        return HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 13))
            Text(errorMessage)
                .font(.system(size: 13))
            Spacer(minLength: 0)
        }
        .foregroundStyle(warn)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(warn.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(warn.opacity(0.25), lineWidth: 1)
        )
    }

    private var loadingOverlay: some View {
        ZStack {
            NormaPalette.canvas.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: NormaPalette.lavender))
                    .scaleEffect(1.1)

                Text("signing you in...")
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

    private func handleLogin() {
        withAnimation { showError = false }
        isLoading = true

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        Task {
            let success = await onboardingViewModel.signIn(email: email, password: password)

            await MainActor.run {
                isLoading = false

                if success {
                    isAuthenticated = true
                } else {
                    withAnimation {
                        errorMessage = "invalid email or password. please try again."
                        showError = true
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        withAnimation { showError = false }
                    }
                }
            }
        }
    }

    private func handleAppleSignIn() {
        withAnimation { showError = false }
        isAppleSignInLoading = true

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        Task {
            let success = await onboardingViewModel.signInWithApple(requireExistingAccount: true)

            await MainActor.run {
                isAppleSignInLoading = false

                if success {
                    isAuthenticated = true
                } else {
                    let notification = UINotificationFeedbackGenerator()
                    notification.notificationOccurred(.error)
                }
            }
        }
    }

    private func handleGoogleSignIn() {
        withAnimation { showError = false }
        isGoogleSignInLoading = true

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        Task {
            let success = await onboardingViewModel.signInWithGoogle(requireExistingAccount: true)

            await MainActor.run {
                isGoogleSignInLoading = false

                if success {
                    isAuthenticated = true
                } else {
                    let notification = UINotificationFeedbackGenerator()
                    notification.notificationOccurred(.error)
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
                                Color(red: 0.91, green: 0.26, blue: 0.21),
                                Color(red: 0.98, green: 0.74, blue: 0.18),
                                Color(red: 0.20, green: 0.66, blue: 0.33),
                                Color(red: 0.26, green: 0.52, blue: 0.96),
                                Color(red: 0.91, green: 0.26, blue: 0.21)
                            ]),
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        lineWidth: 2
                    )

                Text("G")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(red: 0.26, green: 0.52, blue: 0.96))
            }
        }
    }
}

#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    let onboardingViewModel = OnboardingViewModel(sessionViewModel: sessionViewModel)

    return LoginView(isAuthenticated: .constant(false), showSignUp: .constant(false))
        .environmentObject(onboardingViewModel)
}
