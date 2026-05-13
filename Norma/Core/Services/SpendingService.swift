//
//  SpendingService.swift
//  Norma
//
//  Phase-1 read-side bridge: answers "what did the user spend?" by querying
//  NoteToken directly from SwiftData. This is the start of treating notes
//  as the source of truth for spending — the Forecast sheet now reflects
//  whatever the user wrote, not just legacy Expense rows.
//
//  Currency policy (v1):
//  - If a token's currency matches the user's display currency → use amount
//  - Else if usdEquivalent is present → use that (assumes USD display)
//  - Else fall back to amount as-is (best-effort; FX layer comes later)
//

import Foundation
import SwiftData

@MainActor
struct SpendingService {
    let context: ModelContext
    let currency: String
    /// User's bills, used to filter expense tokens that look like bill
    /// payments slipped through the AI prompt rule. Pass an empty array if
    /// you don't have access to the bill list — the filter becomes a no-op.
    let bills: [Bill]

    init(context: ModelContext, currency: String, bills: [Bill] = []) {
        self.context = context
        self.currency = currency
        self.bills = bills
    }

    // MARK: - Totals

    /// Total expense-token amount for the given date range.
    func totalSpent(in range: ClosedRange<Date>) -> Double {
        expenseTokens(in: range).reduce(0) { $0 + amount(for: $1) }
    }

    /// Convenience: total spent in the calendar month containing `reference`.
    func totalSpent(inMonthOf reference: Date) -> Double {
        let bounds = monthBounds(for: reference)
        return totalSpent(in: bounds)
    }

    // MARK: - Weekly buckets

    /// Four buckets of actual spend covering the displayed month:
    /// days 1–7, 8–14, 15–21, 22–end. Use this for the Forecast sparkline.
    func weeklyActuals(inMonthOf reference: Date) -> [Double] {
        let cal = Calendar.current
        let bounds = monthBounds(for: reference)
        let daysInMonth = cal.range(of: .day, in: .month, for: reference)?.last ?? 30

        let ranges: [ClosedRange<Int>] = [
            1...7,
            8...14,
            15...21,
            22...daysInMonth
        ]

        var buckets: [Double] = Array(repeating: 0, count: 4)
        for token in expenseTokens(in: bounds) {
            let day = cal.component(.day, from: token.occurredAt)
            if let idx = ranges.firstIndex(where: { $0.contains(day) }) {
                buckets[idx] += amount(for: token)
            }
        }
        return buckets
    }

    // MARK: - Forecast aggregates

    /// Commitment tokens whose due date falls in the given month.
    func commitmentTokens(inMonthOf reference: Date) -> [NoteToken] {
        tokens(of: .commit, in: monthBounds(for: reference))
    }

    /// Intention tokens whose creation date falls in the given month.
    /// Intentions are scoped to the month they were written in.
    func intentionTokens(inMonthOf reference: Date) -> [NoteToken] {
        tokens(of: .intent, in: monthBounds(for: reference))
    }

    func totalCommitments(inMonthOf reference: Date) -> Double {
        commitmentTokens(inMonthOf: reference).reduce(0) { $0 + amount(for: $1) }
    }

    func totalIntentions(inMonthOf reference: Date) -> Double {
        intentionTokens(inMonthOf: reference).reduce(0) { $0 + amount(for: $1) }
    }

    /// Date of the most recent expense token in the displayed month, used to
    /// drive the freshness signal in the spending pace section.
    func latestExpenseDate(inMonthOf reference: Date) -> Date? {
        expenseTokens(in: monthBounds(for: reference))
            .map(\.occurredAt)
            .max()
    }

    // MARK: - Internals

    private func expenseTokens(in range: ClosedRange<Date>) -> [NoteToken] {
        let raw = tokens(of: .expense, in: range)
        guard !bills.isEmpty else { return raw }
        // Defensive filter: if a token looks like a bill payment that slipped
        // through the AI prompt rule, drop it from the spending pace cumulative.
        // The bill amount is already pre-deducted from breathing room.
        return raw.filter { !BillPaymentMatcher.looksLikeBillPayment($0, against: bills) }
    }

    private func tokens(of kind: NoteToken.Kind, in range: ClosedRange<Date>) -> [NoteToken] {
        let lower = range.lowerBound
        let upper = range.upperBound
        let raw = kind.rawValue
        let descriptor = FetchDescriptor<NoteToken>(
            predicate: #Predicate { token in
                token.kindRaw == raw &&
                token.occurredAt >= lower &&
                token.occurredAt <= upper
            }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    private func amount(for token: NoteToken) -> Double {
        if token.currency.caseInsensitiveCompare(currency) == .orderedSame {
            return token.amount
        }
        if currency.caseInsensitiveCompare("USD") == .orderedSame, let usd = token.usdEquivalent {
            return usd
        }
        // Best-effort fallback when no FX is available.
        return token.usdEquivalent ?? token.amount
    }

    private func monthBounds(for reference: Date) -> ClosedRange<Date> {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: reference)
        let start = cal.date(from: comps) ?? reference
        let nextMonth = cal.date(byAdding: .month, value: 1, to: start) ?? reference
        let end = cal.date(byAdding: .second, value: -1, to: nextMonth) ?? nextMonth
        return start...end
    }
}
