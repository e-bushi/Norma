//
//  CurrencyFormatter.swift
//  Norma
//
//  Currency strings for a decimal amount. Negatives use a leading minus.
//

import Foundation

enum CurrencyFormatter {
    /// "$1,234.50", "-$42.00". The minus sign leads, so a negative amount never uses accounting parentheses.
    static func format(
        _ amount: Decimal,
        currencyCode: String = "USD",
        locale: Locale = Locale(identifier: "en_US")
    ) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        formatter.currencyCode = currencyCode

        // Format the magnitude, then add the sign. Passing the signed value
        // through would follow the locale's negative pattern, which for en_US
        // currency is often "($42.00)" rather than "-$42.00".
        let isNegative = amount < 0
        let magnitude = isNegative ? -amount : amount
        let number = NSDecimalNumber(decimal: magnitude)
        let formatted = formatter.string(from: number) ?? "\(magnitude)"
        return (isNegative ? "-" : "") + formatted
    }

    /// Binary floating-point amounts. The `Decimal` overload is exact.
    static func format(
        _ amount: Double,
        currencyCode: String = "USD",
        locale: Locale = Locale(identifier: "en_US")
    ) -> String {
        format(Decimal(amount), currencyCode: currencyCode, locale: locale)
    }
}
