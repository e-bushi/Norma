//
//  HomeView.swift
//  Norma
//
//  The whole app on one screen: this month's income, minus the bills due in
//  it, is what's left — then the bills themselves, grouped by what needs
//  attention. Settings and the calendar open as sheets.
//

import SwiftData
import SwiftUI

struct HomeView: View {
    let profile: UserProfile

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Bill.dueDate) private var bills: [Bill]

    @State private var monthOffset = 0
    @State private var sheet: Sheet?
    @State private var pendingDeleteID: UUID?
    @State private var saveError: String?

    private enum Sheet: Identifiable {
        case settings, calendar, income
        case newBill(dueDate: Date?)
        case editBill(Bill)

        var id: String {
            switch self {
            case .settings: return "settings"
            case .calendar: return "calendar"
            case .income: return "income"
            case .newBill: return "newBill"
            case .editBill(let bill): return "edit-\(bill.id)"
            }
        }
    }

    private var displayedMonth: Date {
        Calendar.current.date(byAdding: .month, value: monthOffset, to: ScreenshotMode.now) ?? ScreenshotMode.now
    }

    var body: some View {
        let summary = MonthSummary(month: displayedMonth, bills: bills, profile: profile)

        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    topBar
                        .padding(.bottom, 40)

                    LeftoverHeader(
                        summary: summary,
                        currency: profile.currency,
                        hasIncome: profile.hasIncome,
                        collisionNote: profile.hasIncome ? profile.incomeCadence.collisionNote(inMonthOf: summary.month) : nil
                    ) {
                        sheet = .income
                    }
                    .padding(.bottom, 24)

                    monthPills
                        .padding(.bottom, 28)

                    billSections(summary)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 120)
            }
            .task {
                // Accessibility type pushes the first bill under the add button.
                // Scroll it to the center so the whole row is in the screenshot.
                guard ScreenshotMode.isActive, ScreenshotMode.dynamicTypeSize.isAccessibilitySize else { return }
                try? await Task.sleep(nanoseconds: 200_000_000)
                proxy.scrollTo("bill-row-rent", anchor: .center)
            }
        }
        .background(NormaPalette.canvas.ignoresSafeArea())
        .overlay(alignment: .bottom) { addBillButton }
        .modifier(ScreenshotHomeMarker())
        .sheet(item: $sheet, content: sheetContent)
        .alert(
            "delete \(billPendingDelete?.name.lowercased() ?? "this bill")?",
            isPresented: Binding(
                get: { pendingDeleteID != nil },
                set: { if !$0 { pendingDeleteID = nil } }
            ),
            presenting: billPendingDelete
        ) { bill in
            Button("cancel", role: .cancel) {}
            Button("delete", role: .destructive) { delete(bill) }
        } message: { _ in
            Text("it'll be removed from every month. there's no backup.")
        }
        .alert(
            "couldn't save",
            isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )
        ) {
            Button("ok", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
        .task(id: bills.count) {
            guard !ScreenshotMode.isActive else { return }
            await NotificationService.rescheduleAll(bills, currency: profile.currency)
        }
    }

    private var billPendingDelete: Bill? {
        bills.first { $0.id == pendingDeleteID }
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
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(NormaPalette.ink.opacity(0.9))
                .frame(width: 44, height: 44)
                .glassEffect(.regular.interactive(), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var monthPills: some View {
        FlowLayout {
            ChoicePill(label: "last month", isActive: monthOffset == -1) { monthOffset = -1 }
            ChoicePill(label: "this month", isActive: monthOffset == 0) { monthOffset = 0 }
            ChoicePill(label: "next month", isActive: monthOffset == 1) { monthOffset = 1 }
        }
    }

    private var monthWord: String {
        switch monthOffset {
        case ..<0: return "last"
        case 0: return "this"
        default: return "next"
        }
    }

    // MARK: - Bills

    @ViewBuilder
    private func billSections(_ summary: MonthSummary) -> some View {
        let today = ScreenshotMode.now
        let overdue = overdueItems(in: summary, today: today)
        let upcoming = summary.occurrences.filter { !$0.isPaid && !$0.isOverdue(today: today) }
        let paid = summary.occurrences.filter(\.isPaid)

        if bills.isEmpty {
            emptyState
        } else if summary.occurrences.isEmpty && overdue.isEmpty {
            Text("no bills due \(monthWord) month.")
                .font(.custom(FontFamily.Rubik.medium, size: 14))
                .foregroundStyle(NormaPalette.inkMuted)
                .padding(.vertical, 8)
        } else {
            VStack(alignment: .leading, spacing: 28) {
                section("overdue", overdue, tint: NormaPalette.warning)
                section("coming up", upcoming)
                section("paid", paid)
            }
        }
    }

    /// This month also keeps unpaid occurrences from earlier months in Overdue.
    private func overdueItems(in summary: MonthSummary, today: Date) -> [BillOccurrence] {
        let carried =
            Calendar.current.isDate(summary.month, equalTo: today, toGranularity: .month)
            ? summary.earlierUnpaid
            : []
        return carried + summary.occurrences.filter { $0.isOverdue(today: today) }
    }

    @ViewBuilder
    private func section(_ title: String, _ items: [BillOccurrence], tint: Color = NormaPalette.inkSubtle) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    FieldLabel(title, color: tint)
                    Spacer()
                    Text(Money.format(minorUnits: totalMinor(items), currency: profile.currency))
                        .font(.custom(FontFamily.Rubik.medium, size: 12))
                        .foregroundStyle(tint)
                        .amountStaysOneLine()
                }
                .padding(.bottom, 4)

                ForEach(items) { occurrence in
                    BillRow(occurrence: occurrence, currency: profile.currency) {
                        togglePaid(occurrence)
                    } onEdit: {
                        sheet = .editBill(occurrence.bill)
                    } onDelete: {
                        pendingDeleteID = occurrence.bill.id
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("no bills yet.")
                .font(.custom(FontFamily.Rubik.semiBold, size: 17))
                .foregroundStyle(NormaPalette.ink)
            Text("add rent, your phone, subscriptions — anything that comes due. norma subtracts them from your paycheck.")
                .font(.custom(FontFamily.Rubik.regular, size: 14))
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
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(NormaPalette.onAccent)
                .padding(.horizontal, 22)
                .padding(.vertical, 15)
                .background(Capsule().fill(NormaPalette.lavender))
                .shadow(color: NormaPalette.lavender.opacity(0.4), radius: 18, y: 10)
        }
        .buttonStyle(PressableButtonStyle())
        .padding(.bottom, 12)
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

    private func totalMinor(_ items: [BillOccurrence]) -> Int {
        items.reduce(0) { $0 + Money.minorUnits(fromMajor: $1.bill.amount, currency: profile.currency) }
    }

    private func togglePaid(_ occurrence: BillOccurrence) {
        let bill = occurrence.bill
        withAnimation(.snappy) {
            bill.setPaid(!occurrence.isPaid, for: occurrence.date)
        }
        guard Persistence.save(modelContext) else {
            saveError = Persistence.saveFailure
            return
        }
        if !occurrence.isPaid { Haptics.success() } else { Haptics.tap() }
        Task { await NotificationService.scheduleReminders(for: bill, currency: profile.currency) }
    }

    private func delete(_ bill: Bill) {
        let billID = bill.id
        withAnimation(.snappy) { modelContext.delete(bill) }
        guard Persistence.save(modelContext) else {
            saveError = Persistence.saveFailure
            return
        }
        NotificationService.cancelReminders(forBillID: billID)
    }
}

// MARK: - Leftover header

/// "october · left after bills", the big number, and the in/out breakdown.
private struct LeftoverHeader: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let summary: MonthSummary
    let currency: String
    let hasIncome: Bool
    var collisionNote: String? = nil
    let onEditIncome: () -> Void

    private var monthName: String {
        summary.month.formatted(.dateTime.month(.wide)).lowercased()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            FieldLabel("\(monthName) · left after bills")

            (Text(Money.format(minorUnits: summary.leftoverMinor, currency: currency))
                .foregroundStyle(summary.isShortfall ? NormaPalette.warning : NormaPalette.ink)
                + Text(".").foregroundStyle(NormaPalette.lavender))
                .font(.system(size: 64, weight: .heavy))
                .tracking(-2.5)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(1)
                .contentTransition(.numericText(value: Double(summary.leftoverMinor)))
                .animation(ScreenshotMode.animation, value: summary.leftoverMinor)

            Text("income minus every bill due this month.")
                .font(.custom(FontFamily.Rubik.regular, size: 13))
                .foregroundStyle(NormaPalette.inkSubtle)
                .fixedSize(horizontal: false, vertical: true)

            breakdown

            if let collisionNote {
                Text(collisionNote)
                    .font(.custom(FontFamily.Rubik.regular, size: 13))
                    .foregroundStyle(NormaPalette.inkSubtle)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if summary.billsMinor > 0 {
                SpendBar(summary: summary)
                    .padding(.top, 6)
            }
        }
    }

    private var breakdown: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) {
                    incomeLabel
                    billsLabel
                }
            } else {
                HStack(spacing: 6) {
                    incomeLabel
                    Text("·").foregroundStyle(NormaPalette.inkMuted)
                    billsLabel
                }
            }
        }
        .font(.custom(FontFamily.Rubik.medium, size: 15))
        .contentTransition(.numericText())
        .animation(ScreenshotMode.animation, value: summary.billsMinor)
    }

    private var incomeLabel: some View {
        Button {
            Haptics.tap()
            onEditIncome()
        } label: {
            if hasIncome {
                Text("\(Money.format(minorUnits: summary.incomeMinor, currency: currency)) in")
                    .foregroundStyle(NormaPalette.income)
                    .underline(color: NormaPalette.income.opacity(0.35))
                    .amountStaysOneLine()
            } else {
                Text("add your income")
                    .foregroundStyle(NormaPalette.lavender)
                    .underline(color: NormaPalette.lavender.opacity(0.5))
                    .amountStaysOneLine()
            }
        }
        .buttonStyle(.plain)
    }

    private var billsLabel: some View {
        Text("\(Money.format(minorUnits: summary.billsMinor, currency: currency)) in bills")
            .foregroundStyle(NormaPalette.inkSubtle)
            .amountStaysOneLine()
    }
}

