//
//  MiniChatMessage.swift
//  Norma
//
//  Created by Claude on 5/26/26.
//

import Foundation

enum MiniChatRole: String {
    case user
    case assistant
}

struct MiniChatMessage: Identifiable {
    let id = UUID()
    let role: MiniChatRole
    let text: String
    let timestamp: Date

    init(role: MiniChatRole, text: String, timestamp: Date = Date()) {
        self.role = role
        self.text = text
        self.timestamp = timestamp
    }
}
