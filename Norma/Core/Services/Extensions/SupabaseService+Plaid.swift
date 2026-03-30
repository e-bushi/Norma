//
//  SupabaseService+Plaid.swift
//  Norma
//
//  Created by Claude on 3/20/26.
//

import Foundation
import Supabase

struct PlaidItem: Codable {
    let id: String
    let userId: String
    let itemId: String
    let createdAt: String
    let lastSyncedAt: String?
    let institutionName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case itemId = "item_id"
        case createdAt = "created_at"
        case lastSyncedAt = "last_synced_at"
        case institutionName = "institution_name"
    }
}

extension SupabaseService {

    // MARK: - Plaid Items

    func fetchPlaidItems(userId: String) async throws -> [PlaidItem] {
        let response: [PlaidItem] = try await from("plaid_items")
            .select("id, user_id, item_id, created_at, last_synced_at, institution_name")
            .eq("user_id", value: userId)
            .execute()
            .value

        return response
    }

    func updateLastSyncedAt(plaidItemId: String) async throws {
        let now = ISO8601DateFormatter().string(from: Date())
        _ = try await from("plaid_items")
            .update(["last_synced_at": AnyJSON.string(now)])
            .eq("id", value: plaidItemId)
            .execute()
    }
}
