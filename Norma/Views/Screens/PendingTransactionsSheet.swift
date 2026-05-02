//
//  PendingTransactionsSheet.swift
//  Norma
//
//  Phase-2 surface for screenshot-extracted transactions awaiting confirm.
//  Selection-first flow: tap rows to select, pick a target date once, confirm
//  all selected at once. Each selected row's text is appended to the daily
//  note for the chosen date — NoteSyncQueue + extractor turn it into a
//  NoteToken from there.
//

import SwiftUI
import SwiftData

struct PendingTransactionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var dataManager: DataManager

    @State private var selectedIds: Set<String> = []
    @State private var processingIds: Set<String> = []
    @State private var targetDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var showDatePicker = false

    private let bg = Color(red: 0x16/255, green: 0x16/255, blue: 0x1A/255)
    private let cream = Color(red: 0xF2/255, green: 0xED/255, blue: 0xE2/255)
    private let mutedText = Color(red: 0x7A/255, green: 0x76/255, blue: 0x70/255)
    private let dimText = Color(red: 0x5C/255, green: 0x58/255, blue: 0x52/255)
    private let onAccentText = Color(red: 0x0E/255, green: 0x0E/255, blue: 0x10/255)
    private let accentPurple = Color(red: 0x96/255, green: 0x76/255, blue: 0xD9/255)

    private var heroFont: Font { .system(size: 56, weight: .heavy) }

    private var pending: [PendingTransaction] { dataManager.pendingTransactions }
    private var selectedCount: Int { selectedIds.count }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                navBar

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        heroBlock
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24)

                        listBlock
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.bottom, selectedCount > 0 ? 120 : 32)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .background(bg.ignoresSafeArea())

            if selectedCount > 0 {
                bottomActionBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showDatePicker) {
            datePickerSheet
        }
    }

    // MARK: - Nav

    private var navBar: some View {
        HStack {
            Spacer()
            Button {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(cream.opacity(0.85))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }

    // MARK: - Hero

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("inbox")
                    .font(.custom(FontFamily.Rubik.medium, size: 13))
                    .foregroundStyle(mutedText)
                Spacer()
                if !pending.isEmpty {
                    selectAllPill
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("pending")
                    .font(heroFont)
                    .tracking(-2.24)
                    .foregroundStyle(cream)
                Text(".")
                    .font(heroFont)
                    .tracking(-2.24)
                    .foregroundStyle(accentPurple)
            }

            Text(eyebrowText)
                .font(.custom(FontFamily.Rubik.regular, size: 15).italic())
                .foregroundStyle(mutedText)
                .padding(.top, 2)
        }
    }

    private var selectAllPill: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                if selectedIds.count == pending.count {
                    selectedIds.removeAll()
                } else {
                    selectedIds = Set(pending.compactMap { $0.id })
                }
            }
        } label: {
            Text(selectedIds.count == pending.count && !pending.isEmpty ? "clear" : "select all")
                .font(.custom(FontFamily.Rubik.medium, size: 12))
                .foregroundStyle(cream)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .overlay(Capsule().stroke(cream.opacity(0.32), style: StrokeStyle(lineWidth: 1, dash: [3, 3])))
        }
        .buttonStyle(.plain)
    }

    private var eyebrowText: String {
        let count = pending.count
        if count == 0 { return "all caught up." }
        if count == 1 { return "1 transaction waiting." }
        return "\(count) transactions waiting."
    }

    // MARK: - List

    @ViewBuilder
    private var listBlock: some View {
        if pending.isEmpty {
            emptyState
        } else {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(pending) { tx in
                    pendingRow(tx)
                        .transition(
                            .asymmetric(
                                insertion: .opacity,
                                removal: .opacity
                                    .combined(with: .move(edge: .leading))
                                    .combined(with: .scale(scale: 0.92, anchor: .leading))
                            )
                        )
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("nothing pending")
                .font(.custom(FontFamily.Rubik.semiBold, size: 16))
                .foregroundStyle(cream.opacity(0.7))
            Text("screenshot a transaction to send it here.")
                .font(.custom(FontFamily.Rubik.regular, size: 13))
                .foregroundStyle(mutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    @ViewBuilder
    private func pendingRow(_ tx: PendingTransaction) -> some View {
        let id = tx.id ?? ""
        let isSelected = selectedIds.contains(id)
        let isProcessing = processingIds.contains(id)

        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                if isSelected {
                    selectedIds.remove(id)
                } else {
                    selectedIds.insert(id)
                }
            }
        } label: {
            HStack(alignment: .top, spacing: 14) {
                selectionDot(isSelected: isSelected)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(tx.merchant?.lowercased() ?? "unknown")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 16))
                        .tracking(-0.16)
                        .foregroundStyle(cream)
                        .lineLimit(1)
                    if let date = formattedDate(tx.transactionDate) {
                        Text(date)
                            .font(.custom(FontFamily.Rubik.regular, size: 12).italic())
                            .foregroundStyle(dimText)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(formattedAmount(tx))
                    .font(.system(size: 22, weight: .bold))
                    .tracking(-0.44)
                    .monospacedDigit()
                    .foregroundStyle(cream)

                skipButton(tx)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? accentPurple.opacity(0.10) : cream.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? accentPurple.opacity(0.55) : cream.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .opacity(isProcessing ? 0.5 : 1)
        .allowsHitTesting(!isProcessing)
    }

    @ViewBuilder
    private func selectionDot(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .fill(isSelected ? accentPurple : Color.clear)
                .frame(width: 18, height: 18)
            Circle()
                .stroke(isSelected ? accentPurple : cream.opacity(0.32), lineWidth: 1.2)
                .frame(width: 18, height: 18)
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(onAccentText)
            }
        }
    }

    @ViewBuilder
    private func skipButton(_ tx: PendingTransaction) -> some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            skip(tx)
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(dimText)
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bottom action bar

    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [bg.opacity(0), bg],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 24)
            .allowsHitTesting(false)

            HStack(spacing: 12) {
                Text("add \(selectedCount) to")
                    .font(.custom(FontFamily.Rubik.medium, size: 13))
                    .foregroundStyle(mutedText)

                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    showDatePicker = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(cream)
                        Text(targetDateLabel)
                            .font(.custom(FontFamily.Rubik.semiBold, size: 13))
                            .foregroundStyle(cream)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(cream.opacity(0.7))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(accentPurple.opacity(0.10)))
                    .overlay(Capsule().stroke(accentPurple.opacity(0.5), lineWidth: 1))
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    confirmSelected()
                } label: {
                    Text("confirm")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 13))
                        .foregroundStyle(onAccentText)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(accentPurple))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .background(bg)
        }
    }

    private var targetDateLabel: String {
        let cal = Calendar.current
        if cal.isDateInToday(targetDate) { return "today" }
        if cal.isDateInYesterday(targetDate) { return "yesterday" }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: targetDate).lowercased()
    }

    // MARK: - Date picker sheet

    private var datePickerSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Text("add to which day")
                    .font(.custom(FontFamily.Rubik.semiBold, size: 14))
                    .tracking(0.56)
                    .textCase(.uppercase)
                    .foregroundStyle(mutedText)
                Spacer()
                Button {
                    showDatePicker = false
                } label: {
                    Text("done")
                        .font(.custom(FontFamily.Rubik.semiBold, size: 13))
                        .foregroundStyle(accentPurple)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 22)
            .padding(.bottom, 12)

            DatePicker(
                "",
                selection: $targetDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(accentPurple)
            .padding(.horizontal, 16)

            Spacer()
        }
        .background(bg.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Actions

    private func confirmSelected() {
        let toConfirm = pending.filter {
            guard let id = $0.id else { return false }
            return selectedIds.contains(id) && !processingIds.contains(id)
        }
        guard !toConfirm.isEmpty else { return }

        let ids = Set(toConfirm.compactMap(\.id))
        processingIds.formUnion(ids)
        selectedIds.subtract(ids)

        Task {
            // 1. Append every selected transaction to the daily note for targetDate.
            //    Build the combined text first, write once — keeps the note's
            //    update timestamp clean and triggers a single sync round-trip.
            let repo = NoteRepository(context: modelContext)
            let note = repo.note(forDate: targetDate)
            let lines = toConfirm.map { transactionLine(for: $0) }.filter { !$0.isEmpty }
            if !lines.isEmpty {
                let appended = lines.joined(separator: "\n")
                let trimmed = note.rawText.trimmingCharacters(in: .whitespacesAndNewlines)
                let newText = trimmed.isEmpty
                    ? appended
                    : note.rawText + (note.rawText.hasSuffix("\n") ? "" : "\n") + appended
                repo.updateText(newText, on: note)
            }

            // 2. Delete each pending row from Supabase + cache + array.
            for tx in toConfirm {
                do {
                    try await dataManager.rejectPendingTransaction(tx)
                } catch {
                    print("Failed to clear pending transaction after confirm: \(error)")
                }
            }

            await MainActor.run {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                    processingIds.subtract(ids)
                }
            }
        }
    }

    private func skip(_ tx: PendingTransaction) {
        guard let id = tx.id, !processingIds.contains(id) else { return }
        processingIds.insert(id)
        selectedIds.remove(id)

        Task {
            do {
                try await dataManager.rejectPendingTransaction(tx)
            } catch {
                print("Failed to skip pending transaction: \(error)")
            }
            await MainActor.run {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                    _ = processingIds.remove(id)
                }
            }
        }
    }

    // MARK: - Formatting

    private func transactionLine(for tx: PendingTransaction) -> String {
        let amountText: String = {
            guard let amount = tx.amount else { return "" }
            let symbol = currencySymbol(tx.currency ?? "USD")
            let formatted = String(format: "%.2f", amount)
            return "\(symbol)\(formatted)"
        }()
        let merchantText = tx.merchant?.lowercased() ?? ""
        if amountText.isEmpty && merchantText.isEmpty { return "" }
        if merchantText.isEmpty { return amountText }
        if amountText.isEmpty { return merchantText }
        return "\(amountText) at \(merchantText)"
    }

    private func currencySymbol(_ code: String) -> String {
        switch code.uppercased() {
        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        case "THB": return "฿"
        case "INR": return "₹"
        case "KRW": return "₩"
        case "VND": return "₫"
        case "PHP": return "₱"
        default: return "\(code) "
        }
    }

    private func formattedAmount(_ tx: PendingTransaction) -> String {
        guard let amount = tx.amount else { return "—" }
        return "\(currencySymbol(tx.currency ?? "USD"))\(String(format: "%.2f", amount))"
    }

    private func formattedDate(_ raw: String?) -> String? {
        guard let raw, !raw.isEmpty else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = iso.date(from: raw) ?? {
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.dateFormat = "yyyy-MM-dd"
            return f.date(from: raw)
        }()
        guard let date else { return raw }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date).lowercased()
    }
}

#Preview {
    Color.black
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            PendingTransactionsSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
}
