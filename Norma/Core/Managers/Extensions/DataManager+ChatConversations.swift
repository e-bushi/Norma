//
//  DataManager+ChatConversations.swift
//  Norma
//
//  Created by Claude on 1/6/25.
//

import Foundation

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

    // MARK: - Legacy Methods (deprecated)

    /// Fetch chat conversation for the current user (returns most recent)
    @available(*, deprecated, message: "Use fetchAllConversations instead")
    func fetchChatConversation(userId: String) async throws -> ChatConversation? {
        return try await supabaseService.fetchChatConversation(userId: userId)
    }

    /// Save chat conversation
    @available(*, deprecated, message: "Use createConversation or updateConversation instead")
    func saveChatConversation(_ conversation: ChatConversation) async throws {
        do {
            let savedConversation = try await supabaseService.saveChatConversation(conversation)
            print("✅ Saved chat conversation with \(savedConversation.messages.count) messages")
        } catch {
            print("❌ Failed to save chat conversation: \(error.localizedDescription)")
            throw error
        }
    }

    /// Clear all messages in the chat conversation
    @available(*, deprecated, message: "Use deleteConversation instead")
    func clearChatConversation(userId: String) async throws {
        do {
            try await supabaseService.clearChatConversation(userId: userId)
            print("✅ Cleared chat conversation for user: \(userId)")
        } catch {
            print("❌ Failed to clear chat conversation: \(error.localizedDescription)")
            throw error
        }
    }

    /// Delete chat conversation by userId
    @available(*, deprecated, message: "Use deleteConversation(conversationId:) instead")
    func deleteChatConversation(userId: String) async throws {
        do {
            try await supabaseService.deleteChatConversation(userId: userId)
            print("✅ Deleted chat conversation for user: \(userId)")
        } catch {
            print("❌ Failed to delete chat conversation: \(error.localizedDescription)")
            throw error
        }
    }
}
