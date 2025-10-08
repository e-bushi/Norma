//
//  DataManager+ChatConversations.swift
//  Norma
//
//  Created by Claude on 1/6/25.
//

import Foundation

extension DataManager {

    // MARK: - Chat Conversation Methods

    /// Fetch chat conversation for the current user
    func fetchChatConversation(userId: String) async throws -> ChatConversation? {
        return try await supabaseService.fetchChatConversation(userId: userId)
    }

    /// Save chat conversation
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
    func clearChatConversation(userId: String) async throws {
        do {
            try await supabaseService.clearChatConversation(userId: userId)
            print("✅ Cleared chat conversation for user: \(userId)")
        } catch {
            print("❌ Failed to clear chat conversation: \(error.localizedDescription)")
            throw error
        }
    }

    /// Delete chat conversation entirely
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
