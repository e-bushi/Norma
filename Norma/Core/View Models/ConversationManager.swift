//
//  ConversationManager.swift
//  Norma
//
//  Created by Claude on 12/10/24.
//

import Foundation
import Combine

@MainActor
class ConversationManager: ObservableObject {

    // MARK: - Published Properties

    @Published var conversations: [ChatConversation] = []
    @Published var currentConversation: ChatConversation?
    @Published var currentMessages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var error: Error?

    /// Tracks message IDs that were added during the current session (should animate)
    @Published var newlyAddedMessageIds: Set<String> = []

    // MARK: - Dependencies

    private let dataManager: DataManager
    private let sessionViewModel: SessionViewModel

    // MARK: - Initialization

    init(dataManager: DataManager, sessionViewModel: SessionViewModel) {
        self.dataManager = dataManager
        self.sessionViewModel = sessionViewModel
    }

    // MARK: - Conversation Loading

    /// Load all conversations for the current user
    func loadConversations() async {
        guard let userId = sessionViewModel.currentUser?.userId else {
            print("❌ ConversationManager: No userId found in sessionViewModel.currentUser")
            return
        }

        isLoading = true
        error = nil

        do {
            conversations = try await dataManager.fetchAllConversationsWithEncryption(userId: userId)

            // Don't auto-select a conversation - app should start with empty state (new conversation)

            print("✅ ConversationManager: Loaded \(conversations.count) conversations")
        } catch {
            self.error = error
            print("❌ ConversationManager: Failed to load conversations: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Load all conversations (triggered by "See All")
    func loadAllConversations() async {
        guard let userId = sessionViewModel.currentUser?.userId else { return }

        isLoading = true
        do {
            conversations = try await dataManager.fetchEveryConversationWithEncryption(userId: userId)
            print("✅ ConversationManager: Loaded all \(conversations.count) conversations")
        } catch {
            self.error = error
            print("❌ ConversationManager: Failed to load all conversations: \(error.localizedDescription)")
        }
        isLoading = false
    }

    // MARK: - Conversation Creation

    /// Create a new conversation and set it as current
    func createNewConversation() -> ChatConversation {
        guard let userId = sessionViewModel.currentUser?.userId else {
            fatalError("ConversationManager: No userId found in sessionViewModel.currentUser")
        }

        let newConversation = ChatConversation(
            userId: userId,
            title: nil,
            messages: []
        )

        currentConversation = newConversation
        currentMessages = []
        newlyAddedMessageIds = []  // Fresh conversation

        // Add to local list (will be persisted on first message)
        conversations.insert(newConversation, at: 0)

        print("✅ ConversationManager: Created new conversation: \(newConversation.id ?? "new (no id yet)")")
        return newConversation
    }

    // MARK: - Conversation Selection

    /// Select a conversation and load its messages
    func selectConversation(_ conversation: ChatConversation) {
        currentConversation = conversation
        currentMessages = conversation.messages
        newlyAddedMessageIds = []  // Clear - historical messages should not animate

        print("✅ ConversationManager: Selected conversation: \(conversation.id ?? "new")")
    }

    // MARK: - Message Management

    /// Append a message to the current conversation and auto-save
    /// If no conversation exists, creates a new one automatically
    func appendMessage(_ message: ChatMessage) async {
        // Auto-create conversation if none exists
        if currentConversation == nil {
            print("📝 ConversationManager: No current conversation, creating new one")
            _ = createNewConversation()
        }

        guard var conversation = currentConversation else {
            print("❌ ConversationManager: Failed to create conversation for message")
            return
        }

        // Add message locally
        currentMessages.append(message)
        newlyAddedMessageIds.insert(message.id)  // Track as new - should animate
        conversation.messages = currentMessages
        currentConversation = conversation

        // Update in conversations list
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index] = conversation
        }
    }

    /// Save the current conversation to the backend
    func saveCurrentConversation() async {
        print("🔍 [ConversationManager] saveCurrentConversation() called")

        guard var conversation = currentConversation else {
            print("❌ ConversationManager: No current conversation to save")
            return
        }

        // Sync messages
        conversation.messages = currentMessages

        print("🔍 [ConversationManager] Preparing to save conversation:")
        print("🔍 [ConversationManager] - ID: \(conversation.id ?? "nil (new)")")
        print("🔍 [ConversationManager] - User ID: \(conversation.userId)")
        print("🔍 [ConversationManager] - Title: \(conversation.title ?? "nil")")
        print("🔍 [ConversationManager] - Message count: \(conversation.messages.count)")
        for (index, msg) in conversation.messages.enumerated() {
            print("🔍 [ConversationManager]   Message \(index): role=\(msg.role.rawValue), content=\(String(msg.content.prefix(50)))...")
            print("🔍 [ConversationManager]   - hasUIComponent: \(msg.uiComponent != nil)")
            print("🔍 [ConversationManager]   - hasAnthropicContent: \(msg.anthropicContent != nil)")
        }

        do {
            // Check if this is a new conversation (id is nil means not yet persisted)
            if let conversationId = conversation.id {
                // Has an ID - check if it exists in database
                print("🔍 [ConversationManager] Checking if conversation exists in database...")
                let existingConversation = try await dataManager.fetchConversationWithEncryption(conversationId: conversationId)
                print("🔍 [ConversationManager] Existing conversation found: \(existingConversation != nil)")

                if existingConversation != nil {
                    // Update existing
                    print("🔍 [ConversationManager] Updating existing conversation...")
                    let updated = try await dataManager.updateConversationWithEncryption(conversation)
                    currentConversation = updated

                    // Update in list
                    if let index = conversations.firstIndex(where: { $0.id == updated.id }) {
                        conversations[index] = updated
                    }
                    print("✅ [ConversationManager] Update successful")
                } else {
                    // ID exists but not in database - create new
                    print("🔍 [ConversationManager] Creating new conversation (ID not found in database)...")
                    let created = try await dataManager.createConversationWithEncryption(conversation)
                    currentConversation = created

                    // Update in list
                    if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
                        conversations[index] = created
                    }
                    print("✅ [ConversationManager] Create successful")
                }
            } else {
                // No ID - definitely a new conversation, let Supabase generate the ID
                print("🔍 [ConversationManager] Creating new conversation (no ID, Supabase will generate)...")
                let created = try await dataManager.createConversationWithEncryption(conversation)
                currentConversation = created

                // Find the local conversation (by matching first in list since it was just inserted)
                // and replace with the created version that has the server-generated ID
                if let index = conversations.firstIndex(where: { $0.id == nil || $0.id == conversation.id }) {
                    conversations[index] = created
                }
                print("✅ [ConversationManager] Create successful, ID: \(created.id ?? "nil")")
            }

            // Re-sort conversations by updatedAt (handle optional)
            conversations.sort { ($0.updatedAt ?? "") > ($1.updatedAt ?? "") }

            print("✅ ConversationManager: Saved conversation with \(conversation.messages.count) messages")
        } catch {
            self.error = error
            print("❌ ConversationManager: Failed to save conversation: \(error.localizedDescription)")
            print("❌ ConversationManager: Full error: \(error)")
        }
    }

