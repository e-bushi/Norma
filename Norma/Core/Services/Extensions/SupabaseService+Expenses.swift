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
            .gte("date", value: dateFormatter.string(from: startDate))
            .lte("date", value: dateFormatter.string(from: endDate))
            .order("date", ascending: false)
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
    
    /// Fetch expenses with encryption support
    func fetchEncryptableExpenses(userId: String) async throws -> [EncryptableExpense] {
        let response = try await from("expenses")
            .select()
            .eq("user_id", value: userId)
            .order("expense_date", ascending: false)
            .execute()
        
        let decoder = JSONDecoder()
        return try decoder.decode([EncryptableExpense].self, from: response.data)
    }
    
    /// Create expense with encryption support
    func createEncryptableExpense(_ expense: EncryptableExpense) async throws -> EncryptableExpense {
        let encoder = JSONEncoder()
        let data = try encoder.encode(expense)
        
        let response = try await from("expenses")
            .insert(data)
            .select()
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        return try decoder.decode(EncryptableExpense.self, from: response.data)
    }
    
    /// Update expense with encryption support
    func updateEncryptableExpense(_ expense: EncryptableExpense) async throws -> EncryptableExpense {
        guard let id = expense.id else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Expense ID is required for update"])
        }
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(expense)
        
        let response = try await from("expenses")
            .update(data)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        return try decoder.decode(EncryptableExpense.self, from: response.data)
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
}
