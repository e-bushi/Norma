//
//  NormaTests.swift
//  NormaTests
//
//  The money math: when paydays land, when bills come due, and what's left
//  in a month. Everything runs on a fixed UTC Gregorian calendar so results
//  don't depend on the machine's time zone or locale.
//

import Foundation
import SwiftData
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

private func monthBounds(_ year: Int, _ month: Int) -> (Date, Date) {
    let start = day(year, month, 1)
    let count = utc.range(of: .day, in: .month, for: start)!.count
    return (start, day(year, month, count))
}

struct IncomeCadenceTests {
    @Test func weeklyLandsOnEveryMatchingWeekday() {
        let (start, end) = monthBounds(2026, 10)
        let paydays = IncomeCadence.weekly(weekday: 6).paydays(from: start, through: end, calendar: utc)
        #expect(paydays == [day(2026, 10, 2), day(2026, 10, 9), day(2026, 10, 16), day(2026, 10, 23), day(2026, 10, 30)])
    }

    @Test func biweeklyCountsTwoOrThreePaychecksPerMonth() {
        let cadence = IncomeCadence.biweekly(anchor: day(2026, 10, 2))
        let (octStart, octEnd) = monthBounds(2026, 10)
        let (novStart, novEnd) = monthBounds(2026, 11)
        #expect(cadence.paydays(from: octStart, through: octEnd, calendar: utc) == [day(2026, 10, 2), day(2026, 10, 16), day(2026, 10, 30)])
        #expect(cadence.paydays(from: novStart, through: novEnd, calendar: utc) == [day(2026, 11, 13), day(2026, 11, 27)])
    }

    @Test func biweeklyProjectsBackwardFromALaterAnchor() {
        let cadence = IncomeCadence.biweekly(anchor: day(2026, 10, 30))
        let (start, end) = monthBounds(2026, 10)
        #expect(cadence.paydays(from: start, through: end, calendar: utc) == [day(2026, 10, 2), day(2026, 10, 16), day(2026, 10, 30)])
    }

    @Test func dayOfMonthClampsToShortMonths() {
        let (febStart, febEnd) = monthBounds(2026, 2)
        let (aprStart, aprEnd) = monthBounds(2026, 4)
        #expect(IncomeCadence.semiMonthly(day1: 15, day2: 31).paydays(from: febStart, through: febEnd, calendar: utc) == [day(2026, 2, 15), day(2026, 2, 28)])
        #expect(IncomeCadence.monthly(day: 31).paydays(from: aprStart, through: aprEnd, calendar: utc) == [day(2026, 4, 30)])
    }

    @Test func irregularPredictsNoPaydaysAndTreatsAmountAsMonthly() {
        let (start, end) = monthBounds(2026, 10)
        #expect(IncomeCadence.irregular.paydays(from: start, through: end, calendar: utc).isEmpty)
        #expect(IncomeCadence.irregular.income(inMonthOf: start, amountPerPaycheck: 3000, calendar: utc) == 3000)
    }

    @Test func monthlyIncomeIsPaydaysTimesAmount() {
        let cadence = IncomeCadence.biweekly(anchor: day(2026, 10, 2))
        #expect(cadence.income(inMonthOf: day(2026, 10, 20), amountPerPaycheck: 2000, calendar: utc) == 6000)
        #expect(cadence.income(inMonthOf: day(2026, 11, 20), amountPerPaycheck: 2000, calendar: utc) == 4000)
    }

    @Test func profileRoundTripsEveryCadence() {
        let cadences: [IncomeCadence] = [
            .weekly(weekday: 2),
            .biweekly(anchor: day(2026, 10, 2)),
            .semiMonthly(day1: 1, day2: 15),
            .monthly(day: 28),
            .irregular,
        ]
        let profile = UserProfile()
        for cadence in cadences {
            profile.incomeCadence = cadence
            #expect(profile.incomeCadence == cadence)
        }
    }
}

struct BillFrequencyTests {
    @Test func monthlyFromThe31stClampsThenRecovers() {
        let anchor = day(2026, 1, 31)
        let (febStart, febEnd) = monthBounds(2026, 2)
        let (marStart, marEnd) = monthBounds(2026, 3)
        #expect(BillFrequency.monthly.occurrences(anchor: anchor, from: febStart, through: febEnd, calendar: utc) == [day(2026, 2, 28)])
        #expect(BillFrequency.monthly.occurrences(anchor: anchor, from: marStart, through: marEnd, calendar: utc) == [day(2026, 3, 31)])
    }

