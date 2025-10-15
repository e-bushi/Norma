//
//  ChatTools.swift
//  Norma
//
//  Created by Claude on 5/10/25.
//

import Foundation

/// Provides tool definitions for Anthropic API chat interactions
struct ChatToolsProvider {

    static func getAllTools() -> [AnthropicTool] {
        return [
            getBillCreationTool(),
            getExpenseCreationTool(),
            getBillQueryTool(),
            getExpenseSummaryTool(),
            getShowBillsTool(),
            getShowExpensesTool(),
            getShowBudgetsTool()
        ]
    }

    // MARK: - Tool Definitions

    static func getBillCreationTool() -> AnthropicTool {
        AnthropicTool(
            name: "create_bill",
            description: "Create a new recurring bill for the user",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "name": AnthropicToolProperty(
                        type: "string",
                        description: "Name of the bill"
                    ),
                    "amount": AnthropicToolProperty(
                        type: "number",
                        description: "Amount of the bill"
                    ),
                    "due_date": AnthropicToolProperty(
                        type: "string",
                        description: "Due date in YYYY-MM-DD format"
                    ),
                    "frequency": AnthropicToolProperty(
                        type: "string",
                        description: "Frequency: 'Monthly', 'Quarterly', or 'Yearly'"
                    ),
                    "status": AnthropicToolProperty(
                        type: "string",
                        description: "Status: 'Paid', 'Overdue', or 'Scheduled'"
                    )
                ],
                required: ["name", "amount", "due_date", "frequency", "status"]
            )
        )
    }

    static func getExpenseCreationTool() -> AnthropicTool {
        AnthropicTool(
            name: "create_expense",
            description: "Create a new expense record",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "name": AnthropicToolProperty(
                        type: "string",
                        description: "Name/description of the expense"
                    ),
                    "amount": AnthropicToolProperty(
                        type: "number",
                        description: "Amount spent"
                    ),
                    "expense_date": AnthropicToolProperty(
                        type: "string",
                        description: "Date in ISO8601 format"
                    ),
                    "payment_method": AnthropicToolProperty(
                        type: "string",
                        description: "Payment method: 'Cash', 'Credit Card', 'Debit Card', etc."
                    ),
                    "merchant": AnthropicToolProperty(
                        type: "string",
                        description: "Merchant name (optional)"
                    ),
                    "tags": AnthropicToolProperty(
                        type: "array",
                        description: "Tags for categorization (optional)"
                    )
                ],
                required: ["name", "amount", "expense_date", "payment_method"]
            )
        )
    }

    static func getBillQueryTool() -> AnthropicTool {
        AnthropicTool(
            name: "query_bills",
            description: "Query user's bills and due dates",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "status": AnthropicToolProperty(
                        type: "string",
                        description: "Filter by status: 'all', 'overdue', 'scheduled', 'paid'"
                    )
                ],
                required: ["status"]
            )
        )
    }

    static func getExpenseSummaryTool() -> AnthropicTool {
        AnthropicTool(
            name: "expense_summary",
            description: "Get expense summary for a time period",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "period": AnthropicToolProperty(
                        type: "string",
                        description: "Time period: 'week', 'month', 'year'"
                    )
                ],
                required: ["period"]
            )
        )
    }

    static func getShowBillsTool() -> AnthropicTool {
        AnthropicTool(
            name: "show_bills_tool",
            description: "Display bill cards visually in the UI. Use this when the user wants to SEE their bills, not just hear about them. Pass the bill IDs from the system prompt.",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "bill_ids": AnthropicToolProperty(
                        type: "array",
                        description: "Array of bill UUID strings to display as cards. Use the 'id' values from the USER'S BILLS section in the system prompt. Example: [\"uuid-1\", \"uuid-2\"]"
                    )
                ],
                required: ["bill_ids"]
            )
        )
    }

    static func getShowExpensesTool() -> AnthropicTool {
        AnthropicTool(
            name: "show_expenses_tool",
            description: "Display expense cards visually in the UI. Use this when the user wants to SEE their expenses, not just hear about them. Pass the expense IDs from the system prompt as a comma-separated string.",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "expense_ids": AnthropicToolProperty(
                        type: "string",
                        description: "Comma-separated string of expense UUID values from the USER'S RECENT EXPENSES section in the system prompt. Example: \"uuid-1,uuid-2,uuid-3\""
                    )
                ],
                required: ["expense_ids"]
            )
        )
    }

    static func getShowBudgetsTool() -> AnthropicTool {
        AnthropicTool(
            name: "show_budgets_tool",
            description: "Display budget cards visually in the UI. Use this when the user wants to SEE their budgets, not just hear about them. Pass the budget IDs from the system prompt.",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "budget_ids": AnthropicToolProperty(
                        type: "array",
                        description: "Array of budget UUID strings to display as cards. Use the 'id' values from the USER'S BUDGETS section in the system prompt. Example: [\"uuid-1\", \"uuid-2\"]"
                    )
                ],
                required: ["budget_ids"]
            )
        )
    }
}
