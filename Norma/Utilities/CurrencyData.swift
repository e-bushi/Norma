//
//  CurrencyData.swift
//  Norma
//
//  Created by Claude on 7/16/25.
//

import Foundation

struct Currency {
    let name: String
    let code: String
    let symbol: String
}

struct CurrencyData {
    static let currencies: [String: Currency] = [
        "USD": Currency(name: "US Dollar", code: "USD", symbol: "$"),
        "EUR": Currency(name: "Euro", code: "EUR", symbol: "€"),
        "GBP": Currency(name: "British Pound", code: "GBP", symbol: "£"),
        "JPY": Currency(name: "Japanese Yen", code: "JPY", symbol: "¥"),
        "AUD": Currency(name: "Australian Dollar", code: "AUD", symbol: "A$"),
        "CAD": Currency(name: "Canadian Dollar", code: "CAD", symbol: "C$"),
        "CHF": Currency(name: "Swiss Franc", code: "CHF", symbol: "Fr"),
        "CNY": Currency(name: "Chinese Yuan", code: "CNY", symbol: "¥"),
        "SEK": Currency(name: "Swedish Krona", code: "SEK", symbol: "kr"),
        "NZD": Currency(name: "New Zealand Dollar", code: "NZD", symbol: "NZ$"),
        "MXN": Currency(name: "Mexican Peso", code: "MXN", symbol: "$"),
        "SGD": Currency(name: "Singapore Dollar", code: "SGD", symbol: "S$"),
        "HKD": Currency(name: "Hong Kong Dollar", code: "HKD", symbol: "HK$"),
        "NOK": Currency(name: "Norwegian Krone", code: "NOK", symbol: "kr"),
        "KRW": Currency(name: "South Korean Won", code: "KRW", symbol: "₩"),
        "TRY": Currency(name: "Turkish Lira", code: "TRY", symbol: "₺"),
        "INR": Currency(name: "Indian Rupee", code: "INR", symbol: "₹"),
        "RUB": Currency(name: "Russian Ruble", code: "RUB", symbol: "₽"),
        "BRL": Currency(name: "Brazilian Real", code: "BRL", symbol: "R$"),
        "ZAR": Currency(name: "South African Rand", code: "ZAR", symbol: "R"),
        "DKK": Currency(name: "Danish Krone", code: "DKK", symbol: "kr"),
        "PLN": Currency(name: "Polish Zloty", code: "PLN", symbol: "zł"),
        "THB": Currency(name: "Thai Baht", code: "THB", symbol: "฿"),
        "IDR": Currency(name: "Indonesian Rupiah", code: "IDR", symbol: "Rp"),
        "HUF": Currency(name: "Hungarian Forint", code: "HUF", symbol: "Ft"),
        "CZK": Currency(name: "Czech Koruna", code: "CZK", symbol: "Kč"),
        "ILS": Currency(name: "Israeli Shekel", code: "ILS", symbol: "₪"),
        "CLP": Currency(name: "Chilean Peso", code: "CLP", symbol: "$"),
        "PHP": Currency(name: "Philippine Peso", code: "PHP", symbol: "₱"),
        "AED": Currency(name: "UAE Dirham", code: "AED", symbol: "د.إ"),
        "COP": Currency(name: "Colombian Peso", code: "COP", symbol: "$"),
        "SAR": Currency(name: "Saudi Riyal", code: "SAR", symbol: "﷼"),
        "MYR": Currency(name: "Malaysian Ringgit", code: "MYR", symbol: "RM"),
        "RON": Currency(name: "Romanian Leu", code: "RON", symbol: "lei")
    ]
    
    static func getCurrency(for code: String) -> Currency {
        return currencies[code] ?? Currency(name: "US Dollar", code: "USD", symbol: "$")
    }
    
    static func getCurrencyTuple(for code: String) -> (name: String, code: String, symbol: String) {
        let currency = getCurrency(for: code)
        return (currency.name, currency.code, currency.symbol)
    }
    
    static var allCurrencyCodes: [String] {
        return Array(currencies.keys).sorted()
    }
    
    static var allCurrencies: [Currency] {
        return currencies.values.sorted { $0.name < $1.name }
    }
}