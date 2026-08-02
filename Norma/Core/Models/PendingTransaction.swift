//
//  PendingTransaction.swift
//  Norma
//
//  A transaction extracted from a receipt shared through the share
//  extension, waiting for the user to review it on the home screen.
//  Rows live in Supabase (`pending_transactions`) until the user either
//  adds them to the runway or discards them — both remove the row.
//

import Foundation

struct PendingTransaction: Codable, Identifiable, Equatable {
    let id: String
    let userId: String
    let amount: Double?
    let currency: String?
    let merchant: String?
    let transactionDate: Date?
    let rawText: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case amount
        case currency
        case merchant
        case transactionDate = "transaction_date"
        case rawText = "raw_text"
        case createdAt = "created_at"
    }
}
