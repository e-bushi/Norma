//
//  UserKeyManager.swift
//  Norma
//
//  Created by Claude on 7/28/25.
//

import Foundation
import CryptoKit

class UserKeyManager {
    private let supabaseService: SupabaseService
    private let encryptionService = EncryptionService.shared
    
    init(supabaseService: SupabaseService) {
        self.supabaseService = supabaseService
    }
    
    // MARK: - Check Encryption Status
    
    func hasEncryptionEnabled(for userId: String) async -> Bool {
        do {
            let keys = try await supabaseService.getUserEncryptionKeys(userId: userId)
            return keys != nil
        } catch {
            print("Failed to check encryption status: \(error)")
            return false
        }
    }
    
    // MARK: - Setup New User Encryption
    
    func setupEncryption(for userId: String, password: String) async throws -> (masterKey: SymmetricKey, recoveryPhrase: String) {
        print("📍 [DEBUG] UserKeyManager.setupEncryption: Starting for userId: \(userId)")
        
        // Generate master key and recovery phrase
        let masterKey = encryptionService.generateMasterKey()
        let recoveryPhrase = encryptionService.generateRecoveryPhrase()
        print("✅ [DEBUG] Generated master key and recovery phrase")
        
        // Derive keys from password and recovery phrase
        let passwordKey = encryptionService.deriveKeyFromPassword(password, userId: userId)
        let recoveryKey = encryptionService.deriveKeyFromRecoveryPhrase(recoveryPhrase)
        print("✅ [DEBUG] Derived keys from password and recovery phrase")
        
        // Encrypt master key with both
        guard let passwordEncryptedKey = encryptionService.encryptMasterKey(masterKey, with: passwordKey),
              let recoveryEncryptedKey = encryptionService.encryptMasterKey(masterKey, with: recoveryKey) else {
            print("❌ [DEBUG] Failed to encrypt master key")
            throw EncryptionError.encryptionFailed
        }
        print("✅ [DEBUG] Encrypted master key with both password and recovery keys")
        
        // Create recovery hint (first and last word)
        let words = recoveryPhrase.split(separator: "-")
        let hint = words.count >= 2 ? "Starts with '\(words.first!)' and ends with '\(words.last!)'" : nil
        
        // Store on server
        let encryptionKeys = UserEncryptionKeys(
            userId: userId,
            passwordEncryptedKey: passwordEncryptedKey,
            recoveryEncryptedKey: recoveryEncryptedKey,
            recoveryHint: hint,
            createdAt: nil,
            updatedAt: nil
        )
        
        print("📍 [DEBUG] About to store encryption keys on server...")
        do {
            let storedKeys = try await supabaseService.storeUserEncryptionKeys(encryptionKeys)
            print("✅ [DEBUG] Successfully stored encryption keys on server for user: \(storedKeys.userId)")
        } catch {
            print("❌ [DEBUG] Failed to store encryption keys: \(error)")
            throw error
        }
        
        // Store master key in keychain
        _ = KeychainHelper.storeMasterKey(masterKey, for: userId)
        
        // Store recovery hint in keychain (optional, for user convenience)
        if let hint = hint {
            _ = KeychainHelper.storeRecoveryPhraseHint(hint, for: userId)
        }
        
        return (masterKey, recoveryPhrase)
    }
    
    // MARK: - Login with Password
    
    func unlockEncryption(for userId: String, password: String) async throws -> SymmetricKey {
        // Check if we already have the key in keychain
        if let cachedKey = KeychainHelper.getMasterKey(for: userId) {
            return cachedKey
        }
        
        // Get encrypted keys from server
        guard let encryptionKeys = try await supabaseService.getUserEncryptionKeys(userId: userId) else {
            throw EncryptionError.noEncryptionKeys
        }
        
        // Derive password key and decrypt master key
        let passwordKey = encryptionService.deriveKeyFromPassword(password, userId: userId)
        guard let masterKey = encryptionService.decryptMasterKey(encryptionKeys.passwordEncryptedKey, with: passwordKey) else {
            throw EncryptionError.decryptionFailed
        }
        
        // Store in keychain for this session
        _ = KeychainHelper.storeMasterKey(masterKey, for: userId)
        
        return masterKey
    }
    
    // MARK: - Password Change
    
