//
//  IncomeSchedule.swift
//  Norma
//
//  The flexible pay-cadence layer over UserProfile. Income is captured as an
//  amount-per-paycheck plus a cadence that adapts to how the user is actually
//  paid — weekly, biweekly, twice a month, monthly, or irregular — instead of a
//  single day-of-month Int. See plans/income-paydays.md.
//
//  This is the model foundation (P1). Income remains a *projection*: it never
//  mutates the stored balance — the re-anchor is the only truth (see the
//  reconciliation rule in the spec).
//

import Foundation

/// How often income lands. `weekly`/`biweekly` need an anchor the calendar can
/// project from; `semiMonthly`/`monthly` are day-of-month based; `irregular`
/// makes no prediction (a rolling average estimates the monthly figure).
enum IncomeCadence: Equatable {
    case weekly(weekday: Int)              // 1=Sun … 7=Sat
    case biweekly(anchor: Date)           // every 14 days from a known past payday
    case semiMonthly(day1: Int, day2: Int)
    case monthly(day: Int)                // clamped to month length (29–31 → last day)
    case irregular

    var raw: String {
        switch self {
        case .weekly:      return "weekly"
        case .biweekly:    return "biweekly"
        case .semiMonthly: return "semiMonthly"
        case .monthly:     return "monthly"
        case .irregular:   return "irregular"
        }
    }

    /// Average paydays per month — converts a per-paycheck amount into the
    /// monthly figure the forecast math reads.
    var occurrencesPerMonth: Double {
        switch self {
        case .weekly:      return 52.0 / 12.0   // ≈ 4.333
        case .biweekly:    return 26.0 / 12.0   // ≈ 2.167
        case .semiMonthly: return 2
        case .monthly:     return 1
        case .irregular:   return 1
        }
    }

    /// Human label for capture/summary UI.
    var label: String {
        switch self {
        case .weekly:      return "weekly"
        case .biweekly:    return "every 2 weeks"
        case .semiMonthly: return "twice a month"
        case .monthly:     return "monthly"
        case .irregular:   return "it varies"
        }
    }
}

extension UserProfile {

    /// Assemble the structured cadence from the stored fields, falling back to
    /// the legacy `payday` Int (→ monthly) so pre-cadence installs still work.
    var incomeCadence: IncomeCadence? {
        switch incomeCadenceRaw {
        case "weekly":
            return incomeWeekday.map { .weekly(weekday: $0) }
        case "biweekly":
            return incomeAnchorDate.map { .biweekly(anchor: $0) }
        case "semiMonthly":
            if let d1 = payday, let d2 = incomeDay2 { return .semiMonthly(day1: d1, day2: d2) }
            return nil
        case "monthly":
            return payday.map { .monthly(day: $0) }
        case "irregular":
            return .irregular
        default:
            // Legacy: no structured cadence set yet — infer monthly from payday.
            return payday.map { .monthly(day: $0) }
        }
    }

    /// Persist a cadence back into the flat fields.
    func setIncomeCadence(_ cadence: IncomeCadence) {
        incomeCadenceRaw = cadence.raw
        incomeWeekday = nil
        incomeAnchorDate = nil
        incomeDay2 = nil
        switch cadence {
        case .weekly(let weekday):
            incomeWeekday = weekday
        case .biweekly(let anchor):
            incomeAnchorDate = anchor
        case .semiMonthly(let day1, let day2):
            payday = day1
            incomeDay2 = day2
        case .monthly(let day):
            payday = day
        case .irregular:
            break
        }
        updatedAt = Date()
    }

    /// The monthly figure the forecast/calendar math reads — per-paycheck amount
    /// scaled by cadence. Returns nil when there's no amount. For `irregular`,
    /// callers may prefer a rolling average of real inflows (later phase); this
    /// treats the amount as a rough monthly estimate.
    var monthlyEquivalent: Double? {
        guard let amount = incomeAmount, amount > 0 else { return nil }
        guard let cadence = incomeCadence else { return nil }
        return amount * cadence.occurrencesPerMonth
    }

    /// Projected payday dates within `[from, through]` (inclusive), for calendar
    /// markers, forecast refill, and the payday nudge. `irregular` returns [].
    func nextPaydays(from: Date, through: Date, calendar: Calendar = .current) -> [Date] {
        guard let cadence = incomeCadence, from <= through else { return [] }
        let start = calendar.startOfDay(for: from)
        let end = calendar.startOfDay(for: through)

        switch cadence {
        case .weekly(let weekday):
            return daysMatching(start: start, end: end, calendar: calendar) {
                calendar.component(.weekday, from: $0) == weekday
            }

        case .biweekly(let anchor):
            var result: [Date] = []
            let anchorDay = calendar.startOfDay(for: anchor)
            // Walk back/forward in 14-day steps to cover the window.
            var d = anchorDay
            if d > start {
                while let prev = calendar.date(byAdding: .day, value: -14, to: d), prev >= start {
                    d = prev
                }
            } else {
                while d < start {
                    guard let next = calendar.date(byAdding: .day, value: 14, to: d) else { break }
                    d = next
                }
            }
            while d <= end {
                if d >= start { result.append(d) }
                guard let next = calendar.date(byAdding: .day, value: 14, to: d) else { break }
                d = next
            }
            return result

        case .semiMonthly(let day1, let day2):
            return monthlyDays(start: start, end: end, days: [day1, day2], calendar: calendar)

        case .monthly(let day):
            return monthlyDays(start: start, end: end, days: [day], calendar: calendar)

        case .irregular:
            return []
        }
    }

    // MARK: - Helpers

    private func daysMatching(start: Date, end: Date, calendar: Calendar,
                              _ predicate: (Date) -> Bool) -> [Date] {
        var result: [Date] = []
        var d = start
        while d <= end {
            if predicate(d) { result.append(d) }
            guard let next = calendar.date(byAdding: .day, value: 1, to: d) else { break }
            d = next
        }
        return result
    }

    /// For each month spanned by [start, end], the given days-of-month (clamped
    /// to the month's length), kept if they fall inside the window.
    private func monthlyDays(start: Date, end: Date, days: [Int], calendar: Calendar) -> [Date] {
        var result: [Date] = []
        var monthCursor = calendar.date(from: calendar.dateComponents([.year, .month], from: start)) ?? start
        while monthCursor <= end {
            let range = calendar.range(of: .day, in: .month, for: monthCursor) ?? 1..<29
            let lastDay = range.upperBound - 1
            for day in days {
                let clamped = min(max(day, 1), lastDay)
                var comps = calendar.dateComponents([.year, .month], from: monthCursor)
                comps.day = clamped
                if let date = calendar.date(from: comps) {
                    let d = calendar.startOfDay(for: date)
                    if d >= start && d <= end { result.append(d) }
                }
            }
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthCursor) else { break }
            monthCursor = nextMonth
        }
        return result.sorted()
    }
}
