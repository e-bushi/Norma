//
//  UserEncryptionKeys.swift
//  Norma
//
//  Created by Claude on 7/28/25.
//

import Foundation

struct UserEncryptionKeys: Codable {
    let userId: String
    let passwordEncryptedKey: String
    let recoveryEncryptedKey: String
    let recoveryHint: String?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case passwordEncryptedKey = "password_encrypted_key"
        case recoveryEncryptedKey = "recovery_encrypted_key"
        case recoveryHint = "recovery_hint"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}