/// Income as a bar: paid bills, bills still to pay, and what's left. When
/// bills outrun income the bar fills completely and turns to the warning color.
private struct SpendBar: View {
    let summary: MonthSummary

    var body: some View {
        let total = max(summary.incomeMinor, summary.billsMinor)
        let overspent = summary.billsMinor > summary.incomeMinor
        let fill = overspent ? NormaPalette.warning : NormaPalette.lavender

        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geo in
                HStack(spacing: 2) {
                    segment(fraction(summary.paidMinor, total), width: geo.size.width, color: fill)
                    segment(fraction(summary.unpaidMinor, total), width: geo.size.width, color: fill.opacity(0.35))
                    if !overspent {
                        segment(fraction(summary.leftoverMinor, total), width: geo.size.width, color: NormaPalette.ink.opacity(0.08))
                    }
                }
            }
            .frame(height: 6)
            .animation(ScreenshotMode.animation, value: summary.paidMinor)

            HStack(spacing: 14) {
                legend("paid", color: fill)
                legend("to pay", color: fill.opacity(0.35))
            }
        }
    }

    private func fraction(_ part: Int, _ total: Int) -> Double {
        guard total > 0 else { return 0 }
        return Double(part) / Double(total)
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
                .font(.custom(FontFamily.Rubik.medium, size: 11))
                .foregroundStyle(NormaPalette.inkMuted)
        }
    }
}

