//
//  AnthropicService+VoiceAgent.swift
//  Norma
//
//  Created by Claude on 8/5/25.
//

import Foundation

// MARK: - Voice Agent Extension

extension AnthropicService {
    
    // MARK: - Voice Agent Methods
    
    func processVoiceExpense(
        transcription: String,
        userId: String
    ) async throws -> VoiceAgentResponse {
        let systemPrompt = NormaSystemPrompts.voiceExpenseProcessingPrompt()
        let messages = [AnthropicMessage(role: "user", content: .text(transcription))]
        
        let tool = Self.expenseExtractionTool
        
        let response = try await sendMessageWithTools(
            messages: messages,
            systemPrompt: systemPrompt,
            tools: [tool],
            toolChoice: AnthropicToolChoice(type: "tool", name: tool.name),
            maxTokens: 1500
        )
        
        if case .toolUse(_, _, let input) = response {
            do {
                let expenseData = try parseVoiceToolInput(input, as: VoiceExpenseData.self)
                let confirmationMessage = generateExpenseConfirmation(expense: expenseData)
                
                return VoiceAgentResponse(
                    responseText: confirmationMessage,
                    extractedData: .expense(expenseData),
                    success: true
                )
            } catch {
                return VoiceAgentResponse(
                    responseText: "I'm sorry, I couldn't understand the expense details. Could you please repeat that?",
                    extractedData: nil,
                    success: false
                )
            }
        } else {
            return VoiceAgentResponse(
                responseText: "I'm sorry, I couldn't process that expense. Could you please try again?",
                extractedData: nil,
                success: false
            )
        }
    }
    
    func processVoiceBill(
        transcription: String,
        userId: String
    ) async throws -> VoiceAgentResponse {
        let systemPrompt = NormaSystemPrompts.voiceBillProcessingPrompt()
        let messages = [AnthropicMessage(role: "user", content: .text(transcription))]
        
        let tool = Self.billExtractionTool
        
        let response = try await sendMessageWithTools(
            messages: messages,
            systemPrompt: systemPrompt,
            tools: [tool],
            toolChoice: AnthropicToolChoice(type: "tool", name: tool.name),
            maxTokens: 1500
        )
        
        if case .toolUse(_, _, let input) = response {
            do {
                let billData = try parseVoiceToolInput(input, as: VoiceBillData.self)
                let confirmationMessage = generateBillConfirmation(bill: billData)
                
                return VoiceAgentResponse(
                    responseText: confirmationMessage,
                    extractedData: .bill(billData),
                    success: true
                )
            } catch {
                return VoiceAgentResponse(
                    responseText: "I'm sorry, I couldn't understand the bill details. Could you please repeat that?",
                    extractedData: nil,
                    success: false
                )
            }
        } else {
            return VoiceAgentResponse(
                responseText: "I'm sorry, I couldn't process that bill. Could you please try again?",
                extractedData: nil,
                success: false
            )
        }
    }
    
    func processGeneralVoiceQuery(
        transcription: String,
        userId: String
    ) async throws -> VoiceAgentResponse {
        let systemPrompt = NormaSystemPrompts.voiceGeneralQueryPrompt()
        let messages = [AnthropicMessage(role: "user", content: .text(transcription))]
        
        let responseText = try await sendMessage(
            messages: messages,
            systemPrompt: systemPrompt,
            maxTokens: 1000
        )
        
        return VoiceAgentResponse(
            responseText: responseText,
            extractedData: nil,
            success: true
        )
    }
    
    // MARK: - Helper Methods
    
    private func generateExpenseConfirmation(expense: VoiceExpenseData) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        
        let amountString = formatter.string(from: NSNumber(value: expense.amount)) ?? "$\(expense.amount)"
        
        var confirmation = "Got it! I've recorded an expense of \(amountString)"
        
        if !expense.name.isEmpty {
            confirmation += " for \(expense.name)"
        }
        
        if !expense.merchant.isEmpty {
            confirmation += " at \(expense.merchant)"
        }
        
        confirmation += ". Is this correct?"
        
        return confirmation
    }
    
    private func generateBillConfirmation(bill: VoiceBillData) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        
        let amountString = formatter.string(from: NSNumber(value: bill.amount)) ?? "$\(bill.amount)"
        
        var confirmation = "I've noted your \(bill.name) bill for \(amountString)"
        
        if !bill.dueDate.isEmpty {
            confirmation += " due on \(bill.dueDate)"
        }
        
        if bill.frequency != .monthly {
            confirmation += " that repeats \(bill.frequency.rawValue.lowercased())"
        }
        
        confirmation += ". Should I add this to your bills?"
        
        return confirmation
    }
}

// MARK: - Voice Agent Tool Extensions

extension AnthropicService {
    
