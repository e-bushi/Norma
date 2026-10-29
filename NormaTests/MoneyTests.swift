//
//  MoneyTests.swift
//  NormaTests
//
//  Locale parsing and minor-unit rounding. Locales are passed in so the
//  machine's region doesn't change the result.
//

import Foundation
import Testing
@testable import Norma

struct MoneyParseTests {
    private let german = Locale(identifier: "de_DE")
    private let english = Locale(identifier: "en_US")
    private let japanese = Locale(identifier: "ja_JP")

    @Test func commaDecimalParsesAsCents() {
        #expect(Money.parse("10,50", locale: german, currency: "EUR") == 10.5)
        #expect(Money.minorUnits(fromMajor: 10.5, currency: "EUR") == 1_050)
    }

    @Test func germanGroupingSeparatorParsesAsThousands() {
        #expect(Money.parse("2.000", locale: german, currency: "EUR") == 2000)
        #expect(Money.parse("1.400,50", locale: german, currency: "EUR") == 1400.5)
    }

    @Test func englishGroupingAndDecimal() {
        #expect(Money.parse("1,400.50", locale: english, currency: "USD") == 1400.5)
        #expect(Money.parse("10.50", locale: english, currency: "USD") == 10.5)
    }

    @Test func yenDropsTheFraction() {
        #expect(Money.parse("1,000", locale: japanese, currency: "JPY") == 1000)
        #expect(Money.parse("1,000.4", locale: japanese, currency: "JPY") == 1000)
        #expect(Money.minorUnits(fromMajor: 1000, currency: "JPY") == 1000)
        #expect(Money.fractionDigits(for: "JPY") == 0)
        #expect(Money.fractionDigits(for: "KRW") == 0)
        let text = Money.format(minorUnits: 1000, currency: "JPY", locale: english)
        #expect(text == "¥1,000")
        #expect(!text.contains("."))
        let won = Money.format(minorUnits: 5000, currency: "KRW", locale: english)
        #expect(!won.contains("."))
    }

    @Test func editableTextRoundTripsInACommaLocale() {
        let edited = Money.editableText(10.50, locale: german, currency: "EUR")
        #expect(edited == "10,50")
        #expect(Money.parse(edited, locale: german, currency: "EUR") == 10.5)
        #expect(Money.editableText(2000, locale: german, currency: "EUR") == "2000")
        #expect(Money.editableText(2000, locale: japanese, currency: "JPY") == "2000")
    }

    @Test func centsAddInMinorUnits() {
        let a = Money.minorUnits(fromMajor: 0.10, currency: "USD")
        let b = Money.minorUnits(fromMajor: 0.20, currency: "USD")
        #expect(a + b == 30)
        #expect(Money.minorUnits(fromMajor: 11.99, currency: "USD") == 1_199)
        #expect(Money.minorUnits(fromMajor: 10.50, currency: "USD") == 1_050)
        #expect(Money.minorUnits(fromMajor: 0.40, currency: "USD") == 40)
    }

    @Test func negativeMinorUnitsKeepTheMinusUntilTheyRoundToZero() {
        #expect(Money.format(minorUnits: -40, currency: "USD", locale: english) == "-$0.40")
        #expect(Money.format(minorUnits: 0, currency: "USD", locale: english) == "$0")
        #expect(!Money.format(minorUnits: 0, currency: "USD", locale: english).contains("-"))
    }

    @Test func emptyAndZeroDoNotParse() {
        #expect(Money.parse("", locale: english, currency: "USD") == nil)
        #expect(Money.parse("0", locale: english, currency: "USD") == nil)
        #expect(Money.parse("0,00", locale: german, currency: "EUR") == nil)
    }
}
