//
//  WidgetDataManager.swift
//  Norma
//
//  Created by Claude on 8/19/25.
//

import Foundation
import WidgetKit

class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    private let sharedDefaults = UserDefaults(suiteName: "group.com.myndfruit.norma")
    
    private init() {}
    
    // MARK: - Update Widget Data
    
    func updateWidgetData(bills: [Bill], expenses: [Expense], monthlyIncome: Double = 0, currencyCode: String = "USD", currencySymbol: String = "$", aiInsight: String? = nil) {
        print("📱 [WIDGET] Updating widget data:")
        print("  - Bills count: \(bills.count)")
        print("  - Expenses count: \(expenses.count)")
        print("  - Monthly income: \(currencySymbol)\(monthlyIncome)")
        print("  - Currency: \(currencyCode) (\(currencySymbol))")
        
        updateSpendingData(expenses: expenses)
        updateBillsData(bills: bills)
        updateIncomeData(monthlyIncome: monthlyIncome)
        updateCurrencyData(code: currencyCode, symbol: currencySymbol)
        
        if let insight = aiInsight {
            updateAIInsight(insight)
        }
        
        triggerWidgetRefresh()
        
        // Verify data was saved
        if let defaults = sharedDefaults {
            print("📱 [WIDGET] Data saved to UserDefaults:")
            print("  - Today's spending: \(currencySymbol)\(defaults.double(forKey: "todaysSpending"))")
            print("  - Monthly bills: \(currencySymbol)\(defaults.double(forKey: "monthlyBills"))")
            print("  - Monthly non-bill expenses: \(currencySymbol)\(defaults.double(forKey: "monthlyNonBillExpenses"))")
            print("  - Monthly spending (total): \(currencySymbol)\(defaults.double(forKey: "monthlySpending"))")
            print("  - Monthly income: \(currencySymbol)\(defaults.double(forKey: "monthlyIncome"))")
        } else {
            print("❌ [WIDGET] ERROR: sharedDefaults is nil - check app group configuration!")
        }
    }
    
    private func updateSpendingData(expenses: [Expense]) {
        let calendar = Calendar.current
        let today = Date()
        
        // Calculate today's spending (all expenses)
        let todaysExpenses = expenses.filter { expense in
            guard let expenseDate = ISO8601DateFormatter().date(from: expense.expenseDate) else { return false }
            return calendar.isDate(expenseDate, inSameDayAs: today)
        }
        let todaysTotal = todaysExpenses.reduce(0) { $0 + $1.amount }
        
        // Calculate this month's non-bill expenses
        let thisMonthExpenses = expenses.filter { expense in
            guard let expenseDate = ISO8601DateFormatter().date(from: expense.expenseDate) else { return false }
            return calendar.isDate(expenseDate, equalTo: today, toGranularity: .month)
        }
        
        // Separate bill payments from regular expenses
        let nonBillExpenses = thisMonthExpenses.filter { $0.billId == nil }
        let nonBillExpensesTotal = nonBillExpenses.reduce(0) { $0 + $1.amount }
        
        sharedDefaults?.set(todaysTotal, forKey: "todaysSpending")
        sharedDefaults?.set(nonBillExpensesTotal, forKey: "monthlyNonBillExpenses")
    }
    
    private func updateBillsData(bills: [Bill]) {
        let calendar = Calendar.current
        let today = Date()
        
        // Calculate total monthly bills
        let monthlyBillsTotal = bills.reduce(0) { total, bill in
            // Include all bills regardless of status for the month
            return total + bill.amount
        }
        sharedDefaults?.set(monthlyBillsTotal, forKey: "monthlyBills")
        
        // Get upcoming bills (sorted by due date, regardless of how far in the future)
        let upcomingBills = bills
            .filter { bill in
                let dueDate = bill.nextDueDate ?? bill.dueDate
                return dueDate >= today || bill.status == .overdue
            }
            .sorted { ($0.nextDueDate ?? $0.dueDate) < ($1.nextDueDate ?? $1.dueDate) }
            .prefix(5)
        
        let widgetBills = upcomingBills.map { bill in
            WidgetBillData(
                name: bill.name,
                amount: bill.amount,
                dueDate: bill.nextDueDate ?? bill.dueDate,
                status: bill.status.rawValue
            )
        }
        
        if let data = try? JSONEncoder().encode(Array(widgetBills)) {
            sharedDefaults?.set(data, forKey: "upcomingBills")
        }
        
        // Calculate and store total monthly spending (bills + non-bill expenses)
        let nonBillExpenses = sharedDefaults?.double(forKey: "monthlyNonBillExpenses") ?? 0
        let totalMonthlySpending = monthlyBillsTotal + nonBillExpenses
        sharedDefaults?.set(totalMonthlySpending, forKey: "monthlySpending")
    }
    
    private func updateIncomeData(monthlyIncome: Double) {
        sharedDefaults?.set(monthlyIncome, forKey: "monthlyIncome")
    }
    
    private func updateCurrencyData(code: String, symbol: String) {
        sharedDefaults?.set(code, forKey: "currencyCode")
        sharedDefaults?.set(symbol, forKey: "currencySymbol")
    }
    
    private func updateAIInsight(_ insight: String) {
        sharedDefaults?.set(insight, forKey: "latestAIInsight")
    }
    
    private func triggerWidgetRefresh() {
        sharedDefaults?.set(Date(), forKey: "lastUpdated")
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - AI Integration Helper
    
    func updateWithAIAnalysis(bills: [Bill], expenses: [Expense]) async {
        // This could call your AnthropicService for fresh insights
        updateWidgetData(bills: bills, expenses: expenses)
        
        // Future: Add AI analysis call here
        // let insight = try await AnthropicService.shared.generateSpendingInsight(expenses)
        // updateAIInsight(insight)
    }
}

// MARK: - Shared Data Models

struct WidgetBillData: Codable {
    let name: String
    let amount: Double
    let dueDate: Date
    let status: String
}