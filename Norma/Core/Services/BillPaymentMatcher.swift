//
//  BillPaymentMatcher.swift
//  Norma
//
//  Heuristic matcher used in two places:
//   1. SpendingService (read time) — excludes `.expense` tokens that look like
//      payments of an existing bill, so they don't double-count against the
//      user's spending pace cap.
//   2. Ambiguity resolver (post-extraction) — resolves AI-flagged "could-be-a-
//      bill-payment" tokens by checking the user's actual bill list.
//
//  Match rule: token's subject contains the bill name (or vice versa), the
//  amount is within ±5% of the bill amount, and the token's occurredAt falls
//  inside the bill's current cycle. All three must pass — narrow to keep
//  false-positives down.
//

import Foundation

@MainActor
enum BillPaymentMatcher {
    private static let amountTolerance: Double = 0.05  // ±5%

    /// True if the token looks like a payment of any bill in `bills`.
    static func looksLikeBillPayment(_ token: NoteToken, against bills: [Bill]) -> Bool {
        bills.contains { match(token: token, bill: $0) }
    }

    /// Returns the first bill the token plausibly matches, or nil.
    static func matchingBill(_ token: NoteToken, in bills: [Bill]) -> Bill? {
        bills.first { match(token: token, bill: $0) }
    }

    private static func match(token: NoteToken, bill: Bill) -> Bool {
        guard let subject = token.subject?.lowercased(),
              !subject.isEmpty
        else { return false }

        let billName = bill.name.lowercased()
        let nameOverlap = subject.contains(billName) || billName.contains(subject)
        guard nameOverlap else { return false }

        let lower = bill.amount * (1 - amountTolerance)
        let upper = bill.amount * (1 + amountTolerance)
        guard token.amount >= lower, token.amount <= upper else { return false }

        return bill.isInCurrentCycle(expenseDate: token.occurredAt)
    }
}
