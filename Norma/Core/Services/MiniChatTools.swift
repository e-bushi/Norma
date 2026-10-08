//
//  MiniChatTools.swift
//  Norma
//
//  Created by Claude on 5/26/26.
//
//  Tool definitions and executor for Norma's chat. Norma can read bills,
//  the balance, and the profile; create bills, reminders, intentions, and
//  commitments; re-anchor the balance; and save facts.
//

import Foundation
import SwiftData

// MARK: - Tool definitions

/// Model-agnostic description of a chat tool. MiniChatService turns each
/// spec into a Foundation Models tool with a matching generation schema.
struct ChatToolSpec: Sendable {
    enum ParameterType: Sendable {
        case string
        case number
        case integer
        case choice([String])
    }

    struct Parameter: Sendable {
        let name: String
        let description: String
        let type: ParameterType
        let isOptional: Bool

        static func required(_ name: String, _ type: ParameterType, _ description: String) -> Parameter {
            Parameter(name: name, description: description, type: type, isOptional: false)
        }

        static func optional(_ name: String, _ type: ParameterType, _ description: String) -> Parameter {
            Parameter(name: name, description: description, type: type, isOptional: true)
        }
    }

    let name: String
    let description: String
    let parameters: [Parameter]
}

/// Descriptions are deliberately terse: every schema is spent against the
/// on-device model's 4,096-token context window on each turn.
enum MiniChatToolsProvider {
    static let all: [ChatToolSpec] = [
        ChatToolSpec(
            name: "get_bills",
            description: "List the user's bills with amounts, due dates, and frequency.",
            parameters: []
        ),
        ChatToolSpec(
            name: "update_bill",
            description: "Change an existing bill's amount or name. Call get_bills first to find it.",
            parameters: [
                .required("bill_name", .string, "Current name of the bill"),
                .optional("amount", .number, "New amount"),
                .optional("name", .string, "New name")
            ]
        ),
        ChatToolSpec(
            name: "get_freedom_fund",
            description: "Get the user's balance and months of runway.",
            parameters: []
        ),
        ChatToolSpec(
            name: "get_profile",
            description: "Get the user's currency, income, payday, runway floor, and saved facts.",
            parameters: []
        ),
        ChatToolSpec(
            name: "save_fact",
            description: "Remember a durable financial fact the user shared, like a loan or a habit.",
            parameters: [
                .required("fact", .string, "The fact, in plain language"),
                .optional("source", .string, "Where it came from")
            ]
        ),
        ChatToolSpec(
            name: "update_profile",
            description: "Update profile fields. Include only fields that change.",
            parameters: [
                .optional("currency", .string, "Currency code, e.g. USD"),
                .optional("income_amount", .number, "Monthly income"),
                .optional("income_frequency", .choice(["monthly", "biweekly", "irregular"]), "How often they're paid"),
                .optional("payday", .integer, "Day of month income lands"),
                .optional("runway_floor", .number, "Minimum months of runway they want")
            ]
        ),
        ChatToolSpec(
            name: "add_bill",
            description: "Create a recurring or one-time bill.",
            parameters: [
                .required("name", .string, "Bill name, e.g. rent"),
                .required("amount", .number, "Bill amount"),
                .optional("frequency", .choice(["monthly", "quarterly", "yearly", "onetime"]), "How often it's due"),
                .optional("due_date", .string, "Next due date, yyyy-MM-dd")
            ]
        ),
        ChatToolSpec(
            name: "add_reminder",
            description: "Schedule a notification reminder.",
            parameters: [
                .required("subject", .string, "What to remind about"),
                .required("remind_at", .string, "When, yyyy-MM-dd or yyyy-MM-dd'T'HH:mm:ss")
            ]
        ),
        ChatToolSpec(
            name: "add_intention",
            description: "Record a purchase or trip the user is considering but hasn't scheduled.",
            parameters: [
                .required("subject", .string, "What they're considering"),
                .optional("amount", .number, "Estimated cost"),
                .optional("date", .string, "Rough date, yyyy-MM-dd")
            ]
        ),
        ChatToolSpec(
            name: "add_commitment",
            description: "Record a decided one-time expense on a specific date.",
            parameters: [
                .required("subject", .string, "What it is"),
                .required("amount", .number, "Amount"),
                .required("date", .string, "Due date, yyyy-MM-dd")
            ]
        ),
        ChatToolSpec(
            name: "set_balance",
            description: "Re-anchor the user's total spendable balance.",
            parameters: [
                .required("amount", .number, "New total balance")
            ]
        ),
        ChatToolSpec(
            name: "project_runway",
            description: "Show how a one-time cost would change runway. Use for 'can I afford X?'.",
            parameters: [
                .required("cost", .number, "The one-time cost")
            ]
        )
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
        sessionViewModel.updateUserProfile(profile)
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
                sessionViewModel.updateUserProfile(profile)
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
