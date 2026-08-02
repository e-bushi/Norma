//
//  SupabaseService+UserContent.swift
//  Norma
//
//  Server mirrors for user-authored SwiftData content: note tokens
//  (reminders, intentions, commitments, bill chips) and confirmed receipt
//  transactions. Wire DTOs + CRUD, consumed by UserContentSync.
//

import Foundation
import Supabase

/// Wire format for a NoteToken. The local model carries no userId (tokens
/// predate multi-user concerns), so the record is stamped with the active
/// user's id at push time.
struct NoteTokenRecord: Codable {
    let id: String
    let userId: String
    let kind: String
    let amount: Double
    let currency: String
    let usdEquivalent: Double?
    let category: String?
    let subject: String?
    let counterparty: String?
    let recurrence: String?
    let occurredAt: Date
    let sourceStart: Int
    let sourceEnd: Int
    let isProvisional: Bool
    let remindAt: Date?
    let confirmedAt: Date?
    let billId: String?
    let userAdjustedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case kind
        case amount
        case currency
        case usdEquivalent = "usd_equivalent"
        case category
        case subject
        case counterparty
        case recurrence
        case occurredAt = "occurred_at"
        case sourceStart = "source_start"
        case sourceEnd = "source_end"
        case isProvisional = "is_provisional"
        case remindAt = "remind_at"
        case confirmedAt = "confirmed_at"
        case billId = "bill_id"
        case userAdjustedAt = "user_adjusted_at"
    }

    init(token: NoteToken, userId: String) {
        self.id = token.id.uuidString.lowercased()
        self.userId = userId
        self.kind = token.kindRaw
        self.amount = token.amount
        self.currency = token.currency
        self.usdEquivalent = token.usdEquivalent
        self.category = token.categoryRaw
        self.subject = token.subject
        self.counterparty = token.counterparty
        self.recurrence = token.recurrenceRaw
        self.occurredAt = token.occurredAt
        self.sourceStart = token.sourceStart
        self.sourceEnd = token.sourceEnd
        self.isProvisional = token.isProvisional
        self.remindAt = token.remindAt
        self.confirmedAt = token.confirmedAt
        self.billId = token.billId
        self.userAdjustedAt = token.userAdjustedAt
    }

    /// Rebuilds the local model on restore. Unknown enum raws degrade the
    /// same way the local model does (kind falls back to .bill via kindRaw).
    func makeToken() -> NoteToken {
        let token = NoteToken(
            id: UUID(uuidString: id) ?? UUID(),
            kind: NoteToken.Kind(rawValue: kind) ?? .bill,
            amount: amount,
            currency: currency,
            usdEquivalent: usdEquivalent,
            category: category.flatMap(NoteToken.Category.init(rawValue:)),
            subject: subject,
            counterparty: counterparty,
            recurrence: recurrence.flatMap(NoteToken.Recurrence.init(rawValue:)),
            occurredAt: occurredAt,
            sourceStart: sourceStart,
            sourceEnd: sourceEnd,
            isProvisional: isProvisional,
            remindAt: remindAt,
            confirmedAt: confirmedAt,
            billId: billId,
            userAdjustedAt: userAdjustedAt
        )
        // Preserve the exact raw for kinds the enum no longer models.
        token.kindRaw = kind
        return token
    }
}

/// Wire format for a confirmed receipt transaction.
struct CapturedTransactionRecord: Codable {
    let id: String
    let userId: String
    let amount: Double
    let currency: String
    let merchant: String?
    let transactionDate: Date
    let rawText: String?
    let confirmedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case amount
        case currency
        case merchant
        case transactionDate = "transaction_date"
        case rawText = "raw_text"
        case confirmedAt = "confirmed_at"
    }

    init(transaction: CapturedTransaction) {
        self.id = transaction.id.lowercased()
        self.userId = transaction.userId
        self.amount = transaction.amount
        self.currency = transaction.currency
        self.merchant = transaction.merchant
        self.transactionDate = transaction.transactionDate
        self.rawText = transaction.rawText
        self.confirmedAt = transaction.confirmedAt
    }

    func makeTransaction() -> CapturedTransaction {
        CapturedTransaction(
            id: id,
            userId: userId,
            amount: amount,
            currency: currency,
            merchant: merchant,
            transactionDate: transactionDate,
            rawText: rawText,
            confirmedAt: confirmedAt
        )
    }
}

extension SupabaseService {

    // MARK: Note tokens

    func fetchNoteTokens(userId: String) async throws -> [NoteTokenRecord] {
        try await from("note_tokens")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
    }

    func upsertNoteTokens(_ records: [NoteTokenRecord]) async throws {
        guard !records.isEmpty else { return }
        try await from("note_tokens")
            .upsert(records, onConflict: "id")
            .execute()
    }

    func deleteNoteTokens(ids: [String]) async throws {
        guard !ids.isEmpty else { return }
        try await from("note_tokens")
            .delete()
            .in("id", values: ids.map { $0.lowercased() })
            .execute()
    }

    // MARK: Captured transactions

    func fetchCapturedTransactions(userId: String) async throws -> [CapturedTransactionRecord] {
        try await from("captured_transactions")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
    }

    func upsertCapturedTransactions(_ records: [CapturedTransactionRecord]) async throws {
        guard !records.isEmpty else { return }
        try await from("captured_transactions")
            .upsert(records, onConflict: "id")
            .execute()
    }

    func deleteCapturedTransactions(ids: [String]) async throws {
        guard !ids.isEmpty else { return }
        try await from("captured_transactions")
            .delete()
            .in("id", values: ids.map { $0.lowercased() })
            .execute()
    }
}
