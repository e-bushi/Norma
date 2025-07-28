//
//  RecoveryPhraseView.swift
//  Norma
//
//  Created by Claude on 7/28/25.
//

import SwiftUI

struct RecoveryPhraseView: View {
    let userId: String
    @Environment(\.dismiss) private var dismiss
    @State private var recoveryPhrase: String = ""
    @State private var isLoading = true
    @State private var showCopyConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if isLoading {
                    // Loading state
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading recovery phrase...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.1))
                                        .frame(width: 60, height: 60)
                                    
                                    Image(systemName: "key.fill")
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(.blue)
                                }
                                
                                Text("Recovery Phrase")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Text("Keep this phrase safe and secure. You'll need it to restore your account if you lose access.")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top)
                            
                            // Recovery phrase display
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Your Recovery Phrase")
                                        .font(.headline)
                                    Spacer()
                                }
                                
                                VStack(spacing: 12) {
                                    Text(recoveryPhrase)
                                        .font(.system(.body, design: .monospaced))
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(UIColor.secondarySystemBackground))
                                        .cornerRadius(8)
                                        .textSelection(.enabled)
                                    
                                    Button(action: copyToClipboard) {
                                        HStack {
                                            Image(systemName: showCopyConfirmation ? "checkmark" : "doc.on.doc")
                                            Text(showCopyConfirmation ? "Copied!" : "Copy to Clipboard")
                                        }
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(showCopyConfirmation ? Color.green : Color.blue)
                                        .cornerRadius(8)
                                    }
                                    .disabled(showCopyConfirmation)
                                }
                            }
                            
                            // Security warning
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text("Important Security Notice")
                                        .font(.headline)
                                        .foregroundColor(.orange)
                                    Spacer()
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    SecurityWarningRow(
                                        icon: "eye.slash.fill",
                                        text: "Never share this phrase with anyone"
                                    )
                                    SecurityWarningRow(
                                        icon: "wifi.slash",
                                        text: "Don't store it online or in unsecured locations"
                                    )
                                    SecurityWarningRow(
                                        icon: "doc.text.fill",
                                        text: "Write it down and store it in a safe place"
                                    )
                                    SecurityWarningRow(
                                        icon: "key.fill",
                                        text: "This phrase can restore full access to your account"
                                    )
                                }
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                            
                            Spacer(minLength: 40)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Recovery Phrase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadRecoveryPhrase()
            }
        }
    }
    
    private func loadRecoveryPhrase() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let userKeyManager = UserKeyManager(supabaseService: SupabaseService.shared)
            if let phrase = userKeyManager.getRecoveryPhrase(for: userId) {
                recoveryPhrase = phrase
            } else {
                recoveryPhrase = "Recovery phrase not found"
            }
            isLoading = false
        }
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = recoveryPhrase
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showCopyConfirmation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showCopyConfirmation = false
            }
        }
    }
}

struct SecurityWarningRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .frame(width: 16)
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    RecoveryPhraseView(userId: "test-user-id")
}