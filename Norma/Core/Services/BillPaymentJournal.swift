//
//  BillPaymentJournal.swift
//  Norma
//
//  When the user marks bills paid in BillsView, we drop a `.billPayment` token
//  into today's note for each bill — the journal becomes the audit trail.
//  These tokens are excluded from the spending pace cumulative because the
//  bill amount is already pre-deducted from breathing room.
//

import Foundation
import SwiftData

@MainActor
enum BillPaymentJournal {
    /// Append a `.billPayment` token to today's note for each bill in `bills`.
    /// No-ops when the user hasn't created a note today — notes are only
    /// created through explicit user action, so the journal write is
    /// best-effort.
    static func appendBillPayments(
        _ bills: [Bill],
        currency: String,
        in context: ModelContext
    ) {
        guard !bills.isEmpty else { return }

        let repository = NoteRepository(context: context)
        guard let todayNote = repository.today() else { return }
        let now = Date()

        // Append tokens at the end of the note's text. sourceStart == sourceEnd
        // pins the chip after any existing prose without modifying it.
        let endIndex = (todayNote.rawText as NSString).length

        for bill in bills {
            let token = NoteToken(
                kind: .billPayment,
                amount: bill.amount,
                currency: currency,
                subject: bill.name.lowercased(),
                occurredAt: now,
                sourceStart: endIndex,
                sourceEnd: endIndex,
                isProvisional: false,
                billId: bill.id
            )
            token.note = todayNote
            context.insert(token)
        }

        todayNote.updatedAt = now

        do {
            try context.save()
        } catch {
            print("BillPaymentJournal: failed to save bill payment tokens — \(error)")
        }
    }
}
