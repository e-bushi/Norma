//
//  SupabaseService+Budgets.swift
//  Norma
//
//  Created by Claude on 6/29/25.
//

import Foundation
import Supabase

extension SupabaseService {
    
    // MARK: - Budgets Methods (Legacy - Non-encrypted)
    
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
    
    // MARK: - Budgets Methods (Encryption Support)
    
    /// Fetch budgets with encryption support
    func fetchEncryptableBudgets(userId: String) async throws -> [EncryptableBudget] {
        let response = try await from("budgets")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
        
        let decoder = JSONDecoder()
        do {
            return try decoder.decode([EncryptableBudget].self, from: response.data)
        } catch {
            print("❌ Failed to decode EncryptableBudget. Raw response: \(String(data: response.data, encoding: .utf8) ?? "nil")")
            print("❌ Decode error: \(error)")
            
            // If there are no budgets, return empty array
            if let jsonString = String(data: response.data, encoding: .utf8), jsonString == "[]" {
                return []
            }
            
            throw error
        }
    }
    
    /// Create budget with encryption support
    func createEncryptableBudget(_ budget: EncryptableBudget) async throws -> EncryptableBudget {
        let encoder = JSONEncoder()
        let data = try encoder.encode(budget)
        
        let response = try await from("budgets")
            .insert(data)
            .select()
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        return try decoder.decode(EncryptableBudget.self, from: response.data)
    }
    
    /// Update budget with encryption support
    func updateEncryptableBudget(_ budget: EncryptableBudget) async throws -> EncryptableBudget {
        guard let id = budget.id else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Budget ID is required for update"])
        }
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(budget)
        
        let response = try await from("budgets")
            .update(data)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        return try decoder.decode(EncryptableBudget.self, from: response.data)
    }
    
    /// Update budget encryption during migration
    func updateBudgetEncryption(budgetId: String, encryptedName: String) async throws {
        _ = try await from("budgets")
            .update([
                "encrypted_name": AnyJSON.string(encryptedName),
                "is_encrypted": AnyJSON.bool(true)
            ])
            .eq("id", value: budgetId)
            .execute()
    }
}