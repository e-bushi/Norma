//
//  CalendarSheet.swift
//  Norma
//
//  Month grid of when money moves: accent dots for bills, green for paydays.
//  Tapping a day lists what lands on it, and any day can start a new bill.
//

import SwiftData
import SwiftUI

struct CalendarSheet: View {
    let profile: UserProfile

    @Query(sort: \Bill.dueDate) private var bills: [Bill]
    @State private var monthOffset = 0
    @State private var selectedDay = Calendar.current.component(.day, from: Date())
    @State private var sheet: Sheet?

    private enum Sheet: Identifiable {
        case income
        case newBill(Date)
        case editBill(Bill)

        var id: String {
            switch self {
            case .income: return "income"
            case .newBill: return "newBill"
            case .editBill(let bill): return "edit-\(bill.id)"
            }
        }
    }

    private let calendar = Calendar.current

    private var displayedMonth: Date {
        let start = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        return calendar.date(byAdding: .month, value: monthOffset, to: start) ?? start
    }

    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: displayedMonth)?.count ?? 30
    }

    private func date(forDay day: Int) -> Date {
        calendar.date(byAdding: .day, value: day - 1, to: displayedMonth) ?? displayedMonth
    }

    var body: some View {
        let summary = MonthSummary(month: displayedMonth, bills: bills, profile: profile)
        let billsByDay = Dictionary(grouping: summary.occurrences) { calendar.component(.day, from: $0.date) }
        let paydays = Set(summary.paydays.map { calendar.component(.day, from: $0) })

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                hero(summary)
                    .padding(.bottom, 18)

                FlowLayout {
                    ChoicePill(label: "last month", isActive: monthOffset == -1) { select(offset: -1) }
                    ChoicePill(label: "this month", isActive: monthOffset == 0) { select(offset: 0) }
                    ChoicePill(label: "next month", isActive: monthOffset == 1) { select(offset: 1) }
                }
                .padding(.bottom, 22)

                if let note = paydayCollisionNote {
                    Text(note)
                        .font(.custom(FontFamily.Rubik.regular, size: 13))
                        .foregroundStyle(NormaPalette.inkSubtle)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 22)
                }

                grid(billsByDay: billsByDay, paydays: paydays)
                    .padding(.bottom, 22)

                FieldLabel(date(forDay: selectedDay).formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()).lowercased())
                    .padding(.bottom, 10)

                dayDetail(bills: billsByDay[selectedDay] ?? [], isPayday: paydays.contains(selectedDay))
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 32)
        }
        .background(NormaPalette.sheet.ignoresSafeArea())
        .presentationDragIndicator(.visible)
        .sheet(item: $sheet) { sheet in
            switch sheet {
            case .income:
                IncomeEditSheet()
            case .newBill(let date):
                BillEditorSheet(bill: nil, initialDueDate: date, currency: profile.currency)
            case .editBill(let bill):
                BillEditorSheet(bill: bill, currency: profile.currency)
            }
        }
    }

    // MARK: - Hero

    private func hero(_ summary: MonthSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(displayedMonth.formatted(.dateTime.month(.wide).year()).lowercased())
                .font(.custom(FontFamily.Rubik.medium, size: 13))
                .foregroundStyle(NormaPalette.inkSubtle)

            HeroTitle(text: "\(summary.occurrences.count) \(summary.occurrences.count == 1 ? "bill" : "bills")")

            Text(nextUpText(summary))
                .font(.custom(FontFamily.Rubik.regular, size: 15).italic())
                .foregroundStyle(NormaPalette.inkSubtle)
        }
    }

    private func nextUpText(_ summary: MonthSummary) -> String {
        let today = calendar.startOfDay(for: Date())
        guard let next = summary.occurrences.first(where: { !$0.isPaid && $0.date >= today }) else {
            return summary.occurrences.isEmpty ? "nothing due this month." : "all caught up."
        }
        let day = calendar.component(.day, from: next.date)
        let weekday = next.date.formatted(.dateTime.weekday(.abbreviated)).lowercased()
        return "next: \(next.bill.name.lowercased()), \(weekday) the \(day.ordinal)."
    }

    // MARK: - Grid

    private func grid(billsByDay: [Int: [BillOccurrence]], paydays: Set<Int>) -> some View {
        let leading = calendar.component(.weekday, from: displayedMonth) - calendar.firstWeekday
        let offset = (leading + 7) % 7
        let cells: [Int?] = Array(repeating: nil, count: offset) + (1...daysInMonth).map(Optional.some)
        let symbols = Array(calendar.veryShortWeekdaySymbols[(calendar.firstWeekday - 1)...] + calendar.veryShortWeekdaySymbols[..<(calendar.firstWeekday - 1)])

        return VStack(spacing: 6) {
            HStack(spacing: 0) {
                ForEach(symbols.indices, id: \.self) { index in
                    Text(symbols[index])
                        .font(.custom(FontFamily.Rubik.semiBold, size: 10))
                        .foregroundStyle(NormaPalette.inkMuted)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 6)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                ForEach(cells.indices, id: \.self) { index in
                    if let day = cells[index] {
                        dayCell(day, bills: billsByDay[day] ?? [], isPayday: paydays.contains(day))
                    } else {
                        Color.clear.frame(height: 48)
                    }
                }
            }
        }
    }

    private func dayCell(_ day: Int, bills: [BillOccurrence], isPayday: Bool) -> some View {
        let isSelected = day == selectedDay
        let isToday = calendar.isDateInToday(date(forDay: day))
        let hasOverdue = bills.contains { $0.isOverdue() }

        return Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { selectedDay = day }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        Circle().fill(NormaPalette.lavender)
                    } else if isToday {
                        Circle().strokeBorder(NormaPalette.lavender.opacity(0.85), lineWidth: 1)
                    }
                    Text("\(day)")
                        .font(.custom(isSelected || isToday ? FontFamily.Rubik.semiBold : FontFamily.Rubik.medium, size: 14))
                        .foregroundStyle(isSelected ? NormaPalette.onAccent : (isToday ? NormaPalette.lavender : NormaPalette.ink))
                }
                .frame(width: 32, height: 32)

                HStack(spacing: 3) {
                    if !bills.isEmpty {
                        Circle()
                            .fill(hasOverdue ? NormaPalette.warning : NormaPalette.lavender)
                            .frame(width: 4, height: 4)
                    }
                    if isPayday {
                        Circle().fill(NormaPalette.income).frame(width: 4, height: 4)
                    }
                }
                .frame(height: 4)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Day detail

    private func dayDetail(bills: [BillOccurrence], isPayday: Bool) -> some View {
        VStack(spacing: 8) {
            if isPayday {
                detailRow(
                    title: "payday",
                    subtitle: profile.incomeCadence.label,
                    amount: "+" + Money.format(profile.incomeAmount, currency: profile.currency),
                    tint: NormaPalette.income
                ) { sheet = .income }
            }

            ForEach(bills) { occurrence in
                detailRow(
                    title: occurrence.bill.name.lowercased(),
                    subtitle: occurrence.isPaid ? "paid" : (occurrence.isOverdue() ? "overdue" : occurrence.bill.frequency.label),
                    amount: Money.format(occurrence.bill.amount, currency: profile.currency),
                    tint: occurrence.isOverdue() ? NormaPalette.warning : NormaPalette.lavender
                ) { sheet = .editBill(occurrence.bill) }
            }

            if bills.isEmpty && !isPayday {
                Text("nothing due.")
                    .font(.custom(FontFamily.Rubik.medium, size: 13))
                    .foregroundStyle(NormaPalette.inkMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            }

            addBillButton
                .padding(.top, 6)
        }
    }

    private func detailRow(title: String, subtitle: String, amount: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(tint)
                    .frame(width: 3, height: 32)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.custom(FontFamily.Rubik.semiBold, size: 16))
                        .foregroundStyle(NormaPalette.ink)
                    Text(subtitle)
                        .font(.custom(FontFamily.Rubik.medium, size: 12))
                        .foregroundStyle(tint)
                }
                Spacer(minLength: 8)
                Text(amount)
                    .font(.custom(FontFamily.Rubik.semiBold, size: 17))
                    .foregroundStyle(NormaPalette.ink)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(NormaPalette.ink.opacity(0.04)))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(NormaPalette.ink.opacity(0.08)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var addBillButton: some View {
        let selected = date(forDay: selectedDay)
        return Button {
            Haptics.tap()
            sheet = .newBill(selected)
        } label: {
            Label("add a bill on \(selected.formatted(.dateTime.month(.abbreviated).day()).lowercased())", systemImage: "plus")
                .font(.custom(FontFamily.Rubik.semiBold, size: 14))
                .foregroundStyle(NormaPalette.lavender)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Capsule().fill(NormaPalette.lavender.opacity(0.12)))
                .overlay(Capsule().strokeBorder(NormaPalette.lavender.opacity(0.4)))
        }
        .buttonStyle(.plain)
    }

    private var paydayCollisionNote: String? {
        guard profile.hasIncome else { return nil }
        return profile.incomeCadence.collisionNote(inMonthOf: displayedMonth, calendar: calendar)
    }

    private func select(offset: Int) {
        monthOffset = offset
        selectedDay = offset == 0 ? calendar.component(.day, from: Date()) : 1
    }
}
