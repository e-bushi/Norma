//
//  ToolExtractable.swift
//  Norma
//
//  Created by Claude on 6/29/25.
//

import Foundation

/// Protocol for models that can be extracted using Anthropic tools
protocol ToolExtractable: Codable {
    /// The name of the tool used for extraction
    static var toolName: String { get }
    
    /// Description of what this tool extracts
    static var toolDescription: String { get }
    
    /// Generate the tool schema for this type
    static var toolSchema: AnthropicToolSchema { get }
    
    /// Parse from tool input dictionary
    static func parse(from input: [String: Any]) throws -> Self
}

// MARK: - Default Implementation

extension ToolExtractable {
    
    /// Create an Anthropic tool for this type
    static var anthropicTool: AnthropicTool {
        return AnthropicTool(
            name: toolName,
            description: toolDescription,
            inputSchema: toolSchema
        )
    }
}

// MARK: - UserOnboardingData Conformance

extension UserOnboardingData: ToolExtractable {
    
    static var toolName: String {
        return "extract_user_data"
    }
    
    static var toolDescription: String {
        return "Extract user onboarding information from the conversation"
    }
    
    static var toolSchema: AnthropicToolSchema {
        return AnthropicToolSchema(
            type: "object",
            properties: [
                "name": AnthropicToolProperty(type: "string", description: "User's first name"),
                "currency": AnthropicToolProperty(type: "string", description: "3-letter currency code (e.g., USD, EUR)"),
                "monthlyIncome": AnthropicToolProperty(type: "number", description: "User's monthly income after taxes"),
                "freedomFund": AnthropicToolProperty(type: "number", description: "User's freedom fund/emergency savings amount"),
                "painPoint": AnthropicToolProperty(type: "string", description: "User's main pain point with money"),
                "reminderPreference": AnthropicToolProperty(type: "string", description: "When user wants bill reminders")
            ],
            required: ["name", "currency", "monthlyIncome", "painPoint", "reminderPreference"]
        )
    }

    static func parse(from input: [String: Any]) throws -> UserOnboardingData {
        let name = input["name"] as? String ?? ""
        let currency = input["currency"] as? String ?? "USD"
        let monthlyIncome = input["monthlyIncome"] as? Double ?? 0
        let freedomFund = input["freedomFund"] as? Double ?? 0
        let painPoint = input["painPoint"] as? String ?? ""
        let reminderPreference = input["reminderPreference"] as? String ?? ""

        return UserOnboardingData(
            name: name,
            currency: currency,
            monthlyIncome: monthlyIncome,
            freedomFund: freedomFund,
            painPoint: painPoint,
            reminderPreference: reminderPreference
        )
    }
}

// MARK: - Future Model Extensions
// When you need to add tool extraction for other models, just extend them:

/*
extension Bill: ToolExtractable {
    static var toolName: String { "extract_bill_data" }
    static var toolDescription: String { "Extract bill information from user conversation" }
    // ... implement toolSchema and parse methods
}

extension Expense: ToolExtractable {
    static var toolName: String { "extract_expense_data" }
    static var toolDescription: String { "Extract expense information from user conversation" }
    // ... implement toolSchema and parse methods
}
*/