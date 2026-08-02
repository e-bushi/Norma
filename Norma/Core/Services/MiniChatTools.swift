//
//  MiniChatTools.swift
//  Norma
//
//  Created by Claude on 5/26/26.
//
//  Tool definitions and executor for the mini chat. Norma can read bills,
//  read the freedom fund, read/update the user profile, and save facts.
//

import Foundation
import SwiftData

// MARK: - Tool definitions

struct MiniChatToolsProvider {
    static func allTools() -> [[String: Any]] {
        [
            getBillsTool,
            updateBillTool,
            getFreedomFundTool,
            getProfileTool,
            saveFactTool,
            updateProfileTool,
            addBillTool,
            addReminderTool,
            addIntentionTool,
            addCommitmentTool,
            setBalanceTool,
            projectRunwayTool
        ]
    }

    static let addBillTool: [String: Any] = [
        "name": "add_bill",
        "description": "Create a new recurring or one-time bill. Confirm the amount and cadence with the user before calling.",
        "input_schema": [
            "type": "object",
            "properties": [
                "name": ["type": "string", "description": "Bill name, e.g. rent, phone"] as [String: Any],
                "amount": ["type": "number", "description": "Bill amount"] as [String: Any],
                "frequency": ["type": "string", "description": "one of: monthly, quarterly, yearly, onetime"] as [String: Any],
                "due_date": ["type": "string", "description": "Next due date, ISO8601 (yyyy-MM-dd). Defaults to today if omitted."] as [String: Any]
            ] as [String: Any],
            "required": ["name", "amount"]
        ] as [String: Any]
    ]

    static let addReminderTool: [String: Any] = [
        "name": "add_reminder",
        "description": "Set a reminder that fires an OS notification. Use for time-based nudges the user asks to be reminded about.",
        "input_schema": [
            "type": "object",
            "properties": [
                "subject": ["type": "string", "description": "What to remind about"] as [String: Any],
                "remind_at": ["type": "string", "description": "When to fire, ISO8601 date-time (yyyy-MM-dd'T'HH:mm:ss) or date (yyyy-MM-dd)"] as [String: Any]
            ] as [String: Any],
            "required": ["subject", "remind_at"]
        ] as [String: Any]
    ]

    static let addIntentionTool: [String: Any] = [
        "name": "add_intention",
        "description": "Record a soft financial intention the user is planning or considering (a trip, a purchase). Not yet scheduled — shows in the forecast as an optional deduction.",
        "input_schema": [
            "type": "object",
            "properties": [
                "subject": ["type": "string", "description": "What they intend, e.g. visa run, new laptop"] as [String: Any],
                "amount": ["type": "number", "description": "Estimated cost, 0 if unknown"] as [String: Any],
                "date": ["type": "string", "description": "Rough date if any, ISO8601 (yyyy-MM-dd)"] as [String: Any]
            ] as [String: Any],
            "required": ["subject"]
        ] as [String: Any]
    ]

    static let addCommitmentTool: [String: Any] = [
        "name": "add_commitment",
        "description": "Record a dated one-time financial commitment the user has decided on (a known upcoming expense on a specific date).",
        "input_schema": [
            "type": "object",
            "properties": [
                "subject": ["type": "string", "description": "What the commitment is"] as [String: Any],
                "amount": ["type": "number", "description": "Amount"] as [String: Any],
                "date": ["type": "string", "description": "Due date, ISO8601 (yyyy-MM-dd)"] as [String: Any]
            ] as [String: Any],
            "required": ["subject", "amount", "date"]
        ] as [String: Any]
    ]

    static let setBalanceTool: [String: Any] = [
        "name": "set_balance",
        "description": "Re-anchor the user's total spendable balance to a new amount. Use when they tell you their current balance.",
        "input_schema": [
            "type": "object",
            "properties": [
                "amount": ["type": "number", "description": "New total spendable balance"] as [String: Any]
            ] as [String: Any],
            "required": ["amount"]
        ] as [String: Any]
    ]

    static let projectRunwayTool: [String: Any] = [
        "name": "project_runway",
        "description": "Project how a one-time expense would change the user's runway. Use to answer 'can I afford X?' style questions.",
        "input_schema": [
            "type": "object",
            "properties": [
                "cost": ["type": "number", "description": "The one-time cost to model against the current balance"] as [String: Any]
            ] as [String: Any],
            "required": ["cost"]
        ] as [String: Any]
    ]

