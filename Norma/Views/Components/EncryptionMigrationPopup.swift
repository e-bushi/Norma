//
//  EncryptionMigrationPopup.swift
//  Norma
//
//  Created by Claude on 7/28/25.
//

import SwiftUI

struct EncryptionMigrationPopup: View {
    @Binding var isPresented: Bool
    let onMigrate: (String) async throws -> Void  // Pass password to migration (can throw)
    let onDismiss: () -> Void
    let userEmail: String  // User's email for verification
    
    @EnvironmentObject var sessionViewModel: SessionViewModel
    
    @State private var migrationState: MigrationState = .initial
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var errorMessage: String = ""
    
    enum MigrationState {
        case initial
        case passwordEntry
        case loading
        case success
        case error
    }
    
    var body: some View {
        InformationalPopup(
            isPresented: $isPresented,
            config: configForCurrentState(),
            onPrimaryAction: {
                switch migrationState {
                case .initial:
                    moveToPasswordEntry()
                case .passwordEntry:
                    verifyPasswordAndMigrate()
                case .loading:
                    break // Do nothing during loading
                case .success:
                    isPresented = false
                case .error:
                    resetToPasswordEntry()
                }
            },
            onSecondaryAction: migrationState == .initial || migrationState == .passwordEntry ? onDismiss : nil,
            onDismiss: migrationState == .loading ? {} : { isPresented = false }
        )
    }
    
    private func configForCurrentState() -> PopupConfig {
        switch migrationState {
        case .initial:
            return .encryptionMigration(onMigrate: {}, onDismiss: onDismiss)
        case .passwordEntry:
            return .encryptionPasswordEntry(password: $password, isPasswordVisible: $isPasswordVisible, errorMessage: errorMessage)
        case .loading:
            return .encryptionMigrationLoading()
        case .success:
            return .encryptionMigrationSuccess()
        case .error:
            return .encryptionMigrationError(errorMessage: errorMessage)
        }
    }
    
    private func moveToPasswordEntry() {
        withAnimation(.easeInOut(duration: 0.3)) {
            migrationState = .passwordEntry
            errorMessage = ""
            password = ""
        }
    }
    
    private func verifyPasswordAndMigrate() {
        guard !password.isEmpty else {
            showError("Please enter your password")
            return
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            migrationState = .loading
        }
        
        Task {
            do {
                // 1. Verify password by signing in (creates new session)
                _ = try await SupabaseService.shared.signIn(email: userEmail, password: password)
                
                // 2. Refresh session state for new session
                await sessionViewModel.fetchUserProfile()
                
                // 3. Proceed with migration using verified password
                try await onMigrate(password)
                
                // 4. Show success state
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        migrationState = .success
                    }
                }
            } catch {
                await MainActor.run {
                    // Check if it's a password error or migration error
                    if error.localizedDescription.contains("Invalid login credentials") {
                        showError("Incorrect password. Please try again.")
                    } else {
                        showError("Migration failed: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func resetToPasswordEntry() {
        withAnimation(.easeInOut(duration: 0.3)) {
            migrationState = .passwordEntry
            password = ""
            errorMessage = ""
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        withAnimation(.easeInOut(duration: 0.3)) {
            migrationState = .error
        }
        
        // Auto-return to password entry after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            resetToPasswordEntry()
        }
    }
}

// MARK: - Preview

#Preview {
    EncryptionMigrationPopup(
        isPresented: .constant(true),
        onMigrate: { password in
            print("User chose to migrate with password: \(password)")
            // Simulate migration success for preview
        },
        onDismiss: {
            print("User dismissed popup")
        },
        userEmail: "user@example.com"
    )
    .environmentObject(SessionViewModel(dataManager: DataManager()))
    .preferredColorScheme(.dark)
}