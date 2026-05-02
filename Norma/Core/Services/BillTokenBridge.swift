//
//  BillTokenBridge.swift
//  Norma
//
//  Bridges note-extracted bill tokens (NoteToken kind == .bill, with a recurrence)
//  into the canonical Bill model surfaced by BillsView/ForecastSheet. On every
//  extraction pass, recurring bill mentions get reconciled against the user's
//  existing bills via a (name, amount, frequency) match. New tokens become new
//  Bill records; matched tokens are no-ops. Token removal does NOT delete the
//  Bill — once promoted into the bills view, the user owns it.
//

import Foundation

@MainActor
final class BillTokenBridge {
    static let shared = BillTokenBridge()

    private weak var dataManager: DataManager?
    private weak var sessionViewModel: SessionViewModel?

    private init() {}

    func configure(dataManager: DataManager, sessionViewModel: SessionViewModel) {
        self.dataManager = dataManager
        self.sessionViewModel = sessionViewModel
    }

    /// Inspect a freshly-extracted token list and create Bill records for any
    /// recurring bill tokens that don't already have one.
    func reconcile(extractedTokens tokens: [NoteToken]) {
        guard let dataManager,
              let userId = sessionViewModel?.currentUser?.userId
        else { return }

        let billTokens = tokens.filter { $0.kind == .bill && $0.recurrence != nil }
        guard !billTokens.isEmpty else { return }

        let reminderDays = sessionViewModel?.currentUser?.settings.billReminderDays

        for token in billTokens {
            guard let frequency = Self.mapFrequency(token.recurrence),
                  let name = token.subject?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .nilIfEmpty
            else { continue }

            if Self.matchesExistingBill(
                in: dataManager.bills,
                name: name,
                amount: token.amount,
                frequency: frequency
            ) {
                continue
            }

            let dueDate = token.nextOccurrence() ?? token.occurredAt

            let newBill = Bill(
                userId: userId,
                name: name,
                dueDate: dueDate,
                amount: token.amount,
                status: .scheduled,
                frequency: frequency,
                isReminderOn: true,
                reminderDays: reminderDays
            )

            Task { [weak dataManager] in
                guard let dataManager else { return }
                do {
                    try await dataManager.addBillWithEncryption(newBill)
                } catch {
                    print("BillTokenBridge: failed to persist bill from token — \(error)")
                }
            }
        }
    }

    private static func matchesExistingBill(
        in bills: [Bill],
        name: String,
        amount: Double,
        frequency: BillFrequency
    ) -> Bool {
        let lowerName = name.lowercased()
        return bills.contains { bill in
            bill.name.lowercased() == lowerName
            && abs(bill.amount - amount) < 0.01
            && bill.frequency == frequency
        }
    }

    /// NoteToken recurrence (daily/weekly/biweekly/monthly/quarterly/yearly)
    /// collapses onto BillFrequency's coarser enum (monthly/quarterly/yearly).
    /// Sub-monthly cadences are stored as monthly bills — same precedent as
    /// RecurringBillsReviewView's Plaid stream import.
    private static func mapFrequency(_ recurrence: NoteToken.Recurrence?) -> BillFrequency? {
        guard let recurrence else { return nil }
        switch recurrence {
        case .daily, .weekly, .biweekly, .monthly: return .monthly
        case .quarterly: return .quarterly
        case .yearly: return .yearly
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