    static let getBillsTool: [String: Any] = [
        "name": "get_bills",
        "description": "Get the user's active bills with names, amounts, due dates, and frequency.",
        "input_schema": [
            "type": "object",
            "properties": [:] as [String: Any],
            "required": [] as [String]
        ] as [String: Any]
    ]

    static let updateBillTool: [String: Any] = [
        "name": "update_bill",
        "description": "Update an existing bill's amount, name, or due date. Use get_bills first to find the bill name.",
        "input_schema": [
            "type": "object",
            "properties": [
                "bill_name": [
                    "type": "string",
                    "description": "Name of the bill to update (case-insensitive match)"
                ] as [String: Any],
                "amount": [
                    "type": "number",
                    "description": "New amount for the bill"
                ] as [String: Any],
                "name": [
                    "type": "string",
                    "description": "New name for the bill"
                ] as [String: Any]
            ] as [String: Any],
            "required": ["bill_name"]
        ] as [String: Any]
    ]

    static let getFreedomFundTool: [String: Any] = [
        "name": "get_freedom_fund",
        "description": "Get the user's freedom fund balance and months of runway.",
        "input_schema": [
            "type": "object",
            "properties": [:] as [String: Any],
            "required": [] as [String]
        ] as [String: Any]
    ]

    static let getProfileTool: [String: Any] = [
        "name": "get_profile",
        "description": "Get everything Norma knows about the user — currency, income, payday, runway floor, and saved facts.",
        "input_schema": [
            "type": "object",
            "properties": [:] as [String: Any],
            "required": [] as [String]
        ] as [String: Any]
    ]

    static let saveFactTool: [String: Any] = [
        "name": "save_fact",
        "description": "Save an important financial fact about the user that Norma should remember for future conversations. Use this when the user shares something worth remembering — loan details, recurring commitments, financial habits, life context.",
        "input_schema": [
            "type": "object",
            "properties": [
                "fact": [
                    "type": "string",
                    "description": "The fact to remember, in plain language"
                ] as [String: Any],
                "source": [
                    "type": "string",
                    "description": "Where this fact came from, e.g. 'mini chat, may 26 note'"
                ] as [String: Any]
            ] as [String: Any],
            "required": ["fact", "source"]
        ] as [String: Any]
    ]

    static let updateProfileTool: [String: Any] = [
        "name": "update_profile",
        "description": "Update the user's structured financial profile fields. Only include fields that should change.",
        "input_schema": [
            "type": "object",
            "properties": [
                "currency": [
                    "type": "string",
                    "description": "Currency code (e.g. USD, THB, EUR)"
                ] as [String: Any],
                "income_amount": [
                    "type": "number",
                    "description": "Monthly income amount"
                ] as [String: Any],
                "income_frequency": [
                    "type": "string",
                    "description": "How often they're paid: monthly, biweekly, irregular"
                ] as [String: Any],
                "payday": [
                    "type": "integer",
                    "description": "Day of month income typically lands"
                ] as [String: Any],
                "runway_floor": [
                    "type": "number",
                    "description": "Minimum months of runway the user cares about"
                ] as [String: Any]
            ] as [String: Any],
            "required": [] as [String]
        ] as [String: Any]
    ]
}

// MARK: - Tool executor

@MainActor
final class MiniChatToolExecutor {

