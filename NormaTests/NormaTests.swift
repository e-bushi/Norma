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

    @Test func semiMonthly28AndLastDayCollapseToOneFebruaryPaycheck() {
        let cadence = IncomeCadence.semiMonthly(day1: 28, day2: 31)
        let (febStart, febEnd) = monthBounds(2026, 2)
        let (janStart, janEnd) = monthBounds(2026, 1)
        #expect(cadence.paydays(from: febStart, through: febEnd, calendar: utc) == [day(2026, 2, 28)])
        #expect(cadence.income(inMonthOf: febStart, amountPerPaycheck: 1000, calendar: utc) == 1000)
        #expect(cadence.collisionNote(inMonthOf: febStart, calendar: utc) == "both paydays land on the 28th, so this counts as one paycheck.")
        #expect(cadence.paydays(from: janStart, through: janEnd, calendar: utc) == [day(2026, 1, 28), day(2026, 1, 31)])
        #expect(cadence.collisionNote(inMonthOf: janStart, calendar: utc) == nil)
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

    @Test func leapDayPlus12MonthsAndPlus48Months() {
        let anchor = day(2024, 2, 29)
        #expect(utc.date(byAdding: .month, value: 12, to: anchor) == day(2025, 2, 28))
        #expect(utc.date(byAdding: .month, value: 48, to: anchor) == day(2028, 2, 29))
        let (feb2025Start, feb2025End) = monthBounds(2025, 2)
        let (feb2028Start, feb2028End) = monthBounds(2028, 2)
        #expect(BillFrequency.yearly.occurrences(anchor: anchor, from: feb2025Start, through: feb2025End, calendar: utc) == [day(2025, 2, 28)])
        #expect(BillFrequency.yearly.occurrences(anchor: anchor, from: feb2028Start, through: feb2028End, calendar: utc) == [day(2028, 2, 29)])
    }

    @Test func quarterlyAnchoredOnThe31stClampsThenRecovers() {
        let anchor = day(2026, 1, 31)
        #expect(BillFrequency.quarterly.occurrences(anchor: anchor, from: day(2026, 1, 1), through: day(2026, 1, 31), calendar: utc) == [anchor])
        #expect(BillFrequency.quarterly.occurrences(anchor: anchor, from: day(2026, 2, 1), through: day(2026, 2, 28), calendar: utc).isEmpty)
        #expect(BillFrequency.quarterly.occurrences(anchor: anchor, from: day(2026, 4, 1), through: day(2026, 4, 30), calendar: utc) == [day(2026, 4, 30)])
        #expect(BillFrequency.quarterly.occurrences(anchor: anchor, from: day(2026, 7, 1), through: day(2026, 7, 31), calendar: utc) == [day(2026, 7, 31)])
    }
}

struct DueDateAnchorTests {
    @Test func frequencyChangeInFebruaryKeepsTheJanuary31Anchor() {
        let anchor = day(2026, 1, 31)
        let displayed = day(2026, 2, 28)
        let saved = Bill.anchorToSave(existingAnchor: anchor, displayedDay: displayed, pickedDay: displayed, calendar: utc)
        #expect(saved == anchor)
        let (aprStart, aprEnd) = monthBounds(2026, 4)
        #expect(BillFrequency.quarterly.occurrences(anchor: saved, from: aprStart, through: aprEnd, calendar: utc) == [day(2026, 4, 30)])
    }

    @Test func pickingADifferentDayReplacesTheAnchor() {
        let anchor = day(2026, 1, 31)
        let displayed = day(2026, 2, 28)
        let picked = day(2026, 2, 15)
        let saved = Bill.anchorToSave(existingAnchor: anchor, displayedDay: displayed, pickedDay: picked, calendar: utc)
        #expect(saved == picked)
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

        #expect(october.incomeMinor == 600_000)
        #expect(october.paydays.count == 3)
        #expect(october.occurrences.map(\.bill.name) == ["rent", "spotify"])
        #expect(october.billsMinor == 151_199)
        #expect(october.leftoverMinor == 448_801)
        #expect(october.incomeMinor - october.billsMinor == october.leftoverMinor)
    }