// MARK: - Bill row

private struct BillRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let occurrence: BillOccurrence
    let currency: String
    let onTogglePaid: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var bill: Bill { occurrence.bill }

    var body: some View {
        HStack(alignment: dynamicTypeSize.isAccessibilitySize ? .top : .center, spacing: 14) {
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
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(NormaPalette.onAccent)
                    }
                }
                .frame(width: 26, height: 26)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(occurrence.isPaid ? "mark unpaid" : "mark paid")
            .padding(.leading, -9)

            Button(action: onEdit) {
                details
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .id("bill-row-\(bill.name.lowercased())")
        .padding(.vertical, 2)
        .contextMenu {
            Button(occurrence.isPaid ? "mark unpaid" : "mark paid", systemImage: occurrence.isPaid ? "circle" : "checkmark.circle", action: onTogglePaid)
            Button("edit", systemImage: "pencil", action: onEdit)
            Button("delete", systemImage: "trash", role: .destructive, action: onDelete)
        }
    }

    @ViewBuilder
    private var details: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 3) {
                nameAndDate
                amountLabel
            }
        } else {
            HStack(spacing: 12) {
                nameAndDate
                Spacer(minLength: 8)
                amountLabel
            }
        }
    }

    private var nameAndDate: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(bill.name.lowercased())
                .font(.custom(FontFamily.Rubik.semiBold, size: 16))
                .foregroundStyle(occurrence.isPaid ? NormaPalette.inkSubtle : NormaPalette.ink)
                .strikethrough(occurrence.isPaid, color: NormaPalette.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
            Text(dueLabel)
                .font(.custom(FontFamily.Rubik.medium, size: 12))
                .foregroundStyle(statusColor)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var amountLabel: some View {
        Text(Money.format(bill.amount, currency: currency))
            .font(.custom(FontFamily.Rubik.semiBold, size: 16))
            .foregroundStyle(occurrence.isPaid ? NormaPalette.inkSubtle : NormaPalette.ink)
            .amountStaysOneLine()
            .accessibilityIdentifier("bill-amount-\(bill.name.lowercased())")
    }

    private var statusColor: Color {
        if occurrence.isPaid { return NormaPalette.inkMuted }
        if occurrence.isOverdue(today: ScreenshotMode.now) { return NormaPalette.warning }
        return NormaPalette.inkSubtle
    }

    private var dueLabel: String {
        let calendar = Calendar.current
        let date = occurrence.date.formatted(.dateTime.month(.abbreviated).day()).lowercased()
        let frequency = bill.frequency == .oneTime ? "" : " · \(bill.frequency.label)"
        if occurrence.isPaid { return "paid · \(date)" }
        if occurrence.isOverdue(today: ScreenshotMode.now) {
            let days = calendar.dateComponents([.day], from: occurrence.date, to: calendar.startOfDay(for: ScreenshotMode.now)).day ?? 0
            return "\(date) · \(days) \(days == 1 ? "day" : "days") late"
        }
        if calendar.isDateInToday(occurrence.date) { return "due today" + frequency }
        if calendar.isDateInTomorrow(occurrence.date) { return "due tomorrow" + frequency }
        return date + frequency
    }
}

extension View {
    /// An amount never breaks across lines. The name and date beside it wrap.
    fileprivate func amountStaysOneLine() -> some View {
        lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .layoutPriority(1)
    }
}
