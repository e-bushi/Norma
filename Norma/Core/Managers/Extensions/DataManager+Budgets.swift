//
//  DataManager+Budgets.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation
import SwiftData
import CryptoKit

extension DataManager {
    
    // MARK: - Budget Methods (Legacy - Non-encrypted)
    
    func fetchBudgets(userId: String) async throws {
        do {
            // Try to fetch from Supabase first
            let fetchedBudgets = try await supabaseService.fetchBudgets(userId: userId)
            budgets = fetchedBudgets
            
            // Cache budgets in SwiftData
            await cacheBudgets(fetchedBudgets)
            
            print("Fetched \(fetchedBudgets.count) budgets from server")
        } catch {
            // If fetch fails (offline), load from cache
            print("Failed to fetch budgets from server: \(error). Loading from cache...")
            // Note: SwiftData cache loading handled elsewhere
            
            // If we have cached data, don't throw the error
            if !budgets.isEmpty {
                print("Loaded \(budgets.count) budgets from cache")
            } else {
                // Re-throw if we have no cached data
                throw error
            }
        }
    }
    
    func addBudget(_ budget: Budget) async throws {
        // Try to sync to Supabase first
        do {
            // Don't send ID when creating - let database generate it
            var budgetForCreation = budget
            budgetForCreation.id = nil
            
            let createdBudget = try await supabaseService.createBudget(budgetForCreation)
            
            // Add the server-created budget to local state
            budgets.append(createdBudget)
            
            // Cache the budget locally
            await cacheBudgets([createdBudget])
            
            print("Added budget: \(createdBudget.name)")
            
        } catch {
            print("Failed to create budget on server: \(error)")
            
            // Fallback to offline mode
            var budgetToAdd = budget
            if budgetToAdd.id == nil {
                budgetToAdd.id = UUID().uuidString
            }
            
            // Add to local state for offline usage
            budgets.append(budgetToAdd)
            
            // Cache the budget locally
            await cacheBudgets([budgetToAdd])
            
            // Mark as needing sync later
            hasUnsyncedChanges = true
            
            // Re-throw the error so UI can show it
            throw error
        }
    }
    
    func updateBudget(_ budget: Budget) async throws {
        let updatedBudget = try await supabaseService.updateBudget(budget)
        
        if let index = budgets.firstIndex(where: { $0.id == budget.id }) {
            budgets[index] = updatedBudget
            hasUnsyncedChanges = true
        }
        
        // Update cache
        await updateCachedBudget(updatedBudget)
        
        print("Updated budget: \(budget.name)")
    }
    
    func deleteBudget(_ budget: Budget) async throws {
        guard let budgetId = budget.id else {
            throw NSError(domain: "DataManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Budget ID is required for deletion"])
        }
        
        try await supabaseService.deleteBudget(budgetId)
        budgets.removeAll { $0.id == budget.id }
        hasUnsyncedChanges = true
        
        // Remove from cache
        await deleteCachedBudget(budgetId)
        
