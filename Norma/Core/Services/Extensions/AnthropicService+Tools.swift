//
//  AnthropicService+Tools.swift
//  Norma
//
//  Created by Claude on 6/29/25.
//

import Foundation

extension AnthropicService {
    
    // MARK: - Generic Tool Builder
    
    /// Generic tool builder for any Codable type
    func createTool<T: Codable>(
        name: String,
        description: String,
        for type: T.Type
    ) -> AnthropicTool {
        let schema = generateSchema(for: type)
        return AnthropicTool(
            name: name,
            description: description,
            inputSchema: schema
        )
    }
    
    /// Generic tool execution method
    func executeToolExtraction<T: Codable>(
        from conversationHistory: [AnthropicMessage],
        tool: AnthropicTool,
        systemPrompt: String = "You are a helpful assistant that extracts structured data from conversations.",
        targetType: T.Type
    ) async throws -> T {
        let response = try await sendMessageWithTools(
            messages: conversationHistory,
            systemPrompt: systemPrompt,
            tools: [tool],
            toolChoice: AnthropicToolChoice(type: "tool", name: tool.name)
        )
        
        if case .toolUse(_, _, let input) = response {
            return try parseToolInput(input, as: targetType)
        } else {
            throw AnthropicError.dataParsingError
        }
    }
    
    // MARK: - Schema Generation
    
    private func generateSchema<T: Codable>(for type: T.Type) -> AnthropicToolSchema {
        // This is a simplified version - in a real implementation,
        // you'd use reflection or a more sophisticated approach
        
        if type == UserOnboardingData.self {
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
        
        // Add more schemas as needed for other models
        return AnthropicToolSchema(type: "object", properties: [:], required: [])
    }
    
    // MARK: - Input Parsing
    
    /// Public wrapper for parsing tool input data
    func parseVoiceToolInput<T: Codable>(_ input: [String: Any], as type: T.Type) throws -> T {
        return try parseToolInput(input, as: type)
    }
    
    private func parseToolInput<T: Codable>(_ input: [String: Any], as type: T.Type) throws -> T {
        if type == UserOnboardingData.self {
            let name = input["name"] as? String ?? ""
            let currency = input["currency"] as? String ?? "USD"
            let monthlyIncome = input["monthlyIncome"] as? Double ?? 0
            let freedomFund = input["freedomFund"] as? Double ?? 0
            let painPoint = input["painPoint"] as? String ?? ""
            let reminderPreference = input["reminderPreference"] as? String ?? ""

            let result = UserOnboardingData(
                name: name,
                currency: currency,
                monthlyIncome: monthlyIncome,
                freedomFund: freedomFund,
                painPoint: painPoint,
                reminderPreference: reminderPreference
            )

            return result as! T
        }
        
        // Handle VoiceBillData
        if type == VoiceBillData.self {
            guard let name = input["name"] as? String else {
                throw AnthropicError.dataParsingError
            }
            guard let amount = input["amount"] as? Double else {
                throw AnthropicError.dataParsingError
            }
            guard let dueDate = input["dueDate"] as? String else {
                throw AnthropicError.dataParsingError
            }
            guard let frequencyString = input["frequency"] as? String else {
                throw AnthropicError.dataParsingError
            }
            
            let frequency = BillFrequency(rawValue: frequencyString) ?? .monthly
            let merchant = input["merchant"] as? String ?? ""
            let isReminderOn = input["isReminderOn"] as? Bool ?? false
            let reminderDays = input["reminderDays"] as? Int
            let notes = input["notes"] as? String ?? ""
            
            let result = VoiceBillData(
                name: name,
                amount: amount,
                dueDate: dueDate,
                frequency: frequency,
                merchant: merchant,
                isReminderOn: isReminderOn,
                reminderDays: reminderDays,
                notes: notes
            )
            
            return result as! T
        }
        
        // Add parsing for other types as needed
        throw AnthropicError.dataParsingError
    }
}

// MARK: - Voice Agent Data Models

struct VoiceBillData: Codable {
    let name: String
    let amount: Double
    let dueDate: String
    let frequency: BillFrequency
    let merchant: String
    let isReminderOn: Bool
    let reminderDays: Int?
    let notes: String
}

// MARK: - Tool Definitions

extension AnthropicService {
    
    /// Pre-defined tools for common use cases
    static var userDataExtractionTool: AnthropicTool {
        return AnthropicTool(
            name: "extract_user_data",
            description: "Extract user onboarding information from the conversation",
            inputSchema: AnthropicToolSchema(
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
        )
    }
    
    // Future tools can be added here:
    /*
    static var billExtractionTool: AnthropicTool {
        return AnthropicTool(
            name: "extract_bill_data",
            description: "Extract bill information from user conversation",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "name": AnthropicToolProperty(type: "string", description: "Bill name"),
                    "amount": AnthropicToolProperty(type: "number", description: "Bill amount"),
                    "dueDate": AnthropicToolProperty(type: "string", description: "Due date in ISO format"),
                    "frequency": AnthropicToolProperty(type: "string", description: "Bill frequency")
                ],
                required: ["name", "amount", "dueDate", "frequency"]
            )
        )
    }
    
    static var expenseExtractionTool: AnthropicTool {
        // Similar pattern for expenses
    }
    */
}