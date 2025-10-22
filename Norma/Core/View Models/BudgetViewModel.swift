//
//  BudgetViewModel.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class BudgetViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var budgets: [Budget] = []
    @Published var activeBudgets: [Budget] = []
    @Published var selectedBudget: Budget?
    
    // Budget Performance
    @Published var budgetPerformance: [BudgetPerformance] = []
    @Published var overBudgetItems: [Budget] = []
    @Published var nearLimitBudgets: [Budget] = []
    
    // UI State
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var showAddBudget = false
    
    // Statistics
    @Published var totalBudgeted: Double = 0
    @Published var totalSpent: Double = 0
    @Published var remainingBudget: Double = 0
    
    // MARK: - Dependencies
    
    private let dataManager: DataManager
    private let sessionViewModel: SessionViewModel
    private var expenseViewModel: ExpenseViewModel?
    
    // MARK: - Initialization
    
    init(dataManager: DataManager, sessionViewModel: SessionViewModel) {
        self.dataManager = dataManager
        self.sessionViewModel = sessionViewModel
        
        setupObservers()
        loadBudgets()
    }
    
    func setExpenseViewModel(_ expenseViewModel: ExpenseViewModel) {
        self.expenseViewModel = expenseViewModel
        setupExpenseObserver()
        updateBudgetPerformance()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observe DataManager budgets changes
        dataManager.$budgets
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadBudgets()
            }
            .store(in: &cancellables)
    }
    
    private func setupExpenseObserver() {
        // Observe expense changes to update budget performance
        expenseViewModel?.$expenses
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateBudgetPerformance()
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Data Loading
    
    func loadBudgets() {
        budgets = dataManager.budgets
        activeBudgets = budgets.filter { $0.isActive }
        updateBudgetPerformance()
        updateStatistics()
    }

    func refreshBudgets() async {
        guard let userId = sessionViewModel.currentUser?.userId else { return }

        isLoading = true
        clearError()

        do {
            try await dataManager.fetchBudgetsWithEncryption(userId: userId)
            // loadBudgets() will be called automatically by the observer
        } catch {
            showError(error.localizedDescription)
        }

        isLoading = false
    }
    
    // MARK: - Budget Management
    
    func addBudget(
        name: String,
        amount: Double,
        categoryId: String? = nil,
        startDate: Date = Date(),
        endDate: Date? = nil,
        notificationThreshold: Double? = nil,
        notes: String? = nil
    ) async {
        guard let userId = sessionViewModel.currentUser?.userId else {
            showError("No user found")
            return
        }
        
        isLoading = true
        clearError()
        
        let newBudget = Budget(
            userId: userId,
            name: name,
            amount: amount,
            categoryId: categoryId,
            startDate: startDate,
            endDate: endDate,
            isActive: true,
            alertThreshold: notificationThreshold ?? 0.8,
            notes: notes
        )
        
        do {
            try await dataManager.addBudget(newBudget)
            loadBudgets()
            showAddBudget = false
        } catch {
            showError("Failed to add budget: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func updateBudget(_ budget: Budget) async {
        isLoading = true
        clearError()
        
        do {
            try await dataManager.updateBudget(budget)
            loadBudgets()
        } catch {
            showError("Failed to update budget: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func deleteBudget(_ budget: Budget) async {
        isLoading = true
        clearError()
        
        do {
            try await dataManager.deleteBudget(budget)
            loadBudgets()
        } catch {
            showError("Failed to delete budget: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func toggleBudgetActive(_ budget: Budget) async {
        var updatedBudget = budget
        updatedBudget.isActive.toggle()
        await updateBudget(updatedBudget)
    }
    
    // MARK: - Budget Performance
    
    private func updateBudgetPerformance() {
        let currentDate = Date()
        var performances: [BudgetPerformance] = []
        var overBudget: [Budget] = []
        var nearLimit: [Budget] = []
        
        for budget in activeBudgets {
            let dateRange = getDateRange(for: budget, currentDate: currentDate)
            let expenses = getExpensesForBudget(budget, in: dateRange)
            let spent = expenses.reduce(0) { $0 + $1.amount }
            let remaining = budget.amount - spent
            let percentageUsed = budget.amount > 0 ? (spent / budget.amount) * 100 : 0
            
            let performance = BudgetPerformance(
                budget: budget,
                spent: spent,
                remaining: remaining,
                percentageUsed: percentageUsed,
                period: dateRange
            )
            
            performances.append(performance)
            
            // Check if over budget
            if spent > budget.amount {
                overBudget.append(budget)
            }
            // Check if near limit (above 80%)
            else if percentageUsed >= 80 {
                nearLimit.append(budget)
            }
        }
        
        budgetPerformance = performances
        overBudgetItems = overBudget
        nearLimitBudgets = nearLimit
    }
    
    private func getExpensesForBudget(_ budget: Budget, in dateRange: DateInterval) -> [Expense] {
        guard let expenseViewModel = expenseViewModel else { return [] }
        
        let dateFormatter = ISO8601DateFormatter()
        let expenses = expenseViewModel.expenses.filter { expense in
            guard let expenseDate = dateFormatter.date(from: expense.expenseDate) else { return false }
            return dateRange.contains(expenseDate)
        }
        
        return expenses
    }
    
    private func getDateRange(for budget: Budget, currentDate: Date) -> DateInterval {
        // Simply use the budget's start and end dates
        return DateInterval(start: budget.startDate, end: budget.endDate ?? currentDate)
    }
    
    // MARK: - Statistics
    
    private func updateStatistics() {
        totalBudgeted = activeBudgets.reduce(0) { $0 + $1.amount }
        totalSpent = budgetPerformance.reduce(0) { $0 + $1.spent }
        remainingBudget = totalBudgeted - totalSpent
    }
    
    func getBudgetSummary() -> BudgetSummary {
        let averageUtilization = budgetPerformance.isEmpty ? 0 :
            budgetPerformance.reduce(0) { $0 + $1.percentageUsed } / Double(budgetPerformance.count)
        
        return BudgetSummary(
            totalBudgeted: totalBudgeted,
            totalSpent: totalSpent,
            remainingBudget: remainingBudget,
            averageUtilization: averageUtilization,
            overBudgetCount: overBudgetItems.count,
            nearLimitCount: nearLimitBudgets.count
        )
    }
    
    // MARK: - Budget Recommendations
    
    func generateBudgetRecommendations() -> [BudgetRecommendation] {
        var recommendations: [BudgetRecommendation] = []
        
        guard let expenseViewModel = expenseViewModel else { return recommendations }
        
        // Analyze spending patterns
        let categories = dataManager.categories
        let expensesByCategory = expenseViewModel.expensesByCategory
        
        for category in categories {
            let hasExistingBudget = budgets.contains { $0.categoryId == category.id }
            
            if !hasExistingBudget, let spending = expensesByCategory[category], spending > 0 {
                // Recommend budget for categories with spending but no budget
                let recommendedAmount = spending * 1.1 // 10% buffer
                recommendations.append(BudgetRecommendation(
                    category: category,
                    recommendedAmount: recommendedAmount,
                    reason: "You've spent \(formatCurrency(spending)) in \(category.name) without a budget"
                ))
            }
        }
        
        // Check for consistently over-budget categories
        for performance in budgetPerformance where performance.percentageUsed > 110 {
            if let category = categories.first(where: { $0.id == performance.budget.categoryId }) {
                let recommendedAmount = performance.spent * 1.15 // 15% buffer
                recommendations.append(BudgetRecommendation(
                    category: category,
                    recommendedAmount: recommendedAmount,
                    reason: "You consistently exceed your \(category.name) budget"
                ))
            }
        }
        
        return recommendations
    }
    
    // MARK: - Helper Methods
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = sessionViewModel.currentUser?.settings.currency ?? "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
    
    func getBudgetStatus(_ budget: Budget) -> (text: String, color: Color) {
        guard let performance = budgetPerformance.first(where: { $0.budget.id == budget.id }) else {
            return ("No data", .secondary)
        }
        
        if performance.percentageUsed >= 100 {
            return ("Over budget", .red)
        } else if performance.percentageUsed >= 80 {
            return ("Near limit", .orange)
        } else if performance.percentageUsed >= 50 {
            return ("On track", .yellow)
        } else {
            return ("Good", .green)
        }
    }
    
    // MARK: - Error Handling
    
    private func clearError() {
        showError = false
        errorMessage = ""
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showError = true
        
        // Auto-hide error after 5 seconds
        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            await MainActor.run {
                clearError()
            }
        }
    }
}

// MARK: - Supporting Types

struct BudgetPerformance: Identifiable {
    let id = UUID()
    let budget: Budget
    let spent: Double
    let remaining: Double
    let percentageUsed: Double
    let period: DateInterval
}

struct BudgetSummary {
    let totalBudgeted: Double
    let totalSpent: Double
    let remainingBudget: Double
    let averageUtilization: Double
    let overBudgetCount: Int
    let nearLimitCount: Int
}

struct BudgetRecommendation: Identifiable {
    let id = UUID()
    let category: Category
    let recommendedAmount: Double
    let reason: String
}
