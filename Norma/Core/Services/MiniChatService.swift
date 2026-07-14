//
//  MiniChatService.swift
//  Norma
//
//  Created by Claude on 5/26/26.
//
//  Lightweight chat scoped to a single note. Supports tool use so Norma
//  can read bills, freedom fund, profile, and save facts. Handles the
//  tool_use → tool_result loop before returning the final text response.
//

import Foundation
import SwiftData

@MainActor
final class MiniChatService {
    private let baseURL = "https://tafoviioqavefsyxskpo.supabase.co/functions/v1/anthropic-proxy"
    private let model = "claude-haiku-4-5-20251001"

    struct ToolContext {
        let modelContext: ModelContext
        let bills: [Bill]
        let billViewModel: BillViewModel
        let sessionViewModel: SessionViewModel
        let freedomFund: Double
        let totalMonthlyBills: Double
        let note: Note
    }

    func send(
        userText: String,
        noteContext: String,
        profileContext: String = "",
        history: [MiniChatMessage],
        toolContext: ToolContext? = nil
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
        - Use tools to look up bills, freedom fund, or profile before answering questions about them.
        - You can create things: add_bill, add_reminder, add_intention, add_commitment. Confirm amount and timing first, then call the tool and report what you added.
        - When the user tells you their current balance, call set_balance to re-anchor it. For "can I afford X?" questions, call project_runway.
        - When the user shares important financial info (loans, commitments, habits), use save_fact to remember it.
        - The app tracks bills, income, intents, commitments, reminders, and TODOs. It does NOT track day-to-day expenses.
        - Use lowercase, conversational tone. No greetings or sign-offs.
        - When doing math, show the result clearly.
        """

        let systemBlock: [[String: Any]] = [
            [
                "type": "text",
                "text": systemPrompt,
                "cache_control": ["type": "ephemeral"]
            ]
        ]

        var messages: [[String: Any]] = []
        for msg in history.suffix(6) {
            messages.append([
                "role": msg.role == .user ? "user" : "assistant",
                "content": msg.text
            ])
        }
        messages.append(["role": "user", "content": userText])

        let hasTools = toolContext != nil
        let maxRounds = 3
        var round = 0

        while round < maxRounds {
            round += 1

            var body: [String: Any] = [
                "model": model,
                "max_tokens": 800,
                "system": systemBlock,
                "messages": messages
            ]
            if hasTools {
                body["tools"] = MiniChatToolsProvider.allTools()
            }

            // The Anthropic edge proxy injects the API key server-side; authenticate
            // with the Supabase JWT instead of shipping x-api-key in the client.
            let session = try await SupabaseService.shared.getSession()
            var request = URLRequest(url: URL(string: baseURL)!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue(SupabaseService.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            request.setValue("prompt-caching-2024-07-31", forHTTPHeaderField: "anthropic-beta")

            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, _) = try await URLSession.shared.data(for: request)

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let content = json["content"] as? [[String: Any]] else {
                return "sorry, I couldn't process that."
            }

            let stopReason = json["stop_reason"] as? String

            if stopReason == "tool_use", let ctx = toolContext {
                var assistantContent: [[String: Any]] = content
                var toolResults: [[String: Any]] = []

                for block in content where (block["type"] as? String) == "tool_use" {
                    guard let toolId = block["id"] as? String,
                          let toolName = block["name"] as? String,
                          let toolInput = block["input"] as? [String: Any] else { continue }

                    let result = await MiniChatToolExecutor.execute(
                        name: toolName,
                        input: toolInput,
                        modelContext: ctx.modelContext,
                        bills: ctx.bills,
                        billViewModel: ctx.billViewModel,
                        sessionViewModel: ctx.sessionViewModel,
                        freedomFund: ctx.freedomFund,
                        totalMonthlyBills: ctx.totalMonthlyBills,
                        note: ctx.note
                    )

                    toolResults.append([
                        "type": "tool_result",
                        "tool_use_id": toolId,
                        "content": result
                    ])
                }

                messages.append(["role": "assistant", "content": assistantContent] as [String: Any])
                messages.append(["role": "user", "content": toolResults] as [String: Any])
                continue
            }

            if let textBlock = content.first(where: { ($0["type"] as? String) == "text" }),
               let text = textBlock["text"] as? String {
                return text
            }

            return "sorry, I couldn't process that."
        }

        return "sorry, I couldn't process that."
    }
}
