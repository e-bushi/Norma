//
//  EncryptableChatConversation.swift
//  Norma
//
//  Created by Claude on 1/30/25.
//  Updated: 2/6/26 - Simplified for Edge Function encryption architecture
//

import Foundation
import CryptoKit

/// Represents chat conversation data as stored in the database (encrypted)
/// - `title` contains encrypted ciphertext
/// - `messages` contains encrypted JSON string (the message array encrypted as a single ciphertext)
/// - Use `toChatConversation(using:)` to decrypt for display
struct EncryptableChatConversation: Identifiable, Codable {
    var id: String?
    let userId: String

    // Encrypted fields
    var title: String?         // encrypted title (ciphertext)
    var messages: String       // encrypted JSON array of messages (ciphertext)

    // Unencrypted fields
    var createdAt: String?
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case messages
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)

        // Messages can come as encrypted string or as JSON array (during migration)
        if let messagesString = try? container.decode(String.self, forKey: .messages) {
            messages = messagesString
        } else if let messagesArray = try? container.decode([ChatMessage].self, forKey: .messages) {
            // Legacy: encode array to JSON string for processing
            let encoder = JSONEncoder()
            if let jsonData = try? encoder.encode(messagesArray),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                messages = jsonString
            } else {
                messages = "[]"
            }
        } else {
            messages = "[]"
        }
    }

    init(
        id: String? = nil,
        userId: String,
        title: String? = nil,
        messages: String = "[]",
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Decrypt and convert to ChatConversation for display
    /// - Parameter masterKey: The user's master encryption key
    /// - Returns: Decrypted ChatConversation, or nil if decryption fails
    func toChatConversation(using masterKey: SymmetricKey) -> ChatConversation? {
        // Decrypt title if present
        let decryptedTitle = title.flatMap { EncryptionService.shared.decrypt($0, with: masterKey) }

        // Decrypt messages
        guard let decryptedMessagesJSON = EncryptionService.shared.decrypt(messages, with: masterKey),
              let jsonData = decryptedMessagesJSON.data(using: .utf8) else {
            return nil
        }

        do {
            let decoder = JSONDecoder()
            let decryptedMessages = try decoder.decode([ChatMessage].self, from: jsonData)

            return ChatConversation(
                id: id,
                userId: userId,
                title: decryptedTitle,
                messages: decryptedMessages,
                createdAt: createdAt,
                updatedAt: updatedAt
            )
        } catch {
            print("Failed to decode decrypted messages: \(error)")
            return nil
        }
    }
}

// Note: ChatConversationInsert and ChatConversationUpdate are defined in ChatConversation.swift
