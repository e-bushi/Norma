//
//  EncryptionService.swift
//  Norma
//
//  Created by Claude on 7/28/25.
//

import Foundation
import CryptoKit

class EncryptionService {
    static let shared = EncryptionService()
    
    private init() {}
    
    // MARK: - Key Management
    
    func generateMasterKey() -> SymmetricKey {
        SymmetricKey(size: .bits256)
    }
    
    func generateRecoveryPhrase() -> String {
        // Generate 12-word recovery phrase
        let words = [
            "apple", "banana", "cherry", "dog", "elephant", "forest",
            "guitar", "house", "island", "jungle", "kitten", "lemon",
            "mountain", "needle", "ocean", "piano", "queen", "river",
            "sunset", "table", "umbrella", "village", "water", "yellow",
            "zebra", "anchor", "bridge", "castle", "desert", "eagle"
        ]
        
        return (0..<12).map { _ in words.randomElement()! }.joined(separator: "-")
    }
    
    // MARK: - Key Derivation
    
    func deriveKeyFromPassword(_ password: String, userId: String) -> SymmetricKey {
        let salt = userId.data(using: .utf8)!
        let passwordData = password.data(using: .utf8)!
        
        let derivedKey = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: passwordData),
            salt: salt,
            outputByteCount: 32
        )
        
        return derivedKey
    }
    
    func deriveKeyFromRecoveryPhrase(_ recoveryPhrase: String) -> SymmetricKey {
        let phraseData = recoveryPhrase.data(using: .utf8)!
        let hash = SHA256.hash(data: phraseData)
        return SymmetricKey(data: hash)
    }
    
    // MARK: - Master Key Encryption
    
    func encryptMasterKey(_ masterKey: SymmetricKey, with derivedKey: SymmetricKey) -> String? {
        let masterKeyData = masterKey.withUnsafeBytes { Data($0) }
        
        do {
            let sealedBox = try AES.GCM.seal(masterKeyData, using: derivedKey)
            return sealedBox.combined?.base64EncodedString()
        } catch {
            print("Failed to encrypt master key: \(error)")
            return nil
        }
    }
    
    func decryptMasterKey(_ encryptedKey: String, with derivedKey: SymmetricKey) -> SymmetricKey? {
        guard let data = Data(base64Encoded: encryptedKey) else { return nil }
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decryptedData = try AES.GCM.open(sealedBox, using: derivedKey)
            return SymmetricKey(data: decryptedData)
        } catch {
            print("Failed to decrypt master key: \(error)")
            return nil
        }
    }
    
    // MARK: - Data Encryption
    
    func encrypt(_ plaintext: String, with key: SymmetricKey) -> String? {
        guard let data = plaintext.data(using: .utf8) else { return nil }
        
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined?.base64EncodedString()
        } catch {
            print("Encryption failed: \(error)")
            return nil
        }
    }
    
    func decrypt(_ ciphertext: String, with key: SymmetricKey) -> String? {
        guard let data = Data(base64Encoded: ciphertext) else { return nil }
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return String(data: decryptedData, encoding: .utf8)
        } catch {
            print("Decryption failed: \(error)")
            return nil
        }
    }
    
    // MARK: - Amount Encryption
    
    func encryptAmount(_ amount: Double, with key: SymmetricKey) -> String? {
        let amountString = String(amount)
        return encrypt(amountString, with: key)
    }
    
    func decryptAmount(_ encryptedAmount: String, with key: SymmetricKey) -> Double? {
        guard let decryptedString = decrypt(encryptedAmount, with: key),
              let amount = Double(decryptedString) else {
            return nil
        }
        return amount
    }
}