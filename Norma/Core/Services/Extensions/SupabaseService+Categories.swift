//
//  SupabaseService+Categories.swift
//  Norma
//
//  Created by Claude on 6/29/25.
//

import Foundation
import Supabase

extension SupabaseService {
    
    // MARK: - Categories Methods

    /// Fetch all categories (shared across all users)
    func fetchCategories() async throws -> [Category] {
        let response: [Category] = try await from("categories")
            .select()
            .order("sort_order", ascending: true)
            .execute()
            .value

        return response
    }
    
    /// Create a new category
    func createCategory(_ category: Category) async throws -> Category {
        let response: Category = try await from("categories")
            .insert(category)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    /// Update existing category
    func updateCategory(_ category: Category) async throws -> Category {
        let response: Category = try await from("categories")
            .update(category)
            .eq("id", value: category.id ?? "")
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    /// Delete a category
    func deleteCategory(_ categoryId: String) async throws {
        try await from("categories")
            .delete()
            .eq("id", value: categoryId)
            .execute()
    }
    
    /// Fetch categories by type
    func fetchCategories(type: CategoryType) async throws -> [Category] {
        let response: [Category] = try await from("categories")
            .select()
            .eq("type", value: type.rawValue)
            .order("sort_order", ascending: true)
            .execute()
            .value

        return response
    }
}