    func changePassword(for userId: String, oldPassword: String, newPassword: String) async throws {
        // Get current master key
        let masterKey = try await unlockEncryption(for: userId, password: oldPassword)
        
        // Get current encryption keys
        guard let currentKeys = try await supabaseService.getUserEncryptionKeys(userId: userId) else {
            throw EncryptionError.noEncryptionKeys
        }
        
        // Re-encrypt master key with new password
        let newPasswordKey = encryptionService.deriveKeyFromPassword(newPassword, userId: userId)
        guard let newPasswordEncryptedKey = encryptionService.encryptMasterKey(masterKey, with: newPasswordKey) else {
            throw EncryptionError.encryptionFailed
        }
        
        // Update on server
        let updatedKeys = UserEncryptionKeys(
            userId: userId,
            passwordEncryptedKey: newPasswordEncryptedKey,
            recoveryEncryptedKey: currentKeys.recoveryEncryptedKey,
            recoveryHint: currentKeys.recoveryHint,
            createdAt: currentKeys.createdAt,
            updatedAt: nil
        )
        
        try await supabaseService.updateUserEncryptionKeys(updatedKeys)
    }
    
    // MARK: - Account Recovery
    
    func recoverAccount(for userId: String, recoveryPhrase: String, newPassword: String) async throws -> SymmetricKey {
        // Get encrypted keys from server
        guard let encryptionKeys = try await supabaseService.getUserEncryptionKeys(userId: userId) else {
            throw EncryptionError.noEncryptionKeys
        }
        
        // Decrypt master key with recovery phrase
        let recoveryKey = encryptionService.deriveKeyFromRecoveryPhrase(recoveryPhrase)
        guard let masterKey = encryptionService.decryptMasterKey(encryptionKeys.recoveryEncryptedKey, with: recoveryKey) else {
            throw EncryptionError.invalidRecoveryPhrase
        }
        
        // Re-encrypt with new password
        let newPasswordKey = encryptionService.deriveKeyFromPassword(newPassword, userId: userId)
        guard let newPasswordEncryptedKey = encryptionService.encryptMasterKey(masterKey, with: newPasswordKey) else {
            throw EncryptionError.encryptionFailed
        }
        
        // Update on server
        let updatedKeys = UserEncryptionKeys(
            userId: userId,
            passwordEncryptedKey: newPasswordEncryptedKey,
            recoveryEncryptedKey: encryptionKeys.recoveryEncryptedKey,
            recoveryHint: encryptionKeys.recoveryHint,
            createdAt: encryptionKeys.createdAt,
            updatedAt: nil
        )
        
        try await supabaseService.updateUserEncryptionKeys(updatedKeys)
        
        // Store in keychain
        _ = KeychainHelper.storeMasterKey(masterKey, for: userId)
        
        return masterKey
    }
    
    // MARK: - Get Recovery Hint
    
    func getRecoveryHint(for userId: String) async throws -> String? {
        // Check keychain first
        if let hint = KeychainHelper.getRecoveryPhraseHint(for: userId) {
            return hint
        }
        
        // Get from server
        guard let encryptionKeys = try await supabaseService.getUserEncryptionKeys(userId: userId) else {
            throw EncryptionError.noEncryptionKeys
        }
        
        return encryptionKeys.recoveryHint
    }
    
    // MARK: - Recovery Phrase Storage
    
    func storeRecoveryPhrase(_ recoveryPhrase: String, for userId: String) {
        KeychainHelper.storeRecoveryPhrase(recoveryPhrase, for: userId)
    }
    
    func getRecoveryPhrase(for userId: String) -> String? {
        return KeychainHelper.getRecoveryPhrase(for: userId)
    }
    
    func hasStoredRecoveryPhrase(for userId: String) -> Bool {
        return KeychainHelper.getRecoveryPhrase(for: userId) != nil
    }
    
    // MARK: - Clear Keys (Logout)
    
    func clearLocalKeys(for userId: String) {
        KeychainHelper.clearAllKeys(for: userId)
    }
    
    // MARK: - Get Current Master Key
    
    func getCurrentMasterKey(for userId: String) -> SymmetricKey? {
        return KeychainHelper.getMasterKey(for: userId)
    }
}

// MARK: - Encryption Errors

enum EncryptionError: LocalizedError {
    case encryptionFailed
    case decryptionFailed
    case noEncryptionKeys
    case invalidRecoveryPhrase
    case keychainError
    
    var errorDescription: String? {
        switch self {
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data. Please check your password."
        case .noEncryptionKeys:
            return "No encryption keys found for this user"
        case .invalidRecoveryPhrase:
            return "Invalid recovery phrase"
        case .keychainError:
            return "Failed to access secure storage"
        }
    }
}