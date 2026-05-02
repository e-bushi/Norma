//
//  SupabaseService+Expenses.swift
//  Norma
//
//  Created by Claude on 6/29/25.
//

import Foundation
import Supabase

extension SupabaseService {
    
    // MARK: - Expenses Methods (Legacy - Non-encrypted)
    
    /// Fetch all expenses for a user
    func fetchExpenses(userId: String) async throws -> [Expense] {
        let response: [Expense] = try await from("expenses")
            .select()
            .eq("user_id", value: userId)
            .order("expense_date", ascending: false)
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
            .gte("expense_date", value: dateFormatter.string(from: startDate))
            .lte("expense_date", value: dateFormatter.string(from: endDate))
            .order("expense_date", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    /// Fetch expenses by budget
    func fetchExpenses(userId: String, budgetId: String) async throws -> [Expense] {
        let response: [Expense] = try await from("expenses")
            .select()
            .eq("user_id", value: userId)
            .eq("budget_id", value: budgetId)
            .order("date", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    // MARK: - Expenses Methods (Encryption Support)
    
    /// Fetch expenses with encryption support (current month only)
    func fetchEncryptableExpenses(userId: String) async throws -> [EncryptableExpense] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!
        let startDate = dateFormatter.string(from: startOfMonth)

        let response: [EncryptableExpense] = try await from("expenses")
            .select()
            .eq("user_id", value: userId)
            .gte("expense_date", value: startDate)
            .order("expense_date", ascending: false)
            .execute()
            .value

        return response
    }
    
    /// Create expense with encryption support
    func createEncryptableExpense(_ expense: EncryptableExpense) async throws -> EncryptableExpense {
        print("🔍 [DEBUG] SupabaseService.createEncryptableExpense called")
        print("🔍 [DEBUG] Expense to create: \(expense)")
        
        print("🔍 [DEBUG] About to execute Supabase insert query (using object directly)")
        
        let response: EncryptableExpense = try await from("expenses")
            .insert(expense)
            .select()
            .single()
            .execute()
            .value
        
        print("🔍 [DEBUG] Supabase insert successful, returning response")
        return response
    }
    
    /// Update expense with encryption support
    func updateEncryptableExpense(_ expense: EncryptableExpense) async throws -> EncryptableExpense {
        guard let id = expense.id else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Expense ID is required for update"])
        }
        
        let response: EncryptableExpense = try await from("expenses")
            .update(expense)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    /// Update expense encryption during migration
    func updateExpenseEncryption(expenseId: String, encryptedName: String, encryptedAmount: String) async throws {
        _ = try await from("expenses")
            .update([
                "encrypted_name": AnyJSON.string(encryptedName),
                "encrypted_amount": AnyJSON.string(encryptedAmount),
                "is_encrypted": AnyJSON.bool(true)
            ])
            .eq("id", value: expenseId)
            .execute()
    }

    // MARK: - Semantic Search Support

    /// Fetch specific expenses by their IDs (for semantic search results)
    func fetchExpensesByIds(_ ids: [String]) async throws -> [EncryptableExpense] {
        guard !ids.isEmpty else { return [] }

        let response: [EncryptableExpense] = try await from("expenses")
            .select()
            .in("id", values: ids)
            .execute()
            .value

        return response
    }
}
