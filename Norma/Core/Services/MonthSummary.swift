//
//  MonthSummary.swift
//  Norma
//
//  The app's one number: income for a month, minus the bills that fall in
//  it, is what's left. Built fresh from the bills and the profile whenever
//  either changes, so nothing derived is ever stored.
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
    let income: Double
    let paydays: [Date]
    /// Every bill occurrence in the month, earliest first.
    let occurrences: [BillOccurrence]

    init(month: Date, bills: [Bill], profile: UserProfile?, calendar: Calendar = .current) {
        let interval = calendar.dateInterval(of: .month, for: month)
            ?? DateInterval(start: month, duration: 0)
        let lastDay = calendar.date(byAdding: .day, value: -1, to: interval.end) ?? interval.start

        self.month = interval.start
        self.income = profile?.income(inMonthOf: interval.start, calendar: calendar) ?? 0
        self.paydays = profile?.paydays(from: interval.start, through: lastDay, calendar: calendar) ?? []
        self.occurrences = bills
            .flatMap { bill in
                bill.occurrences(from: interval.start, through: lastDay, calendar: calendar).map { date in
                    BillOccurrence(bill: bill, date: date, isPaid: bill.isPaid(date, calendar: calendar))
                }
            }
            .sorted { ($0.date, $0.bill.name) < ($1.date, $1.bill.name) }
    }

    var billsTotal: Double { occurrences.reduce(0) { $0 + $1.bill.amount } }
    var paidTotal: Double { occurrences.filter(\.isPaid).reduce(0) { $0 + $1.bill.amount } }
    var unpaidTotal: Double { billsTotal - paidTotal }
    var leftover: Double { income - billsTotal }
}
