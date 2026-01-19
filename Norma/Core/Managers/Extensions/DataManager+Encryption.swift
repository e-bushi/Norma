//
//  DataManager+Encryption.swift
//  Norma
//
//  Created by Claude on 7/28/25.
//

import Foundation
import CryptoKit

extension DataManager {
    
    // MARK: - Helper Methods (Used by all encryption extensions)
    
    /// Check if the current user has encryption enabled
    func hasEncryptionEnabled() async -> Bool {
        guard let userId = currentProfile?.userId else { return false }
        return await UserKeyManager(supabaseService: supabaseService).hasEncryptionEnabled(for: userId)
    }
    
    /// Get the current master key from keychain
    func getCurrentMasterKey() -> SymmetricKey? {
        guard let userId = currentProfile?.userId else { return nil }
        return UserKeyManager(supabaseService: supabaseService).getCurrentMasterKey(for: userId)
    }
    
    private var userKeyManager: UserKeyManager {
        UserKeyManager(supabaseService: supabaseService)
    }
    
    // MARK: - Encryption Setup & Management
    
    /// Setup encryption for a new user during signup
    func setupEncryption(password: String) async throws -> String {
        print("📍 [DEBUG] DataManager.setupEncryption: Starting...")
        
        guard let userId = currentProfile?.userId else {
            print("❌ [DEBUG] DataManager.setupEncryption: No current profile/userId")
            throw EncryptionError.noEncryptionKeys
        }
        
        print("📍 [DEBUG] DataManager.setupEncryption: userId = \(userId)")
        
        do {
            let (masterKey, recoveryPhrase) = try await userKeyManager.setupEncryption(
                for: userId,
                password: password
            )
            
            print("✅ [DEBUG] DataManager.setupEncryption: Encryption setup successful")
            return recoveryPhrase
        } catch {
            print("❌ [DEBUG] DataManager.setupEncryption: Failed with error: \(error)")
            throw error
        }
    }
    
    /// Unlock encryption for existing user during login
    func unlockEncryption(password: String) async throws {
        guard let userId = currentProfile?.userId else {
            throw EncryptionError.noEncryptionKeys
        }
        
        _ = try await userKeyManager.unlockEncryption(
            for: userId,
            password: password
        )
    }
    
    /// Clear encryption keys on logout
    func clearEncryptionKeys() {
        guard let userId = currentProfile?.userId else { return }
        userKeyManager.clearLocalKeys(for: userId)
    }
    
    // MARK: - Profile Settings Encryption
    
    /// Fetch user profile with decryption support
    func fetchUserProfileWithEncryption(userId: String) async throws -> Profile? {
        let hasEncryption = await hasEncryptionEnabled()
        
        if hasEncryption {
            let masterKey = getCurrentMasterKey()
            guard let encryptableProfile = try await supabaseService.fetchEncryptableProfile(userId: userId) else {
                return nil
            }
            
            // Convert to regular profile, decrypting if necessary
            return encryptableProfile.toProfile(using: masterKey)
        } else {
            // Use legacy path
            return try await supabaseService.fetchProfile(userId: userId)
        }
    }
    
    /// Update user profile with encryption support
    func updateUserProfileWithEncryption(_ profile: Profile) async throws -> Profile {
        let hasEncryption = await hasEncryptionEnabled()
        
        if hasEncryption, let masterKey = getCurrentMasterKey() {
            // Create encrypted version
            guard let encryptableProfile = profile.toEncryptable(encrypt: true, using: masterKey) else {
                throw EncryptionError.encryptionFailed
            }
            
            let updatedEncryptable = try await supabaseService.updateEncryptableProfile(encryptableProfile)
            
            // Convert back to regular profile for display
            guard let displayProfile = updatedEncryptable.toProfile(using: masterKey) else {
                throw EncryptionError.decryptionFailed
            }
            
            // Update local state
            currentProfile = displayProfile
            
            return displayProfile
        } else {
            // Use legacy path
            return try await supabaseService.updateProfile(profile)
        }
    }
    
    /// Create user profile with encryption support
    func createUserProfileWithEncryption(_ profile: Profile) async throws -> Profile {
        let hasEncryption = await hasEncryptionEnabled()
        
        if hasEncryption, let masterKey = getCurrentMasterKey() {
            // Create encrypted version
            guard let encryptableProfile = profile.toEncryptable(encrypt: true, using: masterKey) else {
                throw EncryptionError.encryptionFailed
            }
            
            let createdEncryptable = try await supabaseService.createEncryptableProfile(encryptableProfile)
            
            // Convert back to regular profile for display
            guard let displayProfile = createdEncryptable.toProfile(using: masterKey) else {
                throw EncryptionError.decryptionFailed
            }
            
            // Update local state
            currentProfile = displayProfile
            
            return displayProfile
        } else {
            // Use legacy path
            return try await supabaseService.createProfile(profile)
        }
    }
    
    /// Migrate existing profile settings to encrypted format
    func migrateProfileSettingsToEncryption() async throws {
        guard let userId = currentProfile?.userId,
              let masterKey = getCurrentMasterKey(),
              let currentProfile = currentProfile else {
            throw EncryptionError.noEncryptionKeys
        }
        
        // Encrypt the current profile settings
        guard let encryptableProfile = currentProfile.toEncryptable(encrypt: true, using: masterKey),
              let encryptedSettings = encryptableProfile.encryptedSettings else {
            throw EncryptionError.encryptionFailed
        }
        
        // Update on server
        try await supabaseService.updateProfileSettingsEncryption(
            userId: userId,
            encryptedSettings: encryptedSettings
        )
        
        print("Migrated profile settings to encrypted format")
        
        // Refresh to get encrypted version
        if let updatedProfile = try await fetchUserProfileWithEncryption(userId: userId) {
            self.currentProfile = updatedProfile
        }
    }
    
    // MARK: - Migration Support
    
    /// Migrate all user data to encrypted format
    func migrateAllDataToEncryption() async throws {
        print("📍 [DEBUG] DataManager.migrateAllDataToEncryption: Starting...")

        do {
            print("📍 [DEBUG] Migrating expenses...")
            try await migrateExpensesToEncryption()
            print("✅ [DEBUG] Expenses migrated")

            print("📍 [DEBUG] Migrating bills...")
            try await migrateBillsToEncryption()
            print("✅ [DEBUG] Bills migrated")

            print("📍 [DEBUG] Migrating profile settings...")
            try await migrateProfileSettingsToEncryption()
            print("✅ [DEBUG] Profile settings migrated")

            print("✅ Successfully migrated all data to encrypted format")
        } catch {
            print("❌ [DEBUG] Migration failed at some point: \(error)")
            throw error
        }
    }
}