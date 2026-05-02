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

    // MARK: - Internals

    private func expenseTokens(in range: ClosedRange<Date>) -> [NoteToken] {
        let lower = range.lowerBound
        let upper = range.upperBound
        let descriptor = FetchDescriptor<NoteToken>(
            predicate: #Predicate { token in
                token.kindRaw == "expense" &&
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
