//
//  MiniChatService.swift
//  Norma
//
//  Created by Claude on 5/26/26.
//
//  Lightweight chat scoped to a single note. Sends the note's content
//  and chips as context, keeps a short conversation history (max 6 turns),
//  and returns a plain text response. No persistence — ephemeral by design.
//

import Foundation

@MainActor
final class MiniChatService {
    private var apiKey: String { AnthropicService.shared.anthropicApiKey }
    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let model = "claude-haiku-4-5-20251001"

    func send(
        userText: String,
        noteContext: String,
        profileContext: String = "",
        history: [MiniChatMessage]
    ) async throws -> String {
        let profileBlock = profileContext.isEmpty ? "" : """

        What norma knows about this user:
        \(profileContext)
        """

        let systemPrompt = """
        You are Norma, a concise financial companion embedded inside a note. The user is looking at a specific note and wants a quick exchange — a calculation, a clarification, or a suggestion.

        Context from the current note:
        \(noteContext)
        \(profileBlock)

        Rules:
        - Keep responses under 120 characters. One sentence. No exceptions.
        - Stay grounded in the note's content. Reference specific amounts, dates, names.
        - You can suggest creating reminders, updating chips, or noting something for later.
        - The app tracks bills, income, intents, commitments, reminders, and TODOs. It does NOT track day-to-day expenses.
        - Use lowercase, conversational tone. No greetings or sign-offs.
        - When doing math, show the result clearly.
        """

        var messages: [[String: String]] = []
        for msg in history.suffix(6) {
            messages.append([
                "role": msg.role == .user ? "user" : "assistant",
                "content": msg.text
            ])
        }
        messages.append(["role": "user", "content": userText])

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("prompt-caching-2024-07-31", forHTTPHeaderField: "anthropic-beta")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 256,
            "system": [
                [
                    "type": "text",
                    "text": systemPrompt,
                    "cache_control": ["type": "ephemeral"]
                ]
            ],
            "messages": messages
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: request)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let first = content.first,
              let text = first["text"] as? String else {
            return "sorry, I couldn't process that."
        }

        return text
    }
}
