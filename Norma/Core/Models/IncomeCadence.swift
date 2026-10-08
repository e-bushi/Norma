//
//  IncomeCadence.swift
//  Norma
//
//  How often income lands, and the payday math built on it. Income is
//  captured as an amount per paycheck plus a cadence that matches how people
//  are actually paid — weekly, every two weeks, twice a month, monthly, or
//  irregular — instead of a single monthly figure.
//

import Foundation

enum IncomeCadence: Equatable, Hashable {
    case weekly(weekday: Int)              // 1 = Sun … 7 = Sat
    case biweekly(anchor: Date)            // every 14 days from a known payday
    case semiMonthly(day1: Int, day2: Int)
    case monthly(day: Int)                 // days past the month's end clamp to its last day
    case irregular

    var label: String {
        switch self {
        case .weekly:      return "weekly"
        case .biweekly:    return "every 2 weeks"
        case .semiMonthly: return "twice a month"
        case .monthly:     return "monthly"
        case .irregular:   return "it varies"
        }
    }

    /// Projected paydays within `[from, through]`, inclusive, at start of day.
    /// `irregular` makes no prediction and returns no dates.
    func paydays(from: Date, through: Date, calendar: Calendar = .current) -> [Date] {
        let start = calendar.startOfDay(for: from)
        let end = calendar.startOfDay(for: through)
        guard start <= end else { return [] }

        switch self {
        case .weekly(let weekday):
            var result: [Date] = []
            var day = start
            while day <= end {
                if calendar.component(.weekday, from: day) == weekday { result.append(day) }
                guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
                day = next
            }
            return result

        case .biweekly(let anchor):
            // Step from the anchor in whole 14-day periods to the first payday
            // on or after `start`, then walk forward.
            let anchorDay = calendar.startOfDay(for: anchor)
            let offset = calendar.dateComponents([.day], from: anchorDay, to: start).day ?? 0
            let periods = Int((Double(offset) / 14).rounded(.up))
            guard var day = calendar.date(byAdding: .day, value: periods * 14, to: anchorDay) else { return [] }
            var result: [Date] = []
            while day <= end {
                result.append(day)
                guard let next = calendar.date(byAdding: .day, value: 14, to: day) else { break }
                day = next
            }
            return result

        case .semiMonthly(let day1, let day2):
            return Self.daysOfMonth([day1, day2], from: start, through: end, calendar: calendar)

        case .monthly(let day):
            return Self.daysOfMonth([day], from: start, through: end, calendar: calendar)

        case .irregular:
            return []
        }
    }

    /// Expected income for the calendar month containing `month`: one
    /// `amountPerPaycheck` per projected payday. Irregular income treats the
    /// amount as a rough monthly estimate.
    func income(inMonthOf month: Date, amountPerPaycheck: Double, calendar: Calendar = .current) -> Double {
        guard amountPerPaycheck > 0 else { return 0 }
        if case .irregular = self { return amountPerPaycheck }
        guard let interval = calendar.dateInterval(of: .month, for: month),
              let lastDay = calendar.date(byAdding: .day, value: -1, to: interval.end) else { return 0 }
        return Double(paydays(from: interval.start, through: lastDay, calendar: calendar).count) * amountPerPaycheck
    }

    /// For each month spanned by the window, the given days of month (clamped
    /// to the month's length) that fall inside it.
    private static func daysOfMonth(_ days: [Int], from start: Date, through end: Date, calendar: Calendar) -> [Date] {
        var result: Set<Date> = []
        guard var month = calendar.dateInterval(of: .month, for: start)?.start else { return [] }
        while month <= end {
            let lastDay = calendar.range(of: .day, in: .month, for: month)?.count ?? 28
            for day in days {
                var components = calendar.dateComponents([.year, .month], from: month)
                components.day = min(max(day, 1), lastDay)
                if let date = calendar.date(from: components), date >= start, date <= end {
                    result.insert(date)
                }
            }
            guard let next = calendar.date(byAdding: .month, value: 1, to: month) else { break }
            month = next
        }
        return result.sorted()
    }
}
