//
//  VerifyCodeView.swift
//  Norma
//
//  Brand-voice email verification screen. Dark canvas, 56pt lowercase hero
//  with lavender period, six dark-surface digit slots with lavender focus
//  accent, lavender pill verify CTA, lowercase resend mechanic.
//

import SwiftUI
import UIKit

struct VerifyCodeView: View {
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    let email: String
    @Binding var isAuthenticated: Bool
    @Binding var showVerifyCode: Bool

    @State private var codeDigits: [String] = Array(repeating: "", count: 6)
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var focusedField: Int?

    @State private var isResending = false
    @State private var resendSuccess = false
    @State private var resendCooldown = 0

    @State private var titleAppeared = false
    @State private var subtitleAppeared = false
    @State private var codeAppeared = false
    @State private var ctaAppeared = false
    @State private var resendAppeared = false

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

                    subtitleView
                        .opacity(subtitleAppeared ? 1 : 0)
                        .offset(y: subtitleAppeared ? 0 : 8)
                        .padding(.bottom, 36)

                    codeFieldRow
                        .opacity(codeAppeared ? 1 : 0)
                        .offset(y: codeAppeared ? 0 : 12)

                    if showError {
                        errorBanner
                            .padding(.top, 14)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    Spacer().frame(height: 32)

                    verifyButton
                        .opacity(ctaAppeared ? 1 : 0)
                        .offset(y: ctaAppeared ? 0 : 12)

                    Spacer().frame(height: 28)

                    resendBlock
                        .opacity(resendAppeared ? 1 : 0)
                        .frame(maxWidth: .infinity)

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.hidden)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("done") {
                        focusedField = nil
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(NormaPalette.lavender)
                }
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            impactGenerator.prepare()
            focusedField = 0

            withAnimation(.easeOut(duration: 0.5).delay(0.10)) { titleAppeared = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.25)) { subtitleAppeared = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.40)) { codeAppeared = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.55)) { ctaAppeared = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.70)) { resendAppeared = true }
        }
    }

    // MARK: - Subviews

    private var backButton: some View {
        Button(action: {
            impactGenerator.impactOccurred()
            showVerifyCode = false
            onboardingViewModel.currentStep = .authentication
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
            Text("check your inbox")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(NormaPalette.ink)
            Text(".")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(NormaPalette.lavender)
        }
        .tracking(-1.5)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var subtitleView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("we sent a six-digit code to")
                .font(.system(size: 14))
                .foregroundStyle(NormaPalette.inkSubtle)
            Text(email)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(NormaPalette.ink)
        }
    }

    private var codeFieldRow: some View {
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
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var verifyButton: some View {
        Button(action: {
            impactGenerator.impactOccurred()
            handleVerification()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: NormaPalette.canvas))
                        .scaleEffect(0.85)
                } else {
                    Text("verify")
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

    private var resendBlock: some View {
        VStack(spacing: 8) {
            if resendSuccess {
                Text("code sent.")
                    .font(.system(size: 13))
                    .foregroundStyle(NormaPalette.lavender)
            } else {
                Text("didn't get it?")
                    .font(.system(size: 13))
                    .foregroundStyle(NormaPalette.inkMuted)
            }

            Button(action: {
                impactGenerator.impactOccurred()
                handleResendCode()
            }) {
                Group {
                    if isResending {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: NormaPalette.ink))
                            .scaleEffect(0.8)
                    } else if resendCooldown > 0 {
                        Text("resend in \(resendCooldown)s")
                            .foregroundStyle(NormaPalette.inkSubtle)
                    } else {
                        Text("resend code")
                            .foregroundStyle(NormaPalette.ink)
                    }
                }
                .font(.system(size: 13, weight: .semibold))
            }
            .disabled(isResending || resendCooldown > 0)
            .buttonStyle(.plain)
        }
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

    // MARK: - Logic

    private var isCodeComplete: Bool {
        codeDigits.allSatisfy { !$0.isEmpty }
    }

    private var canSubmit: Bool {
        isCodeComplete && !isLoading
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

        if newValue.count == 1 && index < 5 {
            focusedField = index + 1
        } else if newValue.isEmpty && index > 0 {
            focusedField = index - 1
        }

        if showError {
            showError = false
            errorMessage = ""
        }
    }

    private func handleVerification() {
        isLoading = true
        showError = false
        errorMessage = ""

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        Task {
            do {
                try await onboardingViewModel.verifyCode(email: email, code: fullCode)
                await MainActor.run {
                    let notification = UINotificationFeedbackGenerator()
                    notification.notificationOccurred(.success)

                    isLoading = false
                    onboardingViewModel.proceedToWelcome()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    withAnimation {
                        showError = true
                        errorMessage = error.localizedDescription
                    }

                    codeDigits = Array(repeating: "", count: 6)
                    focusedField = 0

                    let notification = UINotificationFeedbackGenerator()
                    notification.notificationOccurred(.error)
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

                    let notification = UINotificationFeedbackGenerator()
                    notification.notificationOccurred(.success)

                    resendCooldown = 60
                    startCooldownTimer()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        resendSuccess = false
                    }
                }
            } catch {
                await MainActor.run {
                    isResending = false
                    withAnimation {
                        showError = true
                        errorMessage = "failed to resend code. please try again."
                    }

                    let notification = UINotificationFeedbackGenerator()
                    notification.notificationOccurred(.error)
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
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(NormaPalette.ink)
            .tint(NormaPalette.lavender)
            .multilineTextAlignment(.center)
            .keyboardType(.numberPad)
            .textFieldStyle(PlainTextFieldStyle())
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.11, green: 0.11, blue: 0.125))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isActive ? NormaPalette.lavender : NormaPalette.ink.opacity(0.06),
                        lineWidth: isActive ? 1.5 : 1
                    )
            )
            .onChange(of: text) { oldValue, newValue in
                if newValue.count > 1 {
                    text = String(newValue.prefix(1))
                }

                if !newValue.isEmpty && !newValue.allSatisfy({ $0.isNumber }) {
                    text = oldValue
                    return
                }

                onTextChange(newValue)
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
