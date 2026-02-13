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
    
    // Model cascade in order of preference (optimized for quality and capability)
    private let modelCascade = [
        "claude-opus-4-6",               // Most capable model - Opus 4.6
        "claude-opus-4-5-20251101",      // Opus 4.5
        "claude-sonnet-4-5-20250929",    // Sonnet 4.5 - excellent balance
        "claude-sonnet-4-20250514",      // Sonnet 4 fallback
        "claude-3-7-sonnet-20250219",    // Solid fallback
        "claude-3-5-sonnet-20241022",    // Additional fallback
        "claude-3-5-haiku-20241022",     // Faster fallback if needed
        "claude-3-haiku-20240307"        // Last resort
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
                    toolChoice: toolChoice,
                    stream: nil
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
    
    // MARK: - Streaming Support
    
    func streamMessageWithTools(
        messages: [AnthropicMessage],
        systemPrompt: String,
        tools: [AnthropicTool]? = nil,
        toolChoice: AnthropicToolChoice? = nil,
        maxTokens: Int = 1000
    ) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream<String, Error> { continuation in
            Task {
                var lastError: Error?
                
                for model in modelCascade {
                    do {
                        print("🔄 Streaming with model: \(model)")
                        
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
                            toolChoice: toolChoice,
                            stream: true  // Enable streaming
                        )
                        
                        request.httpBody = try JSONEncoder().encode(requestBody)
                        
                        let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
                        
                        guard let httpResponse = response as? HTTPURLResponse else {
                            throw AnthropicError.invalidResponse
                        }
                        
                        if httpResponse.statusCode == 200 {
                            print("✅ Successfully connected to streaming endpoint with \(model)")
                            
                            var buffer = ""
                            print("🔄 Starting SSE processing...")
                            
                            for try await byte in asyncBytes {
                                let character = String(data: Data([byte]), encoding: .utf8) ?? ""
                                buffer += character
                                
                                print("📥 Buffer length: \(buffer.count), last 50 chars: '\(String(buffer.suffix(50)))'")
                                
                                // Process complete SSE events
                                while let lineEndRange = buffer.range(of: "\n") {
                                    print("🔍 Processing line, buffer length: \(buffer.count), lineEnd: \(lineEndRange)")
                                    
                                    // More defensive bounds checking
                                    guard buffer.startIndex <= lineEndRange.lowerBound && lineEndRange.lowerBound <= buffer.endIndex else {
                                        print("❌ Invalid line range bounds")
                                        buffer = "" // Reset buffer to recover
                                        break
                                    }
                                    
                                    let line = String(buffer[buffer.startIndex..<lineEndRange.lowerBound])
                                    print("📝 Extracted line: '\(line)'")
                                    
                                    // More defensive removal
                                    guard buffer.startIndex <= lineEndRange.upperBound && lineEndRange.upperBound <= buffer.endIndex else {
                                        print("❌ Invalid removal range bounds")
                                        buffer = "" // Reset buffer to recover
                                        break
                                    }
                                    
                                    // Use a safer approach to remove the line
                                    let remainingStart = lineEndRange.upperBound
                                    if remainingStart < buffer.endIndex {
                                        buffer = String(buffer[remainingStart...])
                                    } else {
                                        buffer = ""
                                    }
                                    
                                    print("🧹 Buffer after removal, length: \(buffer.count)")
                                    
                                    if line.hasPrefix("data: ") {
                                        print("📡 Processing data line")
                                        
                                        // Use substring instead of dropFirst for safety
                                        guard line.count > 6 else {
                                            print("⚠️ Data line too short, skipping")
                                            continue
                                        }
                                        
                                        let jsonData = String(line[line.index(line.startIndex, offsetBy: 6)...])
                                        print("🔧 JSON data: '\(jsonData)'")
                                        
                                        if jsonData == "[DONE]" {
                                            print("✅ Stream completed")
                                            continuation.finish()
                                            return
                                        }
                                        
                                        if let data = jsonData.data(using: .utf8) {
                                            do {
                                                let streamResponse = try JSONDecoder().decode(AnthropicStreamResponse.self, from: data)
                                                
                                                // Handle different stream event types
                                                switch streamResponse.type {
                                                case "message_start":
                                                    print("📡 Stream started")
                                                case "content_block_start":
                                                    print("📡 Content block started")
                                                case "content_block_delta":
                                                    // This is where the actual text content comes
                                                    if let textDelta = streamResponse.delta?.text {
                                                        print("📡 Streaming chunk: '\(textDelta)'")
                                                        continuation.yield(textDelta)
                                                    }
                                                case "content_block_stop":
                                                    print("📡 Content block ended")
                                                case "message_delta":
                                                    print("📡 Message delta")
                                                case "message_stop":
                                                    print("📡 Message completed")
                                                default:
                                                    print("📡 Unknown event type: \(streamResponse.type)")
                                                }
                                                
                                            } catch {
                                                print("⚠️ Failed to decode stream response: \(error)")
                                                print("   Raw JSON: \(jsonData)")
                                            }
                                        }
                                    }
                                }
                            }
                            
                            continuation.finish()
                            return
                            
                        } else if httpResponse.statusCode == 429 {
                            print("⚠️ Rate limited with \(model), trying next model...")
                            lastError = AnthropicError.rateLimited
                            continue
                        } else {
                            print("❌ HTTP error \(httpResponse.statusCode) with \(model), trying next model...")
                            lastError = AnthropicError.invalidResponse
                            continue
                        }
                        
                    } catch {
                        print("❌ Error with \(model): \(error), trying next model...")
                        lastError = error
                        continue
                    }
                }
                
                // If we get here, all models failed
                print("❌ All models failed for streaming request")
                continuation.finish(throwing: lastError ?? AnthropicError.allModelsFailed)
            }
        }
    }
}
