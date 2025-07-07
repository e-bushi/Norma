//
//  DataManager+Expenses.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation
import SwiftData

extension DataManager {
    
    // MARK: - Expense Methods
    
    func fetchExpenses(userId: String) async throws {
        do {
            // Try to fetch from Supabase first
            let fetchedExpenses = try await supabaseService.fetchExpenses(userId: userId)
            expenses = fetchedExpenses
            
            // Cache expenses in SwiftData
            await cacheExpenses(fetchedExpenses)
            
            print("Fetched \(fetchedExpenses.count) expenses from server")
        } catch {
            // If fetch fails (offline), load from cache
            print("Failed to fetch expenses from server: \(error). Loading from cache...")
            loadCachedExpenses()
            
            // If we have cached data, don't throw the error
            if !expenses.isEmpty {
                print("Loaded \(expenses.count) expenses from cache")
            } else {
                // Re-throw if we have no cached data
                throw error
            }
        }
    }
    
    func addExpense(_ expense: Expense) async throws {
        print("🔍 [DEBUG] DataManager.addExpense called for: \(expense.name)")
        
        // Create expense with temporary ID for offline usage
        var expenseToAdd = expense
        if expenseToAdd.id == nil {
            expenseToAdd.id = UUID().uuidString
        }
        
        // Always add to local state first (offline-first approach)
        print("🔄 [DEBUG] DataManager.addExpense: Adding expense to local expenses array...")
        expenses.append(expenseToAdd)
        print("✅ [DEBUG] DataManager.addExpense: Expenses array now has \(expenses.count) items")
        
        // Cache the expense locally
        print("🔄 [DEBUG] DataManager.addExpense: Caching expense locally...")
        await cacheExpenses([expenseToAdd])
        print("✅ [DEBUG] DataManager.addExpense: Local caching completed")
        
        // Try to sync to Supabase (but don't fail if offline)
        do {
            print("🔄 [DEBUG] DataManager.addExpense: Attempting to sync to Supabase...")
            let createdExpense = try await supabaseService.createExpense(expenseToAdd)
            print("✅ [DEBUG] DataManager.addExpense: Supabase sync successful")
            
            // Update the local expense with the server ID if different
            if let index = expenses.firstIndex(where: { $0.id == expenseToAdd.id }) {
                expenses[index] = createdExpense
            }
            
            // Update cache with server version
            await updateCachedExpense(createdExpense)
            
        } catch {
            print("⚠️ [DEBUG] DataManager.addExpense: Supabase sync failed (offline mode): \(error)")
            // Mark as needing sync later
            hasUnsyncedChanges = true
        }
        
        print("✅ [DEBUG] DataManager.addExpense: Method completed - Added expense: \(expense.name)")
    }
    
    func updateExpense(_ expense: Expense) async throws {
        let updatedExpense = try await supabaseService.updateExpense(expense)
        
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = updatedExpense
            hasUnsyncedChanges = true
        }
        
        // Update cache
        await updateCachedExpense(updatedExpense)
        
