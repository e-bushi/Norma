//
//  UserProfile.swift
//  Norma
//
//  Created by Claude on 5/26/26.
//
//  Persistent memory for Norma's AI. Stores structured financial fields
//  the app reads programmatically, plus freeform facts the AI learns
//  from notes and mini chat conversations. Local-first via SwiftData.
//

import Foundation
import SwiftData

struct FinancialFact: Codable, Identifiable {
    let id: UUID
    let fact: String
    let source: String
    let savedAt: Date

    init(id: UUID = UUID(), fact: String, source: String, savedAt: Date = Date()) {
        self.id = id
        self.fact = fact
        self.source = source
        self.savedAt = savedAt
    }
}

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID

    // MARK: - Fixed fields

    var currency: String
    var incomeAmount: Double?
    var incomeFrequency: String?
    var payday: Int?
    var runwayFloor: Double?

    // MARK: - Freeform facts

    var facts: [FinancialFact]

    // MARK: - Timestamps

    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        currency: String = "USD",
        incomeAmount: Double? = nil,
        incomeFrequency: String? = nil,
        payday: Int? = nil,
        runwayFloor: Double? = nil,
        facts: [FinancialFact] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.currency = currency
        self.incomeAmount = incomeAmount
        self.incomeFrequency = incomeFrequency
        self.payday = payday
        self.runwayFloor = runwayFloor
        self.facts = facts
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Fact management

    func addFact(_ fact: String, source: String) {
        facts.append(FinancialFact(fact: fact, source: source))
        updatedAt = Date()
    }

    func removeFact(id: UUID) {
        facts.removeAll { $0.id == id }
        updatedAt = Date()
    }

    /// Formatted summary for injection into AI system prompts.
    var aiContext: String {
        var lines: [String] = []
        lines.append("currency: \(currency)")
        if let amount = incomeAmount {
            lines.append("income: \(amount) (\(incomeFrequency ?? "unknown frequency"))")
        }
        if let day = payday {
            lines.append("payday: day \(day) of month")
        }
        if let floor = runwayFloor {
            lines.append("runway floor: \(floor) months")
        }
        if !facts.isEmpty {
            lines.append("")
            lines.append("things norma knows:")
            for fact in facts {
                lines.append("- \(fact.fact) (from: \(fact.source))")
            }
        }
        return lines.joined(separator: "\n")
    }
}
