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
                    "monthlyIncome": AnthropicToolProperty(type: "number", description: "User's monthly income amount"),
                    "primaryGoal": AnthropicToolProperty(type: "string", description: "User's primary financial goal"),
                    "reminderPreference": AnthropicToolProperty(type: "string", description: "When user wants bill reminders")
                ],
                required: ["name", "currency", "monthlyIncome", "primaryGoal", "reminderPreference"]
            )
        }
        
        // Add more schemas as needed for other models
        return AnthropicToolSchema(type: "object", properties: [:], required: [])
    }
    
    // MARK: - Input Parsing
    
    private func parseToolInput<T: Codable>(_ input: [String: Any], as type: T.Type) throws -> T {
        if type == UserOnboardingData.self {
            let name = input["name"] as? String ?? ""
            let currency = input["currency"] as? String ?? "USD"
            let monthlyIncome = input["monthlyIncome"] as? Double ?? 0
            let primaryGoal = input["primaryGoal"] as? String ?? ""
            let reminderPreference = input["reminderPreference"] as? String ?? ""
            
            let result = UserOnboardingData(
                name: name,
                currency: currency,
                monthlyIncome: monthlyIncome,
                primaryGoal: primaryGoal,
                reminderPreference: reminderPreference
            )
            
            return result as! T
        }
        
        // Add parsing for other types as needed
        throw AnthropicError.dataParsingError
    }
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
                    "monthlyIncome": AnthropicToolProperty(type: "number", description: "User's monthly income amount"),
                    "primaryGoal": AnthropicToolProperty(type: "string", description: "User's primary financial goal"),
                    "reminderPreference": AnthropicToolProperty(type: "string", description: "When user wants bill reminders")
                ],
                required: ["name", "currency", "monthlyIncome", "primaryGoal", "reminderPreference"]
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