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
            getSaveUserNameTool(),
            getSaveUserCurrencyTool(),
            getSaveUserIncomeTool(),
            getSaveUserFreedomFundTool(),
            getSaveUserChallengeTool(),
            getBillCreationTool(),
            getUpdateBillTool(),
            getExpenseCreationTool(),
            getBillQueryTool(),
            getExpenseSummaryTool(),
            getShowBillsTool(),
            getShowExpensesTool(),
            getShowChallengeTool(),
            getShowSaveProgressModalTool(),
            getShowDaysTool(),
            getShowArcCountTool(),
            getShowFlowStateTool(),
            getScheduleReminderTool()
        ]
    }

    // MARK: - Tool Definitions

    static func getSaveUserNameTool() -> AnthropicTool {
        AnthropicTool(
            name: "save_user_name",
            description: "Save the user's name during onboarding in preview mode",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "name": AnthropicToolProperty(
                        type: "string",
                        description: "The user's name"
                    )
                ],
                required: ["name"]
            )
        )
    }

    static func getSaveUserCurrencyTool() -> AnthropicTool {
        AnthropicTool(
            name: "save_user_currency",
            description: "Save the user's currency during onboarding in preview mode. This will also generate mock financial data with amounts converted using the exchange rate.",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "currency": AnthropicToolProperty(
                        type: "string",
                        description: "The user's currency code (e.g., USD, EUR, GBP, ZAR, JPY)"
                    ),
                    "exchange_rate": AnthropicToolProperty(
                        type: "number",
                        description: "The approximate USD to [currency] exchange rate based on your training data. Use 1.0 for USD."
                    )
                ],
                required: ["currency", "exchange_rate"]
            )
        )
    }

    static func getSaveUserIncomeTool() -> AnthropicTool {
        AnthropicTool(
            name: "save_user_income",
            description: "Save the user's monthly income after taxes during real onboarding. This should be their take-home pay.",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "income": AnthropicToolProperty(
                        type: "number",
                        description: "The user's monthly income after taxes (take-home pay)"
                    )
                ],
                required: ["income"]
            )
        )
    }

    static func getSaveUserFreedomFundTool() -> AnthropicTool {
        AnthropicTool(
            name: "save_user_freedom_fund",
            description: "Save the user's freedom fund - money set aside that could cover their bills and lifestyle if income stopped. Not retirement or long-term savings, just their cushion.",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "freedom_fund": AnthropicToolProperty(
                        type: "number",
                        description: "The user's freedom fund amount"
                    )
                ],
                required: ["freedom_fund"]
            )
        )
    }

    static func getSaveUserChallengeTool() -> AnthropicTool {
        AnthropicTool(
            name: "save_user_challenge",
            description: "Save the user's main financial challenge or worry during real onboarding.",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "challenge": AnthropicToolProperty(
                        type: "string",
                        description: "The user's biggest money worry or financial challenge"
                    )
                ],
                required: ["challenge"]
            )
        )
    }

    static func getBillCreationTool() -> AnthropicTool {
        AnthropicTool(
            name: "create_bill",
            description: "Create a new recurring bill for the user. Frequency defaults to 'Monthly' and status is automatically determined based on the due date.",
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
                    )
                ],
                required: ["name", "amount", "due_date"]
            )
        )
    }

    static func getUpdateBillTool() -> AnthropicTool {
        AnthropicTool(
            name: "update_bill",
            description: "Update an existing bill's properties. Use the bill ID from the USER'S BILLS section in the system prompt.",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "bill_id": AnthropicToolProperty(
                        type: "string",
                        description: "UUID of the bill to update (from the system prompt)"
                    ),
                    "name": AnthropicToolProperty(
                        type: "string",
                        description: "New bill name (optional)"
                    ),
                    "amount": AnthropicToolProperty(
                        type: "number",
                        description: "New bill amount (optional)"
                    ),
                    "due_date": AnthropicToolProperty(
                        type: "string",
                        description: "New due date in YYYY-MM-DD format (optional)"
                    ),
                    "frequency": AnthropicToolProperty(
                        type: "string",
                        description: "New frequency: 'Monthly', 'Quarterly', or 'Yearly' (optional)"
                    ),
                    "status": AnthropicToolProperty(
                        type: "string",
                        description: "New status: 'Paid', 'Overdue', or 'Scheduled' (optional)"
                    )
                ],
                required: ["bill_id"]
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
            description: "Display bill cards visually in the UI. Call without parameters to show ALL bills, or pass specific bill_ids to filter. Use this when the user wants to SEE their bills.",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "bill_ids": AnthropicToolProperty(
                        type: "array",
                        description: "Optional: Array of bill UUID strings to display specific bills. Omit to show ALL bills."
                    )
                ],
                required: []
            )
        )
    }

    static func getShowExpensesTool() -> AnthropicTool {
        AnthropicTool(
            name: "show_expenses_tool",
            description: "Display expense cards visually in the UI. Call without parameters to show ALL recent expenses, or pass specific expense_ids to filter. Use this when the user wants to SEE their expenses.",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "expense_ids": AnthropicToolProperty(
                        type: "string",
                        description: "Optional: Comma-separated string of expense UUID values to display specific expenses. Omit to show ALL recent expenses."
                    )
                ],
                required: []
            )
        )
    }

    static func getShowChallengeTool() -> AnthropicTool {
        AnthropicTool(
            name: "show_challenge_tool",
            description: "Display the user's active spending challenge visually in the UI. Shows the remaining budget amount and days left in the current challenge. Use this when the user wants to see their challenge status.",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [:],
                required: []
            )
        )
    }

    static func getShowSaveProgressModalTool() -> AnthropicTool {
        AnthropicTool(
            name: "show_save_progress_modal",
            description: "Display a modal prompting the user to save their progress after completing the 3 onboarding questions. This should be called after collecting income, biggest bill, and main challenge.",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [:],
                required: []
            )
        )
    }

    static func getShowDaysTool() -> AnthropicTool {
        AnthropicTool(
            name: "show_days",
            description: "Calculate and display how many days the user's freedom fund can sustain their current lifestyle. Use in Step 2 of the transformation to show 'money converted to time'.",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [:],
                required: []
            )
        )
    }

    static func getShowArcCountTool() -> AnthropicTool {
        AnthropicTool(
            name: "show_arc_count",
            description: "Calculate and display the user's arc count visually. This should be called during the arc reveal in Phase 2 of real onboarding, in Step 2 after introducing arcs. The tool will calculate arcs from the user's freedom fund and bills. Optionally accepts arc_count parameter to display a specific number (useful for showing what 1 arc looks like when user has 0).",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "arc_count": AnthropicToolProperty(
                        type: "number",
                        description: "Optional: Specific arc count to display (e.g., 1 to show what 1 arc looks like when user has 0). If not provided, will calculate actual arc count."
                    )
                ],
                required: []
            )
        )
    }

    static func getShowFlowStateTool() -> AnthropicTool {
        AnthropicTool(
            name: "show_flow_state",
            description: "Display the user's spending flow state as a capsule in the navigation bar. This should be called when introducing spending flow in Step 5 of onboarding. The capsule shows one of three states: 'In flow' (arcs growing), 'Stagnant' (arcs flat), or 'Drifting' (arcs shrinking). Since the user hasn't tracked expenses yet during onboarding, you cannot calculate their actual state - use this to show them what the capsule looks like as an example (default to 'In flow' as an aspirational starting point).",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "flow_state": AnthropicToolProperty(
                        type: "string",
                        description: "The flow state to display: 'In flow', 'Stagnant', or 'Drifting'. During onboarding before expense tracking, use 'In flow' as the default example."
                    )
                ],
                required: ["flow_state"]
            )
        )
    }

    static func getScheduleReminderTool() -> AnthropicTool {
        AnthropicTool(
            name: "schedule_reminder",
            description: "Schedule a local notification reminder for the user. Use this when the user asks to be reminded about something, wants a notification at a specific time, or when you think a reminder would be helpful (e.g., 'remind me to check my subscriptions tomorrow', 'set a reminder for rent next week'). Supports both one-time and recurring reminders. The notification will appear on their device at the specified time even if the app is closed. Recurring reminders only use 1 notification slot, making them efficient for regular check-ins.",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "title": AnthropicToolProperty(
                        type: "string",
                        description: "The notification title (short, attention-grabbing)"
                    ),
                    "message": AnthropicToolProperty(
                        type: "string",
                        description: "The notification body message with more details"
                    ),
                    "remind_at": AnthropicToolProperty(
                        type: "string",
                        description: "When to send the reminder in ISO8601 format (YYYY-MM-DDTHH:mm:ss). For relative times like 'tomorrow at 9am' or 'in 2 hours', calculate the actual date/time. For recurring reminders, this is the first occurrence."
                    ),
                    "reminder_type": AnthropicToolProperty(
                        type: "string",
                        description: "Category of reminder: 'bill', 'budget', 'goal', 'general'. Defaults to 'general' if not specified."
                    ),
                    "recurrence": AnthropicToolProperty(
                        type: "string",
                        description: "How often to repeat: 'none' (one-time, default), 'daily' (every day at same time), 'weekly' (same day/time each week), 'monthly' (same day each month). Use for things like 'remind me every Friday to review spending'."
                    )
                ],
                required: ["title", "message", "remind_at"]
            )
        )
    }
}
