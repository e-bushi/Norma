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
    private let budgetViewModel: BudgetViewModel

    init(billViewModel: BillViewModel, expenseViewModel: ExpenseViewModel, budgetViewModel: BudgetViewModel) {
        self.billViewModel = billViewModel
        self.expenseViewModel = expenseViewModel
        self.budgetViewModel = budgetViewModel
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
        case "show_budgets_tool":
            return await executeShowBudgets(input: input)
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

        let success = await expenseViewModel.addExpense(
            name: name,
            amount: amount,
            expenseDate: expenseDateString,
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

    private func executeShowBudgets(input: [String: Any]) async -> (String, UIComponent?) {
        print("🔍 executeShowBudgets called with input: \(input)")
        print("📊 Available budgets: \(budgetViewModel.budgets.count)")

        let budgetIds = input["budget_ids"] as? [String]

        let budgetsToShow: [Budget]
        if let ids = budgetIds, !ids.isEmpty {
            // Filter by specific IDs
            print("📋 Looking for specific budget IDs: \(ids)")
            budgetsToShow = budgetViewModel.budgets.filter { budget in
                guard let budgetId = budget.id else { return false }
                return ids.contains(budgetId)
            }
        } else {
            // No IDs provided - show ALL budgets
            print("📋 No IDs provided, showing all budgets")
            budgetsToShow = budgetViewModel.budgets
        }

        print("✅ Showing \(budgetsToShow.count) budgets")

        if budgetsToShow.isEmpty {
            return ("You don't have any budgets set up yet. Would you like to create one?", nil)
        }

        // TODO: Get currency from user profile settings
        let currency = "USD"
        return ("Displaying \(budgetsToShow.count) budget\(budgetsToShow.count == 1 ? "" : "s")", .budgetCards(budgetsToShow, currency: currency))
    }
}
