//
//  AccessibilityCopy.swift
//  Norma
//
//  Strings and orderings that have to stay stable: weekday chips follow the
//  locale's first weekday without changing the stored Gregorian value,
//  payday subtitles are built from an existing payday list, and calendar
//  days are spoken with their dots.
//

import Foundation

/// Gregorian weekdays (Sunday = 1 … Saturday = 7) in display order.
enum WeekdayOrder {
    /// Starts at `firstWeekday` and walks forward. The values themselves stay
    /// Gregorian, so a stored "Friday" is still 6 in a Monday-first locale.
    static func ordered(firstWeekday: Int) -> [Int] {
        let start = ((firstWeekday - 1) % 7 + 7) % 7
        return (0..<7).map { ((start + $0) % 7) + 1 }
    }
}

/// "3 paydays · Oct 2, 16, 30", from a month's payday dates.
enum PaydaySubtitle {
    static func line(for paydays: [Date], calendar: Calendar = .current) -> String? {
        let days = paydays.map { calendar.startOfDay(for: $0) }.sorted()
        guard !days.isEmpty else { return nil }
        let noun = days.count == 1 ? "payday" : "paydays"
        return "\(days.count) \(noun) · \(condensed(days, calendar: calendar))"
    }

    /// Month name on the first date of each month, then bare day numbers.
    static func condensed(_ days: [Date], calendar: Calendar) -> String {
        var pieces: [String] = []
        var previousMonth: Int?
        var previousYear: Int?
        for day in days {
            let month = calendar.component(.month, from: day)
            let year = calendar.component(.year, from: day)
            let dayNumber = calendar.component(.day, from: day)
            if month == previousMonth && year == previousYear {
                pieces.append(String(dayNumber))
            } else {
                let symbol = calendar.shortMonthSymbols[month - 1]
                pieces.append("\(symbol) \(dayNumber)")
            }
            previousMonth = month
            previousYear = year
        }
        return pieces.joined(separator: ", ")
    }
}

/// Spoken calendar day, e.g. "October 16, payday, rent due".
enum CalendarDayLabel {
    struct Bill: Equatable {
        var name: String
        var isPaid: Bool
    }

    static func day(date: Date, isPayday: Bool, bills: [Bill], calendar: Calendar = .current) -> String {
        let month = calendar.component(.month, from: date)
        let dayNumber = calendar.component(.day, from: date)
        let monthName = calendar.monthSymbols[month - 1]
        return spoken(monthDay: "\(monthName) \(dayNumber)", isPayday: isPayday, bills: bills)
    }

    static func spoken(monthDay: String, isPayday: Bool, bills: [Bill]) -> String {
        var parts = [monthDay]
        if isPayday { parts.append("payday") }
        for bill in bills {
            let name = bill.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !name.isEmpty else { continue }
            parts.append(bill.isPaid ? "\(name) paid" : "\(name) due")
        }
        return parts.joined(separator: ", ")
    }
}
