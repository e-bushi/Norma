//
//  ChatConversation.swift
//  Norma
//
//  Created by Claude on 1/6/25.
//

import Foundation

struct ChatConversation: Identifiable, Codable {
    let id: String              // UUID - primary key for multi-conversation support
    let userId: String
    var title: String?          // AI-generated from first exchange
    var messages: [ChatMessage]
    var createdAt: String       // ISO8601 timestamp
    var updatedAt: String       // ISO8601 timestamp

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case messages
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: String = UUID().uuidString,
        userId: String,
        title: String? = nil,
        messages: [ChatMessage] = [],
        createdAt: String = ISO8601DateFormatter().string(from: Date()),
        updatedAt: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
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