    @Test func quarterlySkipsOffMonths() {
        let anchor = day(2026, 1, 15)
        let (aprStart, aprEnd) = monthBounds(2026, 4)
        let (mayStart, mayEnd) = monthBounds(2026, 5)
        #expect(BillFrequency.quarterly.occurrences(anchor: anchor, from: aprStart, through: aprEnd, calendar: utc) == [day(2026, 4, 15)])
        #expect(BillFrequency.quarterly.occurrences(anchor: anchor, from: mayStart, through: mayEnd, calendar: utc).isEmpty)
    }

    @Test func yearlyRepeatsOnTheAnniversary() {
        let anchor = day(2025, 3, 10)
        let (start, end) = monthBounds(2027, 3)
        #expect(BillFrequency.yearly.occurrences(anchor: anchor, from: start, through: end, calendar: utc) == [day(2027, 3, 10)])
    }

    @Test func oneTimeAppearsOnlyInItsMonth() {
        let anchor = day(2026, 10, 20)
        let (octStart, octEnd) = monthBounds(2026, 10)
        let (novStart, novEnd) = monthBounds(2026, 11)
        #expect(BillFrequency.oneTime.occurrences(anchor: anchor, from: octStart, through: octEnd, calendar: utc) == [anchor])
        #expect(BillFrequency.oneTime.occurrences(anchor: anchor, from: novStart, through: novEnd, calendar: utc).isEmpty)
    }

    @Test func nothingIsDueBeforeTheFirstOccurrence() {
        let (start, end) = monthBounds(2026, 10)
        #expect(BillFrequency.monthly.occurrences(anchor: day(2026, 12, 5), from: start, through: end, calendar: utc).isEmpty)
    }
}

@MainActor
struct MonthSummaryTests {
    let context: ModelContext

    init() throws {
        let container = try ModelContainer(
            for: Bill.self, UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
    }

    private func bill(_ name: String, _ amount: Double, _ due: Date, _ frequency: BillFrequency = .monthly) -> Bill {
        let bill = Bill(name: name, amount: amount, dueDate: due, frequency: frequency)
        context.insert(bill)
        return bill
    }

    @Test func leftoverIsIncomeMinusBillsDueThatMonth() {
        let profile = UserProfile(incomeAmount: 2000, incomeCadence: .biweekly(anchor: day(2026, 10, 2)))
        context.insert(profile)
        let bills = [
            bill("rent", 1500, day(2026, 1, 1)),
            bill("spotify", 11.99, day(2026, 3, 12)),
            bill("insurance", 600, day(2026, 3, 1), .yearly),
        ]

        let october = MonthSummary(month: day(2026, 10, 15), bills: bills, profile: profile, calendar: utc)

        #expect(october.income == 6000)
        #expect(october.paydays.count == 3)
        #expect(october.occurrences.map(\.bill.name) == ["rent", "spotify"])
        #expect(abs(october.billsTotal - 1511.99) < 0.001)
        #expect(abs(october.leftover - 4488.01) < 0.001)
    }

    @Test func paidAndUnpaidSplitTheBillsTotal() {
        let rent = bill("rent", 1500, day(2026, 1, 1))
        let phone = bill("phone", 45, day(2026, 1, 20))
        rent.setPaid(true, for: day(2026, 10, 1), calendar: utc)

        let october = MonthSummary(month: day(2026, 10, 1), bills: [rent, phone], profile: nil, calendar: utc)

        #expect(october.paidTotal == 1500)
        #expect(october.unpaidTotal == 45)
        #expect(october.leftover == -1545)
    }

    @Test func payingAheadSettlesEarlierOccurrences() {
        let rent = bill("rent", 1500, day(2026, 1, 1))
        rent.setPaid(true, for: day(2026, 11, 1), calendar: utc)
        #expect(rent.isPaid(day(2026, 10, 1), calendar: utc))
        #expect(rent.isPaid(day(2026, 11, 1), calendar: utc))
        #expect(!rent.isPaid(day(2026, 12, 1), calendar: utc))
    }

    @Test func unpayingReopensThatOccurrenceAndLater() {
        let rent = bill("rent", 1500, day(2026, 1, 1))
        rent.setPaid(true, for: day(2026, 11, 1), calendar: utc)
        rent.setPaid(false, for: day(2026, 10, 1), calendar: utc)
        #expect(rent.isPaid(day(2026, 9, 1), calendar: utc))
        #expect(!rent.isPaid(day(2026, 10, 1), calendar: utc))
        #expect(!rent.isPaid(day(2026, 11, 1), calendar: utc))
    }
}
