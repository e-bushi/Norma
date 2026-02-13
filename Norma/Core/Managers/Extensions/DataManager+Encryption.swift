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
    
    // MARK: - Profile Operations

    /// Fetch user profile with decryption support
    /// Automatically re-encrypts plaintext profile data when a master key is available
    func fetchUserProfile(userId: String) async throws -> Profile? {
        guard let encryptableProfile = try await supabaseService.fetchEncryptableProfile(userId: userId) else {
            print("⚠️ fetchUserProfile: No encryptable profile found for userId: \(userId)")
            return nil
        }

        // Try to decrypt with master key if available
        if let masterKey = UserKeyManager(supabaseService: supabaseService).getCurrentMasterKey(for: userId) {
            if let decryptedProfile = encryptableProfile.toProfile(using: masterKey) {
                print("✅ fetchUserProfile: Decrypted profile - name: \(decryptedProfile.name), settings.income: \(decryptedProfile.settings.monthlyIncome), profile.income: \(decryptedProfile.monthlyIncome ?? 0)")
                return decryptedProfile
            }

            // Decryption returned nil — data is likely plaintext (not yet encrypted)
            // Parse as plaintext and re-encrypt via Edge Function
            let plaintextProfile = encryptableProfile.toProfile()
            print("🔐 Profile data appears unencrypted — re-encrypting...")
            Task {
                do {
                    try await supabaseService.edgeFunctionService.updateProfile(plaintextProfile, encryptionKey: masterKey)
                    print("✅ Profile re-encrypted successfully")
                } catch {
                    print("⚠️ Failed to re-encrypt profile: \(error)")
                }
            }
            return plaintextProfile
        }

        // No master key available — cannot decrypt
        print("⚠️ fetchUserProfile: No master key found in keychain for userId: \(userId)")
        return encryptableProfile.toProfile()
    }

    // MARK: - Migration Support

    /// Migration result counts
    struct MigrationCounts {
        let bills: Int
        let expenses: Int
        let income: Int
        let budgets: Int
        let chatConversations: Int
        let profiles: Int
    }

    /// Migrate all user data to encrypted format via Edge Function
    /// This calls the Edge Function's migrate endpoint which encrypts all existing data
    /// - Returns: Counts of migrated records by type
    func migrateAllDataToEncryption() async throws -> MigrationCounts {
        print("📍 [DEBUG] DataManager.migrateAllDataToEncryption: Starting...")

        guard let userId = currentProfile?.userId,
              let masterKey = getCurrentMasterKey() else {
            throw EncryptionError.noEncryptionKeys
        }

        // Call Edge Function to migrate all data
        let migrated = try await supabaseService.edgeFunctionService.migrateAllData(
            userId: userId,
            encryptionKey: masterKey
        )

        print("✅ Migration complete:")
        print("   - Bills: \(migrated.bills)")
        print("   - Expenses: \(migrated.expenses)")
        print("   - Income: \(migrated.income)")
        print("   - Budgets: \(migrated.budgets)")
        print("   - Chat conversations: \(migrated.chatConversations)")
        print("   - Profiles: \(migrated.profiles)")

        // Refresh local data to get encrypted versions
        try await fetchBillsWithEncryption(userId: userId)
        try await fetchExpensesWithEncryption(userId: userId)

        print("✅ Successfully migrated all data to encrypted format")

        return MigrationCounts(
            bills: migrated.bills,
            expenses: migrated.expenses,
            income: migrated.income,
            budgets: migrated.budgets,
            chatConversations: migrated.chatConversations,
            profiles: migrated.profiles
        )
    }
}