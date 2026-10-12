//
//  UserProfile.swift
//  Norma
//
//  The single on-device profile: the user's currency and how they're paid.
//  Its existence is what marks onboarding as complete.
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    var currency: String = "USD"
    /// Amount received per paycheck, after tax — not a monthly figure.
    var incomeAmount: Double = 0

    // The cadence is stored flat so SwiftData can persist it; read and write
    // it through `incomeCadence`.
    var incomeCadenceRaw: String = "monthly"
    var incomeWeekday: Int?
    var incomeAnchorDate: Date?
    var incomeDay1: Int?
    var incomeDay2: Int?

    var createdAt: Date = Date()

    init(currency: String = "USD", incomeAmount: Double = 0, incomeCadence: IncomeCadence = .monthly(day: 1)) {
        self.currency = currency
        self.incomeAmount = incomeAmount
        self.incomeCadence = incomeCadence
    }

    var incomeCadence: IncomeCadence {
        get {
            switch incomeCadenceRaw {
            case "weekly": return .weekly(weekday: incomeWeekday ?? 6)
            case "biweekly": return .biweekly(anchor: incomeAnchorDate ?? createdAt)
            case "semiMonthly": return .semiMonthly(day1: incomeDay1 ?? 15, day2: incomeDay2 ?? 31)
            case "irregular": return .irregular
            default: return .monthly(day: incomeDay1 ?? 1)
            }
        }
        set {
            incomeWeekday = nil
            incomeAnchorDate = nil
            incomeDay1 = nil
            incomeDay2 = nil
            switch newValue {
            case .weekly(let weekday):
                incomeCadenceRaw = "weekly"
                incomeWeekday = weekday
            case .biweekly(let anchor):
                incomeCadenceRaw = "biweekly"
                incomeAnchorDate = anchor
            case .semiMonthly(let day1, let day2):
                incomeCadenceRaw = "semiMonthly"
                incomeDay1 = day1
                incomeDay2 = day2
            case .monthly(let day):
                incomeCadenceRaw = "monthly"
                incomeDay1 = day
            case .irregular:
                incomeCadenceRaw = "irregular"
            }
        }
    }

    var hasIncome: Bool { incomeAmount > 0 }

    func income(inMonthOf month: Date, calendar: Calendar = .current) -> Double {
        incomeCadence.income(inMonthOf: month, amountPerPaycheck: incomeAmount, calendar: calendar)
    }

    func paydays(from: Date, through: Date, calendar: Calendar = .current) -> [Date] {
        guard hasIncome else { return [] }
        return incomeCadence.paydays(from: from, through: through, calendar: calendar)
    }
}
