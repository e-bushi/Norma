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

    // MARK: - Dependencies

    private let dataManager: DataManager
    private var userId: String?

    // MARK: - Initialization

    init(dataManager: DataManager) {
        self.dataManager = dataManager
    }

    // MARK: - Configuration

    func configure(userId: String) {
        self.userId = userId
    }

    // MARK: - Conversation Loading

    /// Load all conversations for the current user
    func loadConversations() async {
        guard let userId = userId else {
            print("❌ ConversationManager: No userId configured")
            return
        }

        isLoading = true
        error = nil

        do {
            conversations = try await dataManager.fetchAllConversations(userId: userId)

            // If no current conversation selected and we have conversations, select the most recent
            if currentConversation == nil, let first = conversations.first {
                selectConversation(first)
            }

            print("✅ ConversationManager: Loaded \(conversations.count) conversations")
        } catch {
            self.error = error
            print("❌ ConversationManager: Failed to load conversations: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - Conversation Creation

    /// Create a new conversation and set it as current
    func createNewConversation() -> ChatConversation {
        guard let userId = userId else {
            fatalError("ConversationManager: No userId configured")
        }

        let newConversation = ChatConversation(
            userId: userId,
            title: nil,
            messages: []
        )

        currentConversation = newConversation
        currentMessages = []

        // Add to local list (will be persisted on first message)
        conversations.insert(newConversation, at: 0)

        print("✅ ConversationManager: Created new conversation: \(newConversation.id)")
        return newConversation
    }

    // MARK: - Conversation Selection

    /// Select a conversation and load its messages
    func selectConversation(_ conversation: ChatConversation) {
        currentConversation = conversation
        currentMessages = conversation.messages

        print("✅ ConversationManager: Selected conversation: \(conversation.id)")
    }

    // MARK: - Message Management

    /// Append a message to the current conversation and auto-save
    func appendMessage(_ message: ChatMessage) async {
        guard var conversation = currentConversation else {
            print("❌ ConversationManager: No current conversation to append message to")
            return
        }

        // Add message locally
        currentMessages.append(message)
        conversation.messages = currentMessages
        currentConversation = conversation

        // Update in conversations list
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index] = conversation
        }
    }

    /// Save the current conversation to the backend
    func saveCurrentConversation() async {
        guard var conversation = currentConversation else {
            print("❌ ConversationManager: No current conversation to save")
            return
        }

        // Sync messages
        conversation.messages = currentMessages

        do {
            // Check if this is a new conversation (not yet persisted)
            let existingConversation = try await dataManager.fetchConversation(conversationId: conversation.id)

            if existingConversation != nil {
                // Update existing
                let updated = try await dataManager.updateConversation(conversation)
                currentConversation = updated

                // Update in list
                if let index = conversations.firstIndex(where: { $0.id == updated.id }) {
                    conversations[index] = updated
                }
            } else {
                // Create new
                let created = try await dataManager.createConversation(conversation)
                currentConversation = created

                // Update in list
                if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
                    conversations[index] = created
                }
            }

            // Re-sort conversations by updatedAt
            conversations.sort { $0.updatedAt > $1.updatedAt }

            print("✅ ConversationManager: Saved conversation with \(conversation.messages.count) messages")
        } catch {
            self.error = error
            print("❌ ConversationManager: Failed to save conversation: \(error.localizedDescription)")
        }
    }

    // MARK: - Conversation Deletion

    /// Delete a conversation permanently
    func deleteConversation(_ conversation: ChatConversation) async {
        do {
            try await dataManager.deleteConversation(conversationId: conversation.id)

            // Remove from local list
            conversations.removeAll { $0.id == conversation.id }

            // If we deleted the current conversation, clear it
            if currentConversation?.id == conversation.id {
                currentConversation = nil
                currentMessages = []

                // Select the next available conversation
                if let first = conversations.first {
                    selectConversation(first)
                }
            }

            print("✅ ConversationManager: Deleted conversation: \(conversation.id)")
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
            _ = try await dataManager.updateConversation(conversation)
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
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: conversation.updatedAt) else {
            return ""
        }

        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .abbreviated
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
}
