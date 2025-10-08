//
//  SupabaseService+ChatConversations.swift
//  Norma
//
//  Created by Claude on 1/6/25.
//

import Foundation
import Supabase

extension SupabaseService {

    // MARK: - Chat Conversations Methods

    /// Fetch chat conversation for a user
    func fetchChatConversation(userId: String) async throws -> ChatConversation? {
        let response: [ChatConversation] = try await from("chat_conversations")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value

        return response.first
    }

    /// Save or update chat conversation
    func saveChatConversation(_ conversation: ChatConversation) async throws -> ChatConversation {
        // Try to fetch existing conversation
        let existing = try await fetchChatConversation(userId: conversation.userId)

        if existing != nil {
            // Update existing conversation
            let response: ChatConversation = try await from("chat_conversations")
                .update(conversation)
                .eq("user_id", value: conversation.userId)
                .select()
                .single()
                .execute()
                .value

            return response
        } else {
            // Insert new conversation
            let response: ChatConversation = try await from("chat_conversations")
                .insert(conversation)
                .select()
                .single()
                .execute()
                .value

            return response
        }
    }

    /// Clear chat conversation for a user
    func clearChatConversation(userId: String) async throws {
        // Update the conversation with empty messages array
        let emptyConversation = ChatConversation(userId: userId, messages: [])
        _ = try await saveChatConversation(emptyConversation)
    }

    /// Delete chat conversation entirely
    func deleteChatConversation(userId: String) async throws {
        try await from("chat_conversations")
            .delete()
            .eq("user_id", value: userId)
            .execute()
    }
}
