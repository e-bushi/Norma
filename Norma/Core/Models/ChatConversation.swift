//
//  ChatConversation.swift
//  Norma
//
//  Created by Claude on 1/6/25.
//

import Foundation

struct ChatConversation: Codable {
    let userId: String
    var messages: [ChatMessage]
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case messages
        case updatedAt = "updated_at"
    }

    init(userId: String, messages: [ChatMessage] = [], updatedAt: String? = nil) {
        self.userId = userId
        self.messages = messages
        self.updatedAt = updatedAt
    }
}

struct ChatMessage: Identifiable, Codable {
    let id: String
    let role: MessageRole
    let content: String
    let timestamp: String
    var uiComponent: UIComponent?

    init(id: String = UUID().uuidString, role: MessageRole, content: String, timestamp: String = ISO8601DateFormatter().string(from: Date()), uiComponent: UIComponent? = nil) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.uiComponent = uiComponent
    }

    enum MessageRole: String, Codable {
        case user
        case assistant
    }
}
