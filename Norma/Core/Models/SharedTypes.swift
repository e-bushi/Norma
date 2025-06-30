//
//  SharedTypes.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation

// MARK: - Date Range Options

enum ExpenseDateRangeOption {
    case today
    case thisWeek
    case thisMonth
    case thisYear
    case all
}

enum IncomeDateRangeOption {
    case thisMonth
    case thisQuarter
    case thisYear
    case all
}

// MARK: - Summary Types

struct ExpenseSummary {
    let total: Double
    let count: Int
    let average: Double
    let period: DateInterval
}

struct IncomeProjection {
    let totalAmount: Double
    let taxableAmount: Double
    let nonTaxableAmount: Double
    let months: Int
}