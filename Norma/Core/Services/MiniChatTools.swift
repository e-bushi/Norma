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
            updateProfileTool
        ]
    }

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
        totalMonthlyBills: Double,
        note: Note
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
            return executeSaveFact(input: input, modelContext: modelContext, note: note)
        case "update_profile":
            return await executeUpdateProfile(input: input, modelContext: modelContext, sessionViewModel: sessionViewModel)
        default:
            return "unknown tool: \(name)"
        }
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
        return "freedom fund: \(String(format: "%.2f", balance)). \(runway)."
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

    private static func executeSaveFact(input: [String: Any], modelContext: ModelContext, note: Note) -> String {
        guard let fact = input["fact"] as? String else {
            return "error: missing fact text."
        }
        let source = (input["source"] as? String) ?? "mini chat, \(note.title ?? "untitled")"

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
