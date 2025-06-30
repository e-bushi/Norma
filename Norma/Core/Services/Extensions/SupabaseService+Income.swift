//
//  SupabaseService+Income.swift
//  Norma
//
//  Created by Claude on 6/29/25.
//

import Foundation
import Supabase

extension SupabaseService {
    
    // MARK: - Income Methods
    
    /// Fetch all income for a user
    func fetchIncomes(userId: String) async throws -> [Income] {
        let response: [Income] = try await from("income")
            .select()
            .eq("user_id", value: userId)
            .order("next_date", ascending: true)
            .execute()
            .value
        
        return response
    }
    
    /// Create a new income
    func createIncome(_ income: Income) async throws -> Income {
        let response: Income = try await from("income")
            .insert(income)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    /// Update existing income
    func updateIncome(_ income: Income) async throws -> Income {
        let response: Income = try await from("income")
            .update(income)
            .eq("id", value: income.id ?? "")
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    /// Delete an income
    func deleteIncome(_ incomeId: String) async throws {
        try await from("income")
            .delete()
            .eq("id", value: incomeId)
            .execute()
    }
    
    /// Fetch active income for a user
    func fetchActiveIncomes(userId: String) async throws -> [Income] {
        let response: [Income] = try await from("income")
            .select()
            .eq("user_id", value: userId)
            .eq("is_active", value: true)
            .order("next_date", ascending: true)
            .execute()
            .value
        
        return response
    }
    
    /// Fetch income by source
    func fetchIncomes(userId: String, source: IncomeSource) async throws -> [Income] {
        let response: [Income] = try await from("income")
            .select()
            .eq("user_id", value: userId)
            .eq("source", value: source.rawValue)
            .order("next_date", ascending: true)
            .execute()
            .value
        
        return response
    }
}