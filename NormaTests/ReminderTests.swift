//
//  ReminderTests.swift
//  NormaTests
//
//  Reminder decisions on a fixed UTC clock. The notification center is a fake,
//  so nothing here talks to UNUserNotificationCenter.
//

import Foundation
import Testing
@testable import Norma

private let utc: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
    utc.date(from: DateComponents(year: year, month: month, day: day))!
}

private func moment(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
    utc.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: 0))!
}

private final class FakeNotificationCenter: NotificationCentering {
    var status: ReminderAuthorization
    var requestResult = true
    private(set) var requestCount = 0
    private(set) var removeAllCount = 0
    private var pending: [String: PlannedReminder] = [:]
    private var extraIDs: Set<String> = []

    init(status: ReminderAuthorization) {
        self.status = status
    }

    func seed(_ identifier: String) {
        extraIDs.insert(identifier)
    }

    func authorization() async -> ReminderAuthorization { status }

    func requestAuthorization() async -> Bool {
        requestCount += 1
        status = requestResult ? .authorized : .denied
        return requestResult
    }

    func pendingIdentifiers() async -> [String] {
        Array(pending.keys) + Array(extraIDs)
    }

    func reminders() async -> [PlannedReminder] {
        Array(pending.values)
    }

    func add(_ reminder: PlannedReminder) async throws {
        pending[reminder.identifier] = reminder
    }

    func removePending(identifiers: [String]) {
        for identifier in identifiers {
            pending.removeValue(forKey: identifier)
            extraIDs.remove(identifier)
        }
    }

    func removeAllPending() {
        removeAllCount += 1
        pending.removeAll()
        extraIDs.removeAll()
    }
}

private func makeDefaults() -> UserDefaults {
    let name = "norma.tests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    defaults.removePersistentDomain(forName: name)
    return defaults
}

struct ReminderPlannerTests {
    @Test func dayBeforeStaysWhenNineIsStillAhead() {
        let due = day(2026, 10, 10)
        let now = moment(2026, 10, 9, 8)
        let source = ReminderSource(
            id: UUID(),
            name: "Rent",
            amountText: "$10",
            isReminderOn: true,
            occurrenceDays: [due]
        )
        let planned = ReminderPlanner.plan(bills: [source], now: now, calendar: utc)
        let before = planned.first { $0.identifier.hasSuffix("-before") }
        let dueReminder = planned.first { $0.identifier.hasSuffix("-due") }

        #expect(before?.year == 2026)
        #expect(before?.month == 10)
        #expect(before?.day == 9)
        #expect(before?.hour == 9)
        #expect(before?.minute == 0)
        #expect(before?.second == 0)
        #expect(before?.body.contains("due tomorrow") == true)
        #expect(before.map { ReminderPlanner.shouldSchedule(fireDate: $0.fireDate, now: now) } == true)

        #expect(dueReminder?.day == 10)
        #expect(dueReminder?.hour == 9)
        #expect(dueReminder?.minute == 0)
        #expect(dueReminder?.second == 0)
        #expect(planned.allSatisfy { $0.hour == 9 && $0.minute == 0 && $0.second == 0 })
    }

    @Test func pastNineOnTheDueDateIsNotScheduled() {
        let now = moment(2026, 10, 10, 10)
        let source = ReminderSource(
            id: UUID(),
            name: "Rent",
            amountText: "$10",
            isReminderOn: true,
            occurrenceDays: [day(2026, 10, 10), day(2026, 11, 10)]
        )
        let planned = ReminderPlanner.plan(bills: [source], now: now, calendar: utc)
        #expect(planned.allSatisfy { $0.fireDate > now })
        #expect(!planned.contains { $0.year == 2026 && $0.month == 10 && $0.day == 10 })
        #expect(planned.contains { $0.month == 11 && $0.day == 10 && $0.hour == 9 && $0.minute == 0 && $0.second == 0 })
    }

    @Test func dayBeforeIsDroppedOnceNineHasPassed() {
        let now = moment(2026, 10, 9, 10)
        let source = ReminderSource(
            id: UUID(),
            name: "Rent",
            amountText: "$10",
            isReminderOn: true,
            occurrenceDays: [day(2026, 10, 10)]
        )
        let planned = ReminderPlanner.plan(bills: [source], now: now, calendar: utc)
        #expect(!planned.contains { $0.identifier.hasSuffix("-before") })
        #expect(planned.contains { $0.identifier.hasSuffix("-due") && $0.day == 10 })
        #expect(planned.allSatisfy { ReminderPlanner.shouldSchedule(fireDate: $0.fireDate, now: now) })
    }

    @Test func anEqualFireInstantIsNotAhead() {
        let fire = ReminderPlanner.fireInstant(on: day(2026, 10, 10), calendar: utc)!
        #expect(ReminderPlanner.shouldSchedule(fireDate: fire, now: fire) == false)
        #expect(ReminderPlanner.shouldSchedule(fireDate: fire, now: fire.addingTimeInterval(-1)))
    }

