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
        // Note: user_id is UUID type, so case doesn't matter
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
        print("🔍 [SupabaseService] Creating conversation...")
        print("🔍 [SupabaseService] User ID in conversation: \(conversation.userId)")
        print("🔍 [SupabaseService] Authenticated user (currentUser): \(currentUser != nil ? "EXISTS" : "NIL")")
        print("🔍 [SupabaseService] Authenticated user ID (UUID): \(currentUser?.id.uuidString ?? "nil")")
        print("🔍 [SupabaseService] Authenticated user ID (lowercase): \(currentUser?.id.uuidString.lowercased() ?? "nil")")
        print("🔍 [SupabaseService] Current session exists: \(currentSession != nil ? "YES" : "NO")")
        print("🔍 [SupabaseService] IDs match (exact): \(conversation.userId == currentUser?.id.uuidString)")
        print("🔍 [SupabaseService] IDs match (case-insensitive): \(conversation.userId.lowercased() == currentUser?.id.uuidString.lowercased())")
        print("🔍 [SupabaseService] Title: \(conversation.title ?? "nil")")
        print("🔍 [SupabaseService] Message count: \(conversation.messages.count)")

        // Use ChatConversationInsert to exclude server-generated fields (id, created_at, updated_at)
        let insertData = ChatConversationInsert(from: conversation)

        // Debug: Try encoding to see what will be sent
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(insertData)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("🔍 [SupabaseService] INSERT JSON (using ChatConversationInsert - no id/created_at/updated_at):")
                print("--- BEGIN JSON ---")
                print(jsonString)
                print("--- END JSON ---")
            }
        } catch {
            print("❌ [SupabaseService] JSON encoding failed: \(error)")
            throw error
        }

        // Insert using ChatConversationInsert (excludes id, created_at, updated_at - Supabase generates them)
        do {
            let response: ChatConversation = try await from("chat_conversations")
                .insert(insertData)
                .select()
                .single()
                .execute()
                .value

            print("✅ [SupabaseService] Successfully created conversation: \(response.id ?? "nil")")
            return response
        } catch {
            print("❌ [SupabaseService] Create conversation failed: \(error)")
            print("❌ [SupabaseService] Error details: \(String(describing: error))")
            throw error
        }
    }

    /// Update an existing conversation (messages, title, updatedAt)
    func updateConversation(_ conversation: ChatConversation) async throws -> ChatConversation {
        guard let conversationId = conversation.id else {
            throw NSError(domain: "SupabaseService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Cannot update conversation without ID"])
        }

        // Create update struct (only mutable fields - excludes id, user_id, created_at)
        let updateData = ChatConversationUpdate(from: conversation)

        print("🔍 [SupabaseService] Updating conversation...")
        print("🔍 [SupabaseService] Conversation ID: \(conversationId)")
        print("🔍 [SupabaseService] Message count: \(updateData.messages.count)")
        print("🔍 [SupabaseService] Title: \(updateData.title ?? "nil")")

        // Debug: Try encoding to verify data structure
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(updateData)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("🔍 [SupabaseService] UPDATE JSON (only mutable fields):")
                print("--- BEGIN JSON ---")
                print(String(jsonString.prefix(1000)))
                print("--- END JSON ---")
            }
        } catch {
            print("❌ [SupabaseService] JSON encoding failed for update: \(error)")
            throw error
        }

        do {
            let response: ChatConversation = try await from("chat_conversations")
                .update(updateData)
                .eq("id", value: conversationId)
                .select()
                .single()
                .execute()
                .value

            print("✅ [SupabaseService] Successfully updated conversation: \(response.id ?? "nil")")
            return response
        } catch {
            print("❌ [SupabaseService] Update conversation failed: \(error)")
            print("❌ [SupabaseService] Error details: \(String(describing: error))")
            throw error
        }
    }

    /// Delete a conversation permanently by ID
    func deleteConversation(conversationId: String) async throws {
        try await from("chat_conversations")
            .delete()
            .eq("id", value: conversationId)
            .execute()
    }
}
