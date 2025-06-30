//
//  SupabaseService+Expenses.swift
//  Norma
//
//  Created by Claude on 6/29/25.
//

import Foundation
import Supabase

extension SupabaseService {
    
    // MARK: - Expenses Methods
    
    /// Fetch all expenses for a user
    func fetchExpenses(userId: String) async throws -> [Expense] {
        let response: [Expense] = try await from("expenses")
            .select()
            .eq("user_id", value: userId)
            .order("date", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    /// Create a new expense
    func createExpense(_ expense: Expense) async throws -> Expense {
        let response: Expense = try await from("expenses")
            .insert(expense)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    /// Update existing expense
    func updateExpense(_ expense: Expense) async throws -> Expense {
        let response: Expense = try await from("expenses")
            .update(expense)
            .eq("id", value: expense.id ?? "")
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    /// Delete an expense
    func deleteExpense(_ expenseId: String) async throws {
        try await from("expenses")
            .delete()
            .eq("id", value: expenseId)
            .execute()
    }
    
    /// Fetch expenses within a date range
    func fetchExpenses(userId: String, from startDate: Date, to endDate: Date) async throws -> [Expense] {
        let dateFormatter = ISO8601DateFormatter()
        
        let response: [Expense] = try await from("expenses")
            .select()
            .eq("user_id", value: userId)
            .gte("date", value: dateFormatter.string(from: startDate))
            .lte("date", value: dateFormatter.string(from: endDate))
            .order("date", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    /// Fetch expenses by category
    func fetchExpenses(userId: String, categoryId: String) async throws -> [Expense] {
        let response: [Expense] = try await from("expenses")
            .select()
            .eq("user_id", value: userId)
            .eq("category_id", value: categoryId)
            .order("date", ascending: false)
            .execute()
            .value
        
        return response
    }
}