//
//  BillsView.swift
//  Norma
//
//  D10 — Bills sheet. Pushed from ForecastSheet's "view all bills" pill.
//  Sectioned editorial list: overdue / upcoming / paid. Each row shows
//  status dot, name, short eyebrow, amount, chevron. Plus + in top-right
//  to add a new bill.
//

import SwiftUI

struct BillsView: View {
    enum Tab { case thisMonth, nextMonth }

    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @EnvironmentObject private var billViewModel: BillViewModel

    @Environment(\.modelContext) private var modelContext

    @State private var selectedTab: Tab = .thisMonth
    @State private var isSelecting: Bool = false
    @State private var selectedBillIds: Set<String> = []
    @State private var showDeleteConfirm: Bool = false
    @State private var showMarkPaidConfirm: Bool = false
    @State private var isDeleting: Bool = false
    @State private var isMarkingPaid: Bool = false

    private let bg = Color(red: 0x16/255, green: 0x16/255, blue: 0x1A/255)
    private let cream = Color(red: 0xF2/255, green: 0xED/255, blue: 0xE2/255)
    private let mutedText = Color(red: 0x7A/255, green: 0x76/255, blue: 0x70/255)
    private let dimText = Color(red: 0x5C/255, green: 0x58/255, blue: 0x52/255)
    private let onAccentText = Color(red: 0x0E/255, green: 0x0E/255, blue: 0x10/255)
    private let accentPurple = Color(red: 0x96/255, green: 0x76/255, blue: 0xD9/255)

