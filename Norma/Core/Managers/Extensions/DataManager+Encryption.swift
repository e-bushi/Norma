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
        print("🔓 [DECRYPT-DEBUG] fetchUserProfile: START for userId='\(userId)'")

        guard let encryptableProfile = try await supabaseService.fetchEncryptableProfile(userId: userId) else {
            print("🔓 [DECRYPT-DEBUG] fetchUserProfile: ❌ No encryptable profile found in DB for userId='\(userId)'")
            return nil
        }

        print("🔓 [DECRYPT-DEBUG] fetchUserProfile: Raw EncryptableProfile — name.count=\(encryptableProfile.name.count), monthlyIncome.count=\(encryptableProfile.monthlyIncome?.count ?? 0), freedomFund.count=\(encryptableProfile.freedomFund?.count ?? 0), settings.count=\(encryptableProfile.settings?.count ?? 0), painPoint.count=\(encryptableProfile.painPoint?.count ?? 0)")

        // Try to decrypt with master key if available
        if let masterKey = UserKeyManager(supabaseService: supabaseService).getCurrentMasterKey(for: userId) {
            print("🔓 [DECRYPT-DEBUG] fetchUserProfile: Master key FOUND ✅ — attempting decryption...")
            if let decryptedProfile = encryptableProfile.toProfile(using: masterKey) {
                print("🔓 [DECRYPT-DEBUG] fetchUserProfile: ✅ DECRYPTED — name='\(decryptedProfile.name)', settings.income=\(decryptedProfile.settings.monthlyIncome), profile.income=\(decryptedProfile.monthlyIncome ?? 0), freedomFund=\(decryptedProfile.freedomFund ?? 0)")
                return decryptedProfile
            }

            // Decryption returned nil — data is likely plaintext (not yet encrypted)
            // Parse as plaintext and re-encrypt via Edge Function
            let plaintextProfile = encryptableProfile.toProfile()
            print("🔓 [DECRYPT-DEBUG] fetchUserProfile: Decryption returned nil — PLAINTEXT FALLBACK — name='\(plaintextProfile.name)', settings.income=\(plaintextProfile.settings.monthlyIncome), re-encrypting...")
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
        let fallbackProfile = encryptableProfile.toProfile()
        print("🔓 [DECRYPT-DEBUG] fetchUserProfile: ❌ NO MASTER KEY — returning plaintext fallback — name='\(fallbackProfile.name)', settings.income=\(fallbackProfile.settings.monthlyIncome), profile.income=\(fallbackProfile.monthlyIncome ?? 0)")
        return fallbackProfile
    }

    // MARK: - Migration Support

    /// Migration result counts
    struct MigrationCounts {
        let bills: Int
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
        print("   - Income: \(migrated.income)")
        print("   - Budgets: \(migrated.budgets)")
        print("   - Chat conversations: \(migrated.chatConversations)")
        print("   - Profiles: \(migrated.profiles)")

        // Refresh local data to get encrypted versions
        try await fetchBillsWithEncryption(userId: userId)

        print("✅ Successfully migrated all data to encrypted format")

        return MigrationCounts(
            bills: migrated.bills,
            income: migrated.income,
            budgets: migrated.budgets,
            chatConversations: migrated.chatConversations,
            profiles: migrated.profiles
        )
    }
}