    // MARK: - Conversation Deletion

    /// Delete a conversation permanently
    func deleteConversation(_ conversation: ChatConversation) async {
        guard let conversationId = conversation.id else {
            // No ID means it was never persisted - just remove locally
            conversations.removeAll { $0.id == nil && $0.userId == conversation.userId }
            if currentConversation?.id == nil {
                currentConversation = nil
                currentMessages = []
            }
            print("✅ ConversationManager: Removed local-only conversation")
            return
        }

        do {
            try await dataManager.deleteConversation(conversationId: conversationId)

            // Remove from local list
            conversations.removeAll { $0.id == conversationId }

            // If we deleted the current conversation, clear it
            if currentConversation?.id == conversationId {
                currentConversation = nil
                currentMessages = []

                // Select the next available conversation
                if let first = conversations.first {
                    selectConversation(first)
                }
            }

            print("✅ ConversationManager: Deleted conversation: \(conversationId)")
        } catch {
            self.error = error
            print("❌ ConversationManager: Failed to delete conversation: \(error.localizedDescription)")
        }
    }

    // MARK: - Title Generation

    /// Generate a title for the current conversation after first exchange
    /// Uses AI generation via the existing Anthropic service
    func generateTitle() async {
        guard var conversation = currentConversation,
              conversation.title == nil,
              let firstUserMessage = conversation.messages.first(where: { $0.role == .user }) else {
            return
        }

        // Generate title from first message using AI
        let title = await generateTitleFromMessage(firstUserMessage.content)

        // Update conversation with title
        conversation.title = title
        currentConversation = conversation

        // Update in list
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index] = conversation
        }

        // Save to backend
        do {
            _ = try await dataManager.updateConversationWithEncryption(conversation)
            print("✅ ConversationManager: Generated title: \(title)")
        } catch {
            print("❌ ConversationManager: Failed to save title: \(error.localizedDescription)")
        }
    }

    /// Generate a short title from the first message using AI
    private func generateTitleFromMessage(_ message: String) async -> String {
        // Use the existing Anthropic service for title generation
        let truncatedMessage = String(message.prefix(200))

        do {
            // Create a simple request for title generation
            let titlePrompt = "Generate a brief 3-5 word title for this message. Return ONLY the title, no quotes or extra text: \(truncatedMessage)"

            let title = try await AnthropicService.shared.sendMessage(
                messages: [AnthropicMessage(role: "user", content: .text(titlePrompt))],
                systemPrompt: "You are a title generator. Respond with only a brief 3-5 word title, nothing else.",
                maxTokens: 30
            )

            let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\"", with: "")
                .replacingOccurrences(of: "'", with: "")

            // Limit title length
            if cleanTitle.count > 50 {
                return String(cleanTitle.prefix(47)) + "..."
            }
            return cleanTitle.isEmpty ? generateFallbackTitle(from: message) : cleanTitle
        } catch {
            print("❌ ConversationManager: AI title generation failed: \(error.localizedDescription)")
        }

        // Fallback: use first part of message as title
        return generateFallbackTitle(from: message)
    }

    /// Generate a simple fallback title from the message
    private func generateFallbackTitle(from message: String) -> String {
        let cleaned = message.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.count <= 30 {
            return cleaned
        }
        // Find a good break point
        let prefix = String(cleaned.prefix(30))
        if let lastSpace = prefix.lastIndex(of: " ") {
            return String(prefix[..<lastSpace]) + "..."
        }
        return prefix + "..."
    }

    // MARK: - Helpers

    /// Clear the current conversation selection
    func clearCurrentConversation() {
        currentConversation = nil
        currentMessages = []
        newlyAddedMessageIds = []
    }

    /// Get display title for a conversation
    func displayTitle(for conversation: ChatConversation) -> String {
        if let title = conversation.title, !title.isEmpty {
            return title
        }
        // Fallback to first message preview
        if let firstMessage = conversation.messages.first(where: { $0.role == .user }) {
            let preview = String(firstMessage.content.prefix(30))
            return preview + (firstMessage.content.count > 30 ? "..." : "")
        }
        return "New Conversation"
    }

    /// Format relative timestamp for display
    func relativeTimestamp(for conversation: ChatConversation) -> String {
        // Try updatedAt first, then fall back to createdAt
        let dateString = conversation.updatedAt ?? conversation.createdAt
        guard let dateString else { return "Just now" }

        // Try with fractional seconds first (Supabase format), then without
        let formatterWithFractional = ISO8601DateFormatter()
        formatterWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let formatterBasic = ISO8601DateFormatter()

        guard let date = formatterWithFractional.date(from: dateString)
                ?? formatterBasic.date(from: dateString) else {
            return "Just now"
        }

        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .abbreviated
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
}
