//
//  AnthropicService.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//
//  Holds the shared Anthropic API key. The conversational features that once
//  lived here (main chat, onboarding chat) were removed; the live AI surface
//  — note extraction, mini-chat, and insights — each owns its own Haiku
//  request code and reads the key from here.
//

import Foundation

class AnthropicService {
    static let shared = AnthropicService()

    let anthropicApiKey = "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"

    private init() {}
}
