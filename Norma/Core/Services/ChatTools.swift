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

            getShowSaveProgressModalTool(),
            getShowDaysTool(),
            getShowArcCountTool(),
            getShowFlowStateTool(),
            getScheduleReminderTool(),
            getSearchFinancialRecordsTool(),
            getConvertCurrencyTool(),
            getShowArcSimulatorTool()
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
            description: "Save the user's currency during onboarding.",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "currency": AnthropicToolProperty(
                        type: "string",
                        description: "The user's currency code (e.g., USD, EUR, GBP, ZAR, JPY)"
                    ),
                    "exchange_rate": AnthropicToolProperty(
                        type: "number",
                        description: "Optional: The approximate USD to [currency] exchange rate. Use 1.0 for USD."
                    )
                ],
                required: ["currency"]
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

    static func getSearchFinancialRecordsTool() -> AnthropicTool {
        AnthropicTool(
            name: "search_financial_records",
            description: "Search the user's bills using semantic search with optional date filtering. Use this tool when you need to find specific bills based on the user's question. The search finds records by meaning, not just exact text matches. Returns matching records with full details including dates and amounts. IMPORTANT: When the user asks about a specific date or time period, always include start_date and/or end_date parameters.",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "query": AnthropicToolProperty(
                        type: "string",
                        description: "The search query - describe what you're looking for (e.g., 'grocery food expenses', 'Netflix subscription', 'restaurant dining')"
                    ),
                    "record_type": AnthropicToolProperty(
                        type: "string",
                        description: "Type of records to search: 'bills' or 'all'. Defaults to 'all' if not specified."
                    ),
                    "limit": AnthropicToolProperty(
                        type: "number",
                        description: "Maximum number of results to return (default: 50)"
                    ),
                    "start_date": AnthropicToolProperty(
                        type: "string",
                        description: "Filter results to records on or after this date. Use ISO format YYYY-MM-DD (e.g., '2026-01-01' for January 1st). Use this for queries like 'January expenses' or 'since last week'."
                    ),
                    "end_date": AnthropicToolProperty(
                        type: "string",
                        description: "Filter results to records on or before this date. Use ISO format YYYY-MM-DD (e.g., '2026-01-31' for January 31st). Use this for queries like 'January expenses' or 'before February'."
                    )
                ],
                required: ["query"]
            )
        )
    }

    static func getConvertCurrencyTool() -> AnthropicTool {
        AnthropicTool(
            name: "convert_currency",
            description: "Convert an amount from one currency to another using real-time exchange rates. Use this when the user asks about currency conversion, exchange rates, or wants to know how much something costs in a different currency. Returns the converted amount and current exchange rate.",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [
                    "amount": AnthropicToolProperty(
                        type: "number",
                        description: "The amount to convert"
                    ),
                    "from_currency": AnthropicToolProperty(
                        type: "string",
                        description: "The source currency code (e.g., 'USD', 'EUR', 'GBP', 'JPY')"
                    ),
                    "to_currency": AnthropicToolProperty(
                        type: "string",
                        description: "The target currency code (e.g., 'USD', 'EUR', 'GBP', 'JPY')"
                    )
                ],
                required: ["amount", "from_currency", "to_currency"]
            )
        )
    }

    static func getShowArcSimulatorTool() -> AnthropicTool {
        AnthropicTool(
            name: "show_arc_simulator",
            description: "Display an interactive arc simulator card in the chat. When tapped, it opens a full-screen sheet where the user can adjust their freedom fund with a slider and watch coins appear/disappear on a 12-month timeline. Use this after all onboarding data is collected and you've teased 'I noticed something in your numbers' - when the user says 'yes show me' or expresses interest.",
            inputSchema: AnthropicToolSchema(
                type: "object",
                properties: [:],
                required: []
            )
        )
    }
}
