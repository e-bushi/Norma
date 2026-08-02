//
//  SupabaseService+FreedomFund.swift
//  Norma
//
//  Server mirror of the freedom-fund ledger. SwiftData remains the read
//  path (local-first, offline-capable); these calls keep the server copy in
//  step so the ledger survives logout and follows the account.
//

import Foundation
import Supabase

/// Wire format for a ledger row. Field-for-field with FreedomFundEntry —
/// the local model stays a SwiftData @Model, so the DTO lives here.
struct FreedomFundEntryRecord: Codable {
    let id: String
    let userId: String
    let createdAt: Date
    let delta: Double
    let balanceAfter: Double
    let source: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case createdAt = "created_at"
        case delta
        case balanceAfter = "balance_after"
        case source
    }

    init(entry: FreedomFundEntry) {
        self.id = entry.id.lowercased()
        self.userId = entry.userId
        self.createdAt = entry.createdAt
        self.delta = entry.delta
        self.balanceAfter = entry.balanceAfter
        self.source = entry.sourceRaw
    }

    init(id: String, userId: String, createdAt: Date, delta: Double, balanceAfter: Double, source: String) {
        self.id = id
        self.userId = userId
        self.createdAt = createdAt
        self.delta = delta
        self.balanceAfter = balanceAfter
        self.source = source
    }
}

extension SupabaseService {

    /// The user's full server-side ledger, oldest first.
    func fetchFreedomFundEntries(userId: String) async throws -> [FreedomFundEntryRecord] {
        let response: [FreedomFundEntryRecord] = try await from("freedom_fund_entries")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: true)
            .execute()
            .value
        return response
    }

    /// Insert-or-update by id. Used both for single-entry pushes on write and
    /// for the bulk upload that migrates a pre-sync local ledger.
    func upsertFreedomFundEntries(_ records: [FreedomFundEntryRecord]) async throws {
        guard !records.isEmpty else { return }
        try await from("freedom_fund_entries")
            .upsert(records, onConflict: "id")
            .execute()
    }

    /// Mirrors a local ledger deletion (long-press → delete anchor).
    func deleteFreedomFundEntries(ids: [String]) async throws {
        guard !ids.isEmpty else { return }
        try await from("freedom_fund_entries")
            .delete()
            .in("id", values: ids.map { $0.lowercased() })
            .execute()
    }
}
