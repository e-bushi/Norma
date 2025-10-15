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
              let dueDateString = input["due_date"] as? String,
              let frequencyString = input["frequency"] as? String,
              let statusString = input["status"] as? String else {
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

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let dueDate = dateFormatter.date(from: dueDateString) else {
            return "Error: Invalid date format"
        }

        let frequency: BillFrequency = frequencyString.lowercased() == "monthly" ? .monthly :
                                       frequencyString.lowercased() == "quarterly" ? .quarterly : .yearly

        let status: BillStatus = statusString == "Paid" ? .paid :
                                 statusString == "Overdue" ? .overdue : .scheduled

        await billViewModel.addBill(
            name: name,
            amount: amount,
            dueDate: dueDate,
            frequency: frequency,
            status: status
        )

        return "Successfully created bill '\(name)' for $\(String(format: "%.2f", amount))"
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

        guard let billIds = input["bill_ids"] as? [String] else {
            print("❌ No bill_ids found in input")
            return ("Error: No bill IDs provided", nil)
        }

        print("📋 Looking for bill IDs: \(billIds)")
        print("📊 Available bills: \(billViewModel.bills.count)")

        let matchedBills = billViewModel.bills.filter { bill in
            guard let billId = bill.id else { return false }
            return billIds.contains(billId)
        }

        print("✅ Matched \(matchedBills.count) bills")

        if matchedBills.isEmpty {
            return ("No bills found to display", nil)
        }

        return ("Displaying \(matchedBills.count) bill\(matchedBills.count == 1 ? "" : "s")", .billCards(matchedBills))
    }

    private func executeShowExpenses(input: [String: Any]) async -> (String, UIComponent?) {
        print("🔍 executeShowExpenses called with input: \(input)")

        guard let expenseIdsString = input["expense_ids"] as? String, !expenseIdsString.isEmpty else {
            print("❌ No expense_ids found in input")
            return ("Error: No expense IDs provided", nil)
        }

        let expenseIds = expenseIdsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        print("📋 Looking for expense IDs: \(expenseIds)")
        print("📊 Available expenses: \(expenseViewModel.expenses.count)")

        let matchedExpenses = expenseViewModel.expenses.filter { expense in
            guard let expenseId = expense.id else { return false }
            return expenseIds.contains(expenseId)
        }

        print("✅ Matched \(matchedExpenses.count) expenses")

        if matchedExpenses.isEmpty {
            return ("No expenses found to display", nil)
        }

        return ("Displaying \(matchedExpenses.count) expense\(matchedExpenses.count == 1 ? "" : "s")", .expenseCards(matchedExpenses))
    }

    private func executeShowBudgets(input: [String: Any]) async -> (String, UIComponent?) {
        print("🔍 executeShowBudgets called with input: \(input)")

        guard let budgetIds = input["budget_ids"] as? [String] else {
            print("❌ No budget_ids found in input")
            return ("Error: No budget IDs provided", nil)
        }

        print("📋 Looking for budget IDs: \(budgetIds)")
        print("📊 Available budgets: \(budgetViewModel.budgets.count)")

        let matchedBudgets = budgetViewModel.budgets.filter { budget in
            guard let budgetId = budget.id else { return false }
            return budgetIds.contains(budgetId)
        }

        print("✅ Matched \(matchedBudgets.count) budgets")

        if matchedBudgets.isEmpty {
            return ("No budgets found to display", nil)
        }

        return ("Displaying \(matchedBudgets.count) budget\(matchedBudgets.count == 1 ? "" : "s")", .budgetCards(matchedBudgets))
    }
}
