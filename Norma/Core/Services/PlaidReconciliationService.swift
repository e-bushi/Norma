//
//  PlaidReconciliationService.swift
//  Norma
//
//  Created by Claude on 3/20/26.
//

import Foundation

/// Represents an ambiguous match that needs user resolution
struct AmbiguousMatch: Identifiable {
    let id = UUID()
    let plaidTransaction: PlaidService.PlaidTransaction
    let candidateExpenses: [Expense]
}

/// Result of a reconciliation run
struct ReconciliationResult {
    var updatedExpenses: [Expense] = []
    var ambiguousMatches: [AmbiguousMatch] = []
    var unreconciledTransactions: [PlaidService.PlaidTransaction] = []
}

class PlaidReconciliationService: ObservableObject {
    static let shared = PlaidReconciliationService()

    @Published var pendingMatches: [AmbiguousMatch] = []

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private init() {}

    /// Run reconciliation of Plaid transactions against existing expenses
    func reconcile(
        plaidTransactions: [PlaidService.PlaidTransaction],
        existingExpenses: [Expense],
        userId: String
    ) -> ReconciliationResult {
        var result = ReconciliationResult()
        var mutableExpenses = existingExpenses

        for transaction in plaidTransactions {
            // Skip negative amounts (credits/income) — only reconcile expenses
            // Plaid reports expenses as positive amounts
            if transaction.amount <= 0 { continue }

            // Step 1: Check for existing link by transaction_id
            if let linkedIndex = mutableExpenses.firstIndex(where: {
                $0.bankDetail?.transactionId == transaction.transactionId
            }) {
                var expense = mutableExpenses[linkedIndex]
                var changed = false

                // Update amount if changed
                if expense.amount != transaction.amount {
                    expense.amount = transaction.amount
                    changed = true
                }

                // Update pending status
                if expense.pending != transaction.pending {
                    expense.pending = transaction.pending
                    changed = true
                }

                if changed {
                    mutableExpenses[linkedIndex] = expense
                    result.updatedExpenses.append(expense)
                }
                continue
            }

            // Step 2: Fuzzy match against manual entries
            let transactionDate = dateFormatter.date(from: transaction.authorizedDate ?? transaction.date)
            let candidates = mutableExpenses.filter { expense in
                // Only match manual expenses without a bank link
                guard expense.source == "manual", expense.bankDetail == nil else { return false }

                // Exact amount match
                guard expense.amount == transaction.amount else { return false }

                // Date within 3 days
                guard let expDate = dateFormatter.date(from: String(expense.expenseDate.prefix(10))),
                      let txnDate = transactionDate else { return false }
                let daysDiff = abs(Calendar.current.dateComponents([.day], from: expDate, to: txnDate).day ?? Int.max)
                return daysDiff <= 3
            }

            if candidates.count == 1 {
                // Single strong match — merge silently
                let matched = candidates[0]
                guard let index = mutableExpenses.firstIndex(where: { $0.id == matched.id }) else { continue }

                var expense = mutableExpenses[index]
                expense.bankDetail = makeBankDetail(from: transaction)
                expense.source = "plaid"
                expense.pending = transaction.pending
                mutableExpenses[index] = expense
                result.updatedExpenses.append(expense)
            } else if candidates.count > 1 {
                // Ambiguous — surface to user
                result.ambiguousMatches.append(AmbiguousMatch(
                    plaidTransaction: transaction,
                    candidateExpenses: candidates
                ))
            } else {
                // No match — queue for user confirmation
                result.unreconciledTransactions.append(transaction)
            }
        }

        // Step 3: Handle pending updates for existing plaid-linked expenses
        for (index, expense) in mutableExpenses.enumerated() {
            guard expense.pending,
                  let txnId = expense.bankDetail?.transactionId else { continue }

            // Check if this transaction is now settled
            if let settledTxn = plaidTransactions.first(where: {
                $0.transactionId == txnId && !$0.pending
            }) {
                var updated = mutableExpenses[index]
                updated.pending = false
                if updated.amount != settledTxn.amount {
                    updated.amount = settledTxn.amount
                }
                mutableExpenses[index] = updated
                // Only add if not already in updatedExpenses
                if !result.updatedExpenses.contains(where: { $0.id == updated.id }) {
                    result.updatedExpenses.append(updated)
                }
            }
        }

        return result
    }

    /// Resolve an ambiguous match — user chose a specific expense to link
    func resolveMatch(
        transaction: PlaidService.PlaidTransaction,
        expense: Expense
    ) -> Expense {
        var resolved = expense
        resolved.bankDetail = makeBankDetail(from: transaction)
        resolved.source = "plaid"
        resolved.pending = transaction.pending
        return resolved
    }

    /// Resolve an ambiguous match — user says it's a new transaction
    func resolveAsNew(
        transaction: PlaidService.PlaidTransaction,
        userId: String
    ) -> Expense {
        return makeExpense(from: transaction, userId: userId)
    }

    // MARK: - Private

    private func makeBankDetail(from transaction: PlaidService.PlaidTransaction) -> BankDetail {
        BankDetail(
            transactionId: transaction.transactionId,
            accountId: transaction.accountId,
            pendingTransactionId: nil,
            institutionName: nil,
            merchantNameRaw: transaction.name,
            authorizedDate: transaction.authorizedDate,
            postedDate: transaction.date
        )
    }

    private func makeExpense(from transaction: PlaidService.PlaidTransaction, userId: String) -> Expense {
        let expenseDate = transaction.authorizedDate ?? transaction.date
        return Expense(
            userId: userId,
            name: transaction.merchantName ?? transaction.name,
            amount: transaction.amount,
            expenseDate: expenseDate,
            paymentMethod: .debitCard,
            merchant: transaction.merchantName,
            bankDetail: makeBankDetail(from: transaction),
            source: "plaid",
            pending: transaction.pending
        )
    }
}