    static func execute(
        name: String,
        input: [String: Any],
        modelContext: ModelContext,
        bills: [Bill],
        billViewModel: BillViewModel,
        sessionViewModel: SessionViewModel,
        freedomFund: Double,
        totalMonthlyBills: Double
    ) async -> String {
        switch name {
        case "get_bills":
            return executeBills(bills: bills)
        case "update_bill":
            return await executeUpdateBill(input: input, bills: bills, billViewModel: billViewModel)
        case "get_freedom_fund":
            return executeFreedomFund(balance: freedomFund, monthlyBills: totalMonthlyBills)
        case "get_profile":
            return executeGetProfile(modelContext: modelContext, sessionViewModel: sessionViewModel)
        case "save_fact":
            return executeSaveFact(input: input, modelContext: modelContext)
        case "update_profile":
            return await executeUpdateProfile(input: input, modelContext: modelContext, sessionViewModel: sessionViewModel)
        case "add_bill":
            return await executeAddBill(input: input, billViewModel: billViewModel)
        case "add_reminder":
            return await executeAddReminder(input: input, modelContext: modelContext, sessionViewModel: sessionViewModel)
        case "add_intention":
            return executeAddIntention(input: input, modelContext: modelContext, sessionViewModel: sessionViewModel)
        case "add_commitment":
            return executeAddCommitment(input: input, modelContext: modelContext, sessionViewModel: sessionViewModel)
        case "set_balance":
            return await executeSetBalance(input: input, modelContext: modelContext, sessionViewModel: sessionViewModel)
        case "project_runway":
            return executeProjectRunway(input: input, modelContext: modelContext, sessionViewModel: sessionViewModel, freedomFund: freedomFund, totalMonthlyBills: totalMonthlyBills)
        default:
            return "unknown tool: \(name)"
        }
    }

    // MARK: - Create tools (chat as token producer)

    private static func currencyCode(_ sessionViewModel: SessionViewModel) -> String {
        sessionViewModel.currentUser?.settings.currency ?? "USD"
    }

    /// Accepts ISO8601 date-time, full date, or plain yyyy-MM-dd.
    private static func parseDate(_ raw: String?) -> Date? {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        if let d = iso.date(from: raw) { return d }
        iso.formatOptions = [.withFullDate]
        if let d = iso.date(from: raw) { return d }
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        return df.date(from: raw)
    }

    private static func executeAddBill(input: [String: Any], billViewModel: BillViewModel) async -> String {
        guard let name = input["name"] as? String else { return "error: missing bill name." }
        guard let amount = input["amount"] as? Double else { return "error: missing amount." }
        let frequency: BillFrequency
        switch (input["frequency"] as? String)?.lowercased() {
        case "onetime", "one-time", "once": frequency = .oneTime
        case "quarterly": frequency = .quarterly
        case "yearly", "annual", "annually": frequency = .yearly
        default: frequency = .monthly
        }
        let dueDate = parseDate(input["due_date"] as? String) ?? Date()
        guard let bill = await billViewModel.addBill(name: name, amount: amount, dueDate: dueDate, frequency: frequency) else {
            return "couldn't add the bill."
        }
        return "added bill: \(bill.name) · \(String(format: "%.2f", bill.amount)) · \(frequency.rawValue.lowercased())"
    }

    private static func executeAddReminder(input: [String: Any], modelContext: ModelContext, sessionViewModel: SessionViewModel) async -> String {
        guard let subject = input["subject"] as? String else { return "error: missing subject." }
        guard let remindAt = parseDate(input["remind_at"] as? String) else {
            return "error: missing or invalid remind_at (use ISO8601)."
        }
        let token = NoteToken(
            kind: .reminder,
            amount: 0,
            currency: currencyCode(sessionViewModel),
            subject: subject,
            occurredAt: remindAt,
            remindAt: remindAt,
            confirmedAt: Date()
        )
        modelContext.insert(token)
        // Reuse the async permission path; schedule standalone (no note) — the token
        // surfaces in the forecast/reminders queries directly.
        let service = NotificationService.shared
        await service.refreshPermissionStatus()
        if service.notificationPermissionStatus == .notDetermined {
            _ = await service.requestNotificationPermission()
        }
        let result = await NoteRepository.scheduleReminderRequest(token, fireDate: remindAt)
        try? modelContext.save()
        if case .failure = result {
            return "saved the reminder, but couldn't schedule the notification — check notification permissions in Settings."
        }
        return "reminder set: \(subject) · \(Self.shortDate.string(from: remindAt))"
    }

    private static func executeAddIntention(input: [String: Any], modelContext: ModelContext, sessionViewModel: SessionViewModel) -> String {
        guard let subject = input["subject"] as? String else { return "error: missing subject." }
        let amount = input["amount"] as? Double ?? 0
        let occurredAt = parseDate(input["date"] as? String) ?? Date()
        let token = NoteToken(
            kind: .intent,
            amount: amount,
            currency: currencyCode(sessionViewModel),
            subject: subject,
            occurredAt: occurredAt
        )
        modelContext.insert(token)
        try? modelContext.save()
        let amt = amount > 0 ? " · \(String(format: "%.2f", amount))" : ""
        return "noted intention: \(subject)\(amt)"
    }

