//
//  DataManager+Expenses.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation
import SwiftData
import CryptoKit

extension DataManager {
    
    // MARK: - Expense Methods (Legacy - Non-encrypted)
    
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
            // Note: SwiftData cache loading handled elsewhere
            
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
            filtered = filtered.filter { $0.budgetId == category.id }
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
            if let budgetId = expense.budgetId,
               let category = categories.first(where: { $0.id == budgetId }) {
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
                existingCached.budgetId = expense.budgetId
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
    
    // MARK: - Expense Methods (Encryption Support)

    /// Fetch expenses with decryption support
    /// Data is stored encrypted in the database; we decrypt locally using the master key
    func fetchExpensesWithEncryption(userId: String) async throws {
        do {
            guard let masterKey = getCurrentMasterKey() else {
                throw EncryptionError.noEncryptionKeys
            }

            // Fetch encrypted expenses from Supabase
            let encryptableExpenses = try await supabaseService.fetchEncryptableExpenses(userId: userId)

            // Decrypt locally for display
            let decryptedExpenses = encryptableExpenses.compactMap { encryptable in
                encryptable.toExpense(using: masterKey)
            }

            expenses = decryptedExpenses

            // Cache decrypted expenses in SwiftData for offline access
            await cacheExpenses(decryptedExpenses)

            print("Fetched and decrypted \(decryptedExpenses.count) expenses from server")
        } catch {
            // If fetch fails (offline), load from cache
            print("Failed to fetch expenses from server: \(error). Loading from cache...")

            // If we have cached data, don't throw the error
            if !expenses.isEmpty {
                print("Loaded \(expenses.count) expenses from cache")
            } else {
                throw error
            }
        }
    }

    /// Create expense via Edge Function (encrypts server-side)
    func addExpenseWithEncryption(_ expense: Expense) async throws {
        print("🔍 [DEBUG] DataManager.addExpenseWithEncryption called for: \(expense.name)")

        guard let masterKey = getCurrentMasterKey() else {
            throw EncryptionError.noEncryptionKeys
        }

        // Create expense with temporary ID for offline usage
        var expenseToAdd = expense
        if expenseToAdd.id == nil {
            expenseToAdd.id = UUID().uuidString
        }

        // Add to local state first (offline-first approach)
        expenses.append(expenseToAdd)

        // Cache locally for offline access
        await cacheExpenses([expenseToAdd])

        do {
            // Send to Edge Function for encryption and storage
            let createdId = try await supabaseService.edgeFunctionService.createExpense(expenseToAdd, encryptionKey: masterKey)

            // Update local expense with server ID
            var createdExpense = expenseToAdd
            createdExpense.id = createdId

            if let index = expenses.firstIndex(where: { $0.id == expenseToAdd.id }) {
                expenses[index] = createdExpense
            }

            // Update cache with server version
            await updateCachedExpense(createdExpense)

            print("✅ [DEBUG] Created encrypted expense via Edge Function: \(createdId)")
        } catch {
            print("⚠️ [DEBUG] Failed to sync expense via Edge Function (offline mode): \(error)")
            hasUnsyncedChanges = true
        }
    }

    /// Update expense via Edge Function (encrypts server-side)
    func updateExpenseWithEncryption(_ expense: Expense) async throws {
        guard let masterKey = getCurrentMasterKey() else {
            throw EncryptionError.noEncryptionKeys
        }

        print("🔍 [DEBUG] updateExpenseWithEncryption - Expense: \(expense.name)")

        // Send to Edge Function for encryption and update
        try await supabaseService.edgeFunctionService.updateExpense(expense, encryptionKey: masterKey)

        // Update local state
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = expense
            hasUnsyncedChanges = true
        }

        // Update cache
        await updateCachedExpense(expense)

        print("Updated encrypted expense via Edge Function: \(expense.name)")
    }
    
    // MARK: - Cache Loading
    
    func loadCachedExpenses() {
        guard let userId = currentProfile?.userId else {
            print("No user profile found for loading cached expenses")
            return
        }
        
        Task {
            do {
                try await fetchExpensesWithEncryption(userId: userId)
                print("✅ Expenses loaded: \(expenses.count) expenses")
            } catch {
                print("Failed to load cached expenses: \(error)")
            }
        }
    }
}