//
//  NotificationService.swift
//  Norma
//
//  Local bill reminders: a nudge at 9:00 the day before and at 9:00 the
//  morning a bill is due. Local notifications are one-shot, so the next few
//  unpaid occurrences are re-armed on launch and whenever a bill changes.
//

import Foundation
import UserNotifications

protocol NotificationCentering: AnyObject {
    func authorization() async -> ReminderAuthorization
    func requestAuthorization() async -> Bool
    func pendingIdentifiers() async -> [String]
    func add(_ reminder: PlannedReminder) async throws
    func removePending(identifiers: [String])
    func removeAllPending()
}

/// Schedules reminders through a notification center. Tests pass a fake center
/// and a fixed clock; the app passes the system center.
final class ReminderCoordinator {
    /// Set once the first launch of this version has wiped pending requests
    /// left behind by the old id scheme (`{billId}_{index}_due`, `ai_reminder_…`).
    static let legacyClearKey = "norma.reminders.clearedLegacyPending.v1"

    let center: NotificationCentering
    var calendar: Calendar
    var now: () -> Date
    var defaults: UserDefaults
    var legacyClearKey: String

    init(
        center: NotificationCentering,
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init,
        defaults: UserDefaults = .standard,
        legacyClearKey: String = ReminderCoordinator.legacyClearKey
    ) {
        self.center = center
        self.calendar = calendar
        self.now = now
        self.defaults = defaults
        self.legacyClearKey = legacyClearKey
    }

    func permissionDecision() async -> ReminderPermissionDecision {
        switch await center.authorization() {
        case .authorized:
            return .schedule
        case .denied:
            return .turnOffAndOpenSettings
        case .notDetermined:
            let granted = await center.requestAuthorization()
            return granted ? .schedule : .turnOffAndOpenSettings
        }
    }

    /// Removes every pending request the first time this version runs, then
    /// does nothing on later launches.
    func clearLegacyPendingIfNeeded() {
        guard !defaults.bool(forKey: legacyClearKey) else { return }
        center.removeAllPending()
        defaults.set(true, forKey: legacyClearKey)
    }

    func schedule(source: ReminderSource) async {
        clearLegacyPendingIfNeeded()
        let ids = ReminderPlanner.identifiers(for: source.id)
        let status = await center.authorization()
        guard source.isReminderOn, status == .authorized else {
            center.removePending(identifiers: ids)
            return
        }
        let pending = await center.pendingIdentifiers()
        let others = pending.filter { !ids.contains($0) }.count
        let room = max(0, ReminderPlanner.pendingCap - others)
        let planned = ReminderPlanner.plan(
            bills: [source],
            now: now(),
            calendar: calendar,
            maxPending: room
        )
        center.removePending(identifiers: ids)
        for reminder in planned {
            try? await center.add(reminder)
        }
    }

    func reschedule(sources: [ReminderSource]) async {
        clearLegacyPendingIfNeeded()
        guard await center.authorization() == .authorized else { return }
        let planned = ReminderPlanner.plan(bills: sources, now: now(), calendar: calendar)
        for source in sources {
            center.removePending(identifiers: ReminderPlanner.identifiers(for: source.id))
        }
        for reminder in planned {
            try? await center.add(reminder)
        }
    }

    func cancel(billID: UUID) {
        center.removePending(identifiers: ReminderPlanner.identifiers(for: billID))
    }

    func cancelAll() {
        center.removeAllPending()
    }

    func source(for bill: Bill, currency: String) -> ReminderSource {
        ReminderSource(
            id: bill.id,
            name: bill.name,
            amountText: Money.format(bill.amount, currency: currency),
            isReminderOn: bill.isReminderOn,
            occurrenceDays: bill.upcomingUnpaidDates(from: now(), calendar: calendar)
        )
    }
}

final class SystemNotificationCenter: NotificationCentering {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func authorization() async -> ReminderAuthorization {
        switch await center.notificationSettings().authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized, .provisional, .ephemeral:
            return .authorized
        @unknown default:
            return .denied
        }
    }

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
    }

    func pendingIdentifiers() async -> [String] {
        await center.pendingNotificationRequests().map(\.identifier)
    }

    func add(_ reminder: PlannedReminder) async throws {
        let content = UNMutableNotificationContent()
        content.title = "norma"
        content.body = reminder.body
        content.sound = .default

        var components = DateComponents()
        components.timeZone = reminder.timeZone
        components.year = reminder.year
        components.month = reminder.month
        components.day = reminder.day
        components.hour = reminder.hour
        components.minute = reminder.minute
        components.second = reminder.second
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        try await center.add(UNNotificationRequest(identifier: reminder.identifier, content: content, trigger: trigger))
    }

    func removePending(identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func removeAllPending() {
        center.removeAllPendingNotificationRequests()
    }
}

@MainActor
enum NotificationService {
    private static let coordinator = ReminderCoordinator(center: SystemNotificationCenter())

    /// Asks only when the system hasn't yet. UI tests skip the system prompt
    /// so the onboard-and-add-bill path isn't blocked by an alert.
    static func permissionDecision() async -> ReminderPermissionDecision {
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
            return .schedule
        }
        return await coordinator.permissionDecision()
    }

    @discardableResult
    static func ensurePermission() async -> Bool {
        await permissionDecision() == .schedule
    }

    static func scheduleReminders(for bill: Bill, currency: String) async {
        await coordinator.schedule(source: coordinator.source(for: bill, currency: currency))
    }

    static func rescheduleAll(_ bills: [Bill], currency: String) async {
        let sources = bills.map { coordinator.source(for: $0, currency: currency) }
        await coordinator.reschedule(sources: sources)
    }

    static func cancelReminders(for bill: Bill) {
        coordinator.cancel(billID: bill.id)
    }

    static func cancelReminders(forBillID id: UUID) {
        coordinator.cancel(billID: id)
    }

    static func cancelAll() {
        coordinator.cancelAll()
    }
}
