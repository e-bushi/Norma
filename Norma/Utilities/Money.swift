//
//  Money.swift
//  Norma
//
//  Formatting and parsing for amounts shown in the user's chosen currency.
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

    /// "$1,400", "$14.99", "-€35". Cents appear only when the amount has
    /// them, unless `wholeUnits` drops them for headline numbers.
    static func format(_ amount: Double, currency: String, wholeUnits: Bool = false) -> String {
        let magnitude = wholeUnits ? abs(amount).rounded() : (abs(amount) * 100).rounded() / 100
        let hasCents = magnitude.truncatingRemainder(dividingBy: 1) != 0
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = hasCents ? 2 : 0
        formatter.maximumFractionDigits = hasCents ? 2 : 0
        let number = formatter.string(from: NSNumber(value: magnitude)) ?? "\(magnitude)"
        return (amount < 0 && magnitude > 0 ? "-" : "") + symbol(for: currency) + number
    }

    /// Reads a typed amount, ignoring grouping separators: "1,400.50" → 1400.5.
    static func parse(_ text: String) -> Double? {
        let cleaned = text.filter { $0.isNumber || $0 == "." }
        guard let value = Double(cleaned), value > 0 else { return nil }
        return value
    }

    /// Text-field form of an amount: no symbol or grouping, cents only if present.
    static func editableText(_ amount: Double) -> String {
        guard amount > 0 else { return "" }
        let isWhole = amount.truncatingRemainder(dividingBy: 1) == 0
        return String(format: isWhole ? "%.0f" : "%.2f", amount)
    }
}