    @Test func eachBillGetsItsNextFewOccurrencesUnderTheCap() {
        let now = moment(2026, 1, 1, 8)
        let days = [day(2026, 1, 15), day(2026, 2, 15), day(2026, 3, 15)]
        let sources = (0..<2).map { index in
            ReminderSource(id: UUID(), name: "bill \(index)", amountText: "$1", isReminderOn: true, occurrenceDays: days)
        }
        let planned = ReminderPlanner.plan(bills: sources, now: now, calendar: utc)
        #expect(planned.count == 12)
        for source in sources {
            #expect(planned.filter { $0.billID == source.id }.count == 6)
        }

        let many = (0..<40).map { index in
            ReminderSource(id: UUID(), name: "bill \(index)", amountText: "$1", isReminderOn: true, occurrenceDays: days)
        }
        let capped = ReminderPlanner.plan(bills: many, now: now, calendar: utc)
        #expect(ReminderPlanner.pendingCap < 64)
        #expect(capped.count == ReminderPlanner.pendingCap)
        #expect(capped.count <= 60)
        #expect(Set(capped.map(\.billID)).count == 40)
        #expect(capped.allSatisfy { $0.fireDate > now })
    }
}

struct ReminderCoordinatorTests {
    @Test func notDeterminedAsksAndDeniedDoesNot() async {
        let asking = FakeNotificationCenter(status: .notDetermined)
        let askingCoordinator = ReminderCoordinator(center: asking, defaults: makeDefaults())
        let granted = await askingCoordinator.permissionDecision()
        #expect(granted == .schedule)
        #expect(asking.requestCount == 1)

        let refused = FakeNotificationCenter(status: .notDetermined)
        refused.requestResult = false
        let refusedCoordinator = ReminderCoordinator(center: refused, defaults: makeDefaults())
        let denied = await refusedCoordinator.permissionDecision()
        #expect(denied == .turnOffAndOpenSettings)
        #expect(refused.requestCount == 1)

        let already = FakeNotificationCenter(status: .denied)
        let alreadyCoordinator = ReminderCoordinator(center: already, defaults: makeDefaults())
        let decision = await alreadyCoordinator.permissionDecision()
        #expect(decision == .turnOffAndOpenSettings)
        #expect(already.requestCount == 0)
    }

    @Test func firstLaunchClearsLegacyPendingOnceThenReschedules() async {
        let fake = FakeNotificationCenter(status: .denied)
        let defaults = makeDefaults()
        let now = moment(2026, 10, 9, 8)
        let coordinator = ReminderCoordinator(
            center: fake,
            calendar: utc,
            now: { now },
            defaults: defaults
        )
        let source = ReminderSource(
            id: UUID(),
            name: "rent",
            amountText: "$10",
            isReminderOn: true,
            occurrenceDays: [day(2026, 10, 10)]
        )
        fake.seed("ai_reminder_1")
        fake.seed("\(UUID().uuidString)_0_due")

        await coordinator.reschedule(sources: [source])
        #expect(fake.removeAllCount == 1)
        #expect(await fake.pendingIdentifiers().isEmpty)
        #expect(defaults.bool(forKey: ReminderCoordinator.legacyClearKey))

        fake.status = .authorized
        await coordinator.reschedule(sources: [source])
        #expect(fake.removeAllCount == 1)
        let pending = await fake.pendingIdentifiers()
        #expect(pending.contains { $0.hasSuffix("-due") })
        #expect(pending.contains { $0.hasSuffix("-before") })
        #expect(!pending.contains("ai_reminder_1"))
    }

    @Test func deletingABillCancelsBothReminderIDs() async {
        let fake = FakeNotificationCenter(status: .authorized)
        let defaults = makeDefaults()
        defaults.set(true, forKey: ReminderCoordinator.legacyClearKey)
        let now = moment(2026, 10, 9, 8)
        let coordinator = ReminderCoordinator(
            center: fake,
            calendar: utc,
            now: { now },
            defaults: defaults
        )
        let id = UUID()
        let source = ReminderSource(
            id: id,
            name: "rent",
            amountText: "$10",
            isReminderOn: true,
            occurrenceDays: [day(2026, 10, 10)]
        )
        fake.seed("keep-me")
        await coordinator.schedule(source: source)

        let due = ReminderPlanner.identifier(billID: id, index: 0, suffix: "due")
        let before = ReminderPlanner.identifier(billID: id, index: 0, suffix: "before")
        let pending = await fake.pendingIdentifiers()
        #expect(pending.contains(due))
        #expect(pending.contains(before))

        coordinator.cancel(billID: id)
        let after = await fake.pendingIdentifiers()
        #expect(!after.contains(due))
        #expect(!after.contains(before))
        #expect(after.contains("keep-me"))
    }

    @Test func coordinatorDoesNotAddAPastFire() async {
        let fake = FakeNotificationCenter(status: .authorized)
        let defaults = makeDefaults()
        defaults.set(true, forKey: ReminderCoordinator.legacyClearKey)
        let now = moment(2026, 10, 10, 10)
        let coordinator = ReminderCoordinator(
            center: fake,
            calendar: utc,
            now: { now },
            defaults: defaults
        )
        let source = ReminderSource(
            id: UUID(),
            name: "rent",
            amountText: "$10",
            isReminderOn: true,
            occurrenceDays: [day(2026, 10, 10)]
        )
        await coordinator.schedule(source: source)
        let reminders = await fake.reminders()
        #expect(reminders.isEmpty)
        #expect(reminders.allSatisfy { $0.fireDate > now })
    }
}
