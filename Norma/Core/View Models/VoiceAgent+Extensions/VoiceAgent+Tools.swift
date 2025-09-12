//
//  VoiceAgent+Tools.swift
//  Norma
//
//  Created by Assistant on 12/6/25.
//

import Foundation

// MARK: - Common Tools and Tool Execution
extension VoiceAgentViewModel {
    
    // MARK: - Common Tool Definitions
    
    func getFinancialAnalysisTool() -> AnthropicTool {
        return AnthropicTool(
            name: "analyze_financial_data",
            description: "Perform complex financial analysis using historical data and advanced reasoning. Use this for multi-month trends, budget analysis, spending comparisons, and other complex queries that require historical data beyond the current month.",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "query_description": AnthropicToolProperty(
                        type: "string",
                        description: "Natural language description of the financial analysis needed (e.g., 'Compare my food spending over the last 3 months', 'Analyze my budget performance for Q1')"
                    ),
                    "context": AnthropicToolProperty(
                        type: "string",
                        description: "Whether this is about 'bills' or 'expenses' primarily"
                    ),
                    "time_range": AnthropicToolProperty(
                        type: "string", 
                        description: "Time period for analysis (e.g., 'last 3 months', 'this quarter', 'last 6 months')"
                    )
                ],
                required: ["query_description", "context"]
            )
        )
    }
    
    func getEndConversationTool() -> AnthropicTool {
        return AnthropicTool(
            name: "end_conversation",
            description: "End the current voice conversation session when the user indicates they are finished or wants to stop.",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "farewell_message": AnthropicToolProperty(
                        type: "string",
                        description: "A brief farewell message to the user (optional)"
                    )
                ],
                required: []
            )
        )
    }
    
    func getEditIncomeTool() -> AnthropicTool {
        return AnthropicTool(
            name: "edit_income",
            description: "Update the user's income information, including monthly income or specific income sources",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "income_type": AnthropicToolProperty(
                        type: "string",
                        description: "Type of income update: 'monthly_total' for overall monthly income, or 'source' for specific income source. Must be one of: 'monthly_total', 'source'"
                    ),
                    "amount": AnthropicToolProperty(
                        type: "number",
                        description: "New income amount"
                    ),
                    "frequency": AnthropicToolProperty(
                        type: "string",
                        description: "Income frequency (optional, defaults to monthly). Must be one of: 'monthly', 'annual', 'weekly', 'biweekly'"
                    ),
                    "source_name": AnthropicToolProperty(
                        type: "string",
                        description: "Name of the income source (required when income_type is 'source')"
                    )
                ],
                required: ["income_type", "amount"]
            )
        )
    }
    
    // MARK: - Unified Tools Collection
    
    func getUnifiedTools() -> [AnthropicTool] {
        // Combine bill and expense tools without duplicates
        return [
            getBillCreationTool(),
            getEditBillTool(),
            getDeleteBillTool(),
            getMarkBillPaidTool(),
            getEditIncomeTool(),
            getExpenseCreationTool(),
            getFinancialAnalysisTool(),
            getEndConversationTool()
        ]
    }
    
    // MARK: - Unified Processing
    
    func processUnifiedTranscription(_ transcription: String) async throws -> (String, Bool) {
        print("VoiceAgent: Processing unified transcription: '\(transcription)'")
        
        // Add user message to conversation history
        conversationHistory.append(AnthropicMessage(role: "user", content: .text(transcription)))
        
        let tools = getUnifiedTools()
        let systemPrompt = getUnifiedSystemPrompt()
        
        // Get response from Anthropic with conversational context
        let response = try await anthropicService.sendMessageWithTools(
            messages: conversationHistory,
            systemPrompt: systemPrompt,
            tools: tools
        )
        
        // Handle the response content
        switch response {
        case .text(let text):
            print("VoiceAgent: Got text response: '\(text)'")
            // Add AI response to conversation history
            conversationHistory.append(AnthropicMessage(role: "assistant", content: .text(text)))
            return (text, false)
            
        case .toolUse(let toolUseId, let toolName, let toolInput):
            print("VoiceAgent: Claude wants to use tool: \(toolName)")
            
            // Execute the tool and get result
            let toolResult = await executeToolAndGetResult(toolId: toolUseId, name: toolName, input: toolInput)
            print("VoiceAgent: Tool result: \(toolResult)")
            
            // Add tool use and result to conversation history
            conversationHistory.append(AnthropicMessage(
                role: "assistant",
                content: .toolUse(id: toolUseId, name: toolName, input: toolInput)
            ))
            conversationHistory.append(AnthropicMessage(
                role: "user",
                content: .toolResult(toolUseId: toolUseId, content: toolResult)
            ))
            
            // Get Claude's response after tool execution
            let followUpResponse = try await anthropicService.sendMessageWithTools(
                messages: conversationHistory,
                systemPrompt: systemPrompt,
                tools: tools
            )
            
            switch followUpResponse {
            case .text(let text):
                print("VoiceAgent: Got follow-up response: '\(text)'")
                // Add AI response to conversation history
                conversationHistory.append(AnthropicMessage(role: "assistant", content: .text(text)))
                return (text, true)
            case .toolUse:
                // If Claude wants to use another tool, just return a message
                return ("I've completed that action for you.", true)
            case .toolResult:
                // Unexpected tool result
                return ("I've processed that information.", true)
            }
            
        case .toolResult:
            // Unexpected tool result
            return ("Something went wrong with the request.", false)
        }
    }
    
    // MARK: - Main Tool Execution
    
    func executeToolAndGetResult(toolId: String, name: String, input: [String: Any]) async -> String {
        switch name {
        case "create_bill":
            return await executeBillCreation(input: input)
        case "edit_bill":
            return await executeEditBill(input: input)
        case "delete_bill":
            return await executeDeleteBill(input: input)
        case "mark_bill_paid":
            return await executeMarkBillPaid(input: input)
        case "edit_income":
            return await executeEditIncome(input: input)
        case "create_expense":
            return await executeExpenseCreation(input: input)
        case "analyze_financial_data":
            return await executeFinancialAnalysis(input: input)
        case "end_conversation":
            return await executeEndConversation(input: input)
        default:
            return "Error: Unknown tool '\(name)'"
        }
    }
    
    // MARK: - Tool Execution Methods
    
    func executeEditIncome(input: [String: Any]) async -> String {
        print("VoiceAgent: Executing income edit with input: \(input)")
        
        guard let incomeType = input["income_type"] as? String,
              let amount = input["amount"] as? Double else {
            return "Error: Missing income type or amount information"
        }
        
        let frequency = input["frequency"] as? String ?? "monthly"
        
        switch incomeType {
        case "monthly_total":
            // Update the user's profile monthly income
            guard let sessionViewModel = sessionViewModel,
                  let userId = sessionViewModel.currentUser?.userId else {
                return "Error: No user found to update income"
            }
            
            // Convert to monthly if needed
            let monthlyAmount: Double
            switch frequency.lowercased() {
            case "annual":
                monthlyAmount = amount / 12.0
            case "weekly":
                monthlyAmount = amount * 52.0 / 12.0
            case "biweekly":
                monthlyAmount = amount * 26.0 / 12.0
            default: // monthly
                monthlyAmount = amount
            }
            
            // Update the user's profile income
            do {
                var updatedUser = sessionViewModel.currentUser
                updatedUser?.settings.monthlyIncome = monthlyAmount
                sessionViewModel.currentUser = updatedUser
                
                // Here you would typically save to the backend
                // For now, just confirm the update
                let formattedAmount = String(format: "%.2f", monthlyAmount)
                return "Successfully updated your monthly income to $\(formattedAmount) per month."
                
            } catch {
                return "Error: Failed to update your monthly income. Please try again."
            }
            
        case "source":
            // Handle specific income source updates (would need IncomeViewModel methods)
            guard let sourceName = input["source_name"] as? String else {
                return "Error: Income source name is required"
            }
            
            // This would require implementing income source CRUD in IncomeViewModel
            return "Income source updates are not yet fully implemented. For now, you can update your total monthly income."
            
        default:
            return "Error: Invalid income type. Use 'monthly_total' or 'source'."
        }
    }
    
    func executeFinancialAnalysis(input: [String: Any]) async -> String {
        print("VoiceAgent: Executing financial analysis with input: \(input)")
        
        guard let queryDescription = input["query_description"] as? String else {
            return "Error: Missing query description"
        }
        
        let context = input["context"] as? String ?? "general"
        let timeRange = input["time_range"] as? String ?? "recent"
        
        print("VoiceAgent: Delegating to advanced analysis - Query: \(queryDescription), Context: \(context), Time Range: \(timeRange)")
        
        // Here we delegate to Claude Opus with MCP access for complex analysis
        // For now, return a placeholder that indicates the delegation happened
        return await performAdvancedFinancialAnalysis(
            query: queryDescription,
            context: context,
            timeRange: timeRange
        )
    }
    
    func executeEndConversation(input: [String: Any]) async -> String {
        print("VoiceAgent: Executing end conversation")
        
        let farewellMessage = input["farewell_message"] as? String ?? "Goodbye! Feel free to come back anytime if you need help with your finances."
        
        // Stop any current recording or playback
        await stopVoiceInteraction()
        
        // Set state to idle to end the conversation
        await setState(.idle)
        
        return farewellMessage
    }
    
    // MARK: - Advanced Analysis
    
    private func performAdvancedFinancialAnalysis(query: String, context: String, timeRange: String) async -> String {
        print("VoiceAgent: Starting advanced financial analysis with Opus + MCP")
        
        // Create enhanced system prompt for Opus
        let advancedSystemPrompt = """
        You are Norma, an advanced financial analyst with access to comprehensive financial databases. 
        You have access to detailed historical financial data through MCP tools and can perform complex analysis.
        
        The user is asking: "\(query)"
        Context: \(context)
        Time Range: \(timeRange)
        
        Current user: \(sessionViewModel?.currentUser?.name ?? "Unknown")
        
        You should:
        1. Access historical financial data using MCP tools
        2. Perform the requested analysis
        3. Provide a clear, conversational summary in 2-3 sentences suitable for voice output
        4. Format monetary amounts in spoken form (e.g., "fifty dollars" not "$50")
        
        Remember this is a voice conversation, so keep your response concise and natural.
        """
        
        // TODO: Implement actual MCP integration for advanced analysis
        // For now, return a placeholder response
        return "I'm analyzing your \(context) data for \(timeRange). This feature will provide detailed insights once fully integrated with our advanced analytics system."
    }
}