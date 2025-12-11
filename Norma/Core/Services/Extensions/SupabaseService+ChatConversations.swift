//
//  SupabaseService+ChatConversations.swift
//  Norma
//
//  Created by Claude on 1/6/25.
//

import Foundation
import Supabase

extension SupabaseService {

    // MARK: - Multi-Conversation Methods

    /// Fetch all conversations for a user, sorted by most recently updated
    func fetchAllConversations(userId: String) async throws -> [ChatConversation] {
        let response: [ChatConversation] = try await from("chat_conversations")
            .select()
            .eq("user_id", value: userId)
            .order("updated_at", ascending: false)
            .execute()
            .value

        return response
    }

    /// Fetch a single conversation by its ID
    func fetchConversation(conversationId: String) async throws -> ChatConversation? {
        let response: [ChatConversation] = try await from("chat_conversations")
            .select()
            .eq("id", value: conversationId)
            .execute()
            .value

        return response.first
    }

    /// Create a new conversation
    func createConversation(_ conversation: ChatConversation) async throws -> ChatConversation {
        let response: ChatConversation = try await from("chat_conversations")
            .insert(conversation)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    /// Update an existing conversation (messages, title, updatedAt)
    func updateConversation(_ conversation: ChatConversation) async throws -> ChatConversation {
        // Create updated conversation with current timestamp
        var updatedConversation = conversation
        updatedConversation.updatedAt = ISO8601DateFormatter().string(from: Date())

        let response: ChatConversation = try await from("chat_conversations")
            .update(updatedConversation)
            .eq("id", value: conversation.id)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    /// Delete a conversation permanently by ID
    func deleteConversation(conversationId: String) async throws {
        try await from("chat_conversations")
            .delete()
            .eq("id", value: conversationId)
            .execute()
    }

    // MARK: - Legacy Methods (for backward compatibility)

    /// Fetch chat conversation for a user (returns most recent)
    @available(*, deprecated, message: "Use fetchAllConversations instead")
    func fetchChatConversation(userId: String) async throws -> ChatConversation? {
        let conversations = try await fetchAllConversations(userId: userId)
        return conversations.first
    }

    /// Save or update chat conversation
    @available(*, deprecated, message: "Use createConversation or updateConversation instead")
    func saveChatConversation(_ conversation: ChatConversation) async throws -> ChatConversation {
        // Check if conversation exists by ID
        let existing = try await fetchConversation(conversationId: conversation.id)

        if existing != nil {
            return try await updateConversation(conversation)
        } else {
            return try await createConversation(conversation)
        }
    }

    /// Clear chat conversation for a user
    @available(*, deprecated, message: "Use deleteConversation instead")
    func clearChatConversation(userId: String) async throws {
        let conversations = try await fetchAllConversations(userId: userId)
        for conversation in conversations {
            try await deleteConversation(conversationId: conversation.id)
        }
    }

    /// Delete chat conversation by userId
    @available(*, deprecated, message: "Use deleteConversation(conversationId:) instead")
    func deleteChatConversation(userId: String) async throws {
        try await from("chat_conversations")
            .delete()
            .eq("user_id", value: userId)
            .execute()
    }
}
