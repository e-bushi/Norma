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
}
