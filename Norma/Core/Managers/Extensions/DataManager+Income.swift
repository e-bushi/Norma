//
//  DataManager+Income.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation

extension DataManager {
    
    // MARK: - Income Methods
    
    func fetchIncomes(userId: String) async throws {
        // let fetchedIncome = try await supabaseService.fetchIncome(userId: userId)
        // income = fetchedIncome
        
        print("Fetching income for user: \(userId)")
    }
    
    func addIncome(_ incomeItem: Income) async throws {
        income.append(incomeItem)
        hasUnsyncedChanges = true
        
        // try await supabaseService.createIncome(incomeItem)
        
        print("Added income: \(incomeItem.source)")
    }
    
    func updateIncome(_ incomeItem: Income) async throws {
        if let index = income.firstIndex(where: { $0.id == incomeItem.id }) {
            income[index] = incomeItem
            hasUnsyncedChanges = true
        }
        
        // try await supabaseService.updateIncome(incomeItem)
        
        print("Updated income: \(incomeItem.source)")
    }
    
    func deleteIncome(_ incomeItem: Income) async throws {
        income.removeAll { $0.id == incomeItem.id }
        hasUnsyncedChanges = true
        
        // try await supabaseService.deleteIncome(incomeItem.id)
        
        print("Deleted income: \(incomeItem.source)")
    }
    
    // MARK: - Income Queries
    
    func getIncomes(for period: DateInterval? = nil) -> [Income] {
        var filtered = income
        
        if let period = period {
            filtered = filtered.filter { incomeItem in
                return period.contains(incomeItem.nextDate)
            }
        }
        
        return filtered.sorted { $0.nextDate > $1.nextDate }
    }
    
    func getActiveIncome() -> [Income] {
        return income.filter { $0.isActive }
    }
    
    func getTotalMonthlyIncome() -> Double {
        return getActiveIncome().reduce(0) { total, incomeItem in
            switch incomeItem.frequency {
            case .monthly:
                return total + incomeItem.amount
            case .biweekly:
                return total + (incomeItem.amount * 26 / 12)
            case .weekly:
                return total + (incomeItem.amount * 52 / 12)
            case .quarterly:
                return total + (incomeItem.amount * 4 / 12)
            case .semiAnnually:
                return total + (incomeItem.amount * 2 / 12)
            case .yearly:
                return total + (incomeItem.amount / 12)
            case .oneTime:
                // For one-time income, only count if started this month
                if Calendar.current.isDate(incomeItem.nextDate, equalTo: Date(), toGranularity: .month) {
                    return total + incomeItem.amount
                }
                return total
            }
        }
    }
    
    func getIncomeBySource() -> [IncomeSource: Double] {
        var incomeBySource: [IncomeSource: Double] = [:]
        
        for incomeItem in income where incomeItem.isActive {
            incomeBySource[incomeItem.source, default: 0] += incomeItem.amount
        }
        
        return incomeBySource
    }
    
    func getProjectedAnnualIncome() -> Double {
        return getTotalMonthlyIncome() * 12
    }
}