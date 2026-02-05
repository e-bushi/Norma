//
//  DataManager+ChatConversations.swift
//  Norma
//
//  Created by Claude on 1/6/25.
//

import Foundation
import CryptoKit

extension DataManager {

    // MARK: - Multi-Conversation Methods

    /// Fetch all conversations for a user, sorted by most recently updated
    func fetchAllConversations(userId: String) async throws -> [ChatConversation] {
        do {
            let conversations = try await supabaseService.fetchAllConversations(userId: userId)
            print("✅ Fetched \(conversations.count) conversations for user: \(userId)")
            return conversations
        } catch {
            print("❌ Failed to fetch conversations: \(error.localizedDescription)")
            throw error
        }
    }

    /// Fetch a single conversation by its ID
    func fetchConversation(conversationId: String) async throws -> ChatConversation? {
        do {
            let conversation = try await supabaseService.fetchConversation(conversationId: conversationId)
            print("✅ Fetched conversation: \(conversationId)")
            return conversation
        } catch {
            print("❌ Failed to fetch conversation: \(error.localizedDescription)")
            throw error
        }
    }

    /// Create a new conversation
    func createConversation(_ conversation: ChatConversation) async throws -> ChatConversation {
        do {
            let created = try await supabaseService.createConversation(conversation)
            print("✅ Created conversation: \(created.id)")
            return created
        } catch {
            print("❌ Failed to create conversation: \(error.localizedDescription)")
            throw error
        }
    }

    /// Update an existing conversation
    func updateConversation(_ conversation: ChatConversation) async throws -> ChatConversation {
        do {
            let updated = try await supabaseService.updateConversation(conversation)
            print("✅ Updated conversation: \(updated.id) with \(updated.messages.count) messages")
            return updated
        } catch {
            print("❌ Failed to update conversation: \(error.localizedDescription)")
            throw error
        }
    }

    /// Delete a conversation permanently by ID
    func deleteConversation(conversationId: String) async throws {
        do {
            try await supabaseService.deleteConversation(conversationId: conversationId)
            print("✅ Deleted conversation: \(conversationId)")
        } catch {
            print("❌ Failed to delete conversation: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Encryption Support Methods

    /// Fetch all conversations with encryption support
    func fetchAllConversationsWithEncryption(userId: String) async throws -> [ChatConversation] {
        let hasEncryption = await hasEncryptionEnabled()

        if hasEncryption {
            let masterKey = getCurrentMasterKey()
            let encryptableConversations = try await supabaseService.fetchEncryptableConversations(userId: userId)

            // Convert to regular conversations, decrypting if necessary
            let conversations = encryptableConversations.compactMap { $0.toChatConversation(using: masterKey) }
            print("✅ Fetched \(conversations.count) conversations with encryption for user: \(userId)")
            return conversations
        } else {
            // Use legacy path
            return try await fetchAllConversations(userId: userId)
        }
    }

    /// Fetch a single conversation with encryption support
    func fetchConversationWithEncryption(conversationId: String) async throws -> ChatConversation? {
        let hasEncryption = await hasEncryptionEnabled()

        if hasEncryption {
            let masterKey = getCurrentMasterKey()
            guard let encryptableConversation = try await supabaseService.fetchEncryptableConversation(conversationId: conversationId) else {
                return nil
            }

            // Convert to regular conversation, decrypting if necessary
            let conversation = encryptableConversation.toChatConversation(using: masterKey)
            print("✅ Fetched conversation with encryption: \(conversationId)")
            return conversation
        } else {
            // Use legacy path
            return try await fetchConversation(conversationId: conversationId)
        }
    }

    /// Create a new conversation with encryption support
    func createConversationWithEncryption(_ conversation: ChatConversation) async throws -> ChatConversation {
        let hasEncryption = await hasEncryptionEnabled()

        if hasEncryption, let masterKey = getCurrentMasterKey() {
            // Create encrypted version
            guard let encryptableConversation = conversation.toEncryptable(encrypt: true, using: masterKey) else {
                throw EncryptionError.encryptionFailed
            }

            let createdEncryptable = try await supabaseService.createEncryptableConversation(encryptableConversation)

            // Convert back to regular conversation for display
            guard let displayConversation = createdEncryptable.toChatConversation(using: masterKey) else {
                throw EncryptionError.decryptionFailed
            }

            print("✅ Created conversation with encryption: \(displayConversation.id ?? "nil")")
            return displayConversation
        } else {
            // Use legacy path
            return try await createConversation(conversation)
        }
    }

    /// Update an existing conversation with encryption support
    func updateConversationWithEncryption(_ conversation: ChatConversation) async throws -> ChatConversation {
        let hasEncryption = await hasEncryptionEnabled()

        if hasEncryption, let masterKey = getCurrentMasterKey() {
            // Create encrypted version
            guard let encryptableConversation = conversation.toEncryptable(encrypt: true, using: masterKey) else {
                throw EncryptionError.encryptionFailed
            }

            let updatedEncryptable = try await supabaseService.updateEncryptableConversation(encryptableConversation)

            // Convert back to regular conversation for display
            guard let displayConversation = updatedEncryptable.toChatConversation(using: masterKey) else {
                throw EncryptionError.decryptionFailed
            }

            print("✅ Updated conversation with encryption: \(displayConversation.id ?? "nil")")
            return displayConversation
        } else {
            // Use legacy path
            return try await updateConversation(conversation)
        }
    }

    /// Migrate all conversations to encrypted format
    func migrateConversationsToEncryption() async throws {
        guard let userId = currentProfile?.userId,
              let masterKey = getCurrentMasterKey() else {
            throw EncryptionError.noEncryptionKeys
        }

        // Fetch all unencrypted conversations
        let encryptableConversations = try await supabaseService.fetchEncryptableConversations(userId: userId)
        let unencryptedConversations = encryptableConversations.filter { !$0.isEncrypted }

        print("📍 [DEBUG] Found \(unencryptedConversations.count) unencrypted conversations to migrate")

        for conversation in unencryptedConversations {
            guard let conversationId = conversation.id else { continue }

            // Encrypt the title if present
            let encryptedTitle: String?
            if let title = conversation.title {
                encryptedTitle = EncryptionService.shared.encrypt(title, with: masterKey)
            } else {
                encryptedTitle = nil
            }

            // Encrypt messages
            guard let encryptedMessages = encryptMessages(conversation.messages, with: masterKey) else {
                print("❌ [DEBUG] Failed to encrypt messages for conversation: \(conversationId)")
                continue
            }

            // Update the conversation with encrypted data
            try await supabaseService.updateConversationEncryption(
                conversationId: conversationId,
                encryptedTitle: encryptedTitle,
                encryptedMessages: encryptedMessages
            )

            print("✅ [DEBUG] Migrated conversation: \(conversationId)")
        }

        print("✅ Migrated \(unencryptedConversations.count) conversations to encrypted format")
    }

    /// Encrypt messages to JSON string (helper for migration)
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
