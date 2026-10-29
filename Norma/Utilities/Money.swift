//
//  Money.swift
//  Norma
//
//  Amounts are stored on Bill and UserProfile as major-unit Doubles so an
//  existing SwiftData store still opens. Every sum and every label converts
//  that Double to integer minor units (cents, or whole yen) first and rounds
//  once to the currency's fraction digits.
//

import Foundation

enum Money {
    struct Currency: Identifiable {
        let code: String
        let flag: String
        var id: String { code }
    }

    static let currencies: [Currency] = [
        Currency(code: "USD", flag: "🇺🇸"),
        Currency(code: "EUR", flag: "🇪🇺"),
        Currency(code: "GBP", flag: "🇬🇧"),
        Currency(code: "CAD", flag: "🇨🇦"),
        Currency(code: "AUD", flag: "🇦🇺"),
        Currency(code: "JPY", flag: "🇯🇵"),
        Currency(code: "CNY", flag: "🇨🇳"),
        Currency(code: "INR", flag: "🇮🇳"),
        Currency(code: "THB", flag: "🇹🇭"),
        Currency(code: "MXN", flag: "🇲🇽"),
        Currency(code: "BRL", flag: "🇧🇷"),
        Currency(code: "SGD", flag: "🇸🇬"),
        Currency(code: "HKD", flag: "🇭🇰"),
        Currency(code: "KRW", flag: "🇰🇷"),
        Currency(code: "CHF", flag: "🇨🇭"),
    ]

    static func flag(for code: String) -> String {
        currencies.first { $0.code == code }?.flag ?? "🏳️"
    }

    static func symbol(for code: String) -> String {
        switch code.uppercased() {
        case "USD", "CAD", "AUD", "NZD", "SGD", "HKD", "MXN": return "$"
        case "THB": return "฿"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY", "CNY": return "¥"
        case "INR": return "₹"
        case "KRW": return "₩"
        case "VND": return "₫"
        case "PHP": return "₱"
        case "BRL": return "R$"
        case "CHF": return "CHF "
        default: return code + " "
        }
    }

    /// Decimal places for the currency. Yen and won have none.
    static func fractionDigits(for currency: String) -> Int {
        switch currency.uppercased() {
        case "JPY", "KRW", "VND": return 0
        default: return 2
        }
    }

    /// "$1,400", "$14.99", "-€0,40". Fraction digits follow the currency, and
    /// a zero minor-unit amount never keeps a minus sign.
    static func format(minorUnits: Int, currency: String, locale: Locale = .current) -> String {
        let digits = fractionDigits(for: currency)
        let negative = minorUnits < 0
        let magnitude = abs(minorUnits)
        let showsFraction = digits > 0 && magnitude % powerOfTen(digits) != 0
        let major = majorDecimal(minorUnits: magnitude, fractionDigits: digits)

        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = showsFraction ? digits : 0
        formatter.maximumFractionDigits = showsFraction ? digits : 0
        let number = formatter.string(from: NSDecimalNumber(decimal: major)) ?? "0"
        let sign = negative && magnitude > 0 ? "-" : ""
        return sign + symbol(for: currency) + number
    }

    /// Major-unit convenience. Rounds to minor units before formatting.
    static func format(_ amount: Double, currency: String, locale: Locale = .current) -> String {
        format(minorUnits: minorUnits(fromMajor: amount, currency: currency), currency: currency, locale: locale)
    }

    /// Integer cents (or yen) for a stored major-unit amount.
    static func minorUnits(fromMajor amount: Double, currency: String) -> Int {
        let digits = fractionDigits(for: currency)
        // String(Double) is the shortest round-trip, so 11.99 stays "11.99"
        // instead of the binary expansion. Rounding to the currency scale
        // then absorbs anything that still isn't exact.
        let decimal = Decimal(string: String(amount), locale: posix) ?? Decimal(amount)
        let rounded = round(decimal, scale: digits)
        return minorUnits(fromRoundedMajor: rounded, fractionDigits: digits)
    }

    /// Reads a typed amount with the locale's decimal and grouping separators.
    /// "10,50" in de_DE is 10.50. "2.000" in de_DE is 2000. Zero-fraction
    /// currencies drop the fractional part. Empty, zero, and negative fail.
    static func parse(_ text: String, locale: Locale = .current, currency: String? = nil) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.contains("-") else { return nil }

        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        let decimalSeparator = formatter.decimalSeparator ?? "."
        let groupingSeparator = formatter.groupingSeparator ?? ","

        var cleaned =
            trimmed
            .replacingOccurrences(of: "\u{00A0}", with: "")
            .replacingOccurrences(of: "\u{202F}", with: "")
            .replacingOccurrences(of: " ", with: "")
        if !groupingSeparator.isEmpty, groupingSeparator != decimalSeparator {
            cleaned = cleaned.replacingOccurrences(of: groupingSeparator, with: "")
        }
        if decimalSeparator != "." {
            cleaned = cleaned.replacingOccurrences(of: decimalSeparator, with: ".")
        }

        var numeric = ""
        var sawDecimal = false
        for character in cleaned {
            if character.isNumber {
                numeric.append(character)
            } else if character == ".", !sawDecimal {
                numeric.append(".")
                sawDecimal = true
            }
        }
        if numeric.hasSuffix(".") { numeric.removeLast() }
        guard !numeric.isEmpty, let decimal = Decimal(string: numeric, locale: posix), decimal > 0 else {
            return nil
        }

        let digits = fractionDigits(for: currency ?? "USD")
        let rounded = round(decimal, scale: digits)
        guard rounded > 0 else { return nil }
        return NSDecimalNumber(decimal: rounded).doubleValue
    }

    /// Text-field form of an amount: no symbol or grouping, locale decimal
    /// separator, cents only when the currency has them and the amount isn't whole.
    static func editableText(_ amount: Double, locale: Locale = .current, currency: String = "USD") -> String {
        let minor = minorUnits(fromMajor: amount, currency: currency)
        guard minor > 0 else { return "" }
        let digits = fractionDigits(for: currency)
        let showsFraction = digits > 0 && minor % powerOfTen(digits) != 0
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = showsFraction ? digits : 0
        formatter.maximumFractionDigits = showsFraction ? digits : 0
        let major = majorDecimal(minorUnits: minor, fractionDigits: digits)
        return formatter.string(from: NSDecimalNumber(decimal: major)) ?? ""
    }

    // MARK: - Decimal helpers

    private static let posix = Locale(identifier: "en_US_POSIX")

    private static func powerOfTen(_ digits: Int) -> Int {
        var result = 1
        for _ in 0..<digits { result *= 10 }
        return result
    }

    private static func round(_ value: Decimal, scale: Int) -> Decimal {
        var input = value
        var result = Decimal()
        NSDecimalRound(&result, &input, scale, .plain)
        return result
    }

    private static func minorUnits(fromRoundedMajor value: Decimal, fractionDigits: Int) -> Int {
        var minor = value
        if fractionDigits > 0 {
            var factor = Decimal(1)
            for _ in 0..<fractionDigits { factor *= 10 }
            minor *= factor
        }
        var whole = Decimal()
        var source = minor
        NSDecimalRound(&whole, &source, 0, .plain)
        return Int(NSDecimalNumber(decimal: whole).int64Value)
    }

    private static func majorDecimal(minorUnits: Int, fractionDigits: Int) -> Decimal {
        var major = Decimal(minorUnits)
        if fractionDigits > 0 {
            var factor = Decimal(1)
            for _ in 0..<fractionDigits { factor *= 10 }
            major /= factor
        }
        return major
    }
}
