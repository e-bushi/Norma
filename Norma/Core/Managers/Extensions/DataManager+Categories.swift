//
//  DataManager+Categories.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation

extension DataManager {
    
    // MARK: - Category Methods
    
    func fetchCategories(userId: String) async throws {
        // let fetchedCategories = try await supabaseService.fetchCategories(userId: userId)
        // categories = fetchedCategories
        
        print("Fetching categories for user: \(userId)")
    }
    
    func addCategory(_ category: Category) async throws {
        categories.append(category)
        hasUnsyncedChanges = true
        
        // try await supabaseService.createCategory(category)
        
        print("Added category: \(category.name)")
    }
    
    func updateCategory(_ category: Category) async throws {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
            hasUnsyncedChanges = true
        }
        
        // try await supabaseService.updateCategory(category)
        
        print("Updated category: \(category.name)")
    }
    
    func deleteCategory(_ category: Category) async throws {
        // Check if category is in use
        let isInUse = expenses.contains { $0.categoryId == category.id } ||
                     budgets.contains { $0.categoryId == category.id }
        
        guard !isInUse else {
            throw CategoryError.categoryInUse
        }
        
        categories.removeAll { $0.id == category.id }
        hasUnsyncedChanges = true
        
        // try await supabaseService.deleteCategory(category.id)
        
        print("Deleted category: \(category.name)")
    }
    
    // MARK: - Category Queries
    
    func getCategories(ofType type: CategoryType? = nil) -> [Category] {
        if let type = type {
            return categories.filter { $0.type == type }
                .sorted { $0.name < $1.name }
        }
        return categories.sorted { $0.name < $1.name }
    }
    
    func getSystemCategories() -> [Category] {
        return categories.filter { $0.isSystem }
            .sorted { $0.name < $1.name }
    }
    
    func getUserCategories() -> [Category] {
        return categories.filter { !$0.isSystem }
            .sorted { $0.name < $1.name }
    }
    
    func getCategory(byId id: String) -> Category? {
        return categories.first { $0.id == id }
    }
    
    func getCategory(byName name: String) -> Category? {
        return categories.first { $0.name.lowercased() == name.lowercased() }
    }
    
    func getMostUsedCategories(limit: Int = 5) -> [Category] {
        var categoryUsage: [String: Int] = [:]
        
        // Count expense usage
        for expense in expenses {
            if let categoryId = expense.categoryId {
                categoryUsage[categoryId, default: 0] += 1
            }
        }
        
        // Sort by usage and get categories
        let sortedCategoryIds = categoryUsage.sorted { $0.value > $1.value }
            .prefix(limit)
            .compactMap { $0.key }
        
        return sortedCategoryIds.compactMap { categoryId in
            categories.first { $0.id == categoryId }
        }
    }
    
    func createDefaultCategories(for userId: String) async throws {
        let defaultCategories = [
            Category(
                userId: userId,
                name: "Food & Dining",
                type: .expense,
                icon: "fork.knife",
                colorHex: "#FF6B6B",
                isSystem: true
            ),
            Category(
                userId: userId,
                name: "Transportation",
                type: .expense,
                icon: "car.fill",
                colorHex: "#4ECDC4",
                isSystem: true
            ),
            Category(
                userId: userId,
                name: "Shopping",
                type: .expense,
                icon: "bag.fill",
                colorHex: "#45B7D1",
                isSystem: true
            ),
            Category(
                userId: userId,
                name: "Entertainment",
                type: .expense,
                icon: "tv.fill",
                colorHex: "#96CEB4",
                isSystem: true
            ),
            Category(
                userId: userId,
                name: "Bills & Utilities",
                type: .expense,
                icon: "doc.text.fill",
                colorHex: "#FECA57",
                isSystem: true
            ),
            Category(
                userId: userId,
                name: "Healthcare",
                type: .expense,
                icon: "heart.fill",
                colorHex: "#FF9FF3",
                isSystem: true
            ),
            Category(
                userId: userId,
                name: "Salary",
                type: .income,
                icon: "briefcase.fill",
                colorHex: "#54A0FF",
                isSystem: true
            ),
            Category(
                userId: userId,
                name: "Freelance",
                type: .income,
                icon: "laptopcomputer",
                colorHex: "#48DBFB",
                isSystem: true
            ),
            Category(
                userId: userId,
                name: "Investments",
                type: .income,
                icon: "chart.line.uptrend.xyaxis",
                colorHex: "#0ABDE3",
                isSystem: true
            )
        ]
        
        for category in defaultCategories {
            try await addCategory(category)
        }
    }
}

// MARK: - Category Errors

enum CategoryError: LocalizedError {
    case categoryInUse
    
    var errorDescription: String? {
        switch self {
        case .categoryInUse:
            return "This category is currently in use and cannot be deleted."
        }
    }
}