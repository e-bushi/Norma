//
//  DataManager+Bills.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation
import SwiftData
import CryptoKit

extension DataManager {
    
    // MARK: - Bill Methods (Legacy - Non-encrypted)
    
    func fetchBills(userId: String) async throws {
        do {
            // Try to fetch from Supabase first
            let fetchedBills = try await supabaseService.fetchBills(userId: userId)
            bills = fetchedBills
            
            // Cache bills in SwiftData
            await cacheBills(fetchedBills)
            
            print("Fetched \(fetchedBills.count) bills from server")
        } catch {
            // If fetch fails (offline), load from cache
            print("Failed to fetch bills from server: \(error). Loading from cache...")
            loadCachedBills()
            
            // If we have cached data, don't throw the error
            if !bills.isEmpty {
                print("Loaded \(bills.count) bills from cache")
            } else {
                // Re-throw if we have no cached data
                throw error
            }
        }
    }
    
    func addBill(_ bill: Bill) async throws {
        print("🔍 [DEBUG] DataManager.addBill called with bill: \(bill)")
        
        // Create bill with temporary ID for offline usage
        var billToAdd = bill
        if billToAdd.id == nil {
            billToAdd.id = UUID().uuidString
        }
        
        // Always add to local state first (offline-first approach)
        print("🔄 [DEBUG] DataManager.addBill: Adding bill to local bills array...")
        bills.append(billToAdd)
        print("✅ [DEBUG] DataManager.addBill: Bills array now has \(bills.count) items")
        
        // Cache the bill locally
        print("🔄 [DEBUG] DataManager.addBill: Caching bill locally...")
        await cacheBills([billToAdd])
        print("✅ [DEBUG] DataManager.addBill: Local caching completed")
        
        // Try to sync to Supabase (but don't fail if offline)
        do {
            print("🔄 [DEBUG] DataManager.addBill: Attempting to sync to Supabase...")
            let createdBill = try await supabaseService.createBill(billToAdd)
            print("✅ [DEBUG] DataManager.addBill: Supabase sync successful")
            
            // Update the local bill with the server ID if different
            if let index = bills.firstIndex(where: { $0.id == billToAdd.id }) {
                bills[index] = createdBill
            }
            
            // Update cache with server version
            await updateCachedBill(createdBill)
            
        } catch {
            print("⚠️ [DEBUG] DataManager.addBill: Supabase sync failed (offline mode): \(error)")
            // Mark as needing sync later
            hasUnsyncedChanges = true
        }
        
        print("✅ [DEBUG] DataManager.addBill: Method completed - Added bill: \(bill.name)")
    }
    
    func updateBill(_ bill: Bill) async throws {
        let updatedBill = try await supabaseService.updateBill(bill)
        
        if let index = bills.firstIndex(where: { $0.id == bill.id }) {
            bills[index] = updatedBill
            hasUnsyncedChanges = true
        }
        
        // Update cache
        await updateCachedBill(updatedBill)
        
        print("Updated bill: \(bill.name)")
    }
    
    func deleteBill(_ bill: Bill) async throws {
        guard let billId = bill.id else {
            throw NSError(domain: "DataManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bill ID is required for deletion"])
        }
        
        try await supabaseService.deleteBill(billId)
        bills.removeAll { $0.id == bill.id }
        hasUnsyncedChanges = true
        
        // Remove from cache
        await deleteCachedBill(billId)
        
