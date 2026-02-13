//
//  RecoveryPhraseSheet.swift
//  Norma
//
//  Created by Claude on 2/6/26.
//

import SwiftUI

struct RecoveryPhraseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var dataManager: DataManager

    @State private var password = ""
    @State private var isVerifying = false
    @State private var isVerified = false
    @State private var recoveryPhrase: String?
    @State private var errorMessage: String?
    @State private var showCopiedAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if !isVerified {
                    // Password verification step
                    passwordVerificationView
                } else if let phrase = recoveryPhrase {
                    // Show recovery phrase
                    recoveryPhraseView(phrase: phrase)
                } else {
                    // No recovery phrase found
                    noRecoveryPhraseView
                }
            }
            .padding()
            .navigationTitle("Recovery Phrase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Password Verification View

    private var passwordVerificationView: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 48))
                .foregroundColor(Color("NormaPastelTeal"))

            Text("Verify Your Identity")
                .font(.normaHeadline(20))

            Text("Enter your password to view your recovery phrase. Keep this phrase safe - it's the only way to recover your encrypted data if you forget your password.")
                .font(.normaHeadline(14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .padding(.top, 8)

            if let error = errorMessage {
                Text(error)
                    .font(.normaHeadline(13))
                    .foregroundColor(.red)
            }

            Button(action: verifyPassword) {
                HStack {
                    if isVerifying {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    }
                    Text(isVerifying ? "Verifying..." : "View Recovery Phrase")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color("NormaPastelTeal"))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(password.isEmpty || isVerifying)

            Spacer()
        }
    }

    // MARK: - Recovery Phrase View

    private func recoveryPhraseView(phrase: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "key.fill")
                .font(.system(size: 48))
                .foregroundColor(Color("NormaPastelTeal"))

            Text("Your Recovery Phrase")
                .font(.normaHeadline(20))

            Text("Write this down and store it in a safe place. You'll need it to recover your data if you forget your password.")
                .font(.normaHeadline(14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Recovery phrase display
            VStack(spacing: 12) {
                let words = phrase.split(separator: " ")
                let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                        HStack(spacing: 4) {
                            Text("\(index + 1).")
                                .font(.normaHeadline(12))
                                .foregroundColor(.secondary)
                                .frame(width: 20, alignment: .trailing)

                            Text(String(word))
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray.opacity(0.1))
                        )
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("NormaBackground"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )

            // Copy button
            Button(action: copyPhrase) {
                HStack {
                    Image(systemName: "doc.on.doc")
                    Text("Copy to Clipboard")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color("NormaPastelPurple").opacity(0.1))
                .foregroundColor(Color("NormaPastelPurple"))
                .cornerRadius(12)
            }

            Text("Never share your recovery phrase with anyone.")
                .font(.normaHeadline(12))
                .foregroundColor(.orange)

            Spacer()
        }
        .alert("Copied!", isPresented: $showCopiedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Recovery phrase copied to clipboard. Make sure to store it securely and clear your clipboard.")
        }
    }

    // MARK: - No Recovery Phrase View

    private var noRecoveryPhraseView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("No Recovery Phrase Found")
                .font(.normaHeadline(20))

            Text("Your account doesn't have a recovery phrase set up. This may happen if you signed up with Apple or Google, or if encryption wasn't enabled during signup.")
                .font(.normaHeadline(14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
    }

    // MARK: - Actions

    private func verifyPassword() {
        isVerifying = true
        errorMessage = nil

        Task {
            do {
                // Try to unlock encryption with the password
                try await dataManager.unlockEncryption(password: password)

                // If successful, get the recovery phrase
                if let userId = dataManager.currentProfile?.userId {
                    let userKeyManager = UserKeyManager(supabaseService: dataManager.supabaseService)
                    let phrase = userKeyManager.getRecoveryPhrase(for: userId)

                    await MainActor.run {
                        recoveryPhrase = phrase
                        isVerified = true
                        isVerifying = false
                    }
                } else {
                    await MainActor.run {
                        errorMessage = "Unable to retrieve user information"
                        isVerifying = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Incorrect password. Please try again."
                    isVerifying = false
                }
            }
        }
    }

    private func copyPhrase() {
        if let phrase = recoveryPhrase {
            UIPasteboard.general.string = phrase
            showCopiedAlert = true
        }
    }
}

#Preview {
    RecoveryPhraseSheet(dataManager: DataManager())
}
