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
            // Note: SwiftData cache loading handled elsewhere
            
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
            
            try await addExpenseWithEncryption(expense)
        }
        
        // Then update the bill status and set next due date
        var updatedBill = bill
        updatedBill.status = .paid
        
        // For recurring bills, calculate next due date and store it in nextDueDate field
        // Keep the original dueDate as the current period due date
        let calculatedNextDueDate = calculateNextDueDate(for: bill)
        updatedBill.nextDueDate = calculatedNextDueDate
        
        print("🔍 [DEBUG] markBillAsPaid - Original due date: \(bill.dueDate)")
        print("🔍 [DEBUG] markBillAsPaid - Calculated next due date: \(calculatedNextDueDate)")
        print("🔍 [DEBUG] markBillAsPaid - Updated bill next due date: \(updatedBill.nextDueDate ?? Date())")
        
        try await updateBillWithEncryption(updatedBill)
        
        // If bill has reminders enabled, reschedule notifications for the next period
        if updatedBill.isReminderOn {
            let notificationService = NotificationService.shared
            await notificationService.scheduleBillReminders(for: updatedBill)
        }
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
                existingCached.isReminderOn = bill.isReminderOn
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
    /// Data is stored encrypted in the database; we decrypt locally using the master key
    func fetchBillsWithEncryption(userId: String) async throws {
        do {
            guard let masterKey = getCurrentMasterKey() else {
                throw EncryptionError.noEncryptionKeys
            }

            // Fetch encrypted bills from Supabase
            let encryptableBills = try await supabaseService.fetchEncryptableBills(userId: userId)

            // Decrypt locally for display
            let decryptedBills = encryptableBills.compactMap { encryptable in
                encryptable.toBill(using: masterKey)
            }

            bills = decryptedBills

            // Cache decrypted bills in SwiftData for offline access
            await cacheBills(decryptedBills)

            print("Fetched and decrypted \(decryptedBills.count) bills from server")
        } catch {
            // If fetch fails (offline), load from cache
            print("Failed to fetch bills from server: \(error). Loading from cache...")

            // If we have cached data, don't throw the error
            if !bills.isEmpty {
                print("Loaded \(bills.count) bills from cache")
            } else {
                throw error
            }
        }
    }

    /// Create bill via Edge Function (encrypts server-side)
    func addBillWithEncryption(_ bill: Bill) async throws {
        print("🔍 [DEBUG] DataManager.addBillWithEncryption called with bill: \(bill)")

        guard let masterKey = getCurrentMasterKey() else {
            throw EncryptionError.noEncryptionKeys
        }

        // Create bill with temporary ID for offline usage
        var billToAdd = bill
        if billToAdd.id == nil {
            billToAdd.id = UUID().uuidString
        }

        // Add to local state first (offline-first approach)
        bills.append(billToAdd)

        // Cache locally for offline access
        await cacheBills([billToAdd])

        do {
            // Send to Edge Function for encryption and storage
            let createdId = try await supabaseService.edgeFunctionService.createBill(billToAdd, encryptionKey: masterKey)

            // Update local bill with server ID
            var createdBill = billToAdd
            createdBill.id = createdId

            if let index = bills.firstIndex(where: { $0.id == billToAdd.id }) {
                bills[index] = createdBill
            }

            // Update cache with server version
            await updateCachedBill(createdBill)

            print("✅ [DEBUG] Created encrypted bill via Edge Function: \(createdId)")
        } catch {
            print("⚠️ [DEBUG] Failed to sync bill via Edge Function (offline mode): \(error)")
            hasUnsyncedChanges = true
        }
    }

    /// Update bill via Edge Function (encrypts server-side)
    func updateBillWithEncryption(_ bill: Bill) async throws {
        guard let masterKey = getCurrentMasterKey() else {
            throw EncryptionError.noEncryptionKeys
        }

        print("🔍 [DEBUG] updateBillWithEncryption - Bill: \(bill.name), nextDueDate = \(bill.nextDueDate ?? Date())")

        // Send to Edge Function for encryption and update
        try await supabaseService.edgeFunctionService.updateBill(bill, encryptionKey: masterKey)

        // Update local state
        if let index = bills.firstIndex(where: { $0.id == bill.id }) {
            bills[index] = bill
            hasUnsyncedChanges = true
        }

        // Update cache
        await updateCachedBill(bill)

        print("Updated encrypted bill via Edge Function: \(bill.name)")
    }
    
    /// Update only verification-related fields directly via Supabase (no Edge Function needed)
    func updateBillVerificationFields(_ bill: Bill) async throws {
        guard let billId = bill.id else { return }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        let dueDateString = dateFormatter.string(from: bill.dueDate)
        let nextDueDateString = bill.nextDueDate.map { dateFormatter.string(from: $0) }

        try await supabaseService.updateBillVerificationFields(
            billId: billId,
            status: bill.status,
            verificationDate: bill.verificationDate ?? "",
            dueDate: dueDateString,
            nextDueDate: nextDueDateString
        )

        // Update local state
        if let index = bills.firstIndex(where: { $0.id == billId }) {
            bills[index] = bill
        }
    }

    // MARK: - Cache Loading
    
    func loadCachedBills() {
        guard let userId = currentProfile?.userId else {
            print("No user profile found for loading cached bills")
            return
        }
        
        Task {
            do {
                try await fetchBillsWithEncryption(userId: userId)
                print("✅ Bills loaded: \(bills.count) bills")
            } catch {
                print("Failed to load cached bills: \(error)")
            }
        }
    }
}
