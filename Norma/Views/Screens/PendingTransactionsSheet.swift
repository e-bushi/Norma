//
//  PendingTransactionsSheet.swift
//  Norma
//
//  Review queue for receipt-scanned transactions. Reached from the badge
//  next to the freshness capsule on the runway home. Each row can be
//  discarded individually; "add all to runway" converts every amount to the
//  user's currency, deducts the total from the freedom fund, and records the
//  spend in the ledger — all same-day confirmations collapse into a single
//  ledger entry (FreedomFundLedger.recordReceiptBatch).
//

import SwiftUI
import SwiftData

// MARK: - Store

/// Owns the pending queue so the home badge and the sheet share one source
/// of truth. ArcCountView holds it as a @StateObject; the sheet mutates it.
@MainActor
final class PendingTransactionsStore: ObservableObject {
    @Published var items: [PendingTransaction] = []
    @Published var isLoading = false

    func refresh(userId: String?) async {
        guard let userId, !userId.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await SupabaseService.shared.fetchPendingTransactions(userId: userId)
        } catch {
            print("PendingTransactionsStore: fetch failed — \(error)")
        }
    }

    /// Discard without touching the fund.
    func discard(_ txn: PendingTransaction) async {
        do {
            try await SupabaseService.shared.deletePendingTransactions(ids: [txn.id])
            items.removeAll { $0.id == txn.id }
        } catch {
            print("PendingTransactionsStore: discard failed — \(error)")
        }
    }

    /// Remove confirmed rows from Supabase and the local queue.
    func removeConfirmed(ids: [String]) async throws {
        try await SupabaseService.shared.deletePendingTransactions(ids: ids)
        items.removeAll { ids.contains($0.id) }
    }
}

// MARK: - Sheet