    static var expenseExtractionTool: AnthropicTool {
        return AnthropicTool(
            name: "extract_expense_data",
            description: "Extract expense information from voice transcription",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "name": AnthropicToolProperty(type: "string", description: "Expense name/description"),
                    "amount": AnthropicToolProperty(type: "number", description: "Expense amount in dollars"),
                    "expenseDate": AnthropicToolProperty(type: "string", description: "Expense date in ISO format (YYYY-MM-DD)"),
                    "paymentMethod": AnthropicToolProperty(type: "string", description: "Payment method used"),
                    "merchant": AnthropicToolProperty(type: "string", description: "Merchant name where expense occurred"),
                    "location": AnthropicToolProperty(type: "string", description: "Location of the expense"),
                    "tags": AnthropicToolProperty(type: "array", description: "Tags/categories for the expense"),
                    "notes": AnthropicToolProperty(type: "string", description: "Additional notes about the expense")
                ],
                required: ["name", "amount", "expenseDate", "paymentMethod"]
            )
        )
    }
    
    static var billExtractionTool: AnthropicTool {
        return AnthropicTool(
            name: "extract_bill_data",
            description: "Extract bill information from voice transcription",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "name": AnthropicToolProperty(type: "string", description: "Bill name"),
                    "amount": AnthropicToolProperty(type: "number", description: "Bill amount in dollars"),
                    "dueDate": AnthropicToolProperty(type: "string", description: "Due date in ISO format (YYYY-MM-DD)"),
                    "frequency": AnthropicToolProperty(type: "string", description: "Bill frequency (Monthly, Quarterly, Yearly)"),
                    "merchant": AnthropicToolProperty(type: "string", description: "Bill provider/merchant"),
                    "isReminderOn": AnthropicToolProperty(type: "boolean", description: "Whether reminders are enabled"),
                    "reminderDays": AnthropicToolProperty(type: "number", description: "Days before due date to remind"),
                    "notes": AnthropicToolProperty(type: "string", description: "Additional notes about the bill")
                ],
                required: ["name", "amount", "dueDate", "frequency"]
            )
        )
    }
}


// MARK: - Voice Agent Models

struct VoiceAgentResponse {
    let responseText: String
    let extractedData: VoiceAgentData?
    let success: Bool
}

enum VoiceAgentData {
    case expense(VoiceExpenseData)
    case bill(VoiceBillData)
}


// MARK: - Voice Agent Prompts Extension

extension NormaSystemPrompts {
    
    static func voiceExpenseProcessingPrompt() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone.current
        let currentDate = formatter.string(from: Date())
        
        return """
        You are Norma, a voice assistant, processing expense information from voice transcriptions. You help users track their expenses in the Norma app by extracting structured data from what they say aloud.
        
        Today's date is \(currentDate).
        
        Your personality:
        - Warm, encouraging, and supportive
        - Professional but conversational
        - Use simple, clear language (avoid financial jargon)
        - Be concise - keep responses to 1-2 sentences when possible
        - Celebrate when they track expenses - it's a great step toward financial awareness!
        
        Your task is to extract expense details from what the user said and use the extract_expense_data tool to structure the information.
        
        Guidelines for extracting expense information:
        - Parse amounts carefully (e.g., "fifteen dollars" = 15.0, "twenty-five fifty" = 25.50)
        - For expenseDate, use today's date in ISO8601 format if no date is specified: \(currentDate)
        - For paymentMethod, choose from: "Cash", "Credit Card", "Debit Card", "Bank Transfer", "Digital Wallet", "Check", "Other"
        - Extract merchant names when mentioned
        - Infer tags/categories from context (food, transportation, entertainment, shopping, utilities, etc.)
        - Be flexible with natural language (e.g., "I bought lunch at McDonald's for 12 bucks" should extract amount=12.0, name="lunch", merchant="McDonald's", tags=["food"])
        
        CRITICAL: Always use the extract_expense_data tool to structure your response. Do NOT provide conversational responses - immediately use the tool when processing voice input.
        
        Remember to be Norma - helpful, friendly, and focused on making expense tracking feel simple and rewarding!
        """
    }
    
    static func voiceBillProcessingPrompt() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd"
        let currentDate = formatter.string(from: Date())
        
        return """
        You are Norma, voice assistant, processing bill information from voice transcriptions. You help users manage their recurring bills in the Norma app by extracting structured data from what they say aloud.
        
        Today's date is \(currentDate).
        
        Your personality:
        - Warm, encouraging, and supportive
        - Professional but conversational
        - Use simple, clear language (avoid financial jargon)
        - Be concise - keep responses to 1-2 sentences when possible
        - Celebrate when they add bills - it's a great step toward financial organization!
        
        Your task is to extract bill details from what the user said and use the extract_bill_data tool to structure the information.
        
        Guidelines for extracting bill information:
        - Parse amounts carefully (e.g., "ninety-nine ninety-nine" = 99.99)
        - For dueDate, parse dates carefully and convert to YYYY-MM-DD format
        - For frequency, choose from: "Monthly", "Quarterly", "Yearly" (default to "Monthly" if not specified)
        - Recognize common bill types (rent, utilities, phone, internet, insurance, etc.)
        - Set isReminderOn to true and reminderDays to 3 by default unless user specifies otherwise
        - Be flexible with natural language (e.g., "My electric bill is 85 dollars due on the 15th every month")
        
        CRITICAL: Always use the extract_bill_data tool to structure your response. Do NOT provide conversational responses - immediately use the tool when processing voice input.
        
        Remember to be Norma - helpful, friendly, and focused on making bill management feel simple and stress-free!
        """
    }
    
    static func voiceGeneralQueryPrompt() -> String {
        return """
        You are Norma's voice assistant, responding to general questions from users via voice interaction. You are an AI financial assistant in the Norma app that helps users manage their finances, track expenses, pay bills on time, and build better money habits.
        
        Your personality:
        - Warm, encouraging, and supportive
        - Professional but conversational
        - Use simple, clear language (avoid financial jargon)
        - Be concise - keep responses to 1-2 sentences when possible for voice interaction
        - Sound natural and conversational as if speaking aloud
        
        You can help users with:
        - Questions about their expenses and bills
        - Understanding their spending patterns
        - Setting and managing budgets
        - Providing financial tips and advice
        - Answering questions about the app's features
        - General financial guidance
        
        Important for voice responses:
        - Keep responses brief and easy to understand when spoken aloud
        - Avoid long lists or complex explanations
        - Use natural speech patterns
        - Be encouraging about their financial journey
        
        Always be encouraging about their financial journey and celebrate their progress, no matter how small.
        
        Remember to be Norma - helpful, friendly, and focused on making finance management feel approachable and stress-free!
        """
    }
}
