//
//  PendingTransaction.swift
//  Norma
//
//  Represents a transaction submitted via Share Extension awaiting confirmation
//

import Foundation

struct PendingTransaction: Identifiable, Codable, Equatable {
    var id: String?
    var userId: String
    var amount: Double?
    var currency: String?
    var merchant: String?
    var transactionDate: String?
    var rawText: String?
    var createdAt: String?

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

    init(
        id: String? = nil,
        userId: String,
        amount: Double? = nil,
        currency: String? = nil,
        merchant: String? = nil,
        transactionDate: String? = nil,
        rawText: String? = nil,
        createdAt: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.amount = amount
        self.currency = currency
        self.merchant = merchant
        self.transactionDate = transactionDate
        self.rawText = rawText
        self.createdAt = createdAt
    }
}
