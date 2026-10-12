//
//  NotificationService.swift
//  Norma
//
//  Local bill reminders: a nudge the day before and the morning a bill is
//  due. Local notifications are one-shot, so the next unpaid occurrence is
//  re-armed on launch and whenever a bill changes.
//

import Foundation
import UserNotifications

@MainActor
enum NotificationService {
    private static let center = UNUserNotificationCenter.current()
    private static let reminderHour = 9

    /// Asks for permission the first time; afterwards just reports the answer.
    @discardableResult
    static func ensurePermission() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        case .authorized, .provisional, .ephemeral:
            return true
        default:
            return false
        }
    }

    /// Replaces any pending reminders for the bill with ones for its next
    /// unpaid occurrence. No-ops without permission.
    static func scheduleReminders(for bill: Bill, currency: String) async {
        cancelReminders(for: bill)
        guard bill.isReminderOn, await isAuthorized() else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let due = bill.nextOccurrence(onOrAfter: today, calendar: calendar), !bill.isPaid(due) else { return }

        let amount = Money.format(bill.amount, currency: currency)
        let name = bill.name.lowercased()
        var reminders: [(id: String, date: Date, body: String)] = [
            (identifier(for: bill, suffix: "due"), due, "\(name) · \(amount) is due today.")
        ]
        if let dayBefore = calendar.date(byAdding: .day, value: -1, to: due), dayBefore > today {
            reminders.append((identifier(for: bill, suffix: "before"), dayBefore, "\(name) · \(amount) is due tomorrow."))
        }

        for reminder in reminders {
            let content = UNMutableNotificationContent()
            content.title = "norma"
            content.body = reminder.body
            content.sound = .default

            var components = calendar.dateComponents([.year, .month, .day], from: reminder.date)
            components.hour = reminderHour
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger))
        }
    }

    static func rescheduleAll(_ bills: [Bill], currency: String) async {
        for bill in bills {
            await scheduleReminders(for: bill, currency: currency)
        }
    }

    static func cancelReminders(for bill: Bill) {
        center.removePendingNotificationRequests(withIdentifiers: [
            identifier(for: bill, suffix: "due"),
            identifier(for: bill, suffix: "before"),
        ])
    }

    static func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    private static func isAuthorized() async -> Bool {
        let status = await center.notificationSettings().authorizationStatus
        return status == .authorized || status == .provisional || status == .ephemeral
    }

    private static func identifier(for bill: Bill, suffix: String) -> String {
        "bill-\(bill.id.uuidString)-\(suffix)"
    }
}
