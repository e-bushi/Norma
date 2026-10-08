//
//  MiniChatService.swift
//  Norma
//
//  Created by Claude on 5/26/26.
//
//  Norma's chat, running entirely on Apple's on-device foundation model.
//  Each turn opens a fresh LanguageModelSession with the chat tools attached;
//  the framework drives the tool-call loop and returns the final text.
//

import Foundation
import FoundationModels
import SwiftData

@MainActor
final class MiniChatService {

    struct ToolContext {
        let modelContext: ModelContext
        let bills: [Bill]
        let billViewModel: BillViewModel
        let sessionViewModel: SessionViewModel
        let freedomFund: Double
        let totalMonthlyBills: Double
    }

    /// A create/mutate tool that fired during a turn, surfaced so the chat can
    /// render an inline confirmation chip (e.g. "✓ added rent · $1,400").
    struct ToolOutcome: Identifiable {
        let id = UUID()
        let name: String
        let summary: String
    }

    /// The result of a turn: Norma's text plus any chip-worthy tool outcomes,
    /// in the order they fired (chips render before the text reply).
    struct Response {
        let text: String
        let outcomes: [ToolOutcome]
    }

    /// Prior turns replayed into each prompt. The on-device context window is
    /// 4,096 tokens and the tool schemas take a sizable share, so keep it short.
    private static let historyLimit = 6

    func send(
        userText: String,
        profileContext: String = "",
        history: [MiniChatMessage],
        toolContext: ToolContext
    ) async throws -> Response {
        let model = SystemLanguageModel.default
        if case .unavailable(let reason) = model.availability {
            return Response(text: Self.unavailableMessage(for: reason), outcomes: [])
        }

        let runner = ChatToolRunner(context: toolContext)
        let tools = MiniChatToolsProvider.all.compactMap { spec -> NormaTool? in
            do {
                return try NormaTool(spec: spec, runner: runner)
            } catch {
                print("MiniChatService: invalid schema for \(spec.name) — \(error)")
                return nil
            }
        }

        let session = LanguageModelSession(
            model: model,
            tools: tools,
            instructions: Self.instructions(profileContext: profileContext)
        )

        do {
            let response = try await session.respond(to: Self.prompt(userText: userText, history: history))
            return Response(text: response.content, outcomes: runner.outcomes)
        } catch let error as LanguageModelSession.GenerationError {
            return Response(text: Self.message(for: error), outcomes: runner.outcomes)
        }
    }

    // MARK: - Prompt construction

    private static func instructions(profileContext: String) -> String {
        let today = Date().formatted(.iso8601.year().month().day())
        let profileBlock = profileContext.isEmpty ? "" : """

        What you know about the user:
        \(profileContext)
        """

        return """
        You are Norma, the user's financial copilot. You help them track what's coming and understand their runway — how long their money lasts.
        Today is \(today). Write dates for tools as yyyy-MM-dd.
        \(profileBlock)

        What you can do:
        - Add what the user tells you about: add_bill (recurring or one-time bills), add_reminder (a dated nudge), add_intention (a maybe-purchase they're weighing), add_commitment (a decided, dated expense).
        - Re-anchor their balance with set_balance when they tell you their current total.
        - Answer "can I afford X?" with project_runway.
        - Look things up with get_bills, get_freedom_fund, get_profile before answering.
        - Remember durable financial facts with save_fact.

        Rules:
        - Confirm amount and timing before creating anything, then call the tool and report what you added in one short line.
        - Keep replies to one or two sentences. Lowercase, conversational, no greetings or sign-offs.
        - The app tracks bills, income, intents, commitments, and reminders. It does NOT track day-to-day expenses — never offer to log spending.
        - When doing math, show the result clearly.
        """
    }

    private static func prompt(userText: String, history: [MiniChatMessage]) -> String {
        let recent = history.suffix(historyLimit)
        guard !recent.isEmpty else { return userText }
        let transcript = recent
            .map { "\($0.role == .user ? "user" : "norma"): \($0.text)" }
            .joined(separator: "\n")
        return """
        Conversation so far:
        \(transcript)

        user: \(userText)
        """
    }

    // MARK: - Failure copy

