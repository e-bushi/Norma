//
//  VoiceAgent+Expenses.swift
//  Norma
//
//  Created by Assistant on 12/6/25.
//

import Foundation

// MARK: - Expense Tools and Methods
extension VoiceAgentViewModel {
    
    // MARK: - Expense Tools Collection
    
    func getExpenseTools() -> [AnthropicTool] {
        return [getExpenseCreationTool(), getFinancialAnalysisTool(), getEndConversationTool()]
    }
    
    // MARK: - Expense Tool Definitions
    
    func getExpenseCreationTool() -> AnthropicTool {
        return AnthropicTool(
            name: "create_expense",
            description: "Create a new expense entry for the user",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "description": AnthropicToolProperty(
                        type: "string",
                        description: "Description of what was purchased or spent money on"
                    ),
                    "amount": AnthropicToolProperty(
                        type: "number",
                        description: "Amount spent as a decimal number (e.g., 14.00, 99.99)"
                    ),
                    "category": AnthropicToolProperty(
                        type: "string",
                        description: "Category of the expense (e.g., 'Food', 'Transportation', 'Entertainment')"
                    ),
                    "date": AnthropicToolProperty(
                        type: "string",
                        description: "Date of expense in YYYY-MM-DD format (defaults to today if not specified)"
                    )
                ],
                required: ["description", "amount", "category", "date"]
            )
        )
    }
    
    // MARK: - Expense Execution Methods
    
    func executeExpenseCreation(input: [String: Any]) async -> String {
        print("VoiceAgent: Executing expense creation with input: \(input)")
        
        guard let expenseViewModel = expenseViewModel else {
            print("VoiceAgent: No ExpenseViewModel available")
            return "Error: Unable to save expense - no expense manager available"
        }
        
        guard let description = input["description"] as? String,
              let category = input["category"] as? String,
              let dateString = input["date"] as? String else {
            return "Error: Missing required information (description, amount, category, or date)"
        }
        
        // Handle amount as either Int or Double
        let amount: Double
        if let doubleAmount = input["amount"] as? Double {
            amount = doubleAmount
        } else if let intAmount = input["amount"] as? Int {
            amount = Double(intAmount)
        } else {
            return "Error: Invalid amount format"
        }
        
        print("VoiceAgent: All required parameters found - description: \(description), amount: \(amount), category: \(category), date: \(dateString)")
        
        // Parse date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else {
            return "Error: Invalid date format"
        }
        
        print("VoiceAgent: About to call expenseViewModel.addExpense...")
        
        // Format date as ISO string for expense date
        let isoFormatter = ISO8601DateFormatter()
        let expenseDateString = isoFormatter.string(from: date)
        
        // Create the expense through expenseViewModel
        // Using description as name, category is stored in notes for now
        let success = await expenseViewModel.addExpense(
            name: description,
            amount: amount,
            expenseDate: expenseDateString,
            paymentMethod: .cash, // Default to cash for voice entries
            notes: "Category: \(category)"
        )
        
        print("VoiceAgent: expenseViewModel.addExpense completed successfully")
        
        if success {
            return "Successfully added expense '\(description)' for $\(String(format: "%.2f", amount)) in \(category) category"
        } else {
            return "Error: Failed to create expense"
        }
    }
    
    func executeExpenseToolAndGetResult(toolId: String, name: String, input: [String: Any]) async -> String {
        switch name {
        case "create_expense":
            return await executeExpenseCreation(input: input)
        default:
            return "Error: Unknown tool '\(name)'"
        }
    }
    
    // MARK: - Expense Helper Methods
    
    func generateExpenseGreeting(userName: String?) -> String {
        let greeting = userName != nil ? "Hi \(userName!), " : "Hi there, "
        return greeting + "I'm ready to help you add a new expense! What did you spend money on?"
    }
    
    func processExpenseTranscription(_ transcription: String) async throws -> (String, Bool) {
        print("VoiceAgent: Processing transcription for expense: '\(transcription)'")
        
        // Add user message to conversation history
        conversationHistory.append(AnthropicMessage(role: "user", content: .text(transcription)))
        
        let tools = getExpenseTools()
        let systemPrompt = getExpenseSystemPrompt()
        
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
            let toolResult = await executeExpenseToolAndGetResult(toolId: toolUseId, name: toolName, input: toolInput)
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
                return ("I've added that expense for you.", true)
            case .toolResult:
                // Unexpected tool result
                return ("I've processed that information.", true)
            }
            
        case .toolResult:
            // Unexpected tool result - shouldn't happen here
            return ("I've processed that information.", false)
        }
    }
    
    func getExpenseSystemPrompt() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd"
        let currentDate = formatter.string(from: Date())
        
        // Get current expenses data for the system prompt
        let currentExpensesData = getCurrentExpensesData()
        
        // Get current income data for the system prompt
        let currentIncomeData = getCurrentIncomeData()
        
        return """
        You are Norma, a friendly AI financial assistant in a voice conversation with a user. You help them add new expenses and answer questions about their spending through voice interaction. This is a natural voice conversation, so respond conversationally and naturally as if speaking aloud.
        
        Today's date is \(currentDate).
        
        \(currentExpensesData)
        
        \(currentIncomeData)
        
        Your personality:
        - Warm, encouraging, and supportive
        - Professional but conversational
        - Use simple, clear language (avoid financial jargon)
        - **CRITICAL: Keep ALL responses to maximum 2 sentences for natural voice conversation**
        - Sound natural and conversational as if speaking aloud
        - You are Norma, the AI assistant for the Norma financial app
        
        **CRITICAL VOICE FORMATTING**: When speaking monetary amounts, always write them in full word form for proper text-to-speech pronunciation:
        - $108.88 → "one hundred and eight dollars and eighty-eight cents"
        - $50.00 → "fifty dollars" (omit cents when zero)
        - €75.25 → "seventy-five euros and twenty-five cents"
        - £12.99 → "twelve pounds and ninety-nine pence"
        - ¥1000 → "one thousand yen"
        This applies to ALL currencies and amounts in your responses.
        
        CAPABILITIES:
        1. ANSWER QUESTIONS about current expenses and income using the data above:
           - "How much did I spend this month?"
           - "What did I spend on food?"
           - "Show me my recent expenses"
           - "What's my biggest expense this month?"
           - "What's my total monthly income?"
           - "How much income do I have?"
           - "What income sources do I have?"
           
        2. ADD NEW EXPENSES: Help users add new one-time expenses
        
        3. COMPLEX ANALYSIS: For questions about historical data, trends, or multi-month analysis, use the analyze_financial_data tool
        
        4. END CONVERSATION: When users say they're done, finished, or want to stop, use the end_conversation tool
        
        FOR ADDING EXPENSES, collect this information:
        1. Description of what was purchased or spent on
        2. Amount spent (the dollar amount)
        3. Category (Food, Transportation, Entertainment, Shopping, etc.)
        4. Date (defaults to today if not specified)
        
        **CRITICAL RESPONSE RULES**:
        - Always confirm successful expense additions in 1-2 sentences
        - Use the user's exact words when confirming (e.g., if they say "coffee", don't change it to "beverage")
        - End conversations naturally when the user says goodbye, thanks, or indicates they're done
        - If unsure about specifics, ask ONE clarifying question
        - For dates, if the user says "today" use \(currentDate), if they say a day name, calculate the most recent occurrence
        - Be conversational - this is a voice interaction, not text
        
        IMPORTANT: If the user wants to manage bills (recurring payments), kindly direct them: "To manage bills, please go to the Bills tab and double-tap and hold on the expense tracker to activate voice mode there."
        
        Examples of natural conversation flow:
        User: "I spent fifteen dollars on lunch"
        Assistant: "What kind of food was it and is this for today?"
        User: "Pizza, yeah today"
        Assistant: [Uses create_expense tool] "I've added your fifteen dollar pizza expense for today."
        """
    }
}