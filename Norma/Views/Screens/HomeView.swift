//
//  HomeView.swift
//  Norma
//
//  The whole app on one screen: this month's income, minus the bills due in
//  it, is what's left — then the bills themselves, grouped by what needs
//  attention. Settings and the calendar open as sheets.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    let profile: UserProfile

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Bill.dueDate) private var bills: [Bill]

    @State private var monthOffset = 0
    @State private var sheet: Sheet?

    private enum Sheet: Identifiable {
        case settings, calendar, income
        case newBill(dueDate: Date?)
        case editBill(Bill)

        var id: String {
            switch self {
            case .settings:          return "settings"
            case .calendar:          return "calendar"
            case .income:            return "income"
            case .newBill:           return "newBill"
            case .editBill(let bill): return "edit-\(bill.id)"
            }
        }
    }

    private var displayedMonth: Date {
        Calendar.current.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
    }

    var body: some View {
        let summary = MonthSummary(month: displayedMonth, bills: bills, profile: profile)

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                topBar
                    .padding(.bottom, 40)

                LeftoverHeader(summary: summary, currency: profile.currency, hasIncome: profile.hasIncome) {
                    sheet = .income
                }
                .padding(.bottom, 24)

                monthPills
                    .padding(.bottom, 28)

                billSections(summary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(NormaPalette.canvas.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            addBillButton
                .padding(.top, 8)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity)
                .background(NormaPalette.canvas)
        }
        .sheet(item: $sheet, content: sheetContent)
        .task(id: bills.count) {
            await NotificationService.rescheduleAll(bills, currency: profile.currency)
        }
    }

    // MARK: - Top

    private var topBar: some View {
        HStack {
            circleButton("gearshape", label: "settings") { sheet = .settings }
            Spacer()
            circleButton("calendar", label: "calendar") { sheet = .calendar }
        }
        .padding(.top, 8)
    }

    private func circleButton(_ systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .medium, relativeTo: .body))
                .foregroundStyle(NormaPalette.ink.opacity(0.9))
                .frame(width: 44, height: 44)
                .glassEffect(.regular.interactive(), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var monthPills: some View {
        HStack(spacing: 8) {
            ChoicePill(label: "this month", isActive: monthOffset == 0) { monthOffset = 0 }
            ChoicePill(label: "next month", isActive: monthOffset == 1) { monthOffset = 1 }
        }
    }

    // MARK: - Bills

    @ViewBuilder
    private func billSections(_ summary: MonthSummary) -> some View {
        if bills.isEmpty {
            emptyState
        } else if summary.occurrences.isEmpty {
            Text("no bills due \(monthOffset == 0 ? "this" : "next") month.")
                .rubik(FontFamily.Rubik.medium, size: 14, relativeTo: .subheadline)
                .foregroundStyle(NormaPalette.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 8)
        } else {
            let overdue = summary.occurrences.filter { $0.isOverdue() }
            let upcoming = summary.occurrences.filter { !$0.isPaid && !$0.isOverdue() }
            let paid = summary.occurrences.filter(\.isPaid)

            VStack(alignment: .leading, spacing: 28) {
                section("overdue", overdue, tint: NormaPalette.warning)
                section("coming up", upcoming)
                section("paid", paid)
            }
        }
    }

    @ViewBuilder
    private func section(_ title: String, _ items: [BillOccurrence], tint: Color = NormaPalette.inkSubtle) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    FieldLabel(title, color: tint)
                    Spacer()
                    Text(Money.format(items.reduce(0) { $0 + $1.bill.amount }, currency: profile.currency))
                        .rubik(FontFamily.Rubik.medium, size: 12, relativeTo: .caption)
                        .foregroundStyle(tint)
                }
                .padding(.bottom, 4)

                ForEach(items) { occurrence in
                    BillRow(occurrence: occurrence, currency: profile.currency) {
                        togglePaid(occurrence)
                    } onEdit: {
                        sheet = .editBill(occurrence.bill)
                    } onDelete: {
                        delete(occurrence.bill)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("no bills yet.")
                .rubik(FontFamily.Rubik.semiBold, size: 17, relativeTo: .body)
                .foregroundStyle(NormaPalette.ink)
            Text("add rent, your phone, subscriptions — anything that comes due. norma subtracts them from your paycheck.")
                .rubik(FontFamily.Rubik.regular, size: 14, relativeTo: .subheadline)
                .foregroundStyle(NormaPalette.inkSubtle)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(NormaPalette.ink.opacity(0.04)))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(NormaPalette.ink.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        )
    }

    private var addBillButton: some View {
        Button {
            Haptics.tap()
            sheet = .newBill(dueDate: nil)
        } label: {
            Label("add bill", systemImage: "plus")
                .font(.system(size: 15, weight: .semibold, relativeTo: .headline))
                .foregroundStyle(NormaPalette.onAccent)
                .padding(.horizontal, 22)
                .padding(.vertical, 15)
                .background(Capsule().fill(NormaPalette.lavender))
                .shadow(color: NormaPalette.lavender.opacity(0.4), radius: 18, y: 10)
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: - Sheets

    @ViewBuilder
    private func sheetContent(_ sheet: Sheet) -> some View {
        switch sheet {
        case .settings:
            SettingsView(profile: profile)
        case .calendar:
            CalendarSheet(profile: profile)
        case .income:
            IncomeEditSheet()
        case .newBill(let dueDate):
            BillEditorSheet(bill: nil, initialDueDate: dueDate, currency: profile.currency)
        case .editBill(let bill):
            BillEditorSheet(bill: bill, currency: profile.currency)
        }
    }

    // MARK: - Actions

    private func togglePaid(_ occurrence: BillOccurrence) {
        let bill = occurrence.bill
        withAnimation(.snappy) {
            bill.setPaid(!occurrence.isPaid, for: occurrence.date)
        }
        try? modelContext.save()
        if !occurrence.isPaid { Haptics.success() } else { Haptics.tap() }
        Task { await NotificationService.scheduleReminders(for: bill, currency: profile.currency) }
    }

    private func delete(_ bill: Bill) {
        NotificationService.cancelReminders(for: bill)
        withAnimation(.snappy) { modelContext.delete(bill) }
        try? modelContext.save()
    }
}

// MARK: - Leftover header

/// "october · left after bills", the big number, and the in/out breakdown.
private struct LeftoverHeader: View {
    let summary: MonthSummary
    let currency: String
    let hasIncome: Bool
    let onEditIncome: () -> Void

    private var monthName: String {
        summary.month.formatted(.dateTime.month(.wide)).lowercased()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            FieldLabel("\(monthName) · left after bills")

            (Text(Money.format(summary.leftover, currency: currency, wholeUnits: true))
                .foregroundStyle(summary.leftover < 0 ? NormaPalette.warning : NormaPalette.ink)
                + Text(".").foregroundStyle(NormaPalette.lavender))
                .font(.system(size: 64, weight: .heavy, relativeTo: .largeTitle))
                .tracking(-2.5)
                // The accent period can drop to the next line. The number never
                // shrinks to half; 0.75 is only the last-resort fit.
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.numericText(value: summary.leftover))
                .animation(.snappy, value: summary.leftover)

            breakdown

            if summary.billsTotal > 0 {
                SpendBar(summary: summary, currency: currency)
                    .padding(.top, 6)
            }
        }
    }

    private var breakdown: some View {
        VStack(alignment: .leading, spacing: 6) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 6) { incomeButton; dot; billsTotal }
                VStack(alignment: .leading, spacing: 4) { incomeButton; billsTotal }
            }
            .rubik(FontFamily.Rubik.medium, size: 15, relativeTo: .subheadline)
            .contentTransition(.numericText())
            .animation(.snappy, value: summary.billsTotal)

            if let paydayLine = PaydaySubtitle.line(for: summary.paydays) {
                Text(paydayLine)
                    .rubik(FontFamily.Rubik.regular, size: 13, relativeTo: .footnote)
                    .foregroundStyle(NormaPalette.inkSubtle)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var incomeButton: some View {
        Button {
            Haptics.tap()
            onEditIncome()
        } label: {
            if hasIncome {
                Text("\(Money.format(summary.income, currency: currency, wholeUnits: true)) in")
                    .foregroundStyle(NormaPalette.income)
                    .underline(color: NormaPalette.income.opacity(0.35))
            } else {
                Text("add your income")
                    .foregroundStyle(NormaPalette.lavender)
                    .underline(color: NormaPalette.lavender.opacity(0.5))
            }
        }
        .buttonStyle(.plain)
    }

    private var dot: some View {
        Text("·").foregroundStyle(NormaPalette.inkMuted)
    }

    private var billsTotal: some View {
        Text("\(Money.format(summary.billsTotal, currency: currency, wholeUnits: true)) in bills")
            .foregroundStyle(NormaPalette.inkSubtle)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Income as a bar: paid bills, bills still to pay, and what's left. When
/// bills outrun income the bar fills completely and turns to the warning color.
private struct SpendBar: View {
    let summary: MonthSummary
    let currency: String

    var body: some View {
        let total = max(summary.income, summary.billsTotal)
        let overspent = summary.billsTotal > summary.income
        let fill = overspent ? NormaPalette.warning : NormaPalette.lavender

        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geo in
                HStack(spacing: 2) {
                    segment(summary.paidTotal / total, width: geo.size.width, color: fill)
                    segment(summary.unpaidTotal / total, width: geo.size.width, color: fill.opacity(0.35))
                    if !overspent {
                        segment(summary.leftover / total, width: geo.size.width, color: NormaPalette.ink.opacity(0.08))
                    }
                }
            }
            .frame(height: 6)
            .animation(.snappy, value: summary.paidTotal)

            HStack(spacing: 14) {
                legend("paid", color: fill)
                legend("to pay", color: fill.opacity(0.35))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        let paid = Money.format(summary.paidTotal, currency: currency)
        let unpaid = Money.format(summary.unpaidTotal, currency: currency)
        let bills = Money.format(summary.billsTotal, currency: currency)
        if summary.billsTotal > summary.income {
            let over = Money.format(summary.billsTotal - summary.income, currency: currency)
            return "Spend bar. Bills \(bills) are \(over) over income. \(paid) paid, \(unpaid) still to pay."
        }
        let left = Money.format(summary.leftover, currency: currency)
        return "Spend bar. \(paid) paid, \(unpaid) still to pay, \(left) left."
    }

    private func segment(_ fraction: Double, width: CGFloat, color: Color) -> some View {
        Capsule()
            .fill(color)
            .frame(width: max(0, width * fraction - 2))
    }

    private func legend(_ label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
                .rubik(FontFamily.Rubik.medium, size: 11, relativeTo: .caption2)
                .foregroundStyle(NormaPalette.inkMuted)
        }
    }
}

// MARK: - Bill row

private struct BillRow: View {
    let occurrence: BillOccurrence
    let currency: String
    let onTogglePaid: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var bill: Bill { occurrence.bill }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            paidMark
                .padding(.leading, -9)

            Button(action: onEdit) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        details
                        Spacer(minLength: 8)
                        amount
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        details
                        amount
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button(occurrence.isPaid ? "mark unpaid" : "mark paid", systemImage: occurrence.isPaid ? "circle" : "checkmark.circle", action: onTogglePaid)
            Button("edit", systemImage: "pencil", action: onEdit)
            Button("delete", systemImage: "trash", role: .destructive, action: onDelete)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(rowAccessibilityLabel)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(.default) { onEdit() }
        .accessibilityAction(named: occurrence.isPaid ? "Mark unpaid" : "Mark paid") { onTogglePaid() }
        .accessibilityAction(named: "Edit") { onEdit() }
        .accessibilityAction(named: "Delete") { onDelete() }
    }

    private var paidMark: some View {
        Button(action: onTogglePaid) {
            ZStack {
                Circle()
                    .strokeBorder(
                        occurrence.isPaid ? NormaPalette.lavender : statusColor.opacity(0.7),
                        style: occurrence.isPaid ? StrokeStyle(lineWidth: 1.5) : StrokeStyle(lineWidth: 1.5, dash: [3, 3])
                    )
                if occurrence.isPaid {
                    Circle().fill(NormaPalette.lavender).padding(3)
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold, relativeTo: .caption2))
                        .foregroundStyle(NormaPalette.onAccent)
                }
            }
            .frame(width: 26, height: 26)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHidden(true)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(bill.name.lowercased())
                .rubik(FontFamily.Rubik.semiBold, size: 16, relativeTo: .body)
                .foregroundStyle(occurrence.isPaid ? NormaPalette.inkSubtle : NormaPalette.ink)
                .strikethrough(occurrence.isPaid, color: NormaPalette.inkMuted)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            if let notesLine {
                Text(notesLine)
                    .rubik(FontFamily.Rubik.regular, size: 13, relativeTo: .footnote)
                    .foregroundStyle(NormaPalette.inkSubtle)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(dueLabel)
                .rubik(FontFamily.Rubik.medium, size: 12, relativeTo: .caption)
                .foregroundStyle(statusColor)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var amount: some View {
        Text(Money.format(bill.amount, currency: currency))
            .rubik(FontFamily.Rubik.semiBold, size: 16, relativeTo: .body)
            .foregroundStyle(occurrence.isPaid ? NormaPalette.inkSubtle : NormaPalette.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
    }

    private var notesLine: String? {
        let trimmed = bill.notes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private var rowAccessibilityLabel: String {
        var parts = [bill.name.lowercased(), Money.format(bill.amount, currency: currency)]
        if let notesLine { parts.append(notesLine) }
        parts.append(dueLabel)
        return parts.joined(separator: ", ")
    }

    private var statusColor: Color {
        if occurrence.isPaid { return NormaPalette.inkMuted }
        if occurrence.isOverdue() { return NormaPalette.warning }
        return NormaPalette.inkSubtle
    }

    private var dueLabel: String {
        let calendar = Calendar.current
        let date = occurrence.date.formatted(.dateTime.month(.abbreviated).day()).lowercased()
        let frequency = bill.frequency == .oneTime ? "" : " · \(bill.frequency.label)"
        if occurrence.isPaid { return "paid · \(date)" }
        if occurrence.isOverdue() {
            let days = calendar.dateComponents([.day], from: occurrence.date, to: calendar.startOfDay(for: Date())).day ?? 0
            return "\(date) · \(days) \(days == 1 ? "day" : "days") late"
        }
        if calendar.isDateInToday(occurrence.date) { return "due today" + frequency }
        if calendar.isDateInTomorrow(occurrence.date) { return "due tomorrow" + frequency }
        return date + frequency
    }
}
