//
//  MonthSummary.swift
//  Norma
//
//  The app's one number: income for a month, minus the bills that fall in
//  it, is what's left. Built fresh from the bills and the profile whenever
//  either changes, so nothing derived is ever stored.
//
//  Income, bills, and leftover are integer minor units of the profile's
//  currency, rounded once, so the three figures always add up. Unpaid
//  occurrences from before the month are listed separately and are not part
//  of this month's number.
//

import Foundation

/// One bill's due date within a month.
struct BillOccurrence: Identifiable {
    let bill: Bill
    let date: Date
    let isPaid: Bool

    var id: String { "\(bill.id.uuidString)-\(date.timeIntervalSinceReferenceDate)" }

    func isOverdue(today: Date = Date(), calendar: Calendar = .current) -> Bool {
        !isPaid && date < calendar.startOfDay(for: today)
    }
}

struct MonthSummary {
    let month: Date
    let currency: String
    /// Minor units (cents, or whole yen).
    let incomeMinor: Int
    let paydays: [Date]
    /// Every bill occurrence in the month, earliest first.
    let occurrences: [BillOccurrence]
    /// Unpaid occurrences from before this month. Shown in Overdue until paid.
    /// Not included in `billsMinor` — what's left is still this month only.
    let earlierUnpaid: [BillOccurrence]

    init(month: Date, bills: [Bill], profile: UserProfile?, currency: String? = nil, calendar: Calendar = .current) {
        let interval =
            calendar.dateInterval(of: .month, for: month)
            ?? DateInterval(start: month, duration: 0)
        let lastDay = calendar.date(byAdding: .day, value: -1, to: interval.end) ?? interval.start
        let code = profile?.currency ?? currency ?? "USD"

        self.month = interval.start
        self.currency = code
        self.paydays = profile?.paydays(from: interval.start, through: lastDay, calendar: calendar) ?? []
        self.incomeMinor = Self.incomeMinor(
            profile: profile,
            monthStart: interval.start,
            lastDay: lastDay,
            currency: code,
            calendar: calendar
        )
        self.occurrences =
            bills
            .flatMap { bill in
                bill.occurrences(from: interval.start, through: lastDay, calendar: calendar).map { date in
                    BillOccurrence(bill: bill, date: date, isPaid: bill.isPaid(date, calendar: calendar))
                }
            }
            .sorted { ($0.date, $0.bill.name) < ($1.date, $1.bill.name) }

        let dayBeforeMonth = calendar.date(byAdding: .day, value: -1, to: interval.start) ?? interval.start
        self.earlierUnpaid =
            bills
            .flatMap { bill in
                bill.occurrences(from: bill.dueDate, through: dayBeforeMonth, calendar: calendar).map { date in
                    BillOccurrence(bill: bill, date: date, isPaid: bill.isPaid(date, calendar: calendar))
                }
            }
            .filter { !$0.isPaid }
            .sorted { ($0.date, $0.bill.name) < ($1.date, $1.bill.name) }
    }

    var billsMinor: Int { occurrences.reduce(0) { $0 + Money.minorUnits(fromMajor: $1.bill.amount, currency: currency) } }
    var paidMinor: Int { occurrences.filter(\.isPaid).reduce(0) { $0 + Money.minorUnits(fromMajor: $1.bill.amount, currency: currency) } }
    var unpaidMinor: Int { billsMinor - paidMinor }
    var leftoverMinor: Int { incomeMinor - billsMinor }
    /// True only when the rounded leftover is actually negative. A value that
    /// rounds to zero is not a shortfall.
    var isShortfall: Bool { leftoverMinor < 0 }

    private static func incomeMinor(
        profile: UserProfile?,
        monthStart: Date,
        lastDay: Date,
        currency: String,
        calendar: Calendar
    ) -> Int {
        guard let profile else { return 0 }
        let perPay = Money.minorUnits(fromMajor: profile.incomeAmount, currency: currency)
        guard perPay > 0 else { return 0 }
        if case .irregular = profile.incomeCadence { return perPay }
        let count = profile.incomeCadence.paydays(from: monthStart, through: lastDay, calendar: calendar).count
        return perPay * count
    }
}
