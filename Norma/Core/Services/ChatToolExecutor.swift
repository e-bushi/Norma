//
//  ChatToolExecutor.swift
//  Norma
//
//  Created by Claude on 5/10/25.
//

import Foundation

/// Executes chat tools and returns results with optional UI components
@MainActor
class ChatToolExecutor {
    private let dataManager: DataManager

    init(dataManager: DataManager) {
        self.dataManager = dataManager
    }

    // MARK: - Main Executor

    func executeToolAndGetResult(toolId: String, name: String, input: [String: Any]) async -> (String, UIComponent?) {
        switch name {
        case "schedule_reminder":
            let result = await executeScheduleReminder(input: input)
            return (result, nil)
        case "search_financial_records":
            let result = await executeSearchFinancialRecords(input: input)
            return (result, nil)
        case "convert_currency":
            let result = await executeConvertCurrency(input: input)
            return (result, nil)
        default:
            return ("Error: Unknown tool '\(name)'", nil)
        }
    }

    // MARK: - Tool Execution Methods

    private func executeScheduleReminder(input: [String: Any]) async -> String {
        print("🔔 executeScheduleReminder called with input: \(input)")

        guard let title = input["title"] as? String,
              let message = input["message"] as? String,
              let remindAtString = input["remind_at"] as? String else {
            return "Error: Missing required information (title, message, and remind_at are required)"
        }

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var remindAt: Date?
        remindAt = dateFormatter.date(from: remindAtString)

        if remindAt == nil {
            dateFormatter.formatOptions = [.withInternetDateTime]
            remindAt = dateFormatter.date(from: remindAtString)
        }

        if remindAt == nil {
            let simpleDateFormatter = DateFormatter()
            simpleDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            remindAt = simpleDateFormatter.date(from: remindAtString)
        }

        guard let finalRemindAt = remindAt else {
            return "Error: Invalid date format. Please use ISO8601 format (YYYY-MM-DDTHH:mm:ss)"
        }

        guard finalRemindAt > Date() else {
            return "Error: The reminder time must be in the future"
        }

        let reminderTypeString = input["reminder_type"] as? String ?? "general"
        let reminderType: NotificationService.ReminderType
        switch reminderTypeString.lowercased() {
        case "bill":
            reminderType = .bill
        case "budget":
            reminderType = .budget
        case "goal":
            reminderType = .goal
        default:
            reminderType = .general
        }

        let recurrenceString = input["recurrence"] as? String ?? "none"
        let recurrence: NotificationService.Recurrence
        switch recurrenceString.lowercased() {
        case "daily":
            recurrence = .daily
        case "weekly":
            recurrence = .weekly
        case "monthly":
            recurrence = .monthly
        default:
            recurrence = .none
        }

        let result = await NotificationService.shared.scheduleAIReminder(
            title: title,
            message: message,
            remindAt: finalRemindAt,
            reminderType: reminderType,
            recurrence: recurrence
        )

        switch result {
        case .success:
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            let formattedDate = formatter.string(from: finalRemindAt)
            let recurrenceText: String
            switch recurrence {
            case .none:
                recurrenceText = ""
            case .daily:
                recurrenceText = " (repeats daily)"
            case .weekly:
                recurrenceText = " (repeats weekly)"
            case .monthly:
                recurrenceText = " (repeats monthly)"
            }
            return "Successfully scheduled reminder '\(title)' for \(formattedDate)\(recurrenceText)"
        case .failure(let error):
            if let notificationError = error as? NotificationError {
                return "Error: \(notificationError.localizedDescription)"
            }
            return "Error: Failed to schedule reminder - \(error.localizedDescription)"
        }
    }

    private func executeSearchFinancialRecords(input: [String: Any]) async -> String {
        guard let query = input["query"] as? String else {
            return "Error: Missing search query"
        }

        let recordType = (input["record_type"] as? String)?.lowercased() ?? "all"
        let limit = input["limit"] as? Int
        let startDate = input["start_date"] as? String
        let endDate = input["end_date"] as? String

        print("🔍 [SearchTool] Searching for: \"\(query)\" (type: \(recordType), limit: \(limit), startDate: \(startDate ?? "nil"), endDate: \(endDate ?? "nil"))")

        do {
            let searchResults = try await dataManager.semanticSearch(query: query, limit: limit ?? 10000, startDate: startDate, endDate: endDate)

            var resultText = ""

            if recordType == "all" || recordType == "bills" {
                if searchResults.bills.isEmpty {
                    resultText += "No matching bills found.\n\n"
                } else {
                    resultText += "MATCHING BILLS (\(searchResults.bills.count)):\n"
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    for bill in searchResults.bills {
                        resultText += "- \(bill.name): $\(String(format: "%.2f", bill.amount)), due \(dateFormatter.string(from: bill.effectiveDueDate)), frequency: \(bill.frequency.rawValue), status: \(bill.calculateStatus().rawValue)\n"
                    }
                    resultText += "\n"
                }
            }

            if resultText.isEmpty {
                return "No matching records found for '\(query)'"
            }

            print("✅ [SearchTool] Found \(searchResults.bills.count) bills")
            return resultText

        } catch {
            print("❌ [SearchTool] Search failed: \(error)")
            return "Error searching records: \(error.localizedDescription)"
        }
    }

    private func executeConvertCurrency(input: [String: Any]) async -> String {
        guard let fromCurrency = input["from_currency"] as? String,
              let toCurrency = input["to_currency"] as? String else {
            return "Error: Missing required currency codes (from_currency and to_currency)"
        }

        let amount: Double
        if let doubleAmount = input["amount"] as? Double {
            amount = doubleAmount
        } else if let intAmount = input["amount"] as? Int {
            amount = Double(intAmount)
        } else {
            return "Error: Invalid or missing amount"
        }

        print("💱 [CurrencyTool] Converting \(amount) \(fromCurrency) to \(toCurrency)")

        do {
            let response = try await CurrencyConversionService.shared.convert(
                amount: amount,
                from: fromCurrency.uppercased(),
                to: toCurrency.uppercased()
            )

            let fromSymbol = CurrencyData.getCurrency(for: fromCurrency.uppercased()).symbol
            let toSymbol = CurrencyData.getCurrency(for: toCurrency.uppercased()).symbol

            let result = """
            CURRENCY CONVERSION:
            \(fromSymbol)\(String(format: "%.2f", amount)) \(fromCurrency.uppercased()) = \(toSymbol)\(String(format: "%.2f", response.convertedValue)) \(toCurrency.uppercased())

            Exchange Rate: 1 \(fromCurrency.uppercased()) = \(String(format: "%.4f", response.exchangeRate)) \(toCurrency.uppercased())
            """

            print("✅ [CurrencyTool] Converted: \(amount) \(fromCurrency) = \(response.convertedValue) \(toCurrency)")
            return result

        } catch {
            print("❌ [CurrencyTool] Conversion failed: \(error)")
            return "Error converting currency: \(error.localizedDescription)"
        }
    }
}
