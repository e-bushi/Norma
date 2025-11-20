//
//  UIComponent.swift
//  Norma
//
//  Created by Claude on 10/11/25.
//

import Foundation

enum UIComponent: Codable, Equatable {
    case billCards([Bill])
    case expenseCards([Expense])
    case budgetCards([Budget])
    case actionConfirmation(icon: String, message: String, color: String)
    case toolActivity(String)
    case arcDisplay(Int)
    case flowStateCapsule(String) // "In flow", "Stagnant", or "Drifting"

    // For JSON encoding/decoding if needed
    enum CodingKeys: String, CodingKey {
        case type
        case bills
        case expenses
        case budgets
        case icon
        case message
        case color
        case arcCount
        case flowState
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "billCards":
            let bills = try container.decode([Bill].self, forKey: .bills)
            self = .billCards(bills)
        case "expenseCards":
            let expenses = try container.decode([Expense].self, forKey: .expenses)
            self = .expenseCards(expenses)
        case "budgetCards":
            let budgets = try container.decode([Budget].self, forKey: .budgets)
            self = .budgetCards(budgets)
        case "actionConfirmation":
            let icon = try container.decode(String.self, forKey: .icon)
            let message = try container.decode(String.self, forKey: .message)
            let color = try container.decode(String.self, forKey: .color)
            self = .actionConfirmation(icon: icon, message: message, color: color)
        case "toolActivity":
            let message = try container.decode(String.self, forKey: .message)
            self = .toolActivity(message)
        case "arcDisplay":
            let arcCount = try container.decode(Int.self, forKey: .arcCount)
            self = .arcDisplay(arcCount)
        case "flowStateCapsule":
            let flowState = try container.decode(String.self, forKey: .flowState)
            self = .flowStateCapsule(flowState)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .billCards(let bills):
            try container.encode("billCards", forKey: .type)
            try container.encode(bills, forKey: .bills)
        case .expenseCards(let expenses):
            try container.encode("expenseCards", forKey: .type)
            try container.encode(expenses, forKey: .expenses)
        case .budgetCards(let budgets):
            try container.encode("budgetCards", forKey: .type)
            try container.encode(budgets, forKey: .budgets)
        case .actionConfirmation(let icon, let message, let color):
            try container.encode("actionConfirmation", forKey: .type)
            try container.encode(icon, forKey: .icon)
            try container.encode(message, forKey: .message)
            try container.encode(color, forKey: .color)
        case .toolActivity(let message):
            try container.encode("toolActivity", forKey: .type)
            try container.encode(message, forKey: .message)
        case .arcDisplay(let arcCount):
            try container.encode("arcDisplay", forKey: .type)
            try container.encode(arcCount, forKey: .arcCount)
        case .flowStateCapsule(let flowState):
            try container.encode("flowStateCapsule", forKey: .type)
            try container.encode(flowState, forKey: .flowState)
        }
    }
}
