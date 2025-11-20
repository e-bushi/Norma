//
//  ArcCalculationService.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation

struct ArcCalculationService {

    /// Calculate the number of arcs a user has based on their financial data
    ///
    /// Formula (Billing Cycle Approach):
    /// 1 arc = 1 complete billing cycle (can pay all bills once)
    /// arcs = floor(freedomFund / totalMonthlyExpenses)
    ///
    /// Critical Bill Gate:
    /// If freedomFund < most critical bill amount → 0 arcs
    /// (Can't survive next billing cycle without covering critical bill)
    ///
    /// - Parameters:
    ///   - freedomFund: User's freedom fund (money set aside to cover bills/lifestyle if income stopped)
    ///   - bills: Array of user's bills
    ///   - budgets: Array of user's selected budgets
    /// - Returns: The number of arcs (billing cycles), or 0 if calculation isn't possible
    static func calculateArcs(freedomFund: Double, bills: [Bill], budgets: [Budget] = []) -> Int {
        // Calculate total monthly expenses
        let totalMonthlyBills = calculateMonthlyBillsTotal(bills: bills)
        let totalMonthlyBudgets = calculateBudgetsTotal(budgets: budgets)
        let totalMonthlyExpenses = totalMonthlyBills + totalMonthlyBudgets

        // Guard against division by zero
        guard totalMonthlyExpenses > 0 else {
            return 0
        }

        // Critical Bill Gate: If there's a most critical bill (usually rent/mortgage)
        // and the freedom fund can't cover it, return 0 arcs
        if let criticalBill = bills.first(where: { $0.isMostCritical == true }) {
            let criticalMonthlyAmount = calculateMonthlyBillsTotal(bills: [criticalBill])
            if freedomFund < criticalMonthlyAmount {
                return 0  // Can't survive next billing cycle without covering critical bill
            }
        }

        // Calculate arcs: 1 arc = 1 complete billing cycle
        let arcs = floor(freedomFund / totalMonthlyExpenses)

        return Int(arcs)
    }

    /// Calculate the total monthly bill amount from an array of bills
    /// Converts all bill frequencies to monthly equivalents
    ///
    /// - Parameter bills: Array of user's bills
    /// - Returns: Total monthly bill amount
    static func calculateMonthlyBillsTotal(bills: [Bill]) -> Double {
        return bills.reduce(into: 0.0) { total, bill in
            let monthlyAmount: Double

            switch bill.frequency {
            case .monthly:
                monthlyAmount = bill.amount
            case .quarterly:
                monthlyAmount = bill.amount / 3.0
            case .yearly:
                monthlyAmount = bill.amount / 12.0
            }

            total += monthlyAmount
        }
    }

    /// Calculate the total monthly budget amount from an array of budgets
    ///
    /// - Parameter budgets: Array of user's budgets
    /// - Returns: Total monthly budget amount
    static func calculateBudgetsTotal(budgets: [Budget]) -> Double {
        return budgets.reduce(into: 0.0) { total, budget in
            total += budget.amount
        }
    }

    /// Get the state name based on arc count
    ///
    /// - Parameter arcCount: Number of arcs (1 arc = 1 billing cycle)
    /// - Returns: State name (Urgency, Cautionary, Steady, Calm, or Abundant)
    static func getStateName(arcCount: Int) -> String {
        switch arcCount {
        case ...1:
            return "Urgency"
        case 2...3:
            return "Cautionary"
        case 4...6:
            return "Steady"
        case 7...12:
            return "Calm"
        default: // 13+
            return "Abundant"
        }
    }

    /// Get the state description based on arc count
    ///
    /// - Parameter arcCount: Number of arcs (1 arc = 1 billing cycle)
    /// - Returns: State description
    static func getStateDescription(arcCount: Int) -> String {
        switch arcCount {
        case ...1:
            return "less than a month. Every decision matters right now."
        case 2...3:
            return "some breathing room, but not quite comfortable yet."
        case 4...6:
            return "solid ground, rhythm found."
        case 7...12:
            return "real distance from zero."
        default: // 13+
            return "serious financial cushion."
        }
    }

    /// Convert days to human-scale time description
    ///
    /// - Parameter days: Number of days
    /// - Returns: Human-readable time description (e.g., "about 3 weeks", "over 2 months")
    static func convertDaysToHumanScale(days: Int) -> String {
        switch days {
        case 0:
            return "zero days"
        case 1...6:
            return "\(days) day\(days == 1 ? "" : "s")"
        case 7...13:
            return "about a week"
        case 14...20:
            return "about 2 weeks"
        case 21...27:
            return "about 3 weeks"
        case 28...44:
            return "about a month"
        case 45...74:
            return "about 2 months"
        case 75...104:
            return "about 3 months"
        case 105...165:
            return "about 4 months"
        case 166...225:
            return "about 6 months"
        case 226...285:
            return "about 8 months"
        case 286...345:
            return "about 10 months"
        case 346...410:
            return "almost a year"
        case 411...540:
            return "over a year"
        case 541...720:
            return "about a year and a half"
        case 721...900:
            return "about 2 years"
        default: // 900+
            let years = days / 365
            return "over \(years) year\(years == 1 ? "" : "s")"
        }
    }
}
