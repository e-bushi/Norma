//
//  CurrencyFormatterTests.swift
//  NormaTests
//
//  USD strings in en_US. Each test is tagged with its acceptance check.
//

import Testing

@testable import Norma

struct CurrencyFormatterTests {
    @Test("AC-1: 1234.5 formats as $1,234.50")
    func formatsGroupedDollarsAndCents() {
        // AC-1
        #expect(CurrencyFormatter.format(1234.5) == "$1,234.50")
    }

    @Test("AC-2: -42 formats as -$42.00")
    func negativeAmountUsesLeadingMinus() {
        // AC-2
        #expect(CurrencyFormatter.format(-42) == "-$42.00")
    }
}
