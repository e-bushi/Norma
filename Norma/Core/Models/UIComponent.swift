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

    // For JSON encoding/decoding if needed
    enum CodingKeys: String, CodingKey {
        case type
        case bills
        case expenses
        case budgets
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
        }
    }
}
