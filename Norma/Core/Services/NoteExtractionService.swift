//
//  NoteExtractionService.swift
//  Norma
//
//  Created by Claude on 4/27/26.
//
//  Calls Claude (Haiku, for speed) with a tool-use schema that returns the
//  financial entities extracted from a note's prose. Each entity becomes a
//  NoteToken — kind, amount, currency, plus optional category/subject/
//  counterparty/recurrence/usd_equivalent.
//
//  Returns an empty array when the text contains no extractable amounts.
//

import Foundation

@MainActor
final class NoteExtractionService {
    static let shared = NoteExtractionService()

    private let baseURL = "https://tafoviioqavefsyxskpo.supabase.co/functions/v1/anthropic-proxy"
    private let modelCascade = [
        "claude-haiku-4-5-20251001",
        "claude-3-5-haiku-20241022"
    ]

    private init() {}

    // MARK: - Public API

    /// Extracts NoteTokens from raw note prose. Returns [] if there's nothing
    /// extractable. Throws on transport/decoding failure.
    func extract(text: String) async throws -> [NoteToken] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let response = try await sendToolRequest(text: trimmed)
        guard case .toolUse(_, _, let input) = response else {
            return []
        }

        guard let rawTokens = input["tokens"] as? [[String: Any]] else {
            return []
        }