    private static func executeAddCommitment(input: [String: Any], modelContext: ModelContext, sessionViewModel: SessionViewModel) -> String {
        guard let subject = input["subject"] as? String else { return "error: missing subject." }
        guard let amount = input["amount"] as? Double else { return "error: missing amount." }
        guard let occurredAt = parseDate(input["date"] as? String) else {
            return "error: missing or invalid date (use ISO8601)."
        }
        // userAdjustedAt doubles as the commitment stamp: `occurredAt` holds
        // the due date, so without this the activity feed would have no
        // trustworthy "committed on" date.
        let token = NoteToken(
            kind: .commit,
            amount: amount,
            currency: currencyCode(sessionViewModel),
            subject: subject,
            occurredAt: occurredAt,
            userAdjustedAt: Date()
        )
        modelContext.insert(token)
        try? modelContext.save()
        return "committed: \(subject) · \(String(format: "%.2f", amount)) · \(Self.shortDate.string(from: occurredAt))"
    }

    private static func executeSetBalance(input: [String: Any], modelContext: ModelContext, sessionViewModel: SessionViewModel) async -> String {
        guard let amount = input["amount"] as? Double else { return "error: missing amount." }
        guard var profile = sessionViewModel.currentUser else { return "no user profile to update." }
        var settings = profile.settings
        settings.freedomFund = amount
        profile.freedomFund = amount
        FreedomFundLedger.recordIfChanged(
            in: modelContext,
            userId: profile.userId,
            newBalance: amount,
            source: .manualEdit
        )
        profile.settings = settings
        await sessionViewModel.updateUserProfile(profile)
        return "balance re-anchored to \(String(format: "%.2f", amount))"
    }

    private static func executeProjectRunway(input: [String: Any], modelContext: ModelContext, sessionViewModel: SessionViewModel, freedomFund: Double, totalMonthlyBills: Double) -> String {
        guard let cost = input["cost"] as? Double else { return "error: missing cost." }
        let userId = sessionViewModel.currentUser?.userId
        let entries = ((try? modelContext.fetch(FetchDescriptor<FreedomFundEntry>())) ?? [])
            .filter { userId == nil || $0.userId == userId }
        let burn = ArcCalculationService.dailyBurn(entries: entries, monthlyBills: totalMonthlyBills)
        guard burn > 0 else { return "can't project runway yet — no burn rate and no bills to estimate from." }
        let nowDays = Int(floor(freedomFund / burn))
        let afterDays = Int(floor(max(0, freedomFund - cost) / burn))
        let now = ArcCalculationService.compactRunway(days: nowDays)
        let after = ArcCalculationService.compactRunway(days: afterDays)
        let nowTier = ArcCalculationService.getStateName(days: nowDays)
        let afterTier = ArcCalculationService.getStateName(days: afterDays)
        let tierNote = nowTier == afterTier ? "" : " (\(nowTier) → \(afterTier))"
        return "now: \(now.value) \(now.unit). after spending \(String(format: "%.2f", cost)): \(after.value) \(after.unit)\(tierNote) — that's \(nowDays - afterDays) fewer days."
    }

    private static func executeUpdateBill(input: [String: Any], bills: [Bill], billViewModel: BillViewModel) async -> String {
        guard let billName = input["bill_name"] as? String else {
            return "error: missing bill_name."
        }
        let query = billName.lowercased()
        guard var bill = bills.first(where: { $0.name.lowercased().contains(query) }) else {
            return "no bill matching '\(billName)' found."
        }

        var changes: [String] = []
        if let newAmount = input["amount"] as? Double {
            bill.amount = newAmount
            changes.append("amount → \(newAmount)")
        }
        if let newName = input["name"] as? String {
            bill.name = newName
            changes.append("name → \(newName)")
        }

        guard !changes.isEmpty else { return "nothing to update." }
        await billViewModel.updateBill(bill)
        return "updated \(bill.name): \(changes.joined(separator: ", "))"
    }

    private static func executeBills(bills: [Bill]) -> String {
        guard !bills.isEmpty else { return "no active bills." }
        let lines = bills.map { bill in
            let freq = bill.frequency.rawValue.lowercased()
            let dateStr = Self.shortDate.string(from: bill.dueDate)
            return "- \(bill.name): \(bill.amount) (\(freq), due \(dateStr))"
        }
        return "active bills:\n\(lines.joined(separator: "\n"))"
    }

