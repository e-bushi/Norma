//
//  DataManager+Categories.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation
import SwiftData

extension DataManager {
    
    // MARK: - Category Methods
    
    func fetchCategories() async throws {
        do {
            // Try to fetch from Supabase first
            let fetchedCategories = try await supabaseService.fetchCategories()
            categories = fetchedCategories

            // Cache categories in SwiftData
            await cacheCategories(fetchedCategories)

            print("Fetched \(fetchedCategories.count) categories from server")
        } catch {
            // If fetch fails (offline), load from cache
            print("Failed to fetch categories from server: \(error). Loading from cache...")
            // Note: SwiftData cache loading handled elsewhere

            // If we have cached data, don't throw the error
            if !categories.isEmpty {
                print("Loaded \(categories.count) categories from cache")
            } else {
                // Re-throw if we have no cached data
                throw error
            }
        }
    }
    
    func addCategory(_ category: Category) async throws {
        // Create category with temporary ID for offline usage
        var categoryToAdd = category
        if categoryToAdd.id == nil {
            categoryToAdd.id = UUID().uuidString
        }
        
        // Always add to local state first (offline-first approach)
        categories.append(categoryToAdd)
        
        // Cache the category locally
        await cacheCategories([categoryToAdd])
        
        // Try to sync to Supabase (but don't fail if offline)
        do {
            let createdCategory = try await supabaseService.createCategory(categoryToAdd)
            
            // Update the local category with the server ID if different
            if let index = categories.firstIndex(where: { $0.id == categoryToAdd.id }) {
                categories[index] = createdCategory
            }
            
            // Update cache with server version
            await updateCachedCategory(createdCategory)
            
        } catch {
            print("Supabase sync failed (offline mode): \(error)")
            // Mark as needing sync later
            hasUnsyncedChanges = true
        }
        
        print("Added category: \(category.name)")
    }
    
    func updateCategory(_ category: Category) async throws {
        let updatedCategory = try await supabaseService.updateCategory(category)
        
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = updatedCategory
            hasUnsyncedChanges = true
        }
        
        // Update cache
        await updateCachedCategory(updatedCategory)
        
