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
        // Americas
        "USD": Currency(name: "US Dollar", code: "USD", symbol: "$"),
        "CAD": Currency(name: "Canadian Dollar", code: "CAD", symbol: "C$"),
        "MXN": Currency(name: "Mexican Peso", code: "MXN", symbol: "$"),
        "BRL": Currency(name: "Brazilian Real", code: "BRL", symbol: "R$"),
        "ARS": Currency(name: "Argentine Peso", code: "ARS", symbol: "$"),
        "CLP": Currency(name: "Chilean Peso", code: "CLP", symbol: "$"),
        "COP": Currency(name: "Colombian Peso", code: "COP", symbol: "$"),
        "PEN": Currency(name: "Peruvian Sol", code: "PEN", symbol: "S/"),
        "UYU": Currency(name: "Uruguayan Peso", code: "UYU", symbol: "$U"),

        // Europe
        "EUR": Currency(name: "Euro", code: "EUR", symbol: "€"),
        "GBP": Currency(name: "British Pound", code: "GBP", symbol: "£"),
        "CHF": Currency(name: "Swiss Franc", code: "CHF", symbol: "Fr"),
        "SEK": Currency(name: "Swedish Krona", code: "SEK", symbol: "kr"),
        "NOK": Currency(name: "Norwegian Krone", code: "NOK", symbol: "kr"),
        "DKK": Currency(name: "Danish Krone", code: "DKK", symbol: "kr"),
        "PLN": Currency(name: "Polish Zloty", code: "PLN", symbol: "zł"),
        "CZK": Currency(name: "Czech Koruna", code: "CZK", symbol: "Kč"),
        "HUF": Currency(name: "Hungarian Forint", code: "HUF", symbol: "Ft"),
        "RON": Currency(name: "Romanian Leu", code: "RON", symbol: "lei"),
        "RUB": Currency(name: "Russian Ruble", code: "RUB", symbol: "₽"),
        "TRY": Currency(name: "Turkish Lira", code: "TRY", symbol: "₺"),
        "UAH": Currency(name: "Ukrainian Hryvnia", code: "UAH", symbol: "₴"),
        "BGN": Currency(name: "Bulgarian Lev", code: "BGN", symbol: "лв"),
        "HRK": Currency(name: "Croatian Kuna", code: "HRK", symbol: "kn"),
        "ISK": Currency(name: "Icelandic Krona", code: "ISK", symbol: "kr"),

        // Middle East
        "AED": Currency(name: "UAE Dirham", code: "AED", symbol: "د.إ"),
        "SAR": Currency(name: "Saudi Riyal", code: "SAR", symbol: "﷼"),
        "KWD": Currency(name: "Kuwaiti Dinar", code: "KWD", symbol: "د.ك"),
        "BHD": Currency(name: "Bahraini Dinar", code: "BHD", symbol: "ب.د"),
        "OMR": Currency(name: "Omani Rial", code: "OMR", symbol: "ر.ع"),
        "QAR": Currency(name: "Qatari Riyal", code: "QAR", symbol: "ر.ق"),
        "JOD": Currency(name: "Jordanian Dinar", code: "JOD", symbol: "د.أ"),
        "ILS": Currency(name: "Israeli Shekel", code: "ILS", symbol: "₪"),
        "EGP": Currency(name: "Egyptian Pound", code: "EGP", symbol: "ج.م"),
        "LBP": Currency(name: "Lebanese Pound", code: "LBP", symbol: "ل.ل"),
        "IQD": Currency(name: "Iraqi Dinar", code: "IQD", symbol: "ع.د"),
        "IRR": Currency(name: "Iranian Rial", code: "IRR", symbol: "﷼"),

        // Asia Pacific
        "JPY": Currency(name: "Japanese Yen", code: "JPY", symbol: "¥"),
        "CNY": Currency(name: "Chinese Yuan", code: "CNY", symbol: "¥"),
        "KRW": Currency(name: "South Korean Won", code: "KRW", symbol: "₩"),
        "INR": Currency(name: "Indian Rupee", code: "INR", symbol: "₹"),
        "IDR": Currency(name: "Indonesian Rupiah", code: "IDR", symbol: "Rp"),
        "THB": Currency(name: "Thai Baht", code: "THB", symbol: "฿"),
        "VND": Currency(name: "Vietnamese Dong", code: "VND", symbol: "₫"),
        "PHP": Currency(name: "Philippine Peso", code: "PHP", symbol: "₱"),
        "MYR": Currency(name: "Malaysian Ringgit", code: "MYR", symbol: "RM"),
        "SGD": Currency(name: "Singapore Dollar", code: "SGD", symbol: "S$"),
        "HKD": Currency(name: "Hong Kong Dollar", code: "HKD", symbol: "HK$"),
        "TWD": Currency(name: "Taiwan Dollar", code: "TWD", symbol: "NT$"),
        "PKR": Currency(name: "Pakistani Rupee", code: "PKR", symbol: "₨"),
        "BDT": Currency(name: "Bangladeshi Taka", code: "BDT", symbol: "৳"),
        "LKR": Currency(name: "Sri Lankan Rupee", code: "LKR", symbol: "₨"),
        "NPR": Currency(name: "Nepalese Rupee", code: "NPR", symbol: "₨"),
        "MMK": Currency(name: "Myanmar Kyat", code: "MMK", symbol: "K"),
        "KHR": Currency(name: "Cambodian Riel", code: "KHR", symbol: "៛"),
        "LAK": Currency(name: "Lao Kip", code: "LAK", symbol: "₭"),

        // Oceania
        "AUD": Currency(name: "Australian Dollar", code: "AUD", symbol: "A$"),
        "NZD": Currency(name: "New Zealand Dollar", code: "NZD", symbol: "NZ$"),
        "FJD": Currency(name: "Fijian Dollar", code: "FJD", symbol: "FJ$"),

        // Africa
        "ZAR": Currency(name: "South African Rand", code: "ZAR", symbol: "R"),
        "NGN": Currency(name: "Nigerian Naira", code: "NGN", symbol: "₦"),
        "KES": Currency(name: "Kenyan Shilling", code: "KES", symbol: "KSh"),
        "GHS": Currency(name: "Ghanaian Cedi", code: "GHS", symbol: "₵"),
        "MAD": Currency(name: "Moroccan Dirham", code: "MAD", symbol: "د.م"),
        "TND": Currency(name: "Tunisian Dinar", code: "TND", symbol: "د.ت"),
        "DZD": Currency(name: "Algerian Dinar", code: "DZD", symbol: "د.ج"),
        "ETB": Currency(name: "Ethiopian Birr", code: "ETB", symbol: "Br"),
        "TZS": Currency(name: "Tanzanian Shilling", code: "TZS", symbol: "TSh"),
        "UGX": Currency(name: "Ugandan Shilling", code: "UGX", symbol: "USh"),
        "RWF": Currency(name: "Rwandan Franc", code: "RWF", symbol: "FRw"),
        "XOF": Currency(name: "West African CFA", code: "XOF", symbol: "CFA"),
        "XAF": Currency(name: "Central African CFA", code: "XAF", symbol: "FCFA")
    ]
    
    static func getCurrency(for code: String) -> Currency {
        return currencies[code] ?? Currency(name: code, code: code, symbol: code)
    }

    /// Get just the currency symbol for a given code
    static func getSymbol(for code: String) -> String {
        return currencies[code]?.symbol ?? code
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