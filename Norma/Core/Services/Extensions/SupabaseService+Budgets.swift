//
//  SupabaseService+Budgets.swift
//  Norma
//
//  Created by Claude on 6/29/25.
//

import Foundation
import Supabase

extension SupabaseService {
    
    // MARK: - Budgets Methods
    
    /// Fetch all budgets for a user
    func fetchBudgets(userId: String) async throws -> [Budget] {
        let response: [Budget] = try await from("budgets")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    /// Create a new budget
    func createBudget(_ budget: Budget) async throws -> Budget {
        let response: Budget = try await from("budgets")
            .insert(budget)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    /// Update existing budget
    func updateBudget(_ budget: Budget) async throws -> Budget {
        let response: Budget = try await from("budgets")
            .update(budget)
            .eq("id", value: budget.id ?? "")
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    /// Delete a budget
    func deleteBudget(_ budgetId: String) async throws {
        try await from("budgets")
            .delete()
            .eq("id", value: budgetId)
            .execute()
    }
    
    /// Fetch active budgets for a user
    func fetchActiveBudgets(userId: String) async throws -> [Budget] {
        let response: [Budget] = try await from("budgets")
            .select()
            .eq("user_id", value: userId)
            .eq("is_active", value: true)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    /// Fetch budgets by category
    func fetchBudgets(userId: String, categoryId: String) async throws -> [Budget] {
        let response: [Budget] = try await from("budgets")
            .select()
            .eq("user_id", value: userId)
            .eq("category_id", value: categoryId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    /// Fetch budgets by period
    func fetchBudgets(userId: String, period: BudgetPeriod) async throws -> [Budget] {
        let response: [Budget] = try await from("budgets")
            .select()
            .eq("user_id", value: userId)
            .eq("period", value: period.rawValue)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
}