        print("Updated expense: \(expense.name)")
    }
    
    func deleteExpense(_ expense: Expense) async throws {
        guard let expenseId = expense.id else {
            throw NSError(domain: "DataManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Expense ID is required for deletion"])
        }
        
        try await supabaseService.deleteExpense(expenseId)
        expenses.removeAll { $0.id == expense.id }
        hasUnsyncedChanges = true
        
        // Remove from cache
        await deleteCachedExpense(expenseId)
        
        print("Deleted expense: \(expense.name)")
    }
    
    // MARK: - Expense Queries
    
    func getExpenses(for category: Category? = nil, in dateRange: DateInterval? = nil) -> [Expense] {
        var filtered = expenses
        
        if let category = category {
            filtered = filtered.filter { $0.categoryId == category.id }
        }
        
        if let dateRange = dateRange {
            let dateFormatter = ISO8601DateFormatter()
            filtered = filtered.filter { expense in
                guard let expenseDate = dateFormatter.date(from: expense.expenseDate) else { return false }
                return dateRange.contains(expenseDate)
            }
        }
        
        let dateFormatter = ISO8601DateFormatter()
        return filtered.sorted { 
            guard let date1 = dateFormatter.date(from: $0.expenseDate),
                  let date2 = dateFormatter.date(from: $1.expenseDate) else { return false }
            return date1 > date2
        }
    }
    
    func getTotalExpenses(for period: DateInterval? = nil) -> Double {
        let relevantExpenses = period != nil ? getExpenses(for: nil, in: period) : expenses
        return relevantExpenses.reduce(0) { $0 + $1.amount }
    }
    
    func getExpensesByCategory() -> [Category: Double] {
        var expensesByCategory: [Category: Double] = [:]
        
        for expense in expenses {
            if let categoryId = expense.categoryId,
               let category = categories.first(where: { $0.id == categoryId }) {
                expensesByCategory[category, default: 0] += expense.amount
            }
        }
        
        return expensesByCategory
    }
    
    func getRecentExpenses(limit: Int = 10) -> [Expense] {
        let dateFormatter = ISO8601DateFormatter()
        return Array(expenses.sorted { 
            guard let date1 = dateFormatter.date(from: $0.expenseDate),
                  let date2 = dateFormatter.date(from: $1.expenseDate) else { return false }
            return date1 > date2
        }.prefix(limit))
    }
    
    // MARK: - SwiftData Caching
    
    func loadCachedExpenses() {
        guard let modelContext = modelContext,
              let userId = currentProfile?.userId else { return }
        
        do {
            let descriptor = FetchDescriptor<CachedExpense>(
                predicate: #Predicate { cachedExpense in
                    cachedExpense.userId == userId
                }
            )
            
            let cachedExpenses = try modelContext.fetch(descriptor)
            
            // Convert cached expenses to regular expenses and update the published property
            self.expenses = cachedExpenses.map { $0.toExpense() }
            
            print("Loaded \(cachedExpenses.count) cached expenses")
        } catch {
            print("Failed to load cached expenses: \(error)")
        }
    }
    
    private func cacheExpenses(_ expensesToCache: [Expense]) async {
        print("🔍 [DEBUG] DataManager.cacheExpenses called with \(expensesToCache.count) expenses")
        
        guard let modelContext = modelContext else { 
            print("❌ [DEBUG] DataManager.cacheExpenses: No modelContext found")
            return 
        }
        
        print("✅ [DEBUG] DataManager.cacheExpenses: ModelContext is available")
        
        do {
            // First, clear existing cached expenses for this user
            if let userId = currentProfile?.userId {
                print("🔄 [DEBUG] DataManager.cacheExpenses: Clearing existing cached expenses for user: \(userId)")
                let descriptor = FetchDescriptor<CachedExpense>(
                    predicate: #Predicate { cachedExpense in
                        cachedExpense.userId == userId
                    }
                )
                
                let existingCached = try modelContext.fetch(descriptor)
                print("🔄 [DEBUG] DataManager.cacheExpenses: Found \(existingCached.count) existing cached expenses to remove")
                for cached in existingCached {
                    modelContext.delete(cached)
                }
            }
            
            // Then insert new cached expenses
            print("🔄 [DEBUG] DataManager.cacheExpenses: Inserting \(expensesToCache.count) new cached expenses")
            for expense in expensesToCache {
                let cachedExpense = CachedExpense(from: expense)
                modelContext.insert(cachedExpense)
                print("🔄 [DEBUG] DataManager.cacheExpenses: Inserted cached expense: \(cachedExpense.name)")
            }
            
            print("🔄 [DEBUG] DataManager.cacheExpenses: About to save modelContext...")
            try modelContext.save()
            print("✅ [DEBUG] DataManager.cacheExpenses: Successfully cached \(expensesToCache.count) expenses")
        } catch {
            print("❌ [DEBUG] DataManager.cacheExpenses: Failed to cache expenses: \(error)")
        }
    }
    
    private func updateCachedExpense(_ expense: Expense) async {
        guard let modelContext = modelContext,
              let expenseId = expense.id else { return }
        
        do {
            let descriptor = FetchDescriptor<CachedExpense>(
                predicate: #Predicate { cachedExpense in
                    cachedExpense.id == expenseId
                }
            )
            
            if let existingCached = try modelContext.fetch(descriptor).first {
                // Update existing cached expense
                existingCached.name = expense.name
                existingCached.amount = expense.amount
                existingCached.expenseDate = expense.expenseDate
                existingCached.categoryId = expense.categoryId
                existingCached.billId = expense.billId
                existingCached.paymentMethod = expense.paymentMethod.rawValue
                existingCached.isRecurring = expense.isRecurring
                existingCached.recurringFrequency = expense.recurringFrequency?.rawValue
                existingCached.merchant = expense.merchant
                existingCached.location = expense.location
                existingCached.tags = expense.tags
                existingCached.notes = expense.notes
                existingCached.attachmentUrls = expense.attachmentUrls
                existingCached.updatedAt = Date()
                existingCached.lastSyncedAt = Date()
            } else {
                // Create new cached expense if not found
                let cachedExpense = CachedExpense(from: expense)
                modelContext.insert(cachedExpense)
            }
            
            try modelContext.save()
            print("Updated cached expense: \(expense.name)")
        } catch {
            print("Failed to update cached expense: \(error)")
        }
    }
    
    private func deleteCachedExpense(_ expenseId: String) async {
        guard let modelContext = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<CachedExpense>(
                predicate: #Predicate { cachedExpense in
                    cachedExpense.id == expenseId
                }
            )
            
            if let cachedExpense = try modelContext.fetch(descriptor).first {
                modelContext.delete(cachedExpense)
                try modelContext.save()
                print("Deleted cached expense with id: \(expenseId)")
            }
        } catch {
            print("Failed to delete cached expense: \(error)")
        }
    }
}