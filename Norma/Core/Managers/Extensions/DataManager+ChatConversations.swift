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

    /// Fetch all conversations with decryption support
    /// Data is stored encrypted in the database; we decrypt locally using the master key
    func fetchAllConversationsWithEncryption(userId: String) async throws -> [ChatConversation] {
        guard let masterKey = getCurrentMasterKey() else {
            throw EncryptionError.noEncryptionKeys
        }

        // Fetches recent 8 by default
        let encryptableConversations = try await supabaseService.fetchEncryptableConversations(userId: userId)

        let conversations = encryptableConversations.compactMap { $0.toChatConversation(using: masterKey) }
        print("✅ Fetched \(conversations.count) conversations with encryption for user: \(userId)")
        return conversations
    }

    /// Fetch ALL conversations (for "See All" in chat menu)
    func fetchEveryConversationWithEncryption(userId: String) async throws -> [ChatConversation] {
        guard let masterKey = getCurrentMasterKey() else {
            throw EncryptionError.noEncryptionKeys
        }

        let encryptableConversations = try await supabaseService.fetchAllEncryptableConversations(userId: userId)

        let conversations = encryptableConversations.compactMap { $0.toChatConversation(using: masterKey) }
        print("✅ Fetched ALL \(conversations.count) conversations for user: \(userId)")
        return conversations
    }

    /// Fetch a single conversation with decryption support
    func fetchConversationWithEncryption(conversationId: String) async throws -> ChatConversation? {
        guard let masterKey = getCurrentMasterKey() else {
            throw EncryptionError.noEncryptionKeys
        }

        guard let encryptableConversation = try await supabaseService.fetchEncryptableConversation(conversationId: conversationId) else {
            return nil
        }

        // Decrypt locally for display
        let conversation = encryptableConversation.toChatConversation(using: masterKey)
        print("✅ Fetched conversation with encryption: \(conversationId)")
        return conversation
    }

    /// Create a new conversation via Edge Function (encrypts server-side)
    func createConversationWithEncryption(_ conversation: ChatConversation) async throws -> ChatConversation {
        guard let masterKey = getCurrentMasterKey() else {
            throw EncryptionError.noEncryptionKeys
        }

        // Send to Edge Function for encryption and storage
        let createdId = try await supabaseService.edgeFunctionService.createChatConversation(conversation, encryptionKey: masterKey)

        // Return conversation with new ID
        var createdConversation = conversation
        createdConversation.id = createdId

        print("✅ Created conversation via Edge Function: \(createdId)")
        return createdConversation
    }

    /// Update an existing conversation via Edge Function (encrypts server-side)
    func updateConversationWithEncryption(_ conversation: ChatConversation) async throws -> ChatConversation {
        guard let masterKey = getCurrentMasterKey() else {
            throw EncryptionError.noEncryptionKeys
        }

        // Send to Edge Function for encryption and update
        try await supabaseService.edgeFunctionService.updateChatConversation(conversation, encryptionKey: masterKey)

        print("✅ Updated conversation via Edge Function: \(conversation.id ?? "nil")")
        return conversation
    }
}
