//
//  FreedomFundLedger.swift
//  Norma
//
//  Append-only ledger over FreedomFundEntry. Single rule: an entry is
//  inserted iff the observed balance differs from the most recent entry's
//  balanceAfter. The first observation for a user (no priors) is recorded
//  with delta = newBalance — Norma starts the ledger from zero.
//

import Foundation
import SwiftData

enum FreedomFundLedger {
    /// Compares `newBalance` to the most recent entry for `userId`. Inserts a
    /// new entry only when the value has actually moved. Returns the inserted
    /// entry, or nil if no change.
    @discardableResult
    static func recordIfChanged(
        in context: ModelContext,
        userId: String,
        newBalance: Double,
        source: FreedomFundEntrySource,
        date: Date = Date()
    ) -> FreedomFundEntry? {
        guard !userId.isEmpty else { return nil }

        let previous = latestEntry(in: context, userId: userId)?.balanceAfter ?? 0
        let delta = newBalance - previous
        guard !delta.isNearZero else { return nil }

        let entry = FreedomFundEntry(
            userId: userId,
            createdAt: date,
            delta: delta,
            balanceAfter: newBalance,
            source: source
        )
        context.insert(entry)

        do {
            try context.save()
        } catch {
            print("FreedomFundLedger: failed to save entry — \(error)")
        }
        FreedomFundSync.push(entry)
        return entry
    }

    /// Records a receipt-import batch. Same-day batches collapse: if the most
    /// recent entry is already a receiptImport from the same calendar day, the
    /// new observation folds into it (delta accumulates, balanceAfter moves)
    /// instead of inserting a second row. Otherwise inserts a fresh entry.
    @discardableResult
    static func recordReceiptBatch(
        in context: ModelContext,
        userId: String,
        newBalance: Double,
        date: Date = Date()
    ) -> FreedomFundEntry? {
        guard !userId.isEmpty else { return nil }

        if let latest = latestEntry(in: context, userId: userId),
           latest.source == .receiptImport,
           Calendar.current.isDate(latest.createdAt, inSameDayAs: date) {
            let move = newBalance - latest.balanceAfter
            guard !move.isNearZero else { return nil }
            latest.delta += move
            latest.balanceAfter = newBalance
            latest.createdAt = date
            do {
                try context.save()
            } catch {
                print("FreedomFundLedger: failed to merge receipt batch — \(error)")
            }
            FreedomFundSync.push(latest)
            return latest
        }

        return recordIfChanged(
            in: context,
            userId: userId,
            newBalance: newBalance,
            source: .receiptImport,
            date: date
        )
    }

    /// Most recent entry for the user, or nil if none.
    static func latestEntry(in context: ModelContext, userId: String) -> FreedomFundEntry? {
        var descriptor = FetchDescriptor<FreedomFundEntry>(
            predicate: #Predicate { $0.userId == userId },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }
}

private extension Double {
    /// Treat sub-cent jitter (e.g., from currency rounding noise on Plaid
    /// refreshes) as no-change so we don't flood the ledger.
    var isNearZero: Bool { abs(self) < 0.01 }
}