    private static func executeFreedomFund(balance: Double, monthlyBills: Double) -> String {
        let runway: String
        if monthlyBills > 0 {
            let months = balance / monthlyBills
            runway = String(format: "%.1f months of runway", months)
        } else {
            runway = "no bills to calculate runway"
        }
        return "balance: \(String(format: "%.2f", balance)). \(runway)."
    }

    private static func executeGetProfile(modelContext: ModelContext, sessionViewModel: SessionViewModel) -> String {
        var lines: [String] = []

        if let settings = sessionViewModel.currentUser?.settings {
            lines.append("currency: \(settings.currency)")
            if settings.monthlyIncome > 0 {
                lines.append("monthly income: \(settings.monthlyIncome)")
            }
            if settings.freedomFund > 0 {
                lines.append("freedom fund: \(settings.freedomFund)")
            }
        }

        let descriptor = FetchDescriptor<UserProfile>()
        if let userProfile = try? modelContext.fetch(descriptor).first {
            if let day = userProfile.payday {
                lines.append("payday: day \(day) of month")
            }
            if let freq = userProfile.incomeFrequency {
                lines.append("income frequency: \(freq)")
            }
            if let floor = userProfile.runwayFloor {
                lines.append("runway floor: \(floor) months")
            }
            if !userProfile.facts.isEmpty {
                lines.append("")
                lines.append("things norma knows:")
                for fact in userProfile.facts {
                    lines.append("- \(fact.fact) (from: \(fact.source))")
                }
            }
        }

        return lines.isEmpty ? "no profile saved yet." : lines.joined(separator: "\n")
    }

    private static func executeSaveFact(input: [String: Any], modelContext: ModelContext) -> String {
        guard let fact = input["fact"] as? String else {
            return "error: missing fact text."
        }
        let source = (input["source"] as? String) ?? "norma chat"

        let descriptor = FetchDescriptor<UserProfile>()
        let profile: UserProfile
        if let existing = try? modelContext.fetch(descriptor).first {
            profile = existing
        } else {
            profile = UserProfile()
            modelContext.insert(profile)
        }

        profile.addFact(fact, source: source)
        try? modelContext.save()
        return "saved: \(fact)"
    }

    private static func executeUpdateProfile(input: [String: Any], modelContext: ModelContext, sessionViewModel: SessionViewModel) async -> String {
        var updated: [String] = []

        // Currency and income live on ProfileSettings (Supabase-backed)
        if var profile = sessionViewModel.currentUser {
            var changed = false
            if let currency = input["currency"] as? String {
                profile.settings.currency = currency
                changed = true
                updated.append("currency → \(currency)")
            }
            if let amount = input["income_amount"] as? Double {
                profile.settings.monthlyIncome = amount
                changed = true
                updated.append("income → \(amount)")
            }
            if changed {
                await sessionViewModel.updateUserProfile(profile)
            }
        }

        // Payday, frequency, runway floor live on UserProfile (local)
        let descriptor = FetchDescriptor<UserProfile>()
        let userProfile: UserProfile
        if let existing = try? modelContext.fetch(descriptor).first {
            userProfile = existing
        } else {
            userProfile = UserProfile()
            modelContext.insert(userProfile)
        }

        // Mirror income + currency onto the local profile so its fallback
        // values track the canonical server settings written above.
        if let amount = input["income_amount"] as? Double {
            userProfile.incomeAmount = amount
        }
        if let currency = input["currency"] as? String {
            userProfile.currency = currency
        }

        if let freq = input["income_frequency"] as? String {
            userProfile.incomeFrequency = freq
            updated.append("frequency → \(freq)")
        }
        if let day = input["payday"] as? Int {
            userProfile.payday = day
            updated.append("payday → day \(day)")
        }
        if let floor = input["runway_floor"] as? Double {
            userProfile.runwayFloor = floor
            updated.append("runway floor → \(floor) months")
        }

        userProfile.updatedAt = Date()
        try? modelContext.save()
        return updated.isEmpty ? "nothing to update." : "updated: \(updated.joined(separator: ", "))"
    }

    private static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()
}