        print("Deleted bill: \(bill.name)")
    }
    
    // MARK: - Bill Queries
    
    func getActiveBills() -> [Bill] {
        // Show all bills (scheduled, overdue, and paid)
        return bills.sorted { $0.dueDate < $1.dueDate }
    }
    
    func getUpcomingBills(days: Int = 7) -> [Bill] {
        let endDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        
        return getActiveBills().filter { bill in
            bill.dueDate >= Date() && bill.dueDate <= endDate
        }
    }
    
    func getOverdueBills() -> [Bill] {
        return bills.filter { $0.status == .overdue }
            .sorted { $0.dueDate < $1.dueDate }
    }
    
    func getBillsByStatus(_ status: BillStatus) -> [Bill] {
        return bills.filter { $0.status == status }
            .sorted { $0.dueDate < $1.dueDate }
    }
    
    func getTotalMonthlyBills() -> Double {
        return getActiveBills().reduce(0) { total, bill in
            switch bill.frequency {
            case .monthly:
                return total + bill.amount
            case .quarterly:
                return total + (bill.amount * 4 / 12)
            case .yearly:
                return total + (bill.amount / 12)
            }
        }
    }
    
    func getBillsDueSoon(within days: Int = 3) -> [Bill] {
        let endDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        
        return getActiveBills().filter { bill in
            bill.dueDate >= Date() && bill.dueDate <= endDate
        }
    }
    
    func getNextBillDue() -> Bill? {
        return getActiveBills()
            .filter { $0.dueDate >= Date() }
            .min { $0.dueDate < $1.dueDate }
    }
    
    func markBillAsPaid(_ bill: Bill, paymentMethod: PaymentMethod = .debitCard, notes: String? = nil) async throws {
        // First, create an expense record for this payment
        if let billId = bill.id {
            // Convert bill frequency to expense frequency
            let expenseFrequency: ExpenseFrequency = {
                switch bill.frequency {
                case .monthly: return .monthly
                case .quarterly: return .quarterly  
                case .yearly: return .annually
                }
            }()
            
            // Format today's date as ISO8601 string for expense_date in local timezone
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.timeZone = TimeZone.current
            let todayString = dateFormatter.string(from: Date())
            
            let expense = Expense(
                id: nil,
                userId: bill.userId,
                name: bill.name,
                amount: bill.amount,
                expenseDate: todayString,
                billId: billId,
                paymentMethod: paymentMethod,
                isRecurring: true,
                recurringFrequency: expenseFrequency,
                merchant: bill.merchant ?? bill.name,
                location: nil,
                tags: ["Bill Payment"],
                createdAt: nil,
                updatedAt: nil,
                notes: notes ?? "Bill payment for \(bill.name)",
                attachmentUrls: []
            )
            
            try await addExpense(expense)
        }
        
        // Then update the bill status and due date
        var updatedBill = bill
        updatedBill.status = .paid
        
        // For recurring bills, calculate next due date but keep status as paid
        updatedBill.dueDate = calculateNextDueDate(for: bill)
        
        try await updateBill(updatedBill)
    }
    
    private func calculateNextDueDate(for bill: Bill) -> Date {
        let calendar = Calendar.current
        
        switch bill.frequency {
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: bill.dueDate) ?? bill.dueDate
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: bill.dueDate) ?? bill.dueDate
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: bill.dueDate) ?? bill.dueDate
        }
    }
    
    // MARK: - SwiftData Caching
    
    func loadCachedBills() {
        guard let modelContext = modelContext,
              let userId = currentProfile?.userId else { return }
        
        do {
            let descriptor = FetchDescriptor<CachedBill>(
                predicate: #Predicate { cachedBill in
                    cachedBill.userId == userId
                }
            )
            
            let cachedBills = try modelContext.fetch(descriptor)
            
            // Convert cached bills to regular bills and update the published property
            self.bills = cachedBills.map { $0.toBill() }
            
            print("Loaded \(cachedBills.count) cached bills")
        } catch {
            print("Failed to load cached bills: \(error)")
        }
    }
    
    private func cacheBills(_ billsToCache: [Bill]) async {
        print("🔍 [DEBUG] DataManager.cacheBills called with \(billsToCache.count) bills")
        
        guard let modelContext = modelContext else { 
            print("❌ [DEBUG] DataManager.cacheBills: No modelContext found")
            return 
        }
        
        print("✅ [DEBUG] DataManager.cacheBills: ModelContext is available")
        
        do {
            // First, clear existing cached bills for this user
            if let userId = currentProfile?.userId {
                print("🔄 [DEBUG] DataManager.cacheBills: Clearing existing cached bills for user: \(userId)")
                let descriptor = FetchDescriptor<CachedBill>(
                    predicate: #Predicate { cachedBill in
                        cachedBill.userId == userId
                    }
                )
                
                let existingCached = try modelContext.fetch(descriptor)
                print("🔄 [DEBUG] DataManager.cacheBills: Found \(existingCached.count) existing cached bills to remove")
                for cached in existingCached {
                    modelContext.delete(cached)
                }
            }
            
            // Then insert new cached bills
            print("🔄 [DEBUG] DataManager.cacheBills: Inserting \(billsToCache.count) new cached bills")
            for bill in billsToCache {
                let cachedBill = CachedBill(from: bill)
                modelContext.insert(cachedBill)
                print("🔄 [DEBUG] DataManager.cacheBills: Inserted cached bill: \(cachedBill.name)")
            }
            
            print("🔄 [DEBUG] DataManager.cacheBills: About to save modelContext...")
            try modelContext.save()
            print("✅ [DEBUG] DataManager.cacheBills: Successfully cached \(billsToCache.count) bills")
        } catch {
            print("❌ [DEBUG] DataManager.cacheBills: Failed to cache bills: \(error)")
        }
    }
    
    private func updateCachedBill(_ bill: Bill) async {
        guard let modelContext = modelContext,
              let billId = bill.id else { return }
        
        do {
            let descriptor = FetchDescriptor<CachedBill>(
                predicate: #Predicate { cachedBill in
                    cachedBill.id == billId
                }
            )
            
            if let existingCached = try modelContext.fetch(descriptor).first {
                // Update existing cached bill
                existingCached.name = bill.name
                existingCached.amount = bill.amount
                existingCached.dueDate = bill.dueDate
                existingCached.status = bill.status.rawValue
                existingCached.frequency = bill.frequency.rawValue
                existingCached.categoryId = bill.categoryId
                existingCached.merchant = bill.merchant
                existingCached.isAutoPayEnabled = bill.isAutoPayEnabled
                existingCached.reminderDays = bill.reminderDays
                existingCached.notes = bill.notes
                existingCached.updatedAt = Date()
                existingCached.lastSyncedAt = Date()
            } else {
                // Create new cached bill if not found
                let cachedBill = CachedBill(from: bill)
                modelContext.insert(cachedBill)
            }
            
            try modelContext.save()
            print("Updated cached bill: \(bill.name)")
        } catch {
            print("Failed to update cached bill: \(error)")
        }
    }
    
    private func deleteCachedBill(_ billId: String) async {
        guard let modelContext = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<CachedBill>(
                predicate: #Predicate { cachedBill in
                    cachedBill.id == billId
                }
            )
            
            if let cachedBill = try modelContext.fetch(descriptor).first {
                modelContext.delete(cachedBill)
                try modelContext.save()
                print("Deleted cached bill with id: \(billId)")
            }
        } catch {
            print("Failed to delete cached bill: \(error)")
        }
    }
    
    // MARK: - Bill Methods (Encryption Support)
    
    /// Fetch bills with decryption support
    func fetchBillsWithEncryption(userId: String) async throws {
        do {
            let hasEncryption = await hasEncryptionEnabled()
            
            if hasEncryption {
                let masterKey = getCurrentMasterKey()
                let encryptableBills = try await supabaseService.fetchEncryptableBills(userId: userId)
                
                // Convert to regular bills, decrypting if necessary
                let decryptedBills = encryptableBills.compactMap { encryptable in
                    encryptable.toBill(using: masterKey)
                }
                
                bills = decryptedBills
                
                // Cache bills in SwiftData
                await cacheBills(decryptedBills)
                
                print("Fetched and decrypted \(decryptedBills.count) bills from server")
            } else {
                // Use legacy path
                try await fetchBills(userId: userId)
            }
        } catch {
            // If fetch fails (offline), load from cache
            print("Failed to fetch bills from server: \(error). Loading from cache...")
            loadCachedBills()
            
            // If we have cached data, don't throw the error
            if !bills.isEmpty {
                print("Loaded \(bills.count) bills from cache")
            } else {
                // Re-throw if we have no cached data
                throw error
            }
        }
    }
    
    /// Create bill with encryption support if enabled
    func addBillWithEncryption(_ bill: Bill) async throws {
        print("🔍 [DEBUG] DataManager.addBillWithEncryption called with bill: \(bill)")
        
        let hasEncryption = await hasEncryptionEnabled()
        
        if hasEncryption, let masterKey = getCurrentMasterKey() {
            // Create bill with temporary ID for offline usage
            var billToAdd = bill
            if billToAdd.id == nil {
                billToAdd.id = UUID().uuidString
            }
            
            // Add to local state first
            bills.append(billToAdd)
            
            // Cache locally
            await cacheBills([billToAdd])
            
            do {
                // Create encrypted version
                guard let encryptableBill = billToAdd.toEncryptable(encrypt: true, using: masterKey) else {
                    throw EncryptionError.encryptionFailed
                }
                
                let createdEncryptable = try await supabaseService.createEncryptableBill(encryptableBill)
                
                // Convert back to regular bill for display
                guard let displayBill = createdEncryptable.toBill(using: masterKey) else {
                    throw EncryptionError.decryptionFailed
                }
                
                // Update the local bill with the server version
                if let index = bills.firstIndex(where: { $0.id == billToAdd.id }) {
                    bills[index] = displayBill
                }
                
                // Update cache with server version
                await updateCachedBill(displayBill)
                
                print("✅ [DEBUG] Created encrypted bill successfully")
            } catch {
                print("⚠️ [DEBUG] Failed to sync encrypted bill (offline mode): \(error)")
                hasUnsyncedChanges = true
            }
        } else {
            // Use legacy non-encrypted path
            try await addBill(bill)
        }
    }
    
    /// Update bill with encryption support
    func updateBillWithEncryption(_ bill: Bill) async throws {
        let hasEncryption = await hasEncryptionEnabled()
        
        if hasEncryption, let masterKey = getCurrentMasterKey() {
            // Create encrypted version
            guard let encryptableBill = bill.toEncryptable(encrypt: true, using: masterKey) else {
                throw EncryptionError.encryptionFailed
            }
            
            let updatedEncryptable = try await supabaseService.updateEncryptableBill(encryptableBill)
            
            // Convert back to regular bill for display
            guard let displayBill = updatedEncryptable.toBill(using: masterKey) else {
                throw EncryptionError.decryptionFailed
            }
            
            if let index = bills.firstIndex(where: { $0.id == bill.id }) {
                bills[index] = displayBill
                hasUnsyncedChanges = true
            }
            
            // Update cache
            await updateCachedBill(displayBill)
            
            print("Updated encrypted bill: \(bill.name)")
        } else {
            // Use legacy path
            try await updateBill(bill)
        }
    }
    
    /// Migrate existing bills to encrypted format
    func migrateBillsToEncryption() async throws {
        guard let userId = currentProfile?.userId,
              let masterKey = getCurrentMasterKey() else {
            throw EncryptionError.noEncryptionKeys
        }
        
        // Fetch all unencrypted bills
        let allBills = bills
        var migratedCount = 0
        
        for bill in allBills {
            // Skip if already encrypted (would need to track this)
            if let encryptableBill = bill.toEncryptable(encrypt: true, using: masterKey) {
                do {
                    try await supabaseService.updateBillEncryption(
                        billId: bill.id ?? "",
                        encryptedName: encryptableBill.encryptedName ?? "",
                        encryptedAmount: encryptableBill.encryptedAmount ?? ""
                    )
                    migratedCount += 1
                } catch {
                    print("Failed to migrate bill \(bill.id ?? ""): \(error)")
                }
            }
        }
        
        print("Migrated \(migratedCount) bills to encrypted format")
        
        // Refresh to get encrypted versions
        try await fetchBillsWithEncryption(userId: userId)
    }
}
