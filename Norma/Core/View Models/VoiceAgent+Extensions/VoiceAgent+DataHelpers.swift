//
//  VoiceAgent+DataHelpers.swift
//  Norma
//
//  Created by Assistant on 12/6/25.
//

import Foundation

// MARK: - Data Fetching Helpers
extension VoiceAgentViewModel {
    
    // MARK: - Bills Data
    
    func getCurrentBillsData() -> String {
        guard let billViewModel = billViewModel else {
            return "No bills data available."
        }
        
        let bills = billViewModel.activeBills
        if bills.isEmpty {
            return "You currently have no bills set up."
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        var billsSummary = "CURRENT BILLS THIS MONTH:\n"
        // Show up to 20 bills for better visibility, but still maintain reasonable context limits
        for bill in bills.prefix(20) { 
            let dueDateStr = formatter.string(from: bill.dueDate)
            billsSummary += "• \(bill.name): $\(String(format: "%.2f", bill.amount)) due \(dueDateStr) - \(bill.status.rawValue)\n"
        }
        
        // If there are more bills, indicate this
        if bills.count > 20 {
            billsSummary += "• ... and \(bills.count - 20) more bills\n"
        }
        
        let totalOwed = bills.filter { $0.status != .paid }.reduce(0) { $0 + $1.amount }
        let overdueCount = bills.filter { $0.status == .overdue }.count
        let paidCount = bills.filter { $0.status == .paid }.count
        
        billsSummary += "\nSUMMARY: \(bills.count) total bill\(bills.count == 1 ? "" : "s"), $\(String(format: "%.2f", totalOwed)) still owed"
        if overdueCount > 0 { billsSummary += ", \(overdueCount) overdue" }
        if paidCount > 0 { billsSummary += ", \(paidCount) paid this month" }
        
        return billsSummary
    }
    
    // MARK: - Expenses Data
    
    func getCurrentExpensesData() -> String {
        guard let expenseViewModel = expenseViewModel else {
            return "No expenses data available."
        }
        
        let expenses = expenseViewModel.expenses
        if expenses.isEmpty {
            return "You currently have no expenses recorded this month."
        }
        
        // Get this month's expenses
        let calendar = Calendar.current
        let thisMonth = calendar.dateInterval(of: .month, for: Date())!
        let thisMonthExpenses = expenses.filter { expense in
            // Parse expense date string to Date
            let formatter = ISO8601DateFormatter()
            let expenseDate = formatter.date(from: expense.expenseDate) ?? Date()
            return thisMonth.contains(expenseDate)
        }.prefix(15) // Limit to recent expenses
        
        if thisMonthExpenses.isEmpty {
            return "You have no expenses recorded this month yet."
        }
        
        var expensesSummary = "EXPENSES THIS MONTH:\n"
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        for expense in thisMonthExpenses {
            // Parse expense date string for display
            let isoFormatter = ISO8601DateFormatter()
            let expenseDate = isoFormatter.date(from: expense.expenseDate) ?? Date()
            let dateStr = formatter.string(from: expenseDate)
            expensesSummary += "• \(expense.name): $\(String(format: "%.2f", expense.amount)) on \(dateStr)\n"
        }
        
        let monthlyTotal = Array(thisMonthExpenses).reduce(0) { $0 + $1.amount }
        expensesSummary += "\nTOTAL THIS MONTH: $\(String(format: "%.2f", monthlyTotal))"
        
        return expensesSummary
    }
    
    // MARK: - Income Data
    
    func getCurrentIncomeData() -> String {
        guard let incomeViewModel = incomeViewModel else {
            return "No income data available."
        }
        
        // Check for profile-based monthly income first (from onboarding)
        let profileIncome = sessionViewModel?.currentUser?.settings.monthlyIncome ?? 0.0
        
        // Get all income sources from IncomeViewModel
        let incomes = incomeViewModel.incomes
        let totalIncomeFromSources = incomeViewModel.totalMonthlyIncome
        
        if profileIncome > 0 && incomes.isEmpty {
            // User has profile income but no detailed income sources
            return """
            MONTHLY INCOME:
            • Total Monthly Income: $\(String(format: "%.2f", profileIncome)) (from profile settings)
            
            Note: This is your base monthly income. You can add specific income sources for more detailed tracking.
            """
        } else if incomes.isEmpty {
            return "You haven't set up any income sources yet. You can add income sources like salary, freelance work, or other income streams."
        } else {
            // User has detailed income sources
            var incomeSummary = "INCOME SOURCES:\n"
            
            for income in incomes.prefix(10) { // Limit to avoid too much context
                let frequency = income.frequency.rawValue
                let source = income.source.rawValue
                incomeSummary += "• \(source): $\(String(format: "%.2f", income.amount)) (\(frequency))\n"
            }
            
            incomeSummary += "\nTOTAL MONTHLY INCOME: $\(String(format: "%.2f", totalIncomeFromSources))"
            
            // Include profile income if it's different
            if profileIncome > 0 && abs(profileIncome - totalIncomeFromSources) > 0.01 {
                incomeSummary += "\nProfile Monthly Income: $\(String(format: "%.2f", profileIncome))"
            }
            
            return incomeSummary
        }
    }
    
    // MARK: - Data Preparation
    
    func prepareConversationContext() -> String {
        var context = ""
        
        // Add bills context
        context += "=== BILLS ===\n"
        context += getCurrentBillsData()
        context += "\n\n"
        
        // Add expenses context
        context += "=== EXPENSES ===\n"
        context += getCurrentExpensesData()
        context += "\n\n"
        
        // Add income context
        context += "=== INCOME ===\n"
        context += getCurrentIncomeData()
        
        return context
    }
    
    // MARK: - Data Analysis Helpers
    
    func getBillsSummaryStats() -> (total: Double, unpaid: Double, overdue: Int, paid: Int) {
        guard let billViewModel = billViewModel else {
            return (0, 0, 0, 0)
        }
        
        let bills = billViewModel.activeBills
        let total = bills.reduce(0) { $0 + $1.amount }
        let unpaid = bills.filter { $0.status != .paid }.reduce(0) { $0 + $1.amount }
        let overdue = bills.filter { $0.status == .overdue }.count
        let paid = bills.filter { $0.status == .paid }.count
        
        return (total, unpaid, overdue, paid)
    }
    
    func getExpensesSummaryStats() -> (monthlyTotal: Double, dailyAverage: Double, transactionCount: Int) {
        guard let expenseViewModel = expenseViewModel else {
            return (0, 0, 0)
        }
        
        let calendar = Calendar.current
        let thisMonth = calendar.dateInterval(of: .month, for: Date())!
        let formatter = ISO8601DateFormatter()
        
        let thisMonthExpenses = expenseViewModel.expenses.filter { expense in
            let expenseDate = formatter.date(from: expense.expenseDate) ?? Date()
            return thisMonth.contains(expenseDate)
        }
        
        let monthlyTotal = thisMonthExpenses.reduce(0) { $0 + $1.amount }
        let daysInMonth = calendar.range(of: .day, in: .month, for: Date())?.count ?? 30
        let dailyAverage = monthlyTotal / Double(daysInMonth)
        
        return (monthlyTotal, dailyAverage, thisMonthExpenses.count)
    }
    
    func getFinancialHealth() -> String {
        let (_, unpaidBills, overdueBills, _) = getBillsSummaryStats()
        let (monthlyExpenses, _, _) = getExpensesSummaryStats()
        let monthlyIncome = sessionViewModel?.currentUser?.settings.monthlyIncome ?? 
                           incomeViewModel?.totalMonthlyIncome ?? 0
        
        let remainingBudget = monthlyIncome - monthlyExpenses - unpaidBills
        
        if remainingBudget < 0 {
            return "You're over budget by $\(String(format: "%.2f", abs(remainingBudget)))"
        } else if overdueBills > 0 {
            return "You have \(overdueBills) overdue bill\(overdueBills > 1 ? "s" : "")"
        } else if remainingBudget < 100 {
            return "You have $\(String(format: "%.2f", remainingBudget)) left for the month"
        } else {
            return "Your finances are looking good with $\(String(format: "%.2f", remainingBudget)) remaining"
        }
    }
}