        print("Deleted budget: \(budget.name)")
    }
    
    // MARK: - Budget Queries
    
    func getActiveBudgets() -> [Budget] {
        let currentDate = Date()
        
        return budgets.filter { budget in
            // Check if budget is active and within date range
            guard budget.isActive else { return false }
            
            let startDate = budget.startDate
            
            // If there's an end date, check if we're within range
            if let endDate = budget.endDate {
                return startDate <= currentDate && currentDate <= endDate
            } else {
                // If no end date, budget is ongoing from start date
                return startDate <= currentDate
            }
        }.sorted { $0.name < $1.name }
    }
    
    func getBudget(for category: Category) -> Budget? {
        return getActiveBudgets().first { budget in
            budget.categoryId == category.id
        }
    }
    
    func getBudgetUtilization(for budget: Budget) -> Double {
        guard let categoryId = budget.categoryId,
              let category = categories.first(where: { $0.id == categoryId }) else {
            return 0
        }
        
        let currentMonth = DateInterval(
            start: Date().startOfMonth(),
            end: Date().endOfMonth()
        )
        
        let spent = getExpenses(for: category, in: currentMonth)
            .reduce(0) { $0 + $1.amount }
        
        return budget.amount > 0 ? (spent / budget.amount) : 0
    }
    
    func getOverBudgetCategories() -> [(category: Category, budget: Budget, spent: Double)] {
        var overBudgetList: [(Category, Budget, Double)] = []
        
        for budget in getActiveBudgets() {
            guard let categoryId = budget.categoryId,
                  let category = categories.first(where: { $0.id == categoryId }) else {
                continue
            }
            
            let currentMonth = DateInterval(
                start: Date().startOfMonth(),
                end: Date().endOfMonth()
            )
            
            let spent = getExpenses(for: category, in: currentMonth)
                .reduce(0) { $0 + $1.amount }
            
            if spent > budget.amount {
                overBudgetList.append((category, budget, spent))
            }
        }
        
        return overBudgetList
    }
    
    func getTotalBudgetAmount() -> Double {
        return getActiveBudgets().reduce(0) { $0 + $1.amount }
    }
    
    func getRemainingBudget() -> Double {
        let totalBudget = getTotalBudgetAmount()
        let currentMonth = DateInterval(
            start: Date().startOfMonth(),
            end: Date().endOfMonth()
        )
        let totalSpent = getTotalExpenses(for: currentMonth)
        
        return totalBudget - totalSpent
    }
    
    // MARK: - SwiftData Caching
    
    private func cacheBudgets(_ budgetsToCache: [Budget]) async {
        guard let modelContext = modelContext else { return }
        
        do {
            // First, clear existing cached budgets for this user
            if let userId = currentProfile?.userId {
                let descriptor = FetchDescriptor<CachedBudget>(
                    predicate: #Predicate { cachedBudget in
                        cachedBudget.userId == userId
                    }
                )
                
                let existingCached = try modelContext.fetch(descriptor)
                for cached in existingCached {
                    modelContext.delete(cached)
                }
            }
            
            // Then insert new cached budgets
            for budget in budgetsToCache {
                let cachedBudget = CachedBudget(from: budget)
                modelContext.insert(cachedBudget)
            }
            
            try modelContext.save()
            print("Successfully cached \(budgetsToCache.count) budgets")
        } catch {
            print("Failed to cache budgets: \(error)")
        }
    }
    
    private func updateCachedBudget(_ budget: Budget) async {
        guard let modelContext = modelContext,
              let budgetId = budget.id else { return }
        
        do {
            let descriptor = FetchDescriptor<CachedBudget>(
                predicate: #Predicate { cachedBudget in
                    cachedBudget.id == budgetId
                }
            )
            
            if let existingCached = try modelContext.fetch(descriptor).first {
                // Update existing cached budget
                existingCached.name = budget.name
                existingCached.amount = budget.amount
                existingCached.categoryId = budget.categoryId
                existingCached.startDate = budget.startDate
                existingCached.endDate = budget.endDate
                existingCached.isActive = budget.isActive
                existingCached.currentSpent = budget.currentSpent
                existingCached.alertThreshold = budget.alertThreshold
                existingCached.notes = budget.notes
                existingCached.updatedAt = Date()
                existingCached.lastSyncedAt = Date()
            } else {
                // Create new cached budget if not found
                let cachedBudget = CachedBudget(from: budget)
                modelContext.insert(cachedBudget)
            }
            
            try modelContext.save()
            print("Updated cached budget: \(budget.name)")
        } catch {
            print("Failed to update cached budget: \(error)")
        }
    }
    
    private func deleteCachedBudget(_ budgetId: String) async {
        guard let modelContext = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<CachedBudget>(
                predicate: #Predicate { cachedBudget in
                    cachedBudget.id == budgetId
                }
            )
            
            if let cachedBudget = try modelContext.fetch(descriptor).first {
                modelContext.delete(cachedBudget)
                try modelContext.save()
                print("Deleted cached budget with id: \(budgetId)")
            }
        } catch {
            print("Failed to delete cached budget: \(error)")
        }
    }
    
    // MARK: - Budget Methods (Encryption Support)
    
    /// Fetch budgets with decryption support
    func fetchBudgetsWithEncryption(userId: String) async throws {
        do {
            let hasEncryption = await hasEncryptionEnabled()
            
            if hasEncryption {
                let masterKey = getCurrentMasterKey()
                let encryptableBudgets = try await supabaseService.fetchEncryptableBudgets(userId: userId)
                
                // Convert to regular budgets, decrypting if necessary
                let decryptedBudgets = encryptableBudgets.compactMap { encryptable in
                    encryptable.toBudget(using: masterKey)
                }
                
                budgets = decryptedBudgets
                
                // Cache budgets in SwiftData
                await cacheBudgets(decryptedBudgets)
                
                print("Fetched and decrypted \(decryptedBudgets.count) budgets from server")
            } else {
                // Use legacy path
                try await fetchBudgets(userId: userId)
            }
        } catch {
            // If fetch fails (offline), load from cache
            print("Failed to fetch budgets from server: \(error). Loading from cache...")
            // Note: SwiftData cache loading handled elsewhere
            
            // If we have cached data, don't throw the error
            if !budgets.isEmpty {
                print("Loaded \(budgets.count) budgets from cache")
            } else {
                // Re-throw if we have no cached data
                throw error
            }
        }
    }
    
    /// Create budget with encryption support if enabled
    func addBudgetWithEncryption(_ budget: Budget) async throws {
        let hasEncryption = await hasEncryptionEnabled()
        
        if hasEncryption, let masterKey = getCurrentMasterKey() {
            do {
                // Don't send ID when creating - let database generate it
                var budgetForCreation = budget
                budgetForCreation.id = nil
                
                // Create encrypted version
                guard let encryptableBudget = budgetForCreation.toEncryptable(encrypt: true, using: masterKey) else {
                    throw EncryptionError.encryptionFailed
                }
                
                let createdEncryptable = try await supabaseService.createEncryptableBudget(encryptableBudget)
                
                // Convert back to regular budget for display
                guard let displayBudget = createdEncryptable.toBudget(using: masterKey) else {
                    throw EncryptionError.decryptionFailed
                }
                
                // Add to local state
                budgets.append(displayBudget)
                
                // Cache the budget locally
                await cacheBudgets([displayBudget])
                
                print("Created encrypted budget: \(displayBudget.name)")
            } catch {
                print("Failed to sync encrypted budget (offline mode): \(error)")
                hasUnsyncedChanges = true
            }
        } else {
            // Use legacy non-encrypted path
            try await addBudget(budget)
        }
    }
    
    /// Update budget with encryption support
    func updateBudgetWithEncryption(_ budget: Budget) async throws {
        let hasEncryption = await hasEncryptionEnabled()
        
        if hasEncryption, let masterKey = getCurrentMasterKey() {
            // Create encrypted version
            guard let encryptableBudget = budget.toEncryptable(encrypt: true, using: masterKey) else {
                throw EncryptionError.encryptionFailed
            }
            
            let updatedEncryptable = try await supabaseService.updateEncryptableBudget(encryptableBudget)
            
            // Convert back to regular budget for display
            guard let displayBudget = updatedEncryptable.toBudget(using: masterKey) else {
                throw EncryptionError.decryptionFailed
            }
            
            if let index = budgets.firstIndex(where: { $0.id == budget.id }) {
                budgets[index] = displayBudget
                hasUnsyncedChanges = true
            }
            
            // Update cache
            await updateCachedBudget(displayBudget)
            
            print("Updated encrypted budget: \(budget.name)")
        } else {
            // Use legacy path
            try await updateBudget(budget)
        }
    }
    
    /// Migrate existing budgets to encrypted format
    func migrateBudgetsToEncryption() async throws {
        guard let userId = currentProfile?.userId,
              let masterKey = getCurrentMasterKey() else {
            throw EncryptionError.noEncryptionKeys
        }
        
        // Fetch all unencrypted budgets
        let allBudgets = budgets
        var migratedCount = 0
        
        for budget in allBudgets {
            // Skip if already encrypted (would need to track this)
            if let encryptableBudget = budget.toEncryptable(encrypt: true, using: masterKey) {
                do {
                    try await supabaseService.updateBudgetEncryption(
                        budgetId: budget.id ?? "",
                        encryptedName: encryptableBudget.encryptedName ?? ""
                    )
                    migratedCount += 1
                } catch {
                    print("Failed to migrate budget \(budget.id ?? ""): \(error)")
                }
            }
        }
        
        print("Migrated \(migratedCount) budgets to encrypted format")
        
        // Refresh to get encrypted versions
        try await fetchBudgetsWithEncryption(userId: userId)
    }
}

// MARK: - Date Extensions

extension Date {
    func startOfMonth() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
    
    func endOfMonth() -> Date {
        let calendar = Calendar.current
        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth()) {
            return calendar.date(byAdding: .day, value: -1, to: nextMonth) ?? self
        }
        return self
    }
}