struct PendingTransactionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @ObservedObject var store: PendingTransactionsStore

    /// The user's display/fund currency (same value ArcCountView renders with).
    let currency: String

    @State private var isConfirming = false
    @State private var errorMessage: String?

    private let bg = Color(red: 0x16/255, green: 0x16/255, blue: 0x1A/255)
    private let cream = Color(red: 0xF2/255, green: 0xED/255, blue: 0xE2/255)
    private let mutedText = Color(red: 0x7A/255, green: 0x76/255, blue: 0x70/255)
    private let coral = Color(red: 0xE0/255, green: 0x7B/255, blue: 0x6F/255)
    private let onAccentText = Color(red: 0x0E/255, green: 0x0E/255, blue: 0x10/255)
    private var accent: Color { NormaPalette.lavender }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                if store.items.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(store.items) { txn in
                                row(txn)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 12)
                    }

                    footer
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(bg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Text("close")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(cream.opacity(0.85))
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("pending")
                .font(.custom(FontFamily.Rubik.semiBold, size: 11))
                .tracking(0.88)
                .textCase(.uppercase)
                .foregroundStyle(mutedText)
            Text("from your receipts.")
                .font(.custom(FontFamily.Rubik.semiBold, size: 24))
                .foregroundStyle(cream)
            Text(store.items.isEmpty
                 ? "nothing waiting on you."
                 : "add them to keep your runway true, or discard what's noise.")
                .font(.custom(FontFamily.Rubik.regular, size: 13))
                .foregroundStyle(mutedText)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        }
    }

    // MARK: - Rows

    private func row(_ txn: PendingTransaction) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text((txn.merchant?.lowercased()).flatMap { $0.isEmpty ? nil : $0 } ?? "unknown merchant")
                    .font(.custom(FontFamily.Rubik.semiBold, size: 15))
                    .foregroundStyle(cream)
                    .lineLimit(1)
                Text(dateLabel(for: txn))
                    .font(.custom(FontFamily.Rubik.medium, size: 12))
                    .foregroundStyle(mutedText)
            }

            Spacer(minLength: 8)

            Text(amountLabel(for: txn))
                .font(.custom(FontFamily.Rubik.bold, size: 17))
                .foregroundStyle(accent)

            Button {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                Task { await store.discard(txn) }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(mutedText)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isConfirming)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(cream.opacity(0.04)))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(cream.opacity(0.08), lineWidth: 1))
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(mutedText)
            Text("all caught up.")
                .font(.custom(FontFamily.Rubik.medium, size: 15))
                .foregroundStyle(mutedText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 10) {
            if let errorMessage {
                Text(errorMessage)
                    .font(.custom(FontFamily.Rubik.medium, size: 12))
                    .foregroundStyle(coral)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: confirmAll) {
                HStack(spacing: 8) {
                    if isConfirming {
                        ProgressView()
                            .controlSize(.small)
                            .tint(onAccentText)
                    }
                    Text(isConfirming ? "adding…" : "add all to runway")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 16))
                        .foregroundStyle(onAccentText)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Capsule(style: .continuous).fill(accent))
            }
            .buttonStyle(.plain)
            .disabled(isConfirming)
            .opacity(isConfirming ? 0.7 : 1)
        }
    }

    // MARK: - Confirm

    /// Converts every amount to the fund currency, deducts the total, records
    /// the ledger batch, then clears the queue. Supabase rows are deleted
    /// before the fund is touched so a network failure can't double-spend.
    private func confirmAll() {
        guard !isConfirming else { return }
        let txns = store.items
        guard !txns.isEmpty else { return }
        isConfirming = true
        errorMessage = nil

        Task {
            do {
                let total = try await totalInFundCurrency(txns)
                try await store.removeConfirmed(ids: txns.map(\.id))
                persistLocally(txns)

                if total > 0, var updatedProfile = sessionViewModel.currentUser {
                    var updatedSettings = updatedProfile.settings
                    let newFund = max(0, updatedSettings.freedomFund - total)
                    updatedSettings.freedomFund = newFund
                    updatedProfile.freedomFund = newFund
                    FreedomFundLedger.recordReceiptBatch(
                        in: modelContext,
                        userId: updatedProfile.userId,
                        newBalance: newFund
                    )
                    updatedProfile.settings = updatedSettings
                    sessionViewModel.updateUserProfile(updatedProfile)
                }

                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                isConfirming = false
                dismiss()
            } catch {
                isConfirming = false
                errorMessage = "couldn't add these right now — try again."
                print("PendingTransactionsSheet: confirm failed — \(error)")
            }
        }
    }

    /// Confirmed transactions become local CapturedTransaction records —
    /// the server row is a hand-off, not the source of truth.
    private func persistLocally(_ txns: [PendingTransaction]) {
        guard let userId = sessionViewModel.currentUser?.userId else { return }
        for txn in txns {
            guard let amount = txn.amount, amount > 0 else { continue }
            modelContext.insert(CapturedTransaction(
                id: txn.id,
                userId: userId,
                amount: amount,
                currency: (txn.currency ?? currency).uppercased(),
                merchant: txn.merchant,
                transactionDate: txn.transactionDate ?? txn.createdAt ?? Date(),
                rawText: txn.rawText
            ))
        }
        do {
            try modelContext.save()
        } catch {
            print("PendingTransactionsSheet: failed to save captured transactions — \(error)")
        }
    }

    /// Sums per-currency subtotals, converting foreign ones through the
    /// currency-convert edge function. Throws if a needed conversion fails —
    /// silently guessing a rate would corrupt the runway.
    private func totalInFundCurrency(_ txns: [PendingTransaction]) async throws -> Double {
        var subtotals: [String: Double] = [:]
        for txn in txns {
            guard let amount = txn.amount, amount > 0 else { continue }
            let code = (txn.currency ?? currency).uppercased()
            subtotals[code, default: 0] += amount
        }

        var total: Double = 0
        for (code, subtotal) in subtotals {
            if code == currency.uppercased() {
                total += subtotal
            } else {
                let converted = try await CurrencyConversionService.shared.convert(
                    amount: subtotal, from: code, to: currency.uppercased()
                )
                total += converted.convertedValue
            }
        }
        return total
    }

    // MARK: - Formatting

    private func dateLabel(for txn: PendingTransaction) -> String {
        let date = txn.transactionDate ?? txn.createdAt
        guard let date else { return "no date" }
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "today" }
        if cal.isDateInYesterday(date) { return "yesterday" }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date).lowercased()
    }

    private func amountLabel(for txn: PendingTransaction) -> String {
        guard let amount = txn.amount else { return "—" }
        let code = (txn.currency ?? currency).uppercased()
        let symbol = NormaPalette.currencySymbol(for: code)
        let isWhole = amount.truncatingRemainder(dividingBy: 1) == 0
        let value = String(format: isWhole ? "%.0f" : "%.2f", amount)
        return "\(symbol)\(NormaPalette.thousandsSeparated(value))"
    }
}
