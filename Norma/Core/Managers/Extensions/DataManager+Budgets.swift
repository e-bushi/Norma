//
//  DataManager+Budgets.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation

extension DataManager {
    
    // MARK: - Budget Methods
    
    func fetchBudgets(userId: String) async throws {
        // let fetchedBudgets = try await supabaseService.fetchBudgets(userId: userId)
        // budgets = fetchedBudgets
        
        print("Fetching budgets for user: \(userId)")
    }
    
    func addBudget(_ budget: Budget) async throws {
        budgets.append(budget)
        hasUnsyncedChanges = true
        
        // try await supabaseService.createBudget(budget)
        
        print("Added budget: \(budget.name)")
    }
    
    func updateBudget(_ budget: Budget) async throws {
        if let index = budgets.firstIndex(where: { $0.id == budget.id }) {
            budgets[index] = budget
            hasUnsyncedChanges = true
        }
        
        // try await supabaseService.updateBudget(budget)
        
        print("Updated budget: \(budget.name)")
    }
    
    func deleteBudget(_ budget: Budget) async throws {
        budgets.removeAll { $0.id == budget.id }
        hasUnsyncedChanges = true
        
        // try await supabaseService.deleteBudget(budget.id)
        
        print("Deleted budget: \(budget.name)")
    }
    
    // MARK: - Budget Queries
    
    func getActiveBudgets() -> [Budget] {
        let currentDate = Date()
        
        return budgets.filter { budget in
            // Check if budget is active and within date range
            guard budget.isActive else { return false }
            
            let startDate = budget.startDate
            
            // If there's an end date, check if we're within range
            if let endDate = budget.endDate {
                return startDate <= currentDate && currentDate <= endDate
            } else {
                // If no end date, budget is ongoing from start date
                return startDate <= currentDate
            }
        }.sorted { $0.name < $1.name }
    }
    
    func getBudget(for category: Category) -> Budget? {
        return getActiveBudgets().first { budget in
            budget.categoryId == category.id
        }
    }
    
    func getBudgetUtilization(for budget: Budget) -> Double {
        guard let categoryId = budget.categoryId,
              let category = categories.first(where: { $0.id == categoryId }) else {
            return 0
        }
        
        let currentMonth = DateInterval(
            start: Date().startOfMonth(),
            end: Date().endOfMonth()
        )
        
        let spent = getExpenses(for: category, in: currentMonth)
            .reduce(0) { $0 + $1.amount }
        
        return budget.amount > 0 ? (spent / budget.amount) : 0
    }
    
    func getOverBudgetCategories() -> [(category: Category, budget: Budget, spent: Double)] {
        var overBudgetList: [(Category, Budget, Double)] = []
        
        for budget in getActiveBudgets() {
            guard let categoryId = budget.categoryId,
                  let category = categories.first(where: { $0.id == categoryId }) else {
                continue
            }
            
            let currentMonth = DateInterval(
                start: Date().startOfMonth(),
                end: Date().endOfMonth()
            )
            
            let spent = getExpenses(for: category, in: currentMonth)
                .reduce(0) { $0 + $1.amount }
            
            if spent > budget.amount {
                overBudgetList.append((category, budget, spent))
            }
        }
        
        return overBudgetList
    }
    
    func getTotalBudgetAmount() -> Double {
        return getActiveBudgets().reduce(0) { $0 + $1.amount }
    }
    
    func getRemainingBudget() -> Double {
        let totalBudget = getTotalBudgetAmount()
        let currentMonth = DateInterval(
            start: Date().startOfMonth(),
            end: Date().endOfMonth()
        )
        let totalSpent = getTotalExpenses(for: currentMonth)
        
        return totalBudget - totalSpent
    }
}

// MARK: - Date Extensions

extension Date {
    func startOfMonth() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
    
    func endOfMonth() -> Date {
        let calendar = Calendar.current
        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth()) {
            return calendar.date(byAdding: .day, value: -1, to: nextMonth) ?? self
        }
        return self
    }
}