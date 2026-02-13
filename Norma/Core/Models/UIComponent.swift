//
//  UIComponent.swift
//  Norma
//
//  Created by Claude on 10/11/25.
//

import Foundation

enum UIComponent: Codable, Equatable {
    case billCards([Bill], currency: String)
    case expenseCards([Expense], currency: String)
    case challengeCard(Challenge, currency: String)
    case actionConfirmation(icon: String, message: String, color: String)
    case toolActivity(String)
    case arcDisplay(Double)
    case flowStateCapsule(String) // "In flow", "Stagnant", or "Drifting"
    case instructionalImages([String]) // Bundle asset names for instructional image carousel

    // For JSON encoding/decoding if needed
    enum CodingKeys: String, CodingKey {
        case type
        case bills
        case expenses
        case challenge
        case currency
        case icon
        case message
        case color
        case arcCount
        case flowState
        case imageNames
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "billCards":
            let bills = try container.decode([Bill].self, forKey: .bills)
            let currency = try container.decodeIfPresent(String.self, forKey: .currency) ?? "USD"
            self = .billCards(bills, currency: currency)
        case "expenseCards":
            let expenses = try container.decode([Expense].self, forKey: .expenses)
            let currency = try container.decodeIfPresent(String.self, forKey: .currency) ?? "USD"
            self = .expenseCards(expenses, currency: currency)
        case "challengeCard":
            let challenge = try container.decode(Challenge.self, forKey: .challenge)
            let currency = try container.decodeIfPresent(String.self, forKey: .currency) ?? "USD"
            self = .challengeCard(challenge, currency: currency)
        case "actionConfirmation":
            let icon = try container.decode(String.self, forKey: .icon)
            let message = try container.decode(String.self, forKey: .message)
            let color = try container.decode(String.self, forKey: .color)
            self = .actionConfirmation(icon: icon, message: message, color: color)
        case "toolActivity":
            let message = try container.decode(String.self, forKey: .message)
            self = .toolActivity(message)
        case "arcDisplay":
            let arcCount = try container.decode(Double.self, forKey: .arcCount)
            self = .arcDisplay(arcCount)
        case "flowStateCapsule":
            let flowState = try container.decode(String.self, forKey: .flowState)
            self = .flowStateCapsule(flowState)
        case "instructionalImages":
            let imageNames = try container.decode([String].self, forKey: .imageNames)
            self = .instructionalImages(imageNames)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .billCards(let bills, let currency):
            try container.encode("billCards", forKey: .type)
            try container.encode(bills, forKey: .bills)
            try container.encode(currency, forKey: .currency)
        case .expenseCards(let expenses, let currency):
            try container.encode("expenseCards", forKey: .type)
            try container.encode(expenses, forKey: .expenses)
            try container.encode(currency, forKey: .currency)
        case .challengeCard(let challenge, let currency):
            try container.encode("challengeCard", forKey: .type)
            try container.encode(challenge, forKey: .challenge)
            try container.encode(currency, forKey: .currency)
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
        case .instructionalImages(let imageNames):
            try container.encode("instructionalImages", forKey: .type)
            try container.encode(imageNames, forKey: .imageNames)
        }
    }
}