    private static func unavailableMessage(for reason: SystemLanguageModel.Availability.UnavailableReason) -> String {
        switch reason {
        case .deviceNotEligible:
            return "i think with apple intelligence, and this iphone doesn't support it — so i can't chat here."
        case .appleIntelligenceNotEnabled:
            return "turn on apple intelligence in settings and i can start chatting."
        case .modelNotReady:
            return "apple intelligence is still getting ready on this iphone — try me again in a bit."
        @unknown default:
            return "i can't think right now — apple intelligence isn't available."
        }
    }

    private static func message(for error: LanguageModelSession.GenerationError) -> String {
        switch error {
        case .exceededContextWindowSize:
            return "that's more than i can hold at once — close the chat and start fresh."
        case .guardrailViolation, .refusal:
            return "i can't help with that one. try asking about your bills or runway."
        case .unsupportedLanguageOrLocale:
            return "i can only chat in a supported language right now."
        default:
            return "sorry, i couldn't process that — try again."
        }
    }
}

// MARK: - Tool plumbing

/// Runs tool calls on the main actor and records the ones that earn a chip.
/// Shared by every tool in a turn, so outcomes come back in firing order.
@MainActor
final class ChatToolRunner {
    private let context: MiniChatService.ToolContext
    private(set) var outcomes: [MiniChatService.ToolOutcome] = []

    /// Tools whose success produces a visible confirmation chip. Reads
    /// (get_*, project_runway) and save_fact don't — Norma just speaks those.
    private static let chipTools: Set<String> = [
        "add_bill", "add_reminder", "add_intention", "add_commitment", "set_balance"
    ]

    init(context: MiniChatService.ToolContext) {
        self.context = context
    }

    func run(name: String, argumentsJSON: String) async -> String {
        let input = (try? JSONSerialization.jsonObject(with: Data(argumentsJSON.utf8))) as? [String: Any] ?? [:]
        let result = await MiniChatToolExecutor.execute(
            name: name,
            input: input,
            modelContext: context.modelContext,
            bills: context.bills,
            billViewModel: context.billViewModel,
            sessionViewModel: context.sessionViewModel,
            freedomFund: context.freedomFund,
            totalMonthlyBills: context.totalMonthlyBills
        )

        let lowered = result.lowercased()
        let failed = lowered.hasPrefix("error") || lowered.hasPrefix("couldn't") || lowered.hasPrefix("no user")
        if Self.chipTools.contains(name), !failed {
            outcomes.append(.init(name: name, summary: result))
        }
        return result
    }
}

/// Adapts a `ChatToolSpec` to the Foundation Models `Tool` protocol. Arguments
/// arrive as untyped `GeneratedContent` constrained by the spec's schema, and
/// are handed to the shared executor as JSON.
struct NormaTool: Tool {
    let name: String
    let description: String
    let parameters: GenerationSchema
    private let runner: ChatToolRunner

    init(spec: ChatToolSpec, runner: ChatToolRunner) throws {
        self.name = spec.name
        self.description = spec.description
        self.parameters = try spec.generationSchema()
        self.runner = runner
    }

    func call(arguments: GeneratedContent) async throws -> String {
        await runner.run(name: name, argumentsJSON: arguments.jsonString)
    }
}

extension ChatToolSpec {
    func generationSchema() throws -> GenerationSchema {
        let properties = parameters.map { parameter in
            DynamicGenerationSchema.Property(
                name: parameter.name,
                description: parameter.description,
                schema: parameter.type.schema(named: "\(name).\(parameter.name)"),
                isOptional: parameter.isOptional
            )
        }
        let root = DynamicGenerationSchema(name: name, description: description, properties: properties)
        return try GenerationSchema(root: root, dependencies: [])
    }
}

private extension ChatToolSpec.ParameterType {
    func schema(named name: String) -> DynamicGenerationSchema {
        switch self {
        case .string: return DynamicGenerationSchema(type: String.self)
        case .number: return DynamicGenerationSchema(type: Double.self)
        case .integer: return DynamicGenerationSchema(type: Int.self)
        case .choice(let values): return DynamicGenerationSchema(name: name, anyOf: values)
        }
    }
}