        print("Updated category: \(category.name)")
    }
    
    func deleteCategory(_ category: Category) async throws {
        // Check if category is in use
        let isInUse = expenses.contains { $0.budgetId == category.id } ||
                     budgets.contains { $0.categoryId == category.id }
        
        guard !isInUse else {
            throw CategoryError.categoryInUse
        }
        
        guard let categoryId = category.id else {
            throw NSError(domain: "DataManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Category ID is required for deletion"])
        }
        
        try await supabaseService.deleteCategory(categoryId)
        categories.removeAll { $0.id == category.id }
        hasUnsyncedChanges = true
        
        // Remove from cache
        await deleteCachedCategory(categoryId)
        
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
            if let budgetId = expense.budgetId {
                categoryUsage[budgetId, default: 0] += 1
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
    
    func createDefaultCategories() async throws {
        let defaultCategories = [
            Category(
                name: "Housing",
                type: .expense,
                icon: "house.fill",
                colorHex: "#FF6B6B",
                isSystem: true,
                sortOrder: 1
            ),
            Category(
                name: "Transportation",
                type: .expense,
                icon: "car.fill",
                colorHex: "#4ECDC4",
                isSystem: true,
                sortOrder: 2
            ),
            Category(
                name: "Food",
                type: .expense,
                icon: "fork.knife",
                colorHex: "#FF5722",
                isSystem: true,
                sortOrder: 3
            ),
            Category(
                name: "Utilities",
                type: .expense,
                icon: "bolt.fill",
                colorHex: "#FECA57",
                isSystem: true,
                sortOrder: 4
            ),
            Category(
                name: "Healthcare",
                type: .expense,
                icon: "heart.fill",
                colorHex: "#FF9FF3",
                isSystem: true,
                sortOrder: 5
            ),
            Category(
                name: "Shopping",
                type: .expense,
                icon: "bag.fill",
                colorHex: "#45B7D1",
                isSystem: true,
                sortOrder: 6
            ),
            Category(
                name: "Entertainment",
                type: .expense,
                icon: "tv.fill",
                colorHex: "#96CEB4",
                isSystem: true,
                sortOrder: 7
            ),
            Category(
                name: "Education",
                type: .expense,
                icon: "book.fill",
                colorHex: "#3F51B5",
                isSystem: true,
                sortOrder: 8
            ),
            Category(
                name: "Financial",
                type: .expense,
                icon: "banknote.fill",
                colorHex: "#54A0FF",
                isSystem: true,
                sortOrder: 9
            ),
            Category(
                name: "Self Care",
                type: .expense,
                icon: "sparkles",
                colorHex: "#E91E63",
                isSystem: true,
                sortOrder: 10
            ),
            Category(
                name: "Travel",
                type: .expense,
                icon: "airplane",
                colorHex: "#9C27B0",
                isSystem: true,
                sortOrder: 11
            ),
            Category(
                name: "Miscellaneous",
                type: .expense,
                icon: "questionmark.circle.fill",
                colorHex: "#607D8B",
                isSystem: true,
                sortOrder: 12
            )
        ]
        
        // Get existing category names to avoid duplicates
        let existingCategoryNames = categories
            .filter { $0.type == .expense && $0.isSystem }
            .map { $0.name.lowercased() }
        
        var categoriesAdded = 0
        
        for category in defaultCategories {
            // Only add if a category with this name doesn't already exist
            if !existingCategoryNames.contains(category.name.lowercased()) {
                try await addCategory(category)
                categoriesAdded += 1
            }
        }
        
        print("✅ Created \(categoriesAdded) new default categories (skipped \(defaultCategories.count - categoriesAdded) existing)")
    }
    
    func removeDuplicateCategories() async throws {
        // Group categories by name and type
        var categoryGroups: [String: [Category]] = [:]
        
        for category in categories {
            let key = "\(category.name.lowercased())_\(category.type.rawValue)"
            if categoryGroups[key] == nil {
                categoryGroups[key] = []
            }
            categoryGroups[key]?.append(category)
        }
        
        var duplicatesRemoved = 0
        
        // For each group, keep only the first (oldest) and remove the rest
        for (_, group) in categoryGroups where group.count > 1 {
            // Sort by creation date or ID to keep the oldest
            let sortedGroup = group.sorted { cat1, cat2 in
                // If both have IDs, compare them (older IDs are usually smaller)
                if let id1 = cat1.id, let id2 = cat2.id {
                    return id1 < id2
                }
                // If one has no ID, it's newer (offline created)
                return cat1.id != nil
            }
            
            // Keep the first one, remove the rest
            for i in 1..<sortedGroup.count {
                let duplicateCategory = sortedGroup[i]
                
                // Check if this category is being used
                let isInUse = expenses.contains { $0.budgetId == duplicateCategory.id } ||
                             budgets.contains { $0.categoryId == duplicateCategory.id }
                
                if !isInUse {
                    // Safe to remove this duplicate
                    if let id = duplicateCategory.id {
                        try await deleteCategory(duplicateCategory)
                        duplicatesRemoved += 1
                    }
                }
            }
        }
        
        if duplicatesRemoved > 0 {
            print("🧹 Removed \(duplicatesRemoved) duplicate categories")
        }
    }
    
    // MARK: - SwiftData Caching
    
    private func cacheCategories(_ categoriesToCache: [Category]) async {
        guard let modelContext = modelContext else { return }

        do {
            // First, clear all existing cached categories (shared across all users)
            let descriptor = FetchDescriptor<CachedCategory>()

            let existingCached = try modelContext.fetch(descriptor)
            for cached in existingCached {
                modelContext.delete(cached)
            }

            // Then insert new cached categories
            for category in categoriesToCache {
                let cachedCategory = CachedCategory(from: category)
                modelContext.insert(cachedCategory)
            }

            try modelContext.save()
            print("Successfully cached \(categoriesToCache.count) categories")
        } catch {
            print("Failed to cache categories: \(error)")
        }
    }
    
    private func updateCachedCategory(_ category: Category) async {
        guard let modelContext = modelContext,
              let categoryId = category.id else { return }
        
        do {
            let descriptor = FetchDescriptor<CachedCategory>(
                predicate: #Predicate { cachedCategory in
                    cachedCategory.id == categoryId
                }
            )
            
            if let existingCached = try modelContext.fetch(descriptor).first {
                // Update existing cached category
                existingCached.name = category.name
                existingCached.type = category.type.rawValue
                existingCached.icon = category.icon
                existingCached.colorHex = category.colorHex
                existingCached.isSystem = category.isSystem
                existingCached.isActive = category.isActive
                existingCached.sortOrder = category.sortOrder
                existingCached.updatedAt = Date()
                existingCached.lastSyncedAt = Date()
            } else {
                // Create new cached category if not found
                let cachedCategory = CachedCategory(from: category)
                modelContext.insert(cachedCategory)
            }
            
            try modelContext.save()
            print("Updated cached category: \(category.name)")
        } catch {
            print("Failed to update cached category: \(error)")
        }
    }
    
    private func deleteCachedCategory(_ categoryId: String) async {
        guard let modelContext = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<CachedCategory>(
                predicate: #Predicate { cachedCategory in
                    cachedCategory.id == categoryId
                }
            )
            
            if let cachedCategory = try modelContext.fetch(descriptor).first {
                modelContext.delete(cachedCategory)
                try modelContext.save()
                print("Deleted cached category with id: \(categoryId)")
            }
        } catch {
            print("Failed to delete cached category: \(error)")
        }
    }
    
    // MARK: - Cache Loading

    func loadCachedCategories() {
        Task {
            do {
                try await fetchCategories()
                print("✅ Categories loaded: \(categories.count) categories")
            } catch {
                print("Failed to load cached categories: \(error)")
            }
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