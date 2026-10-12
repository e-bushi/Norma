//
//  Bill.swift
//  Norma
//
//  A bill the user pays on a schedule. `dueDate` is the anchor occurrence;
//  recurring bills repeat from it every month, quarter, or year. Paid state
//  is tracked per occurrence, so marking October paid never touches November.
//

import Foundation
import SwiftData

enum BillFrequency: String, Codable, CaseIterable, Identifiable {
    case oneTime
    case monthly
    case quarterly
    case yearly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .oneTime: return "one-time"
        case .monthly: return "monthly"
        case .quarterly: return "quarterly"
        case .yearly: return "yearly"
        }
    }

    var monthsBetweenOccurrences: Int? {
        switch self {
        case .oneTime: return nil
        case .monthly: return 1
        case .quarterly: return 3
        case .yearly: return 12
        }
    }

    /// Every occurrence of a bill anchored at `anchor` that falls inside
    /// `[from, through]`, inclusive, at start of day. Each occurrence is
    /// computed from the anchor rather than the previous one, so a bill due on
    /// the 31st lands on Feb 28 and returns to the 31st in March.
    func occurrences(anchor: Date, from: Date, through: Date, calendar: Calendar = .current) -> [Date] {
        let anchorDay = calendar.startOfDay(for: anchor)
        let start = calendar.startOfDay(for: from)
        let end = calendar.startOfDay(for: through)
        guard start <= end else { return [] }

        guard let step = monthsBetweenOccurrences else {
            return (start...end).contains(anchorDay) ? [anchorDay] : []
        }

        let monthsToStart = calendar.dateComponents([.month], from: anchorDay, to: start).month ?? 0
        var index = max(0, monthsToStart / step - 1)
        var result: [Date] = []
        while let date = calendar.date(byAdding: .month, value: index * step, to: anchorDay), date <= end {
            if date >= start { result.append(date) }
            index += 1
        }
        return result
    }
}

@Model
final class Bill {
    var id: UUID = UUID()
    var name: String = ""
    var amount: Double = 0
    /// The first (anchor) occurrence. Recurring bills repeat from this date.
    var dueDate: Date = Date()
    var frequencyRaw: String = BillFrequency.monthly.rawValue
    var isReminderOn: Bool = true
    var notes: String?
    /// Every occurrence on or before this date counts as paid.
    var paidThrough: Date?
    var createdAt: Date = Date()

    init(name: String, amount: Double, dueDate: Date, frequency: BillFrequency, isReminderOn: Bool = true, notes: String? = nil) {
        self.name = name
        self.amount = amount
        self.dueDate = dueDate
        self.frequencyRaw = frequency.rawValue
        self.isReminderOn = isReminderOn
        self.notes = notes
    }

    var frequency: BillFrequency {
        get { BillFrequency(rawValue: frequencyRaw) ?? .monthly }
        set { frequencyRaw = newValue.rawValue }
    }

    func occurrences(from: Date, through: Date, calendar: Calendar = .current) -> [Date] {
        frequency.occurrences(anchor: dueDate, from: from, through: through, calendar: calendar)
    }

    func occurrences(inMonthOf month: Date, calendar: Calendar = .current) -> [Date] {
        guard let interval = calendar.dateInterval(of: .month, for: month),
            let lastDay = calendar.date(byAdding: .day, value: -1, to: interval.end)
        else { return [] }
        return occurrences(from: interval.start, through: lastDay, calendar: calendar)
    }

    /// The first occurrence on or after `date`, if the bill has one.
    func nextOccurrence(onOrAfter date: Date, calendar: Calendar = .current) -> Date? {
        guard let horizon = calendar.date(byAdding: .year, value: 2, to: date) else { return nil }
        return occurrences(from: date, through: horizon, calendar: calendar).first
    }

    func isPaid(_ occurrence: Date, calendar: Calendar = .current) -> Bool {
        guard let paidThrough else { return false }
        return calendar.startOfDay(for: occurrence) <= paidThrough
    }

    /// Marking an occurrence paid also settles the ones before it; marking it
    /// unpaid reopens it and everything after.
    func setPaid(_ isPaid: Bool, for occurrence: Date, calendar: Calendar = .current) {
        let day = calendar.startOfDay(for: occurrence)
        if isPaid {
            paidThrough = max(paidThrough ?? day, day)
        } else if self.isPaid(day, calendar: calendar) {
            let earlier = calendar.date(byAdding: .day, value: -1, to: day) ?? day
            paidThrough = occurrences(from: .distantPast, through: earlier, calendar: calendar).last
        }
    }
}
