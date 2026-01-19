//
//  ChatConversation.swift
//  Norma
//
//  Created by Claude on 1/6/25.
//

import Foundation

struct ChatConversation: Identifiable, Codable {
    var id: String?             // UUID - primary key (optional for insert, Supabase generates)
    let userId: String
    var title: String?          // AI-generated from first exchange
    var messages: [ChatMessage]
    var createdAt: String?      // ISO8601 timestamp (optional, Supabase generates)
    var updatedAt: String?      // ISO8601 timestamp (optional, Supabase generates)

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case messages
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: String? = nil,
        userId: String,
        title: String? = nil,
        messages: [ChatMessage] = [],
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Struct for inserting new conversations - excludes server-generated fields
struct ChatConversationInsert: Codable {
    let userId: String
    var title: String?
    var messages: [ChatMessage]

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case title
        case messages
    }

    init(from conversation: ChatConversation) {
        // Note: user_id is UUID type in Supabase, so case doesn't matter
        self.userId = conversation.userId
        self.title = conversation.title
        self.messages = conversation.messages
    }
}

/// Struct for updating conversations - only includes mutable fields
struct ChatConversationUpdate: Codable {
    var title: String?
    var messages: [ChatMessage]
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case title
        case messages
        case updatedAt = "updated_at"
    }

    init(from conversation: ChatConversation) {
        self.title = conversation.title
        self.messages = conversation.messages
        self.updatedAt = ISO8601DateFormatter().string(from: Date())
    }
}

struct ChatMessage: Identifiable, Codable {
    let id: String
    let role: MessageRole
    let content: String
    let timestamp: String
    var uiComponent: UIComponent?
    let isVisible: Bool  // Controls whether message is displayed in UI

    // Store raw Anthropic content for conversation history
    var anthropicContent: AnthropicMessageContent?

    init(id: String = UUID().uuidString, role: MessageRole, content: String, timestamp: String = ISO8601DateFormatter().string(from: Date()), uiComponent: UIComponent? = nil, isVisible: Bool = true, anthropicContent: AnthropicMessageContent? = nil) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.uiComponent = uiComponent
        self.isVisible = isVisible
        self.anthropicContent = anthropicContent
    }

    enum MessageRole: String, Codable {
        case user
        case assistant
    }
}
