//
//  SupabaseService+PendingTransactions.swift
//  Norma
//
//  Supabase methods for pending transactions from Share Extension
//

import Foundation
import Supabase

extension SupabaseService {

    // MARK: - Pending Transactions

    /// Fetch pending transactions for a user
    func fetchPendingTransactions(userId: String) async throws -> [PendingTransaction] {
        let response: [PendingTransaction] = try await from("pending_transactions")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value

        return response
    }

    /// Delete a pending transaction
    func deletePendingTransaction(_ transactionId: String) async throws {
        try await from("pending_transactions")
            .delete()
            .eq("id", value: transactionId)
            .execute()
    }

    /// Get count of pending transactions for a user
    func getPendingTransactionsCount(userId: String) async throws -> Int {
        let response: [PendingTransaction] = try await from("pending_transactions")
            .select("id")
            .eq("user_id", value: userId)
            .execute()
            .value

        return response.count
    }

    // MARK: - Device Token for Push Notifications

    /// Update device token for push notifications
    func updateDeviceToken(userId: String, token: String) async throws {
        _ = try await from("profiles")
            .update(["device_token": AnyJSON.string(token)])
            .eq("user_id", value: userId)
            .execute()
    }
}
