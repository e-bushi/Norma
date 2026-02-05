//
//  EncryptableChatConversation.swift
//  Norma
//
//  Created by Claude on 1/30/25.
//

import Foundation
import CryptoKit

/// This model represents the raw chat conversation data from the database that may or may not be encrypted
struct EncryptableChatConversation: Identifiable, Codable {
    var id: String?
    let userId: String

    // Original fields (for backward compatibility)
    var title: String?
    var messages: [ChatMessage]

    // Encrypted fields (new)
    let encryptedTitle: String?
    let encryptedMessages: String?
    let isEncrypted: Bool

    // Other fields (remain unencrypted)
    var createdAt: String?
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case messages
        case encryptedTitle = "encrypted_title"
        case encryptedMessages = "encrypted_messages"
        case isEncrypted = "is_encrypted"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Custom decoder to handle missing encryption fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        messages = try container.decodeIfPresent([ChatMessage].self, forKey: .messages) ?? []
        encryptedTitle = try container.decodeIfPresent(String.self, forKey: .encryptedTitle)
        encryptedMessages = try container.decodeIfPresent(String.self, forKey: .encryptedMessages)
        isEncrypted = try container.decodeIfPresent(Bool.self, forKey: .isEncrypted) ?? false
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
    }

    init(
        id: String? = nil,
        userId: String,
        title: String? = nil,
        messages: [ChatMessage] = [],
        encryptedTitle: String? = nil,
        encryptedMessages: String? = nil,
        isEncrypted: Bool = false,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.messages = messages
        self.encryptedTitle = encryptedTitle
        self.encryptedMessages = encryptedMessages
        self.isEncrypted = isEncrypted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Convert to regular ChatConversation for display (decrypting if necessary)
    func toChatConversation(using masterKey: SymmetricKey?) -> ChatConversation? {
        let displayTitle: String?
        let displayMessages: [ChatMessage]

        if isEncrypted {
            // Decrypt the data
            guard let key = masterKey,
                  let encryptedMessages = encryptedMessages,
                  let decryptedMessages = decryptMessages(encryptedMessages, with: key) else {
                return nil
            }
            displayMessages = decryptedMessages

            // Title is optional - decrypt if present
            if let encryptedTitle = encryptedTitle {
                displayTitle = EncryptionService.shared.decrypt(encryptedTitle, with: key)
            } else {
                displayTitle = title
            }
        } else {
            // Use plain data
            displayTitle = title
            displayMessages = messages
        }

        return ChatConversation(
            id: id,
            userId: userId,
            title: displayTitle,
            messages: displayMessages,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// Decrypt messages from encrypted JSON string
    private func decryptMessages(_ encryptedString: String, with key: SymmetricKey) -> [ChatMessage]? {
        guard let decryptedJSON = EncryptionService.shared.decrypt(encryptedString, with: key),
              let jsonData = decryptedJSON.data(using: .utf8) else {
            return nil
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode([ChatMessage].self, from: jsonData)
        } catch {
            print("Failed to decode decrypted messages: \(error)")
            return nil
        }
    }
}

// MARK: - Extension to create EncryptableChatConversation from regular ChatConversation
extension ChatConversation {
    func toEncryptable(encrypt: Bool = false, using masterKey: SymmetricKey? = nil) -> EncryptableChatConversation? {
        if encrypt {
            guard let key = masterKey,
                  let encryptedMessages = encryptMessages(messages, with: key) else {
                return nil
            }

            // Encrypt title if present
            let encryptedTitle: String?
            if let title = title {
                encryptedTitle = EncryptionService.shared.encrypt(title, with: key)
            } else {
                encryptedTitle = nil
            }

            return EncryptableChatConversation(
                id: id,
                userId: userId,
                title: title, // Keep original for migration purposes
                messages: messages, // Keep original for migration purposes
                encryptedTitle: encryptedTitle,
                encryptedMessages: encryptedMessages,
                isEncrypted: true,
                createdAt: createdAt,
                updatedAt: updatedAt
            )
        } else {
            // Create unencrypted version
            return EncryptableChatConversation(
                id: id,
                userId: userId,
                title: title,
                messages: messages,
                encryptedTitle: nil,
                encryptedMessages: nil,
                isEncrypted: false,
                createdAt: createdAt,
                updatedAt: updatedAt
            )
        }
    }

    /// Encrypt messages to JSON string
    private func encryptMessages(_ messages: [ChatMessage], with key: SymmetricKey) -> String? {
        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(messages)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                return nil
            }
            return EncryptionService.shared.encrypt(jsonString, with: key)
        } catch {
            print("Failed to encode messages for encryption: \(error)")
            return nil
        }
    }
}

// MARK: - Insert/Update structs for Supabase operations

/// Struct for inserting new encrypted conversations - excludes server-generated fields
struct EncryptableChatConversationInsert: Codable {
    let userId: String
    var title: String?
    var messages: [ChatMessage]
    var encryptedTitle: String?
    var encryptedMessages: String?
    var isEncrypted: Bool

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case title
        case messages
        case encryptedTitle = "encrypted_title"
        case encryptedMessages = "encrypted_messages"
        case isEncrypted = "is_encrypted"
    }

    init(from conversation: EncryptableChatConversation) {
        self.userId = conversation.userId
        self.title = conversation.title
        self.messages = conversation.messages
        self.encryptedTitle = conversation.encryptedTitle
        self.encryptedMessages = conversation.encryptedMessages
        self.isEncrypted = conversation.isEncrypted
    }
}

/// Struct for updating encrypted conversations - only includes mutable fields
struct EncryptableChatConversationUpdate: Codable {
    var title: String?
    var messages: [ChatMessage]
    var encryptedTitle: String?
    var encryptedMessages: String?
    var isEncrypted: Bool
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case title
        case messages
        case encryptedTitle = "encrypted_title"
        case encryptedMessages = "encrypted_messages"
        case isEncrypted = "is_encrypted"
        case updatedAt = "updated_at"
    }

    init(from conversation: EncryptableChatConversation) {
        self.title = conversation.title
        self.messages = conversation.messages
        self.encryptedTitle = conversation.encryptedTitle
        self.encryptedMessages = conversation.encryptedMessages
        self.isEncrypted = conversation.isEncrypted
        self.updatedAt = ISO8601DateFormatter().string(from: Date())
    }
}

/// Struct for updating only the encryption fields of a conversation
struct ChatConversationEncryptionUpdate: Codable {
    var encryptedTitle: String?
    var encryptedMessages: String
    var isEncrypted: Bool
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case encryptedTitle = "encrypted_title"
        case encryptedMessages = "encrypted_messages"
        case isEncrypted = "is_encrypted"
        case updatedAt = "updated_at"
    }

    init(encryptedTitle: String?, encryptedMessages: String) {
        self.encryptedTitle = encryptedTitle
        self.encryptedMessages = encryptedMessages
        self.isEncrypted = true
        self.updatedAt = ISO8601DateFormatter().string(from: Date())
    }
}
