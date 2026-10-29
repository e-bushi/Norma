//
//  ReminderPlanner.swift
//  Norma
//
//  Decides which bill reminders to schedule. A reminder exists only when its
//  fire instant (9:00:00 that morning) is still ahead of the clock. Each bill
//  gets its next few occurrences, and the whole list stays under iOS's
//  64-pending cap.
//

import Foundation

struct ReminderSource: Equatable {
    var id: UUID
    var name: String
    var amountText: String
    var isReminderOn: Bool
    /// Unpaid occurrence days, earliest first.
    var occurrenceDays: [Date]
}

struct PlannedReminder: Equatable {
    var billID: UUID
    var identifier: String
    var body: String
    var fireDate: Date
    var timeZone: TimeZone
    var year: Int
    var month: Int
    var day: Int
    var hour: Int
    var minute: Int
    var second: Int
}

enum ReminderAuthorization: Equatable {
    case notDetermined
    case denied
    case authorized
}

enum ReminderPermissionDecision: Equatable {
    /// Permission is granted; schedule reminders.
    case schedule
    /// The user said no, or already had. Turn the toggle off and point at Settings.
    case turnOffAndOpenSettings
}

enum ReminderPlanner {
    /// iOS keeps at most 64 pending local notifications. Stay under that.
    static let pendingCap = 60
    /// Next few occurrences per bill, when the cap has room.
    static let occurrencesPerBill = 3
    static let hour = 9

    static func shouldSchedule(fireDate: Date, now: Date) -> Bool {
        fireDate > now
    }

    /// 9:00:00 on the calendar day of `day`.
    static func fireInstant(on day: Date, calendar: Calendar) -> Date? {
        var parts = calendar.dateComponents([.year, .month, .day], from: day)
        parts.hour = hour
        parts.minute = 0
        parts.second = 0
        return calendar.date(from: parts)
    }

    static func identifier(billID: UUID, index: Int, suffix: String) -> String {
        "bill-\(billID.uuidString)-\(index)-\(suffix)"
    }

    /// Every id this version might have registered for the bill, plus the
    /// previous single-occurrence ids (`bill-{id}-due` / `bill-{id}-before`).
    static func identifiers(for billID: UUID, occurrences: Int = occurrencesPerBill) -> [String] {
        var ids: [String] = []
        for index in 0..<occurrences {
            ids.append(identifier(billID: billID, index: index, suffix: "due"))
            ids.append(identifier(billID: billID, index: index, suffix: "before"))
        }
        ids.append("bill-\(billID.uuidString)-due")
        ids.append("bill-\(billID.uuidString)-before")
        return ids
    }

    /// Future reminders only. Bills take turns so one long list can't use the whole cap.
    static func plan(
        bills: [ReminderSource],
        now: Date,
        calendar: Calendar,
        maxPending: Int = pendingCap,
        occurrencesPerBill: Int = occurrencesPerBill
    ) -> [PlannedReminder] {
        let pools =
            bills
            .filter(\.isReminderOn)
            .map { candidates(for: $0, now: now, calendar: calendar, occurrencesPerBill: occurrencesPerBill) }
        var planned: [PlannedReminder] = []
        var cursors = Array(repeating: 0, count: pools.count)
        var moved = true
        while planned.count < maxPending, moved {
            moved = false
            for index in pools.indices {
                guard planned.count < maxPending else { break }
                let cursor = cursors[index]
                guard cursor < pools[index].count else { continue }
                planned.append(pools[index][cursor])
                cursors[index] = cursor + 1
                moved = true
            }
        }
        return planned
    }

    private static func candidates(
        for bill: ReminderSource,
        now: Date,
        calendar: Calendar,
        occurrencesPerBill: Int
    ) -> [PlannedReminder] {
        var result: [PlannedReminder] = []
        var scheduled = 0
        var index = 0
        let days = bill.occurrenceDays.sorted()
        for day in days {
            guard scheduled < occurrencesPerBill else { break }
            let start = calendar.startOfDay(for: day)
            var fires: [(suffix: String, date: Date)] = []
            let dayBefore = calendar.date(byAdding: .day, value: -1, to: start)
            let beforeFire = dayBefore.flatMap { fireInstant(on: $0, calendar: calendar) }
            if let beforeFire, shouldSchedule(fireDate: beforeFire, now: now) {
                fires.append(("before", beforeFire))
            }
            let dueFire = fireInstant(on: start, calendar: calendar)
            if let dueFire, shouldSchedule(fireDate: dueFire, now: now) {
                fires.append(("due", dueFire))
            }
            guard !fires.isEmpty else { continue }
            for fire in fires {
                result.append(make(bill: bill, index: index, suffix: fire.suffix, fire: fire.date, calendar: calendar))
            }
            scheduled += 1
            index += 1
        }
        return result
    }

    private static func make(
        bill: ReminderSource,
        index: Int,
        suffix: String,
        fire: Date,
        calendar: Calendar
    ) -> PlannedReminder {
        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fire)
        let name = bill.name.lowercased()
        let body =
            suffix == "before"
            ? "\(name) · \(bill.amountText) is due tomorrow."
            : "\(name) · \(bill.amountText) is due today."
        return PlannedReminder(
            billID: bill.id,
            identifier: identifier(billID: bill.id, index: index, suffix: suffix),
            body: body,
            fireDate: fire,
            timeZone: calendar.timeZone,
            year: parts.year ?? 0,
            month: parts.month ?? 0,
            day: parts.day ?? 0,
            hour: parts.hour ?? hour,
            minute: parts.minute ?? 0,
            second: parts.second ?? 0
        )
    }
}
