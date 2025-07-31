//
//  AnthropicService.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation

class AnthropicService {
    static let shared = AnthropicService()
    
    private let apiKey = "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"
    private let baseURL = "https://api.anthropic.com/v1/messages"
    
    // Model cascade in order of preference
    private let modelCascade = [
        "claude-sonnet-4-20250514",
        "claude-3-7-sonnet-20250219", 
        "claude-3-5-sonnet-20241022",
        "claude-3-5-haiku-20241022",
        "claude-3-haiku-20240307"
    ]
    
    private init() {}
    
    // MARK: - Model Cascading Helper
    
    private func sendRequestWithModelCascade<T>(
        messages: [AnthropicMessage],
        systemPrompt: String,
        tools: [AnthropicTool]? = nil,
        toolChoice: AnthropicToolChoice? = nil,
        maxTokens: Int = 1000,
        responseHandler: (Data) throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for model in modelCascade {
            do {
                print("🔄 Trying model: \(model)")
                
                var request = URLRequest(url: URL(string: baseURL)!)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
                request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
                
                let requestBody = AnthropicRequest(
                    model: model,
                    maxTokens: maxTokens,
                    system: systemPrompt,
                    messages: messages,
                    tools: tools,
                    toolChoice: toolChoice
                )
                
                request.httpBody = try JSONEncoder().encode(requestBody)
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw AnthropicError.networkError
                }
                
                if httpResponse.statusCode == 200 {
                    print("✅ Successfully used model: \(model)")
                    return try responseHandler(data)
                } else if httpResponse.statusCode == 529 {
                    // Overloaded - try next model
                    print("⚠️ Model \(model) is overloaded, trying next model...")
                    if let errorData = try? JSONDecoder().decode(AnthropicErrorResponse.self, from: data) {
                        lastError = AnthropicError.apiError(errorData.error.message)
                    } else {
                        lastError = AnthropicError.unknownError(httpResponse.statusCode)
                    }
                    continue
                } else {
                    // Other errors - still try next model but save error
                    if let errorData = try? JSONDecoder().decode(AnthropicErrorResponse.self, from: data) {
                        lastError = AnthropicError.apiError(errorData.error.message)
                    } else {
                        lastError = AnthropicError.unknownError(httpResponse.statusCode)
                    }
                    
                    // For non-overload errors, we might still want to try the next model
                    if httpResponse.statusCode == 400 || httpResponse.statusCode == 401 {
                        // Auth or bad request - likely won't work with other models either
                        throw lastError!
                    }
                    continue
                }
            } catch {
                lastError = error
                print("❌ Failed with model \(model): \(error)")
                continue
            }
        }
        
        // If we get here, all models failed
        throw lastError ?? AnthropicError.unknownError(0)
    }
    
    func sendMessage(
        messages: [AnthropicMessage],
        systemPrompt: String,
        maxTokens: Int = 1000
    ) async throws -> String {
        return try await sendRequestWithModelCascade(
            messages: messages,
            systemPrompt: systemPrompt,
            maxTokens: maxTokens
        ) { data in
            let anthropicResponse = try JSONDecoder().decode(AnthropicResponse.self, from: data)
            return anthropicResponse.content.first?.text ?? ""
        }
    }
    
    func sendMessageWithTools(
        messages: [AnthropicMessage],
        systemPrompt: String,
        tools: [AnthropicTool],
        toolChoice: AnthropicToolChoice? = nil,
        maxTokens: Int = 1000
    ) async throws -> AnthropicMessageContent {
        return try await sendRequestWithModelCascade(
            messages: messages,
            systemPrompt: systemPrompt,
            tools: tools,
            toolChoice: toolChoice,
            maxTokens: maxTokens
        ) { data in
            let anthropicResponse = try JSONDecoder().decode(AnthropicResponse.self, from: data)
            
            // Look for tool use in the content array
            for content in anthropicResponse.content {
                if content.type == "tool_use" {
                    if let id = content.id,
                       let name = content.name,
                       let input = content.input {
                        return .toolUse(id: id, name: name, input: input)
                    }
                }
            }
            
            // If no tool use found, return the first text content
            for content in anthropicResponse.content {
                if content.type == "text", let text = content.text {
                    return .text(text)
                }
            }
            
            return .text("")
        }
    }
    
    // MARK: - Conversation Methods
    
    func startOnboardingConversation(userName: String) async throws -> String {
        let systemPrompt = NormaSystemPrompts.onboardingSystemPrompt(userName: userName)
        let messages = [AnthropicMessage(role: "user", content: .text("Hi, I just signed up for Norma!"))]
        
        return try await sendMessage(messages: messages, systemPrompt: systemPrompt)
    }
    
    func continueOnboardingConversation(
        conversationHistory: [AnthropicMessage],
        userMessage: String,
        userName: String
    ) async throws -> AnthropicMessageContent {
        let systemPrompt = NormaSystemPrompts.onboardingSystemPrompt(userName: userName)
        var messages = conversationHistory
        messages.append(AnthropicMessage(role: "user", content: .text(userMessage)))
        
        // Include the extraction tool so Claude can use it when ready
        let tool = Self.userDataExtractionTool
        
        return try await sendMessageWithTools(
            messages: messages,
            systemPrompt: systemPrompt,
            tools: [tool],
            toolChoice: nil // Let Claude decide when to use the tool
        )
    }
    
    // MARK: - Specific Tool Extraction Methods
    
    func extractUserData(from conversationHistory: [AnthropicMessage]) async throws -> UserOnboardingData {
        let tool = Self.userDataExtractionTool
        let systemPrompt = NormaSystemPrompts.extractUserDataPrompt()
        
        return try await executeToolExtraction(
            from: conversationHistory,
            tool: tool,
            systemPrompt: systemPrompt,
            targetType: UserOnboardingData.self
        )
    }
    
    // MARK: - Generic Tool Extraction
    
    /// Generic method for extracting any ToolExtractable type
    func extractData<T: ToolExtractable>(
        from conversationHistory: [AnthropicMessage],
        as type: T.Type,
        systemPrompt: String = "You are a helpful assistant that extracts structured data from conversations."
    ) async throws -> T {
        let tool = T.anthropicTool
        
        let response = try await sendMessageWithTools(
            messages: conversationHistory,
            systemPrompt: systemPrompt,
            tools: [tool],
            toolChoice: AnthropicToolChoice(type: "tool", name: tool.name)
        )
        
        if case .toolUse(_, _, let input) = response {
            return try T.parse(from: input)
        } else {
            throw AnthropicError.dataParsingError
        }
    }
}
