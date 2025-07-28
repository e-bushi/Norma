//
//  KeychainHelper.swift
//  Norma
//
//  Created by Claude on 7/28/25.
//

import Foundation
import CryptoKit

class KeychainHelper {
    static let masterKeyAccount = "norma_master_encryption_key"
    static let recoveryPhraseAccount = "norma_recovery_phrase"
    
    // MARK: - Master Key Storage
    
    static func storeMasterKey(_ key: SymmetricKey, for userId: String) -> Bool {
        let keyData = key.withUnsafeBytes { Data($0) }
        let account = "\(masterKeyAccount)_\(userId)"
        
        // Delete any existing key first
        deleteMasterKey(for: userId)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrLabel as String: "Norma Encryption Key"
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    static func getMasterKey(for userId: String) -> SymmetricKey? {
        let account = "\(masterKeyAccount)_\(userId)"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess,
              let keyData = dataTypeRef as? Data else {
            return nil
        }
        
        return SymmetricKey(data: keyData)
    }
    
    static func deleteMasterKey(for userId: String) -> Bool {
        let account = "\(masterKeyAccount)_\(userId)"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Recovery Phrase Storage (Optional - for user convenience)
    
    static func storeRecoveryPhraseHint(_ hint: String, for userId: String) -> Bool {
        let account = "\(recoveryPhraseAccount)_\(userId)"
        let hintData = hint.data(using: .utf8)!
        
        // Delete any existing hint first
        deleteRecoveryPhraseHint(for: userId)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecValueData as String: hintData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrLabel as String: "Norma Recovery Phrase Hint"
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    static func getRecoveryPhraseHint(for userId: String) -> String? {
        let account = "\(recoveryPhraseAccount)_\(userId)"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess,
              let hintData = dataTypeRef as? Data,
              let hint = String(data: hintData, encoding: .utf8) else {
            return nil
        }
        
        return hint
    }
    
    static func deleteRecoveryPhraseHint(for userId: String) -> Bool {
        let account = "\(recoveryPhraseAccount)_\(userId)"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Recovery Phrase Storage
    
    static func storeRecoveryPhrase(_ phrase: String, for userId: String) -> Bool {
        let account = "\(recoveryPhraseAccount)_\(userId)"
        let phraseData = phrase.data(using: .utf8)!
        
        // Delete any existing phrase first
        deleteRecoveryPhrase(for: userId)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecValueData as String: phraseData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrLabel as String: "Norma Recovery Phrase"
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    static func getRecoveryPhrase(for userId: String) -> String? {
        let account = "\(recoveryPhraseAccount)_\(userId)"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess,
              let phraseData = dataTypeRef as? Data,
              let phrase = String(data: phraseData, encoding: .utf8) else {
            return nil
        }
        
        return phrase
    }
    
    static func deleteRecoveryPhrase(for userId: String) -> Bool {
        let account = "\(recoveryPhraseAccount)_\(userId)"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Clear All Keys
    
    static func clearAllKeys(for userId: String) {
        _ = deleteMasterKey(for: userId)
        _ = deleteRecoveryPhraseHint(for: userId)
        _ = deleteRecoveryPhrase(for: userId)
    }
}