//
//  CapturedTransaction.swift
//  Norma
//
//  Local-first record of a receipt-scanned transaction the user confirmed
//  from the pending queue. The server's pending_transactions table is only a
//  transient hand-off from the share extension — once confirmed, the row is
//  deleted there and lives here in SwiftData, like the freedom fund ledger.
//

import Foundation
import SwiftData

@Model
final class CapturedTransaction {
    @Attribute(.unique) var id: String
    var userId: String
    /// Amount in the receipt's original currency.
    var amount: Double
    /// ISO currency code of the original amount (e.g. "THB").
    var currency: String
    var merchant: String?
    /// When the transaction happened, per the receipt. Falls back to the
    /// scan date when the receipt had no readable date.
    var transactionDate: Date
    /// Raw extracted text, kept for later re-interpretation.
    var rawText: String?
    /// When the user confirmed it into the runway.
    var confirmedAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String,
        amount: Double,
        currency: String,
        merchant: String? = nil,
        transactionDate: Date,
        rawText: String? = nil,
        confirmedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.amount = amount
        self.currency = currency
        self.merchant = merchant
        self.transactionDate = transactionDate
        self.rawText = rawText
        self.confirmedAt = confirmedAt
    }
}
