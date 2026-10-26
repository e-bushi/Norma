//
//  CurrencyFormatterTests.swift
//  NormaTests
//
//  USD strings in en_US. Each test is tagged with its acceptance check.
//

import Foundation
import Testing

@testable import Norma

struct CurrencyFormatterTests {
    @Test("AC-1: 1234.5 formats as $1,234.50")
    func formatsGroupedDollarsAndCents() throws {
        // AC-1
        let enUS = Locale(identifier: "en_US")
        let amount = try #require(Decimal(string: "1234.5", locale: enUS))
        #expect(CurrencyFormatter.format(amount) == "$1,234.50")
        #expect(CurrencyFormatter.format(1234.5) == "$1,234.50")
    }

    @Test("AC-2: -42 formats as -$42.00")
    func negativeAmountUsesLeadingMinus() {
        // AC-2
        #expect(CurrencyFormatter.format(Decimal(-42)) == "-$42.00")
        #expect(CurrencyFormatter.format(-42.0) == "-$42.00")
    }
}
