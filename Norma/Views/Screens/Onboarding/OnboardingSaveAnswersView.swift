//
//  OnboardingSaveAnswersView.swift
//  Norma
//
//  O2 — "save your answers". Final auth gate at the end of the question
//  flow. Apple/Google complete + finalize directly. "prefer email? sign up"
//  routes to the email signup form (.authentication).
//

import SwiftUI
import UIKit

struct OnboardingSaveAnswersView: View {
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    let onEmailSignUp: () -> Void
    let onBack: () -> Void

    @State private var subtitleAppeared = false
    @State private var appleAppeared = false
    @State private var googleAppeared = false
    @State private var emailAppeared = false

    @State private var isAppleLoading = false
    @State private var isGoogleLoading = false

    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        ZStack {
            NormaPalette.canvas.ignoresSafeArea()

            DitherShaderView(intensity: 1.0)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            LinearGradient(
                stops: [
                    .init(color: NormaPalette.canvas.opacity(0),    location: 0.00),
                    .init(color: NormaPalette.canvas.opacity(0),    location: 0.18),
                    .init(color: NormaPalette.canvas.opacity(0.55), location: 0.40),
                    .init(color: NormaPalette.canvas.opacity(0.85), location: 0.62),
                    .init(color: NormaPalette.canvas,               location: 0.88)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 0) {
                backButton
                    .padding(.top, 8)

                Spacer()

                titleView
                    .padding(.bottom, 14)

                Text("lock in what you wrote. one tap and you're in.")
                    .font(.system(size: 14))
                    .foregroundStyle(NormaPalette.inkSubtle)
                    .lineSpacing(2)
                    .opacity(subtitleAppeared ? 1 : 0)
                    .offset(y: subtitleAppeared ? 0 : 8)
                    .padding(.bottom, 24)

                appleButton
                    .opacity(appleAppeared ? 1 : 0)
                    .offset(y: appleAppeared ? 0 : 8)
                    .padding(.bottom, 12)

                googleButton
                    .opacity(googleAppeared ? 1 : 0)
                    .offset(y: googleAppeared ? 0 : 8)
                    .padding(.bottom, 18)

                emailLink
                    .opacity(emailAppeared ? 1 : 0)

                Spacer().frame(height: 36)
            }
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity, alignment: .leading)

            if isAppleLoading || isGoogleLoading {
                loadingOverlay
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            impactGenerator.prepare()
            withAnimation(.easeOut(duration: 0.5).delay(0.40)) { subtitleAppeared = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.55)) { appleAppeared = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.70)) { googleAppeared = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.85)) { emailAppeared = true }
        }
    }

    // MARK: - Subviews

    private var backButton: some View {
        Button(action: {
            impactGenerator.impactOccurred()
            onBack()
        }) {
            Image(systemName: "chevron.left")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(NormaPalette.ink)
                .frame(width: 36, height: 36)
                .background(Circle().fill(NormaPalette.ink.opacity(0.05)))
                .overlay(Circle().strokeBorder(NormaPalette.ink.opacity(0.10), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var titleView: some View {
        WaveTextView(
            text: "save your answers",
            font: .system(size: 56, weight: .bold),
            color: NormaPalette.ink,
            isAnimating: true,
            alignment: .leading,
            tracking: -1.5,
            wordSpacing: 12,
            lineSpacing: 0
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var appleButton: some View {
        Button(action: {
            impactGenerator.impactOccurred()
            handleAppleSignIn()
        }) {
            HStack(spacing: 10) {
                if isAppleLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: NormaPalette.canvas))
                        .scaleEffect(0.85)
                } else {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 16, weight: .semibold))
                    Text("continue with apple")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundStyle(NormaPalette.canvas)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(Capsule().fill(NormaPalette.ink))
        }
        .disabled(isAppleLoading)
        .buttonStyle(.plain)
    }

    private var googleButton: some View {
        Button(action: {
            impactGenerator.impactOccurred()
            handleGoogleSignIn()
        }) {
            HStack(spacing: 10) {
                if isGoogleLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: NormaPalette.ink))
                        .scaleEffect(0.85)
                } else {
                    GoogleLogoView()
                        .frame(width: 14, height: 14)
                    Text("continue with google")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundStyle(NormaPalette.ink)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(Capsule().fill(NormaPalette.ink.opacity(0.06)))
            .overlay(Capsule().strokeBorder(NormaPalette.ink.opacity(0.15), lineWidth: 1))
        }
        .disabled(isGoogleLoading)
        .buttonStyle(.plain)
    }

    private var emailLink: some View {
        HStack(spacing: 6) {
            Text("prefer email?")
                .font(.system(size: 13))
                .foregroundStyle(NormaPalette.inkSubtle)
            Button(action: {
                impactGenerator.impactOccurred()
                onEmailSignUp()
            }) {
                Text("sign up")
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

                Text("saving...")
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

    private func handleAppleSignIn() {
        isAppleLoading = true
        Task {
            _ = await onboardingViewModel.signInWithApple()
            await MainActor.run {
                isAppleLoading = false
            }
        }
    }

    private func handleGoogleSignIn() {
        isGoogleLoading = true
        Task {
            _ = await onboardingViewModel.signInWithGoogle()
            await MainActor.run {
                isGoogleLoading = false
            }
        }
    }
}

#Preview {
    OnboardingSaveAnswersView(onEmailSignUp: {}, onBack: {})
        .environmentObject(OnboardingViewModel(sessionViewModel: SessionViewModel(dataManager: DataManager())))
}
