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
    /// Finds-or-creates the daily note via NoteRepository so the chip lands
    /// alongside whatever else the user has written today.
    static func appendBillPayments(
        _ bills: [Bill],
        currency: String,
        in context: ModelContext
    ) {
        guard !bills.isEmpty else { return }

        let repository = NoteRepository(context: context)
        let todayNote = repository.today()
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
