//
//  InsightEngine.swift
//  Norma
//
//  Created by Claude on 5/26/26.
//
//  Runs on app foreground. Reads all notes + existing insights, sends them
//  to Claude (Haiku for speed), and persists any new insights it finds.
//  Skips analysis if the last run was < 6 hours ago or no notes changed.
//

import Foundation
import SwiftData

@MainActor
final class InsightEngine {
    static let shared = InsightEngine()

    private let baseURL = "https://tafoviioqavefsyxskpo.supabase.co/functions/v1/anthropic-proxy"
    private let model = "claude-haiku-4-5-20251001"

    private var lastRunTimestamp: Double {
        get { UserDefaults.standard.double(forKey: "insightEngine.lastRunAt") }
        set { UserDefaults.standard.set(newValue, forKey: "insightEngine.lastRunAt") }
    }

    private var lastNoteHash: String {
        get { UserDefaults.standard.string(forKey: "insightEngine.lastNoteHash") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "insightEngine.lastNoteHash") }
    }

    private var isRunning = false
    private let cooldownInterval: TimeInterval = 6 * 60 * 60 // 6 hours

    private init() {}

    // MARK: - Public API

    func analyzeIfNeeded(modelContext: ModelContext) async {
        guard !isRunning else { return }
        guard Date().timeIntervalSince1970 - lastRunTimestamp > cooldownInterval else { return }

        let notes = fetchNotes(modelContext: modelContext)
        guard !notes.isEmpty else { return }

        let hash = computeHash(notes)
        guard hash != lastNoteHash else { return }

        isRunning = true
        defer { isRunning = false }

        do {
            let existingInsights = fetchInsights(modelContext: modelContext)
            let newInsights = try await generateInsights(notes: notes, existing: existingInsights)

            for insight in newInsights {
                modelContext.insert(insight)
            }
            try modelContext.save()

            lastRunTimestamp = Date().timeIntervalSince1970
            lastNoteHash = hash
        } catch {
            print("InsightEngine: analysis failed: \(error)")
        }
    }

    // MARK: - Data fetching

    private func fetchNotes(modelContext: ModelContext) -> [Note] {
        let descriptor = FetchDescriptor<Note>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func fetchInsights(modelContext: ModelContext) -> [Insight] {
        let descriptor = FetchDescriptor<Insight>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func computeHash(_ notes: [Note]) -> String {
        let combined = notes.map { "\($0.id):\($0.updatedAt.timeIntervalSince1970)" }.joined()
        var hash: UInt64 = 5381
        for byte in combined.utf8 {
            hash = 127 &* (hash & 0x00ffffffffffffff) &+ UInt64(byte)
        }
        return String(hash)
    }

    // MARK: - AI analysis

    private func generateInsights(notes: [Note], existing: [Insight]) async throws -> [Insight] {
        let noteSummaries = notes.prefix(30).map { note -> String in
            let dateStr = Self.dateFormatter.string(from: note.updatedAt)
            let title = note.title ?? "untitled"
            let tokens = note.tokens.map { token -> String in
                "\(token.kind.rawValue): \(token.subject ?? "") \(token.amount)"
            }.joined(separator: ", ")
            let tokenLine = tokens.isEmpty ? "" : "\n  chips: \(tokens)"
            return "[\(dateStr)] \(title)\n  \(note.rawText.prefix(300))\(tokenLine)"
        }.joined(separator: "\n\n")

        // Dismissed insights stay in the prompt as tombstones — the user
        // saying "not this" is a stronger signal than mere duplication, so
        // they get their own do-not-resurface section.
        let liveInsights = existing.filter { $0.dismissedAt == nil }
        let dismissedInsights = existing.filter { $0.dismissedAt != nil }

        let existingSummary = liveInsights.prefix(10).map { insight in
            "[\(insight.type.rawValue)] \(insight.headline)"
        }.joined(separator: "\n")

        let dismissedSummary = dismissedInsights.prefix(15).map { insight in
            "[\(insight.type.rawValue)] \(insight.headline)"
        }.joined(separator: "\n")

        let systemPrompt = """
        You are Norma's insight engine. You analyze a user's financial notes to surface patterns, nudges, milestones, and anomalies.

        Insight types:
        - pattern: recurring behavior the user hasn't explicitly named
        - nudge: something the user said they'd do but hasn't acted on
        - milestone: a threshold crossed or progress made
        - anomaly: something that broke from the user's usual pattern

        Rules:
        - Only surface insights with clear evidence from the notes
        - Don't repeat insights that already exist
        - Never re-surface an insight the user dismissed, or anything close to it — dismissal means "not this"
        - Keep headlines conversational and lowercase
        - Keep details specific — reference dates, amounts, note content
        - Return 0-3 insights per run. Quality over quantity.
        - The app tracks bills, income, intents, commitments, reminders, and TODOs. It does NOT track day-to-day expenses.
        """

        let userMessage = """
        Here are the user's recent notes:

        \(noteSummaries)

        Existing insights (don't repeat these):
        \(existingSummary.isEmpty ? "none yet" : existingSummary)

        Insights the user dismissed (never re-surface these or near-duplicates of them):
        \(dismissedSummary.isEmpty ? "none" : dismissedSummary)

        Analyze the notes and return new insights using the record_insights tool. If there's nothing meaningful to surface, return an empty array.
        """

        let tool = AnthropicTool(
            name: "record_insights",
            description: "Record financial insights derived from the user's notes.",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "insights": AnthropicToolProperty(
                        type: "array",
                        description: "Array of insights",
                        items: AnthropicToolItems(
                            type: "object",
                            properties: [
                                "type": AnthropicToolProperty(type: "string", description: "Insight category", enum: ["pattern", "nudge", "milestone", "anomaly"]),
                                "headline": AnthropicToolProperty(type: "string", description: "One-line finding, conversational lowercase"),
                                "detail": AnthropicToolProperty(type: "string", description: "Supporting detail with specific references")
                            ],
                            required: ["type", "headline", "detail"]
                        )
                    )
                ],
                required: ["insights"]
            )
        )

        // Build request body with JSONSerialization so we can use the array
        // form of `system` with cache_control for prompt caching.
        let toolEncoder = JSONEncoder()
        let toolData = try toolEncoder.encode(tool)
        let toolDict = try JSONSerialization.jsonObject(with: toolData) as! [String: Any]

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "system": [
                [
                    "type": "text",
                    "text": systemPrompt,
                    "cache_control": ["type": "ephemeral"]
                ]
            ],
            "messages": [
                ["role": "user", "content": userMessage]
            ],
            "tools": [toolDict],
            "tool_choice": ["type": "tool", "name": "record_insights"]
        ]

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
        return try parseResponse(data)
    }

    private func parseResponse(_ data: Data) throws -> [Insight] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]] else {
            return []
        }

        guard let toolBlock = content.first(where: { ($0["type"] as? String) == "tool_use" }),
              let input = toolBlock["input"] as? [String: Any],
              let rawInsights = input["insights"] as? [[String: Any]] else {
            return []
        }

        return rawInsights.compactMap { raw -> Insight? in
            guard let typeStr = raw["type"] as? String,
                  let type = InsightType(rawValue: typeStr),
                  let headline = raw["headline"] as? String,
                  let detail = raw["detail"] as? String else {
                return nil
            }
            return Insight(type: type, headline: headline, detail: detail)
        }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()
}