    private var heroFont: Font { .system(size: 56, weight: .heavy) }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    heroBlock
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)

                    filterCapsules
                        .padding(.horizontal, 24)
                        .padding(.bottom, 22)

                    sectionsBlock
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(bg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .animation(.easeInOut(duration: 0.18), value: isSelecting)
            .alert("delete bills?", isPresented: $showDeleteConfirm) {
                Button("cancel", role: .cancel) {}
                Button("delete", role: .destructive) { performBulkDelete() }
            } message: {
                Text("this will remove \(selectedBillIds.count) \(selectedBillIds.count == 1 ? "bill" : "bills") permanently.")
            }
            .alert("mark as paid?", isPresented: $showMarkPaidConfirm) {
                Button("cancel", role: .cancel) {}
                Button("mark paid") { performBulkMarkPaid() }
            } message: {
                Text("\(selectedBillIds.count) \(selectedBillIds.count == 1 ? "bill" : "bills") will be marked paid for this cycle and added to today's note.")
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if isSelecting {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    exitSelection()
                } label: {
                    Text("cancel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(cream.opacity(0.85))
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        showMarkPaidConfirm = true
                    } label: {
                        Label("mark paid", systemImage: "checkmark.circle")
                    }
                    .disabled(selectedBillIds.isEmpty || isMarkingPaid)

                    Divider()

                    Button(role: .destructive) {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        showDeleteConfirm = true
                    } label: {
                        Label("delete", systemImage: "trash")
                    }
                    .disabled(selectedBillIds.isEmpty || isDeleting)
                } label: {
                    Text(selectedBillIds.isEmpty
                         ? "actions"
                         : "actions (\(selectedBillIds.count))")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(selectedBillIds.isEmpty
                                         ? cream.opacity(0.4)
                                         : accentPurple)
                }
                .disabled(selectedBillIds.isEmpty)
            }
        } else {
            if !billViewModel.bills.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    ShareLink(
                        item: exportText,
                        subject: Text("my bills"),
                        message: Text("here are my bills")
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(cream.opacity(0.85))
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    // TODO: open add-bill flow
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(cream.opacity(0.85))
                }
            }
        }
    }

    // MARK: - Selection mode

    private func enterSelection(with bill: Bill) {
        guard let id = bill.id else { return }
        withAnimation(.easeInOut(duration: 0.18)) {
            isSelecting = true
            selectedBillIds.insert(id)
        }
    }

    private func toggleSelection(_ bill: Bill) {
        guard let id = bill.id else { return }
        if selectedBillIds.contains(id) {
            selectedBillIds.remove(id)
        } else {
            selectedBillIds.insert(id)
        }
    }

    private func exitSelection() {
        withAnimation(.easeInOut(duration: 0.18)) {
            isSelecting = false
            selectedBillIds.removeAll()
        }
    }

    private func performBulkDelete() {
        let toDelete = billViewModel.bills.filter { bill in
            bill.id.map { selectedBillIds.contains($0) } ?? false
        }
        isDeleting = true
        Task {
            for bill in toDelete {
                await billViewModel.deleteBill(bill)
            }
            await MainActor.run {
                isDeleting = false
                exitSelection()
            }
        }
    }

    private func performBulkMarkPaid() {
        let toMark = billViewModel.bills.filter { bill in
            bill.id.map { selectedBillIds.contains($0) } ?? false
        }
        guard !toMark.isEmpty else { return }
        isMarkingPaid = true
        Task {
            await billViewModel.markBillsAsPaid(toMark)
            await MainActor.run {
                BillPaymentJournal.appendBillPayments(
                    toMark,
                    currency: sessionViewModel.currentUser?.settings.currency ?? "USD",
                    in: modelContext
                )
                isMarkingPaid = false
                exitSelection()
            }
        }
    }

    /// Plain-text export of bills for sharing via iMessage / mail / etc.
    /// One bill per line: "name — $amount — due Mon DD, YYYY".
    private var exportText: String {
        let amountFormatter = NumberFormatter()
        amountFormatter.numberStyle = .currency
        amountFormatter.currencyCode = sessionViewModel.currentUser?.settings.currency ?? "USD"
        amountFormatter.maximumFractionDigits = 2

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"

        let lines = billViewModel.bills
            .sorted { $0.dueDate < $1.dueDate }
            .map { bill -> String in
                let amount = amountFormatter.string(from: NSNumber(value: bill.amount))
                    ?? String(format: "$%.2f", bill.amount)
                let date = dateFormatter.string(from: bill.dueDate)
                return "\(bill.name) — \(amount) — due \(date)"
            }

        return lines.joined(separator: "\n")
    }

    // MARK: - Hero

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(monthLabel)
                .font(.custom(FontFamily.Rubik.medium, size: 13))
                .foregroundStyle(mutedText)

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("\(monthlyBills.count) \(monthlyBills.count == 1 ? "bill" : "bills")")
                    .font(heroFont)
                    .tracking(-2.24)
                    .foregroundStyle(cream)
                Text(".")
                    .font(heroFont)
                    .tracking(-2.24)
                    .foregroundStyle(accentPurple)
            }

            Text("\(formatCurrency(totalAmount)) due across the month.")
                .font(.custom(FontFamily.Rubik.regular, size: 15).italic())
                .foregroundStyle(mutedText)
                .padding(.top, 2)
        }
    }

    // MARK: - Filter capsules

    private var filterCapsules: some View {
        HStack(spacing: 8) {
            tabPill("this month", active: selectedTab == .thisMonth) { selectedTab = .thisMonth }
            tabPill("next month", active: selectedTab == .nextMonth) { selectedTab = .nextMonth }
        }
    }

    @ViewBuilder
    private func tabPill(_ label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                action()
            }
        } label: {
            Text(label)
                .font(.custom(active ? FontFamily.Rubik.semiBold : FontFamily.Rubik.medium, size: 13))
                .foregroundStyle(active ? onAccentText : cream)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background {
                    if active { Capsule().fill(accentPurple) }
                }
                .overlay(
                    Capsule().stroke(
                        active ? accentPurple : cream.opacity(0.32),
                        style: active ? StrokeStyle(lineWidth: 1) : StrokeStyle(lineWidth: 1, dash: [3, 3])
                    )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sections

    @ViewBuilder
    private var sectionsBlock: some View {
        if monthlyBills.isEmpty {
            emptyState
        } else {
            VStack(alignment: .leading, spacing: 0) {
                if !overdueBills.isEmpty {
                    section(
                        title: "overdue",
                        titleColor: accentPurple,
                        dividerColor: accentPurple.opacity(0.25),
                        bills: overdueBills,
                        kind: .overdue
                    )
                }
                if !upcomingBills.isEmpty {
                    section(
                        title: "upcoming",
                        titleColor: cream,
                        dividerColor: cream.opacity(0.12),
                        bills: upcomingBills,
                        kind: .upcoming
                    )
                    .padding(.top, overdueBills.isEmpty ? 0 : 14)
                }
                if !paidBills.isEmpty {
                    section(
                        title: "paid",
                        titleColor: dimText,
                        dividerColor: cream.opacity(0.08),
                        bills: paidBills,
                        kind: .paid
                    )
                    .padding(.top, (overdueBills.isEmpty && upcomingBills.isEmpty) ? 0 : 14)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("nothing \(selectedTab == .thisMonth ? "this month" : "next month")")
                .font(.custom(FontFamily.Rubik.semiBold, size: 16))
                .foregroundStyle(cream.opacity(0.7))
            Text("tap the + above to add a bill.")
                .font(.custom(FontFamily.Rubik.regular, size: 13))
                .foregroundStyle(mutedText)
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private func section(
        title: String,
        titleColor: Color,
        dividerColor: Color,
        bills: [Bill],
        kind: RowKind
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.custom(FontFamily.Rubik.semiBold, size: 11))
                    .tracking(0.88)
                    .textCase(.uppercase)
                    .foregroundStyle(titleColor)
                Rectangle()
                    .fill(dividerColor)
                    .frame(height: 1)
                Text("\(bills.count)")
                    .font(.custom(FontFamily.Rubik.medium, size: 11))
                    .tracking(0.44)
                    .foregroundStyle(dimText)
            }
            .padding(.top, 6)
            .padding(.bottom, 14)

            ForEach(Array(bills.enumerated()), id: \.element.id) { index, bill in
                billRow(bill, kind: kind, showTopDivider: index > 0)
            }
        }
    }

    // MARK: - Row

    private enum RowKind { case overdue, upcoming, paid }

    @ViewBuilder
    private func billRow(_ bill: Bill, kind: RowKind, showTopDivider: Bool) -> some View {
        let isSelected = bill.id.map { selectedBillIds.contains($0) } ?? false
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            if isSelecting {
                toggleSelection(bill)
            } else {
                // TODO: open bill detail / edit sheet
            }
        } label: {
            HStack(spacing: 12) {
                if isSelecting {
                    selectionIndicator(selected: isSelected)
                } else {
                    statusDot(for: kind)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(bill.name.lowercased())
                        .font(.custom(kind == .paid ? FontFamily.Rubik.medium : FontFamily.Rubik.semiBold, size: 16))
                        .tracking(-0.16)
                        .foregroundStyle(kind == .paid ? mutedText : cream)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(eyebrowText(for: bill, kind: kind))
                            .font(.custom(FontFamily.Rubik.medium, size: 12))
                            .tracking(0.48)
                            .textCase(.uppercase)
                            .foregroundStyle(eyebrowColor(for: kind))
                        if kind != .paid {
                            Text(shortDate(bill.effectiveDueDate))
                                .font(.custom(FontFamily.Rubik.regular, size: 12).italic())
                                .foregroundStyle(dimText)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(formatCurrency(bill.amount))
                    .font(.custom(kind == .paid ? FontFamily.Rubik.medium : FontFamily.Rubik.bold, size: 18))
                    .tracking(-0.18)
                    .foregroundStyle(amountColor(for: kind))
                    .strikethrough(kind == .paid, color: dimText)

                if !isSelecting {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(dimText)
                        .frame(width: 16, alignment: .trailing)
                }
            }
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .overlay(alignment: .top) {
                if showTopDivider {
                    Rectangle()
                        .fill(cream.opacity(0.08))
                        .frame(height: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45)
                .onEnded { _ in
                    guard !isSelecting else { return }
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    enterSelection(with: bill)
                }
        )
    }

    private func selectionIndicator(selected: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(selected ? accentPurple : cream.opacity(0.32), lineWidth: 1.5)
                .frame(width: 18, height: 18)
            if selected {
                Circle()
                    .fill(accentPurple)
                    .frame(width: 12, height: 12)
            }
        }
        .frame(width: 18, height: 18)
    }

    private func statusDot(for kind: RowKind) -> some View {
        Group {
            switch kind {
            case .overdue:
                Circle().fill(accentPurple)
            case .upcoming:
                Circle().fill(cream.opacity(0.65))
            case .paid:
                Circle()
                    .stroke(dimText, lineWidth: 1)
            }
        }
        .frame(width: 8, height: 8)
    }

    private func eyebrowColor(for kind: RowKind) -> Color {
        switch kind {
        case .overdue: return accentPurple
        case .upcoming: return mutedText
        case .paid: return dimText
        }
    }

    private func amountColor(for kind: RowKind) -> Color {
        switch kind {
        case .overdue: return accentPurple
        case .upcoming: return cream
        case .paid: return dimText
        }
    }

    // MARK: - Computed: month context

    private var displayedMonthDate: Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: Date())
        let firstOfThisMonth = cal.date(from: comps) ?? Date()
        if selectedTab == .nextMonth {
            return cal.date(byAdding: .month, value: 1, to: firstOfThisMonth) ?? firstOfThisMonth
        }
        return firstOfThisMonth
    }

    private var monthLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: displayedMonthDate).lowercased()
    }

    // MARK: - Computed: bills

    private var monthlyBills: [Bill] {
        let cal = Calendar.current
        return billViewModel.bills
            .filter { bill in
                cal.isDate(bill.effectiveDueDate, equalTo: displayedMonthDate, toGranularity: .month)
            }
            .sorted { $0.effectiveDueDate < $1.effectiveDueDate }
    }

    private var totalAmount: Double {
        monthlyBills.reduce(0) { $0 + $1.amount }
    }

    private var overdueBills: [Bill] {
        let now = Calendar.current.startOfDay(for: Date())
        return monthlyBills.filter { $0.status != .paid && Calendar.current.startOfDay(for: $0.effectiveDueDate) < now }
    }

    private var upcomingBills: [Bill] {
        let now = Calendar.current.startOfDay(for: Date())
        return monthlyBills.filter { $0.status != .paid && Calendar.current.startOfDay(for: $0.effectiveDueDate) >= now }
    }

    private var paidBills: [Bill] {
        monthlyBills.filter { $0.status == .paid }
    }

    // MARK: - Formatting

    private var currency: String {
        sessionViewModel.currentUser?.settings.currency ?? "USD"
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currency) \(Int(amount))"
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date).lowercased()
    }

    private func eyebrowText(for bill: Bill, kind: RowKind) -> String {
        let cal = Calendar.current
        let now = cal.startOfDay(for: Date())
        let due = cal.startOfDay(for: bill.effectiveDueDate)
        let days = cal.dateComponents([.day], from: now, to: due).day ?? 0
        switch kind {
        case .overdue:
            let n = max(0, -days)
            return "overdue \(n)d"
        case .upcoming:
            if days == 0 { return "due today" }
            return "in \(days) \(days == 1 ? "day" : "days")"
        case .paid:
            return "paid \(shortDate(bill.effectiveDueDate))"
        }
    }
}

#Preview {
    Color.black
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            BillsView()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
}
