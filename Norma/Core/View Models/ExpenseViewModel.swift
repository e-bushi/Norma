//
//  ExpenseViewModel.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ExpenseViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var expenses: [Expense] = []
    @Published var recentExpenses: [Expense] = []
    @Published var expensesByCategory: [Category: Double] = [:]
    
    // Filtering
    @Published var selectedCategory: Category?
    @Published var selectedDateRange: DateInterval?
    @Published var searchText = ""
    @Published var selectedPaymentMethod: PaymentMethod?
    
    // UI State
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var selectedExpense: Expense?
    @Published var showAddExpense = false
    
    // Statistics
    @Published var totalExpenses: Double = 0
    @Published var monthlyAverage: Double = 0
    @Published var topCategories: [(category: Category, amount: Double)] = []
    
    // MARK: - Dependencies
    
    private let dataManager: DataManager
    private let sessionViewModel: SessionViewModel
    
    // MARK: - Initialization
    
    init(dataManager: DataManager, sessionViewModel: SessionViewModel) {
        self.dataManager = dataManager
        self.sessionViewModel = sessionViewModel
        
        setupObservers()
        loadExpenses()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observe DataManager expenses changes
        dataManager.$expenses
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadExpenses()
            }
            .store(in: &cancellables)
        
        // Observe category selection changes
        $selectedCategory
            .combineLatest($selectedDateRange)
            .sink { [weak self] _, _ in
                self?.loadExpenses()
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Data Loading
    
    func loadExpenses() {
        expenses = dataManager.getExpenses(for: selectedCategory, in: selectedDateRange)
        recentExpenses = dataManager.getRecentExpenses()
        expensesByCategory = dataManager.getExpensesByCategory()
        totalExpenses = dataManager.getTotalExpenses(for: selectedDateRange)
        
        updateStatistics()
    }
    
    func refreshExpenses() async {
        guard let userId = sessionViewModel.currentUser?.userId else { return }
        
        isLoading = true
        clearError()
        
        do {
            try await dataManager.fetchExpenses(userId: userId)
            loadExpenses()
        } catch {
            showError(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    // MARK: - Expense Management
    
    func addExpense(
        name: String,
        amount: Double,
        expenseDate: String,
        categoryId: String? = nil,
        billId: String? = nil,
        paymentMethod: PaymentMethod,
        isRecurring: Bool = false,
        recurringFrequency: ExpenseFrequency? = nil,
        merchant: String? = nil,
        location: String? = nil,
        tags: [String] = [],
        createdAt: String? = nil,
        updatedAt: String? = nil,
        notes: String? = nil,
        attachmentUrls: [String] = []
    ) async -> Bool {
        guard let userId = sessionViewModel.currentUser?.userId else {
            showError("No user found")
            return false
        }
        
        isLoading = true
        clearError()
        
        let newExpense = Expense(
            userId: userId,
            name: name,
            amount: amount,
            expenseDate: expenseDate,
            categoryId: categoryId,
            billId: billId,
            paymentMethod: paymentMethod,
            isRecurring: isRecurring,
            recurringFrequency: recurringFrequency,
            merchant: merchant,
            location: location,
            tags: tags,
            createdAt: createdAt,
            updatedAt: updatedAt,
            notes: notes,
            attachmentUrls: attachmentUrls
        )
        
        do {
            try await dataManager.addExpense(newExpense)
            loadExpenses()
            showAddExpense = false
            isLoading = false
            return true
        } catch {
            showError("Failed to add expense: \(error.localizedDescription)")
            isLoading = false
            return false
        }
    }
    
    func updateExpense(_ expense: Expense) async {
        isLoading = true
        clearError()
        
        do {
            try await dataManager.updateExpense(expense)
            loadExpenses()
        } catch {
            showError("Failed to update expense: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func deleteExpense(_ expense: Expense) async {
        isLoading = true
        clearError()
        
        do {
            try await dataManager.deleteExpense(expense)
            loadExpenses()
        } catch {
            showError("Failed to delete expense: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // MARK: - Quick Expense
    
    func addQuickExpense(amount: Double, categoryId: String) async -> Bool {
        guard let category = dataManager.categories.first(where: { $0.id == categoryId }) else {
            showError("Invalid category")
            return false
        }
        
        // Format today's date as ISO8601 string for expense_date in local timezone
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        let todayString = dateFormatter.string(from: Date())
        
        return await addExpense(
            name: category.name,
            amount: amount,
            expenseDate: todayString,
            categoryId: categoryId,
            paymentMethod: .debitCard
        )
    }
    
    // MARK: - Filtering and Searching
    
    var filteredExpenses: [Expense] {
        var filtered = expenses
        
        // Filter by payment method
        if let paymentMethod = selectedPaymentMethod {
            filtered = filtered.filter { $0.paymentMethod == paymentMethod }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { expense in
                expense.name.localizedCaseInsensitiveContains(searchText) ||
                (expense.merchant?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                expense.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        return filtered
    }
    
    // MARK: - Date Range Helpers
    
    func setDateRange(_ range: ExpenseDateRangeOption) {
        let calendar = Calendar.current
        let now = Date()
        
        switch range {
        case .today:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            selectedDateRange = DateInterval(start: start, end: end)
            
        case .thisWeek:
            let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start)!
            selectedDateRange = DateInterval(start: start, end: end)
            
        case .thisMonth:
            let start = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            selectedDateRange = DateInterval(start: start, end: end)
            
        case .thisYear:
            let start = calendar.dateInterval(of: .year, for: now)?.start ?? now
            let end = calendar.date(byAdding: .year, value: 1, to: start)!
            selectedDateRange = DateInterval(start: start, end: end)
            
        case .all:
            selectedDateRange = nil
        }
    }
    
    // MARK: - Statistics
    
    private func updateStatistics() {
        // Calculate monthly average
        let calendar = Calendar.current
        let dateFormatter = ISO8601DateFormatter()
        
        let uniqueMonths: Set<Date> = Set(expenses.compactMap { expense -> Date? in
            guard let date = dateFormatter.date(from: expense.expenseDate) else { return nil }
            return calendar.dateInterval(of: .month, for: date)?.start
        })
        
        if !uniqueMonths.isEmpty {
            monthlyAverage = totalExpenses / Double(uniqueMonths.count)
        } else {
            monthlyAverage = 0
        }
        
        // Get top categories
        topCategories = expensesByCategory
            .map { (category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
            .prefix(5)
            .map { $0 }
    }
    
    func getExpensesSummary(for period: DateInterval) -> ExpenseSummary {
        let periodExpenses = dataManager.getExpenses(for: nil, in: period)
        let total = periodExpenses.reduce(0) { $0 + $1.amount }
        let count = periodExpenses.count
        let average = count > 0 ? total / Double(count) : 0
        
        return ExpenseSummary(
            total: total,
            count: count,
            average: average,
            period: period
        )
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
