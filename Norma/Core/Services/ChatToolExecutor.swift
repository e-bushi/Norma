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
    private let billViewModel: BillViewModel
    private let expenseViewModel: ExpenseViewModel
    private let challengeViewModel: ChallengeViewModel
    private let dataManager: DataManager

    init(billViewModel: BillViewModel, expenseViewModel: ExpenseViewModel, challengeViewModel: ChallengeViewModel, dataManager: DataManager) {
        self.billViewModel = billViewModel
        self.expenseViewModel = expenseViewModel
        self.challengeViewModel = challengeViewModel
        self.dataManager = dataManager
    }

    // MARK: - Main Executor

    func executeToolAndGetResult(toolId: String, name: String, input: [String: Any]) async -> (String, UIComponent?) {
        switch name {
        case "create_bill":
            let result = await executeBillCreation(input: input)
            return (result, nil)
        case "update_bill":
            let result = await executeUpdateBill(input: input)
            return (result, nil)
        case "create_expense":
            let result = await executeExpenseCreation(input: input)
            return (result, nil)
        case "query_bills":
            let result = await executeQueryBills(input: input)
            return (result, nil)
        case "expense_summary":
            let result = await executeExpenseSummary(input: input)
            return (result, nil)
        case "show_bills_tool":
            return await executeShowBills(input: input)
        case "show_expenses_tool":
            return await executeShowExpenses(input: input)
        case "show_challenge_tool":
            return await executeShowChallenge()
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

    private func executeBillCreation(input: [String: Any]) async -> String {
        guard let name = input["name"] as? String,
              let dueDateString = input["due_date"] as? String else {
            return "Error: Missing required information (name and due_date)"
        }

        let amount: Double
        if let doubleAmount = input["amount"] as? Double {
            amount = doubleAmount
        } else if let intAmount = input["amount"] as? Int {
            amount = Double(intAmount)
        } else {
            return "Error: Invalid amount format"
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let dueDate = dateFormatter.date(from: dueDateString) else {
            return "Error: Invalid date format. Use YYYY-MM-DD"
        }

        // Default to Monthly frequency
        let frequency: BillFrequency = .monthly

        // Automatically determine status based on due date
        let status: BillStatus
        if dueDate < Date() {
            // Due date is in the past - mark as overdue
            status = .overdue
        } else {
            // Due date is in the future - mark as scheduled
            status = .scheduled
        }

        // Check if this is the first bill (mark as most critical for arc calculation)
        let isFirstBill = billViewModel.bills.isEmpty

        await billViewModel.addBill(
            name: name,
            amount: amount,
            dueDate: dueDate,
            frequency: frequency,
            status: status,
            isMostCritical: isFirstBill ? true : nil
        )

        // Check for first bill added via chat milestone
        let isFirst = await RewardMilestoneTracker.shared.checkAndMarkFirstTime(.firstBillAddedViaChat)
        if isFirst {
            RewardQueueManager.shared.enqueue(.firstBillViaChat(billName: name))
        }

        return "Successfully created bill '\(name)' for $\(String(format: "%.2f", amount)). Frequency is set to Monthly and status is \(status == .overdue ? "Overdue" : "Scheduled")."
    }

    private func executeUpdateBill(input: [String: Any]) async -> String {
        guard let billIdString = input["bill_id"] as? String else {
            return "Error: Missing bill ID"
        }

        // Find the bill
        guard let existingBill = billViewModel.bills.first(where: { $0.id == billIdString }) else {
            return "Error: Bill not found"
        }

        // Update fields if provided
        let newName = input["name"] as? String ?? existingBill.name

        let newAmount: Double
        if let doubleAmount = input["amount"] as? Double {
            newAmount = doubleAmount
        } else if let intAmount = input["amount"] as? Int {
            newAmount = Double(intAmount)
        } else {
            newAmount = existingBill.amount
        }

        let newDueDate: Date
        if let dueDateString = input["due_date"] as? String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            newDueDate = dateFormatter.date(from: dueDateString) ?? existingBill.dueDate
        } else {
            newDueDate = existingBill.dueDate
        }

        let newFrequency: BillFrequency
        if let frequencyString = input["frequency"] as? String {
            newFrequency = frequencyString.lowercased() == "monthly" ? .monthly :
                          frequencyString.lowercased() == "quarterly" ? .quarterly : .yearly
        } else {
            newFrequency = existingBill.frequency
        }

        let newStatus: BillStatus
        if let statusString = input["status"] as? String {
            newStatus = statusString == "Paid" ? .paid :
                       statusString == "Overdue" ? .overdue : .scheduled
        } else {
            newStatus = existingBill.status
        }

        // Create updated bill object
        let updatedBill = Bill(
            id: existingBill.id,
            userId: existingBill.userId,
            name: newName,
            dueDate: newDueDate,
            nextDueDate: existingBill.nextDueDate,
            amount: newAmount,
            status: newStatus,
            frequency: newFrequency,
            categoryId: existingBill.categoryId,
            merchant: existingBill.merchant,
            isReminderOn: existingBill.isReminderOn,
            reminderDays: existingBill.reminderDays,
            isActive: existingBill.isActive,
            createdAt: existingBill.createdAt,
            updatedAt: existingBill.updatedAt,
            notes: existingBill.notes,
            verificationDate: existingBill.verificationDate
        )

        // Update the bill
        await billViewModel.updateBill(updatedBill)

        return "Successfully updated bill '\(newName)'"
    }

    private func executeExpenseCreation(input: [String: Any]) async -> String {
        guard let name = input["name"] as? String,
              let expenseDateString = input["expense_date"] as? String,
              let paymentMethodString = input["payment_method"] as? String else {
            return "Error: Missing required information"
        }

        let amount: Double
        if let doubleAmount = input["amount"] as? Double {
            amount = doubleAmount
        } else if let intAmount = input["amount"] as? Int {
            amount = Double(intAmount)
        } else {
            return "Error: Invalid amount format"
        }

        let paymentMethod: PaymentMethod = {
            switch paymentMethodString.lowercased() {
            case "cash": return .cash
            case "credit card": return .creditCard
            case "debit card": return .debitCard
            default: return .debitCard
            }
        }()

        let merchant = input["merchant"] as? String
        let tags = input["tags"] as? [String] ?? []

        // Normalize date to full ISO8601 format with timezone
        let normalizedDate: String
        let hasTimezone = expenseDateString.hasSuffix("Z") ||
            expenseDateString.range(of: #"[+-]\d{2}:?\d{2}$"#, options: .regularExpression) != nil
        if !expenseDateString.contains("T") {
            // Just a date like "2026-03-01"
            normalizedDate = expenseDateString + "T00:00:00Z"
        } else if !hasTimezone {
            // Has time but no timezone like "2026-03-01T12:00:00"
            normalizedDate = expenseDateString + "Z"
        } else {
            normalizedDate = expenseDateString
        }

        let success = await expenseViewModel.addExpense(
            name: name,
            amount: amount,
            expenseDate: normalizedDate,
            billId: nil,
            paymentMethod: paymentMethod,
            isRecurring: false,
            recurringFrequency: nil,
            merchant: merchant,
            location: nil,
            tags: tags,
            createdAt: nil,
            updatedAt: nil,
            notes: nil,
            attachmentUrls: []
        )

        return success ? "Successfully recorded expense '\(name)' for $\(String(format: "%.2f", amount))" :
                        "Error: Failed to create expense"
    }

    private func executeQueryBills(input: [String: Any]) async -> String {
        let statusFilter = input["status"] as? String ?? "all"

        let bills = billViewModel.bills
        let filteredBills: [Bill]

        switch statusFilter.lowercased() {
        case "overdue":
            filteredBills = bills.filter { $0.status == .overdue }
        case "scheduled":
            filteredBills = bills.filter { $0.status == .scheduled }
        case "paid":
            filteredBills = bills.filter { $0.status == .paid }
        default:
            filteredBills = bills
        }

        if filteredBills.isEmpty {
            return "You don't have any \(statusFilter == "all" ? "" : statusFilter) bills."
        }

        var result = "Here are your \(statusFilter == "all" ? "" : statusFilter) bills:\n"
        for bill in filteredBills.prefix(5) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            result += "• \(bill.name): $\(String(format: "%.2f", bill.amount)) due \(formatter.string(from: bill.dueDate))\n"
        }

        if filteredBills.count > 5 {
            result += "...and \(filteredBills.count - 5) more"
        }

        return result
    }

    private func executeExpenseSummary(input: [String: Any]) async -> String {
        let period = input["period"] as? String ?? "month"

        let expenses = expenseViewModel.expenses
        let now = Date()
        let calendar = Calendar.current
        let dateFormatter = ISO8601DateFormatter()

        let filteredExpenses: [Expense]
        switch period.lowercased() {
        case "week":
            let weekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
            filteredExpenses = expenses.filter { expense in
                guard let createdAtString = expense.createdAt,
                      let createdAtDate = dateFormatter.date(from: createdAtString) else {
                    return false
                }
                return createdAtDate >= weekAgo
            }
        case "year":
            let yearAgo = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            filteredExpenses = expenses.filter { expense in
                guard let createdAtString = expense.createdAt,
                      let createdAtDate = dateFormatter.date(from: createdAtString) else {
                    return false
                }
                return createdAtDate >= yearAgo
            }
        default:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            filteredExpenses = expenses.filter { expense in
                guard let createdAtString = expense.createdAt,
                      let createdAtDate = dateFormatter.date(from: createdAtString) else {
                    return false
                }
                return createdAtDate >= monthAgo
            }
        }

        let total = filteredExpenses.reduce(0) { $0 + $1.amount }
        let count = filteredExpenses.count

        return "In the past \(period), you've recorded \(count) expense\(count == 1 ? "" : "s") totaling $\(String(format: "%.2f", total))"
    }

    private func executeShowBills(input: [String: Any]) async -> (String, UIComponent?) {
        print("🔍 executeShowBills called with input: \(input)")
        print("📊 Available bills: \(billViewModel.bills.count)")

        let billIds = input["bill_ids"] as? [String]

        let billsToShow: [Bill]
        if let ids = billIds, !ids.isEmpty {
            // Filter by specific IDs
            print("📋 Looking for specific bill IDs: \(ids)")
            billsToShow = billViewModel.bills.filter { bill in
                guard let billId = bill.id else { return false }
                return ids.contains(billId)
            }
        } else {
            // No IDs provided - show ALL bills
            print("📋 No IDs provided, showing all bills")
            billsToShow = billViewModel.bills
        }

        print("✅ Showing \(billsToShow.count) bills")

        if billsToShow.isEmpty {
            return ("You don't have any bills yet. Would you like to add one?", nil)
        }

        // TODO: Get currency from user profile settings
        let currency = "USD"
        return ("Displaying \(billsToShow.count) bill\(billsToShow.count == 1 ? "" : "s")", .billCards(billsToShow, currency: currency))
    }

    private func executeShowExpenses(input: [String: Any]) async -> (String, UIComponent?) {
        print("🔍 executeShowExpenses called with input: \(input)")
        print("📊 Available expenses: \(expenseViewModel.expenses.count)")

        let expenseIdsString = input["expense_ids"] as? String

        let expensesToShow: [Expense]
        if let idsString = expenseIdsString, !idsString.isEmpty {
            // Filter by specific IDs
            let expenseIds = idsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            print("📋 Looking for specific expense IDs: \(expenseIds)")
            expensesToShow = expenseViewModel.expenses.filter { expense in
                guard let expenseId = expense.id else { return false }
                return expenseIds.contains(expenseId)
            }
        } else {
            // No IDs provided - show ALL recent expenses (limit to 20)
            print("📋 No IDs provided, showing all recent expenses")
            expensesToShow = Array(expenseViewModel.expenses.prefix(20))
        }

        print("✅ Showing \(expensesToShow.count) expenses")

        if expensesToShow.isEmpty {
            return ("You don't have any expenses tracked yet.", nil)
        }

        // TODO: Get currency from user profile settings
        let currency = "USD"
        return ("Displaying \(expensesToShow.count) expense\(expensesToShow.count == 1 ? "" : "s")", .expenseCards(expensesToShow, currency: currency))
    }

    private func executeShowChallenge() async -> (String, UIComponent?) {
        print("🔍 executeShowChallenge called")

        guard let challenge = challengeViewModel.activeChallenge else {
            return ("You don't have an active challenge right now. One will be generated when you open the Challenges screen.", nil)
        }

        print("✅ Showing active challenge with \(challengeViewModel.formatCurrency(challenge.amountRemaining)) remaining")

        let currency = challenge.currency
        return ("Here's your current challenge", .challengeCard(challenge, currency: currency))
    }

    private func executeScheduleReminder(input: [String: Any]) async -> String {
        print("🔔 executeScheduleReminder called with input: \(input)")

        guard let title = input["title"] as? String,
              let message = input["message"] as? String,
              let remindAtString = input["remind_at"] as? String else {
            return "Error: Missing required information (title, message, and remind_at are required)"
        }

        // Parse the ISO8601 date string
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var remindAt: Date?
        remindAt = dateFormatter.date(from: remindAtString)

        // Try without fractional seconds if that fails
        if remindAt == nil {
            dateFormatter.formatOptions = [.withInternetDateTime]
            remindAt = dateFormatter.date(from: remindAtString)
        }

        // Try a simpler format as fallback
        if remindAt == nil {
            let simpleDateFormatter = DateFormatter()
            simpleDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            remindAt = simpleDateFormatter.date(from: remindAtString)
        }

        guard let finalRemindAt = remindAt else {
            return "Error: Invalid date format. Please use ISO8601 format (YYYY-MM-DDTHH:mm:ss)"
        }

        // Check if the date is in the future
        guard finalRemindAt > Date() else {
            return "Error: The reminder time must be in the future"
        }

        // Parse reminder type
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

        // Parse recurrence
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

        // Schedule the reminder
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
        // No artificial limit - Edge Function guesses based on embeddings
        // (encrypted data can't be verified server-side, only client can decrypt)
        // Let date filtering and semantic search handle the narrowing
        let limit = input["limit"] as? Int  // nil = unlimited
        let startDate = input["start_date"] as? String
        let endDate = input["end_date"] as? String

        print("🔍 [SearchTool] Searching for: \"\(query)\" (type: \(recordType), limit: \(limit), startDate: \(startDate ?? "nil"), endDate: \(endDate ?? "nil"))")

        do {
            let searchResults = try await dataManager.semanticSearch(query: query, limit: limit ?? 10000, startDate: startDate, endDate: endDate)

            var resultText = ""

            // Format bills if requested
            if recordType == "all" || recordType == "bills" {
                if searchResults.bills.isEmpty {
                    resultText += "No matching bills found.\n\n"
                } else {
                    resultText += "MATCHING BILLS (\(searchResults.bills.count)):\n"
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    for bill in searchResults.bills {
                        resultText += "- \(bill.name): $\(String(format: "%.2f", bill.amount)), due \(dateFormatter.string(from: bill.dueDate)), frequency: \(bill.frequency.rawValue), status: \(bill.status.rawValue)\n"
                    }
                    resultText += "\n"
                }
            }

            // Format expenses if requested
            if recordType == "all" || recordType == "expenses" {
                if searchResults.expenses.isEmpty {
                    resultText += "No matching expenses found.\n"
                } else {
                    resultText += "MATCHING EXPENSES (\(searchResults.expenses.count)):\n"
                    for expense in searchResults.expenses {
                        resultText += "- \(expense.name): $\(String(format: "%.2f", expense.amount)), date: \(expense.expenseDate)"
                        if let merchant = expense.merchant {
                            resultText += ", merchant: \(merchant)"
                        }
                        resultText += "\n"
                    }
                }
            }

            if resultText.isEmpty {
                return "No matching records found for '\(query)'"
            }

            print("✅ [SearchTool] Found \(searchResults.bills.count) bills, \(searchResults.expenses.count) expenses")
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
