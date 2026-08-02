//
//  SupabaseService+PendingTransactions.swift
//  Norma
//
//  Fetch/delete for receipt-scanned transactions awaiting review.
//

import Foundation
import Supabase

extension SupabaseService {

    /// All pending (unreviewed) transactions for a user, newest first.
    func fetchPendingTransactions(userId: String) async throws -> [PendingTransaction] {
        let response: [PendingTransaction] = try await from("pending_transactions")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value

        return response
    }

    /// Remove reviewed transactions — both "added to runway" and "discarded"
    /// end here; the pending table only holds what still needs a decision.
    func deletePendingTransactions(ids: [String]) async throws {
        guard !ids.isEmpty else { return }
        try await from("pending_transactions")
            .delete()
            .in("id", values: ids)
            .execute()
    }
}