    @Test func paidAndUnpaidSplitTheBillsTotal() {
        let rent = bill("rent", 1500, day(2026, 1, 1))
        let phone = bill("phone", 45, day(2026, 1, 20))
        rent.setPaid(true, for: day(2026, 10, 1), calendar: utc)

        let october = MonthSummary(month: day(2026, 10, 1), bills: [rent, phone], profile: nil, calendar: utc)

        #expect(october.paidMinor == 150_000)
        #expect(october.unpaidMinor == 4_500)
        #expect(october.leftoverMinor == -154_500)
        #expect(october.isShortfall)
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

    @Test func unpayingTheFirstOccurrenceClearsPaidThrough() {
        let rent = bill("rent", 1500, day(2026, 1, 1))
        rent.setPaid(true, for: day(2026, 1, 1), calendar: utc)
        #expect(rent.paidThrough != nil)
        rent.setPaid(false, for: day(2026, 1, 1), calendar: utc)
        #expect(rent.paidThrough == nil)
    }

    @Test func upcomingUnpaidSkipsPaidOccurrences() {
        let rent = bill("rent", 10, day(2026, 1, 1))
        rent.setPaid(true, for: day(2026, 10, 1), calendar: utc)
        let dates = rent.upcomingUnpaidDates(from: day(2026, 10, 15), calendar: utc)
        #expect(dates.first == day(2026, 11, 1))
    }

    @Test func firstAndLastDayAreInsideTheMonthAndNextFirstIsOutside() {
        let bills = [
            bill("first", 1, day(2026, 10, 1), .oneTime),
            bill("last", 1, day(2026, 10, 31), .oneTime),
            bill("next", 1, day(2026, 11, 1), .oneTime),
        ]
        let october = MonthSummary(month: day(2026, 10, 15), bills: bills, profile: nil, calendar: utc)
        #expect(october.occurrences.map(\.bill.name) == ["first", "last"])
    }

    @Test func dueTodayIsNotOverdueAndYesterdayIs() {
        let bills = [
            bill("yesterday", 1, day(2026, 10, 9), .oneTime),
            bill("today", 1, day(2026, 10, 10), .oneTime),
        ]
        let october = MonthSummary(month: day(2026, 10, 1), bills: bills, profile: nil, calendar: utc)
        let today = day(2026, 10, 10)
        let yesterday = october.occurrences.first { $0.bill.name == "yesterday" }!
        let dueToday = october.occurrences.first { $0.bill.name == "today" }!
        #expect(yesterday.isOverdue(today: today, calendar: utc))
        #expect(!dueToday.isOverdue(today: today, calendar: utc))
    }

    @Test func unpaidOccurrencesFromLastMonthStayOverdueUntilPaid() {
        let profile = UserProfile(incomeAmount: 500, incomeCadence: .monthly(day: 1))
        context.insert(profile)
        let rent = bill("rent", 100, day(2026, 10, 1))
        let gift = bill("gift", 20, day(2026, 10, 15), .oneTime)

        let november = MonthSummary(month: day(2026, 11, 15), bills: [rent, gift], profile: profile, calendar: utc)
        #expect(november.earlierUnpaid.map(\.bill.name) == ["rent", "gift"])
        #expect(november.occurrences.map(\.bill.name) == ["rent"])
        #expect(november.billsMinor == 10_000)
        #expect(november.incomeMinor == 50_000)
        #expect(november.leftoverMinor == 40_000)

        let october = MonthSummary(month: day(2026, 10, 1), bills: [rent, gift], profile: profile, calendar: utc)
        #expect(october.occurrences.map(\.bill.name) == ["rent", "gift"])
        #expect(october.occurrences.allSatisfy { !$0.isPaid })

        rent.setPaid(true, for: day(2026, 10, 1), calendar: utc)
        gift.setPaid(true, for: day(2026, 10, 15), calendar: utc)
        let after = MonthSummary(month: day(2026, 11, 15), bills: [rent, gift], profile: profile, calendar: utc)
        #expect(after.earlierUnpaid.isEmpty)
    }

    @Test func oneThousandMinusTenFiftyAddsUp() {
        let profile = UserProfile(currency: "USD", incomeAmount: 1000, incomeCadence: .monthly(day: 1))
        context.insert(profile)
        let phone = bill("phone", 10.50, day(2026, 10, 5))
        let october = MonthSummary(month: day(2026, 10, 1), bills: [phone], profile: profile, calendar: utc)
        let en = Locale(identifier: "en_US")

        #expect(october.incomeMinor == 100_000)
        #expect(october.billsMinor == 1_050)
        #expect(october.leftoverMinor == 98_950)
        #expect(october.incomeMinor - october.billsMinor == october.leftoverMinor)
        #expect(Money.format(minorUnits: october.incomeMinor, currency: "USD", locale: en) == "$1,000")
        #expect(Money.format(minorUnits: october.billsMinor, currency: "USD", locale: en) == "$10.50")
        #expect(Money.format(minorUnits: october.leftoverMinor, currency: "USD", locale: en) == "$989.50")
    }

    @Test func negativeUnderHalfAUnitKeepsAMinusAndIsAShortfall() {
        let fee = bill("fee", 0.40, day(2026, 10, 3), .oneTime)
        let october = MonthSummary(month: day(2026, 10, 1), bills: [fee], profile: nil, calendar: utc)
        let en = Locale(identifier: "en_US")
        #expect(october.leftoverMinor == -40)
        #expect(october.isShortfall)
        #expect(Money.format(minorUnits: october.leftoverMinor, currency: "USD", locale: en) == "-$0.40")
    }

    @Test func amountThatRoundsToZeroIsNotAShortfall() {
        let dust = bill("dust", 0.004, day(2026, 10, 3), .oneTime)
        let october = MonthSummary(month: day(2026, 10, 1), bills: [dust], profile: nil, calendar: utc)
        let en = Locale(identifier: "en_US")
        #expect(october.billsMinor == 0)
        #expect(october.leftoverMinor == 0)
        #expect(!october.isShortfall)
        #expect(Money.format(minorUnits: 0, currency: "USD", locale: en) == "$0")
    }

    @Test func yenHasNoFractionDigits() {
        let profile = UserProfile(currency: "JPY", incomeAmount: 1000, incomeCadence: .monthly(day: 1))
        context.insert(profile)
        let tea = bill("tea", 1, day(2026, 10, 2))
        let october = MonthSummary(month: day(2026, 10, 1), bills: [tea], profile: profile, calendar: utc)
        let en = Locale(identifier: "en_US")
        #expect(october.incomeMinor == 1000)
        #expect(october.billsMinor == 1)
        #expect(october.leftoverMinor == 999)
        let text = Money.format(minorUnits: october.incomeMinor, currency: "JPY", locale: en)
        #expect(text == "¥1,000")
        #expect(!text.contains("."))
    }

    @Test func centsSumWithoutFloatingPointDrift() {
        let bills = [
            bill("a", 0.10, day(2026, 10, 1), .oneTime),
            bill("b", 0.20, day(2026, 10, 2), .oneTime),
        ]
        let october = MonthSummary(month: day(2026, 10, 1), bills: bills, profile: nil, calendar: utc)
        #expect(october.billsMinor == 30)
    }
}
