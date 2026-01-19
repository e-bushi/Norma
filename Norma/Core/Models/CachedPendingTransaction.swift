//
//  CachedPendingTransaction.swift
//  Norma
//
//  SwiftData model for local caching of pending transactions
//

import Foundation
import SwiftData

@Model
final class CachedPendingTransaction {
    @Attribute(.unique) var id: String
    var userId: String
    var createdAt: Date

    // Transaction data
    var amount: Double?
    var currency: String?
    var merchant: String?
    var transactionDate: String?
    var rawText: String?

    // Sync metadata
    var lastSyncedAt: Date
    var isFromCache: Bool = true

    init(
        id: String,
        userId: String,
        createdAt: Date = Date(),
        amount: Double? = nil,
        currency: String? = nil,
        merchant: String? = nil,
        transactionDate: String? = nil,
        rawText: String? = nil,
        lastSyncedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.createdAt = createdAt
        self.amount = amount
        self.currency = currency
        self.merchant = merchant
        self.transactionDate = transactionDate
        self.rawText = rawText
        self.lastSyncedAt = lastSyncedAt
    }

    // Convert from Supabase PendingTransaction model
    convenience init(from pendingTransaction: PendingTransaction) {
        let createdDate = ISO8601DateFormatter().date(from: pendingTransaction.createdAt ?? "") ?? Date()

        self.init(
            id: pendingTransaction.id ?? UUID().uuidString,
            userId: pendingTransaction.userId,
            createdAt: createdDate,
            amount: pendingTransaction.amount,
            currency: pendingTransaction.currency,
            merchant: pendingTransaction.merchant,
            transactionDate: pendingTransaction.transactionDate,
            rawText: pendingTransaction.rawText,
            lastSyncedAt: Date()
        )
    }

    // Convert to Supabase PendingTransaction model
    func toPendingTransaction() -> PendingTransaction {
        let formatter = ISO8601DateFormatter()

        return PendingTransaction(
            id: id,
            userId: userId,
            amount: amount,
            currency: currency,
            merchant: merchant,
            transactionDate: transactionDate,
            rawText: rawText,
            createdAt: formatter.string(from: createdAt)
        )
    }
}
