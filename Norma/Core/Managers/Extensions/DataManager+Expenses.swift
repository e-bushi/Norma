//
//  DataManager+Expenses.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation

extension DataManager {
    
    // MARK: - Expense Methods
    
    func fetchExpenses(userId: String) async throws {
        // let fetchedExpenses = try await supabaseService.fetchExpenses(userId: userId)
        // expenses = fetchedExpenses
        
        print("Fetching expenses for user: \(userId)")
    }
    
    func addExpense(_ expense: Expense) async throws {
        // Add to local state immediately
        expenses.append(expense)
        hasUnsyncedChanges = true
        
        // Sync to remote
        // try await supabaseService.createExpense(expense)
        
        print("Added expense: \(expense.name)")
    }
    
    func updateExpense(_ expense: Expense) async throws {
        // Update local state
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = expense
            hasUnsyncedChanges = true
        }
        
        // Sync to remote
        // try await supabaseService.updateExpense(expense)
        
        print("Updated expense: \(expense.name)")
    }
    
    func deleteExpense(_ expense: Expense) async throws {
        // Remove from local state
        expenses.removeAll { $0.id == expense.id }
        hasUnsyncedChanges = true
        
        // Sync to remote
        // try await supabaseService.deleteExpense(expense.id)
        
        print("Deleted expense: \(expense.name)")
    }
    
    // MARK: - Expense Queries
    
    func getExpenses(for category: Category? = nil, in dateRange: DateInterval? = nil) -> [Expense] {
        var filtered = expenses
        
        if let category = category {
            filtered = filtered.filter { $0.categoryId == category.id }
        }
        
        if let dateRange = dateRange {
            filtered = filtered.filter { expense in
                return dateRange.contains(expense.date)
            }
        }
        
        return filtered.sorted { $0.date > $1.date }
    }
    
    func getTotalExpenses(for period: DateInterval? = nil) -> Double {
        let relevantExpenses = period != nil ? getExpenses(for: nil, in: period) : expenses
        return relevantExpenses.reduce(0) { $0 + $1.amount }
    }
    
    func getExpensesByCategory() -> [Category: Double] {
        var expensesByCategory: [Category: Double] = [:]
        
        for expense in expenses {
            if let categoryId = expense.categoryId,
               let category = categories.first(where: { $0.id == categoryId }) {
                expensesByCategory[category, default: 0] += expense.amount
            }
        }
        
        return expensesByCategory
    }
    
    func getRecentExpenses(limit: Int = 10) -> [Expense] {
        return Array(expenses.sorted { 
            $0.date > $1.date 
        }.prefix(limit))
    }
}