        let endIndex = (text as NSString).length
        return rawTokens.compactMap { Self.parseToken($0, sourceEnd: endIndex) }
    }

    // MARK: - Tool Schema

    private static let extractionTool = AnthropicTool(
        name: "record_note_tokens",
        description: "Record the financial entities found in the note's prose.",
        inputSchema: AnthropicToolSchema(
            type: "object",
            properties: [
                "tokens": AnthropicToolProperty(
                    type: "array",
                    description: "Array of extracted entities. Empty if the note has nothing extractable.",
                    items: AnthropicToolItems(
                        type: "object",
                        properties: tokenObjectProperties,
                        required: ["kind"]
                    )
                )
            ],
            required: ["tokens"]
        )
    )

    private static let tokenObjectProperties: [String: AnthropicToolProperty] = [
        "kind": AnthropicToolProperty(
            type: "string",
            description: "bill | income | transfer | reminder | intent",
            enum: ["bill", "income", "transfer", "reminder", "intent"]
        ),
        "amount": AnthropicToolProperty(type: "number", description: "Numeric amount, e.g., 450. Required for financial kinds, omit for reminders."),
        "currency": AnthropicToolProperty(type: "string", description: "ISO 4217 code: USD, EUR, THB, etc. Required for financial kinds, omit for reminders."),
        "usd_equivalent": AnthropicToolProperty(type: "number", description: "Approximate USD value if confidently convertible."),
        "category": AnthropicToolProperty(
            type: "string",
            description: "Closest category match.",
            enum: NoteToken.Category.allCases.map(\.rawValue)
        ),
        "subject": AnthropicToolProperty(type: "string", description: "Short noun phrase. For financial kinds: what the money is for ('lunch at peppermint', 'rent'). For reminders: the action to remember ('call mom', 'pay verizon'). Do not include the amount."),
        "counterparty": AnthropicToolProperty(type: "string", description: "Lowercase person or business name when explicitly mentioned, e.g., 'marcus', 'acme'."),
        "recurrence": AnthropicToolProperty(
            type: "string",
            description: "Only set if the text explicitly indicates recurrence.",
            enum: NoteToken.Recurrence.allCases.map(\.rawValue)
        ),
        "remind_at": AnthropicToolProperty(
            type: "string",
            description: "ISO 8601 datetime for when the reminder should fire. Set when a time reference is present in the text. Resolve relative phrases ('tomorrow', 'friday at 3pm') against the 'Now' timestamp in the user message. Omit when the user clearly intends a reminder but hasn't named a time — the user will fill it in."
        ),
        "occurred_at": AnthropicToolProperty(
            type: "string",
            description: "ISO 8601 date for when the financial event happens (or first happens, for recurring). For bills with a due-day hint ('due 31', 'every 1st', 'on the 14th'), resolve to the next future occurrence on that day relative to the 'Now' timestamp — current month if the day hasn't passed, otherwise next month. Omit when no date hint is present; the client will default to today. Ignored for reminders."
        )
    ]

    // MARK: - Prompt

    private static let systemPrompt = """
    You extract structured entities from short personal notes. Each entity becomes a chip in the user's planning canvas.

    Three families of entities:

    1) FINANCIAL — explicit amounts of money paired with a recurring obligation, income, or account transfer.
       - Only extract amounts EXPLICITLY written in the text. Never guess, infer, or hallucinate amounts.
       - Each qualifying amount is one token.
       - kind:
         * income — user received money ("got paid", "received", "deposited", or +amount sign)
         * bill — amount paired with a recurrence keyword (monthly, weekly, /mo, every month, etc.)
         * transfer — explicitly described as moving money between own accounts
       - DO NOT extract a token for discretionary day-to-day spending (lunches, coffee, scooters, beach clubs, retail purchases, etc.). The app no longer tracks expenses; emit nothing for those amounts.
       - DO NOT extract a token for prose describing the *payment* of a recurring obligation (e.g., "paid rent today", "sent verizon $80", "paid the electric bill"). Bills are tracked separately via the bills view; emit nothing for the payment line itself.
         * Common recurring-obligation keywords to suppress on payment-line prose: rent, mortgage, utilities, electric, water, gas, internet, phone, verizon, comcast, spotify, netflix, insurance, subscription, hoa, cable, wifi.
         * "I paid rent $920" → emit nothing.
         * "$2,000 rent monthly" → still emit a `bill` token (this is creating the recurring bill record, not paying it).
       - currency: ISO 4217 codes. Symbol map: $ → USD, ฿ → THB, € → EUR, £ → GBP, ¥ → JPY, ₹ → INR, ₩ → KRW, ₫ → VND, ₱ → PHP. Default USD if ambiguous.
       - category: pick the closest match from the enum. "other" if nothing fits.
       - subject: short noun phrase describing what the money is for. Do not include the amount itself in the subject.
       - counterparty: lowercase, only when explicitly named. Omit otherwise.
       - recurrence: only if the text explicitly indicates it.
       - usd_equivalent: only if you can confidently convert. Omit otherwise.
       - occurred_at: for bills with a due-day hint ("due 31", "due 1", "on the 4th", "every 14th"), resolve to the next future ISO 8601 date on that day relative to "Now". Pick current month if the day hasn't passed yet, otherwise next month. Omit for bills without a due-day hint.

    2) INTENTION — tentative future spend the user is considering but hasn't committed to.
       - Triggers: tentative language about a future amount.
         Examples: "thinking about a $200 bali stay", "maybe ~$120 for a scuba day", "considering a $170 camera lens", "want to do a visa run, ~$150", "might do dinner with friends, $80", "planning a $300 getaway", "eyeing a $400 jacket".
         Soft markers: thinking, maybe, considering, want to, planning, hoping to, would like, eyeing, looking at, might, debating, possibly.
       - kind: "intent"
       - amount, currency, subject, usd_equivalent: same shape as financial tokens.
       - subject: short noun phrase ("bali stay", "camera lens", "scuba day"). Do not include the amount or tentative wording.
       - Do not set recurrence or occurred_at — intentions are one-shot and scoped to the month they're written in; the client handles month-bucketing automatically.

    3) REMINDER — the user expresses an intent to be reminded of something (non-financial).
       - Triggers: "remind me to X", "don't forget to Y", "[task] tomorrow at 3pm", "call mom friday", "i need to file taxes".
       - Emit when there's a clear action intent. The user will confirm and (if missing) fill in the time before any notification fires.
       - kind: "reminder"
       - subject: the action phrase, lowercase, no leading "to" ("call mom", "pay verizon", "submit timesheet").
       - remind_at: ISO 8601 datetime resolved against the "Now" timestamp in the user message. Set when the text contains a time reference (default time-of-day 09:00 local if only a date is given). Omit when the text has no time reference.
       - recurrence: set if the user says "every monday", "weekly", etc.
       - Omit amount, currency, category, counterparty.

    Always call the record_note_tokens tool — even when the result is an empty array.
    """

    // MARK: - Network

    private func sendToolRequest(text: String) async throws -> AnthropicMessageContent {
        var lastError: Error?

        // The Anthropic edge proxy injects the API key server-side; authenticate
        // with the Supabase JWT instead of shipping x-api-key in the client.
        let session = try await SupabaseService.shared.getSession()

        for model in modelCascade {
            do {
                var request = URLRequest(url: URL(string: baseURL)!)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
                request.setValue(SupabaseService.supabaseAnonKey, forHTTPHeaderField: "apikey")
                request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
                request.setValue("prompt-caching-2024-07-31", forHTTPHeaderField: "anthropic-beta")
                request.timeoutInterval = 30

                let nowISO = ISO8601DateFormatter().string(from: Date())
                let userMessage = "Now: \(nowISO)\n\nNote text:\n\n\(text)"

                // Build with JSONSerialization so `system` can use the array form
                // with cache_control. The breakpoint on the system block caches the
                // static tool schema + system prompt as a prefix (~90% off on repeat
                // extractions); only the per-note user message is billed in full.
                // Mirrors InsightEngine's caching setup.
                let toolData = try JSONEncoder().encode(Self.extractionTool)
                let toolDict = try JSONSerialization.jsonObject(with: toolData) as! [String: Any]

                let body: [String: Any] = [
                    "model": model,
                    "max_tokens": 1024,
                    "system": [
                        [
                            "type": "text",
                            "text": Self.systemPrompt,
                            "cache_control": ["type": "ephemeral"]
                        ]
                    ],
                    "messages": [
                        ["role": "user", "content": userMessage]
                    ],
                    "tools": [toolDict],
                    "tool_choice": ["type": "tool", "name": Self.extractionTool.name]
                ]

                request.httpBody = try JSONSerialization.data(withJSONObject: body)

                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    throw AnthropicError.networkError
                }

                if http.statusCode == 200 {
                    let decoded = try JSONDecoder().decode(AnthropicResponse.self, from: data)
                    for content in decoded.content where content.type == "tool_use" {
                        if let id = content.id, let name = content.name, let input = content.input {
                            return .toolUse(id: id, name: name, input: input)
                        }
                    }
                    return .text("")
                } else if http.statusCode == 529 {
                    lastError = AnthropicError.unknownError(529)
                    continue
                } else if http.statusCode == 400 || http.statusCode == 401 {
                    if let err = try? JSONDecoder().decode(AnthropicErrorResponse.self, from: data) {
                        throw AnthropicError.apiError(err.error.message)
                    }
                    throw AnthropicError.unknownError(http.statusCode)
                } else {
                    lastError = AnthropicError.unknownError(http.statusCode)
                    continue
                }
            } catch {
                lastError = error
                continue
            }
        }
        throw lastError ?? AnthropicError.unknownError(0)
    }

    // MARK: - Parsing

    private static func parseToken(_ dict: [String: Any], sourceEnd: Int) -> NoteToken? {
        guard let kindString = dict["kind"] as? String,
              let kind = NoteToken.Kind(rawValue: kindString)
        else { return nil }

        let subject = (dict["subject"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let counterparty = (dict["counterparty"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().nilIfEmpty
        let recurrence = (dict["recurrence"] as? String).flatMap(NoteToken.Recurrence.init(rawValue:))

        // Reminder-shaped tokens have no amount/currency. remind_at may be omitted
        // when the user hasn't named a time yet — the chip enters a "needs info"
        // state so the user can fill the time in via tap. confirmedAt stays nil
        // until the user explicitly confirms; nothing schedules until then.
        if kind == .reminder {
            guard let subject, !subject.isEmpty else { return nil }
            let remindAt = (dict["remind_at"] as? String).flatMap(ISO8601DateFormatter().date(from:))
            return NoteToken(
                kind: .reminder,
                amount: 0,
                currency: "",
                subject: subject,
                counterparty: counterparty,
                recurrence: recurrence,
                occurredAt: remindAt ?? Date(),
                sourceStart: sourceEnd,
                sourceEnd: sourceEnd,
                isProvisional: false,
                remindAt: remindAt,
                confirmedAt: nil
            )
        }

        // Financial token shape.
        guard let amount = (dict["amount"] as? Double) ?? (dict["amount"] as? Int).map(Double.init),
              let currency = (dict["currency"] as? String)?.uppercased()
        else { return nil }

        let usd = (dict["usd_equivalent"] as? Double) ?? (dict["usd_equivalent"] as? Int).map(Double.init)
        let category = (dict["category"] as? String).flatMap(NoteToken.Category.init(rawValue:))
        let occurredAt = (dict["occurred_at"] as? String)
            .flatMap { Self.parseFlexibleDate($0) }
            ?? Date()

        return NoteToken(
            kind: kind,
            amount: amount,
            currency: currency,
            usdEquivalent: usd,
            category: category,
            subject: subject,
            counterparty: counterparty,
            recurrence: recurrence,
            occurredAt: occurredAt,
            sourceStart: sourceEnd,
            sourceEnd: sourceEnd,
            isProvisional: false
        )
    }

    /// Accept either a full ISO 8601 datetime ("2026-05-31T00:00:00Z") or a
    /// date-only form ("2026-05-31") since the LLM may emit either.
    private static func parseFlexibleDate(_ string: String) -> Date? {
        if let date = ISO8601DateFormatter().date(from: string) { return date }
        let dateOnly = DateFormatter()
        dateOnly.locale = Locale(identifier: "en_US_POSIX")
        dateOnly.timeZone = TimeZone.current
        dateOnly.dateFormat = "yyyy-MM-dd"
        return dateOnly.date(from: string)
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
