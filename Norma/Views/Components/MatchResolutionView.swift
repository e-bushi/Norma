//
//  MatchResolutionView.swift
//  Norma
//
//  Created by Claude on 3/20/26.
//

import SwiftUI

struct MatchResolutionView: View {
    @EnvironmentObject private var dataManager: DataManager
    @SwiftUI.Environment(\.dismiss) private var dismiss
    @ObservedObject private var reconciliationService = PlaidReconciliationService.shared

    @State private var showLinkConfirmation = false
    @State private var showNewConfirmation = false
    @State private var selectedMatch: AmbiguousMatch?
    @State private var selectedExpense: Expense?

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(String(format: "%.2f", amount))"
    }

    private func formatDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = inputFormatter.date(from: dateString) else { return dateString }
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMM d"
        return outputFormatter.string(from: date)
    }

    var body: some View {
        NavigationStack {
            List {
                if reconciliationService.pendingMatches.isEmpty {
                    Section {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 28))
                                .foregroundColor(Color("NormaPastelTeal"))
                            Text("All transactions resolved")
                                .font(.custom(FontFamily.Rubik.medium, size: 14))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }
                } else {
                    ForEach(reconciliationService.pendingMatches) { match in
                        Section {
                            // Plaid transaction header
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(match.plaidTransaction.merchantName ?? match.plaidTransaction.name)
                                        .font(.custom(FontFamily.Rubik.medium, size: 16))
                                        .foregroundColor(.primary)

                                    Spacer()

                                    Text(formatCurrency(match.plaidTransaction.amount))
                                        .font(.custom(FontFamily.Rubik.medium, size: 16))
                                        .foregroundColor(.primary)
                                }

                                Text(formatDate(match.plaidTransaction.authorizedDate ?? match.plaidTransaction.date))
                                    .font(.custom(FontFamily.Rubik.regular, size: 13))
                                    .foregroundColor(.secondary)

                                Text("Which expense is this?")
                                    .font(.custom(FontFamily.Rubik.medium, size: 13))
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                            }

                            // Candidate expenses
                            ForEach(match.candidateExpenses, id: \.id) { expense in
                                Button {
                                    selectedMatch = match
                                    selectedExpense = expense
                                    showLinkConfirmation = true
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(expense.name)
                                                .font(.custom(FontFamily.Rubik.regular, size: 15))
                                                .foregroundColor(.primary)
                                            Text(formatDate(String(expense.expenseDate.prefix(10))))
                                                .font(.custom(FontFamily.Rubik.regular, size: 12))
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        Text(formatCurrency(expense.amount))
                                            .font(.custom(FontFamily.Rubik.medium, size: 15))
                                            .foregroundColor(.primary)

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }

                            // "It's a new transaction" option
                            Button {
                                selectedMatch = match
                                showNewConfirmation = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color("NormaPastelTeal"))

                                    Text("It's a new transaction")
                                        .font(.custom(FontFamily.Rubik.medium, size: 15))
                                        .foregroundColor(Color("NormaPastelTeal"))

                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Review Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.custom(FontFamily.Rubik.medium, size: 16))
                }
            }
            .alert("Link Transaction", isPresented: $showLinkConfirmation) {
                Button("Cancel", role: .cancel) {
                    selectedMatch = nil
                    selectedExpense = nil
                }
                Button("Link") {
                    if let match = selectedMatch, let expense = selectedExpense {
                        resolveWithExpense(match: match, expense: expense)
                    }
                    selectedMatch = nil
                    selectedExpense = nil
                }
            } message: {
                if let expense = selectedExpense {
                    Text("Link this bank transaction to \"\(expense.name)\" (\(formatCurrency(expense.amount)))?")
                }
            }
            .alert("New Transaction", isPresented: $showNewConfirmation) {
                Button("Cancel", role: .cancel) {
                    selectedMatch = nil
                }
                Button("Add as New") {
                    if let match = selectedMatch {
                        resolveAsNew(match: match)
                    }
                    selectedMatch = nil
                }
            } message: {
                if let match = selectedMatch {
                    Text("Add \"\(match.plaidTransaction.merchantName ?? match.plaidTransaction.name)\" as a new expense?")
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func resolveWithExpense(match: AmbiguousMatch, expense: Expense) {
        let resolved = PlaidReconciliationService.shared.resolveMatch(
            transaction: match.plaidTransaction,
            expense: expense
        )

        Task {
            try await dataManager.updateExpenseWithEncryption(resolved)
            await MainActor.run {
                reconciliationService.pendingMatches.removeAll { $0.id == match.id }
            }
        }
    }

    private func resolveAsNew(match: AmbiguousMatch) {
        guard let userId = dataManager.currentProfile?.userId else { return }

        let newExpense = PlaidReconciliationService.shared.resolveAsNew(
            transaction: match.plaidTransaction,
            userId: userId
        )

        Task {
            try await dataManager.addExpenseWithEncryption(newExpense)
            await MainActor.run {
                reconciliationService.pendingMatches.removeAll { $0.id == match.id }
            }
        }
    }
}
