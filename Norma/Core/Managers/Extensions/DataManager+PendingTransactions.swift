//
//  DataManager+PendingTransactions.swift
//  Norma
//
//  DataManager methods for pending transactions from Share Extension
//

import Foundation
import SwiftData

extension DataManager {

    // MARK: - Fetch Methods

    /// Fetch pending transactions for the current user
    func fetchPendingTransactions() async throws {
        guard let userId = currentProfile?.userId else {
            print("No user profile found for fetching pending transactions")
            return
        }

        try await fetchPendingTransactions(userId: userId)
    }

    /// Fetch pending transactions for a specific user
    func fetchPendingTransactions(userId: String) async throws {
        do {
            let fetchedTransactions = try await supabaseService.fetchPendingTransactions(userId: userId)
            pendingTransactions = fetchedTransactions

            // Cache pending transactions
            await cachePendingTransactions(fetchedTransactions)

            print("Fetched \(fetchedTransactions.count) pending transactions from server")
        } catch {
            print("Failed to fetch pending transactions from server: \(error)")

            // If we have cached data, don't throw the error
            if !pendingTransactions.isEmpty {
                print("Using \(pendingTransactions.count) cached pending transactions")
            } else {
                throw error
            }
        }
    }

    // MARK: - Query Methods

    /// Get all pending transactions
    func getPendingTransactionsList() -> [PendingTransaction] {
        return pendingTransactions
    }

    /// Get count of pending transactions
    func getPendingTransactionsCount() -> Int {
        return pendingTransactions.count
    }

    // MARK: - Confirmation Methods

    /// Confirm a pending transaction and convert it to an expense (uses today's date)
    func confirmPendingTransaction(_ transaction: PendingTransaction) async throws {
        try await confirmPendingTransaction(transaction, withDate: Date())
    }

    /// Confirm a pending transaction with a specific date
    func confirmPendingTransaction(_ transaction: PendingTransaction, withDate date: Date) async throws {
        guard let userId = currentProfile?.userId,
              let transactionId = transaction.id,
              let amount = transaction.amount else {
            throw NSError(domain: "DataManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid transaction data"])
        }

        // Use merchant as the expense name, or "Unknown" if not available
        let name = transaction.merchant ?? "Unknown"

        // Convert date to ISO8601 string
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: date)

        // Create expense from pending transaction with specified date
        let expense = Expense(
            userId: userId,
            name: name,
            amount: amount,
            expenseDate: dateString,
            paymentMethod: .other,
            merchant: transaction.merchant
        )

        // Add expense with encryption support
        try await addExpenseWithEncryption(expense)

        // Delete from pending_transactions table
        try await supabaseService.deletePendingTransaction(transactionId)

        // Remove from local list
        pendingTransactions.removeAll { $0.id == transaction.id }

        // Remove from cache
        await deleteCachedPendingTransaction(transactionId)

        print("Confirmed pending transaction: \(name) with date: \(dateString)")
    }

    /// Confirm multiple pending transactions with a single date
    func confirmPendingTransactions(_ transactions: [PendingTransaction], withDate date: Date) async throws {
        for transaction in transactions {
            try await confirmPendingTransaction(transaction, withDate: date)
        }
    }

    /// Reject a pending transaction
    func rejectPendingTransaction(_ transaction: PendingTransaction) async throws {
        guard let transactionId = transaction.id else {
            throw NSError(domain: "DataManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Transaction ID is required"])
        }

        // Delete from pending_transactions table
        try await supabaseService.deletePendingTransaction(transactionId)

        // Remove from local list
        pendingTransactions.removeAll { $0.id == transaction.id }

        // Remove from cache
        await deleteCachedPendingTransaction(transactionId)

        print("Rejected pending transaction: \(transaction.merchant ?? "Unknown")")
    }

    // MARK: - SwiftData Caching

    private func cachePendingTransactions(_ transactionsToCache: [PendingTransaction]) async {
        guard let modelContext = modelContext else {
            print("No modelContext found for caching pending transactions")
            return
        }

        do {
            // Clear existing cached pending transactions for this user
            if let userId = currentProfile?.userId {
                let descriptor = FetchDescriptor<CachedPendingTransaction>(
                    predicate: #Predicate { cached in
                        cached.userId == userId
                    }
                )

                let existingCached = try modelContext.fetch(descriptor)
                for cached in existingCached {
                    modelContext.delete(cached)
                }
            }

            // Insert new cached pending transactions
            for transaction in transactionsToCache {
                let cachedTransaction = CachedPendingTransaction(from: transaction)
                modelContext.insert(cachedTransaction)
            }

            try modelContext.save()
            print("Cached \(transactionsToCache.count) pending transactions")
        } catch {
            print("Failed to cache pending transactions: \(error)")
        }
    }

    private func deleteCachedPendingTransaction(_ transactionId: String) async {
        guard let modelContext = modelContext else { return }

        do {
            let descriptor = FetchDescriptor<CachedPendingTransaction>(
                predicate: #Predicate { cached in
                    cached.id == transactionId
                }
            )

            if let cachedTransaction = try modelContext.fetch(descriptor).first {
                modelContext.delete(cachedTransaction)
                try modelContext.save()
                print("Deleted cached pending transaction with id: \(transactionId)")
            }
        } catch {
            print("Failed to delete cached pending transaction: \(error)")
        }
    }

    // MARK: - Cache Loading

    func loadCachedPendingTransactions() {
        guard let userId = currentProfile?.userId else {
            print("No user profile found for loading cached pending transactions")
            return
        }

        Task {
            do {
                try await fetchPendingTransactions(userId: userId)
                print("Loaded \(pendingTransactions.count) pending transactions")
            } catch {
                print("Failed to load pending transactions: \(error)")
            }
        }
    }
}
