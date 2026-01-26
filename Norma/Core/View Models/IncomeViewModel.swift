//
//  IncomeViewModel.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class IncomeViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var incomes: [Income] = []
    @Published var activeIncomes: [Income] = []
    @Published var recurringIncomes: [Income] = []
    @Published var oneTimeIncomes: [Income] = []
    
    // UI State
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var showAddIncome = false
    @Published var selectedIncome: Income?
    
    // Task Management
    private var refreshTask: Task<Void, Never>?
    
    // Filtering
    @Published var selectedSource: IncomeSource?
    @Published var selectedDateRange: DateInterval?
    @Published var searchText = ""
    
    // Statistics
    @Published var totalMonthlyIncome: Double = 0
    @Published var totalYearlyIncome: Double = 0
    @Published var averageMonthlyIncome: Double = 0
    @Published var incomeBySource: [(source: IncomeSource, amount: Double)] = []
    @Published var nextExpectedIncome: Income?
    
    // MARK: - Dependencies
    
    private let dataManager: DataManager
    private let sessionViewModel: SessionViewModel
    
    // MARK: - Initialization
    
    init(dataManager: DataManager, sessionViewModel: SessionViewModel) {
        self.dataManager = dataManager
        self.sessionViewModel = sessionViewModel
        
        setupObservers()
        loadIncomes()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observe DataManager incomes changes
        dataManager.$income
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadIncomes()
            }
            .store(in: &cancellables)
        
        // Observe date range changes
        $selectedDateRange
            .sink { [weak self] _ in
                self?.loadIncomes()
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Data Loading
    
    func loadIncomes() {
        incomes = dataManager.getIncomes(for: selectedDateRange)
        activeIncomes = incomes.filter { $0.isActive }
        recurringIncomes = incomes.filter { $0.frequency != .oneTime }
        oneTimeIncomes = incomes.filter { $0.frequency == .oneTime }
        
        updateStatistics()
    }
    
    func refreshIncomes() async {
        // Cancel any existing refresh task
        refreshTask?.cancel()
        
        // Create new refresh task
        refreshTask = Task {
            await performRefresh()
        }
        
        await refreshTask?.value
    }
    
    private func performRefresh() async {
        guard let userId = sessionViewModel.currentUser?.userId else { return }
        
        isLoading = true
        clearError()
        
        do {
            try await dataManager.fetchIncomes(userId: userId)
            loadIncomes()
        } catch {
            if !Task.isCancelled {
                showError(error.localizedDescription)
            }
        }
        
        isLoading = false
    }
    
    // MARK: - Income Management
    
    func addIncome(
        name: String,
        amount: Double,
        source: IncomeSource,
        frequency: IncomeFrequency,
        nextDate: Date,
        endDate: Date? = nil,
        taxable: Bool = true,
        notes: String? = nil
    ) async {
        guard let userId = sessionViewModel.currentUser?.userId else {
            showError("No user found")
            return
        }
        
        isLoading = true
        clearError()
        
        let newIncome = Income(
            userId: userId,
            name: name,
            amount: amount,
            source: source,
            frequency: frequency,
            nextDate: nextDate,
            endDate: endDate,
            isActive: true,
            taxable: taxable,
            notes: notes
        )
        
        do {
            try await dataManager.addIncome(newIncome)
            loadIncomes()

            // Track income created
            AnalyticsService.shared.track(.incomeCreated(
                amount: amount,
                frequency: frequency.rawValue,
                source: .manual
            ))

            showAddIncome = false
        } catch {
            showError("Failed to add income: \(error.localizedDescription)")
        }

        isLoading = false
    }
    
    func updateIncome(_ income: Income) async {
        isLoading = true
        clearError()

        do {
            try await dataManager.updateIncome(income)
            loadIncomes()

            // Track income updated
            AnalyticsService.shared.track(.incomeUpdated(incomeId: income.id ?? "", field: "multiple"))
        } catch {
            showError("Failed to update income: \(error.localizedDescription)")
        }

        isLoading = false
    }
    
    func deleteIncome(_ income: Income) async {
        isLoading = true
        clearError()

        do {
            try await dataManager.deleteIncome(income)
            loadIncomes()

            // Track income deleted
            AnalyticsService.shared.track(.incomeDeleted(incomeId: income.id ?? ""))
        } catch {
            showError("Failed to delete income: \(error.localizedDescription)")
        }

        isLoading = false
    }
    
    func toggleIncomeActive(_ income: Income) async {
        var updatedIncome = income
        updatedIncome.isActive.toggle()
        await updateIncome(updatedIncome)
    }
    
    func recordIncomeReceived(_ income: Income) async {
        // Update next date based on frequency
        var updatedIncome = income
        let calendar = Calendar.current
        
        switch income.frequency {
        case .weekly:
            updatedIncome.nextDate = calendar.date(byAdding: .weekOfYear, value: 1, to: income.nextDate) ?? income.nextDate
        case .biweekly:
            updatedIncome.nextDate = calendar.date(byAdding: .weekOfYear, value: 2, to: income.nextDate) ?? income.nextDate
        case .monthly:
            updatedIncome.nextDate = calendar.date(byAdding: .month, value: 1, to: income.nextDate) ?? income.nextDate
        case .quarterly:
            updatedIncome.nextDate = calendar.date(byAdding: .month, value: 3, to: income.nextDate) ?? income.nextDate
        case .semiAnnually:
            updatedIncome.nextDate = calendar.date(byAdding: .month, value: 6, to: income.nextDate) ?? income.nextDate
        case .yearly:
            updatedIncome.nextDate = calendar.date(byAdding: .year, value: 1, to: income.nextDate) ?? income.nextDate
        case .oneTime:
            updatedIncome.isActive = false
        }
        
        updatedIncome.lastReceivedDate = Date()
        await updateIncome(updatedIncome)
    }
    
    // MARK: - Filtering and Searching
    
    var filteredIncomes: [Income] {
        var filtered = incomes
        
        // Filter by source
        if let source = selectedSource {
            filtered = filtered.filter { $0.source == source }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { income in
                income.name.localizedCaseInsensitiveContains(searchText) ||
                income.source.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered.sorted { $0.nextDate < $1.nextDate }
    }
    
    // MARK: - Date Range Helpers
    
    func setDateRange(_ range: IncomeDateRangeOption) {
        let calendar = Calendar.current
        let now = Date()
        
        switch range {
        case .thisMonth:
            let start = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            selectedDateRange = DateInterval(start: start, end: end)
            
        case .thisQuarter:
            let start = calendar.dateInterval(of: .quarter, for: now)?.start ?? now
            let end = calendar.date(byAdding: .month, value: 3, to: start)!
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
        calculateMonthlyIncome()
        calculateYearlyIncome()
        calculateIncomeBySource()
        findNextExpectedIncome()
    }
    
    private func calculateMonthlyIncome() {
        totalMonthlyIncome = 0
        
        for income in activeIncomes {
            let monthlyAmount: Double
            
            switch income.frequency {
            case .weekly:
                monthlyAmount = income.amount * 4.33 // Average weeks per month
            case .biweekly:
                monthlyAmount = income.amount * 2.167 // 26 pay periods / 12 months
            case .monthly:
                monthlyAmount = income.amount
            case .quarterly:
                monthlyAmount = income.amount / 3
            case .semiAnnually:
                monthlyAmount = income.amount / 6
            case .yearly:
                monthlyAmount = income.amount / 12
            case .oneTime:
                // Only include if expected this month
                let calendar = Calendar.current
                if calendar.isDate(income.nextDate, equalTo: Date(), toGranularity: .month) {
                    monthlyAmount = income.amount
                } else {
                    monthlyAmount = 0
                }
            }
            
            totalMonthlyIncome += monthlyAmount
        }
        
        // Calculate average from historical data
        let calendar = Calendar.current
        let uniqueMonths = Set(incomes.compactMap { income in
            calendar.dateInterval(of: .month, for: income.lastReceivedDate ?? income.nextDate)?.start
        })
        
        if !uniqueMonths.isEmpty {
            let totalHistorical = incomes.reduce(0) { $0 + $1.amount }
            averageMonthlyIncome = totalHistorical / Double(uniqueMonths.count)
        } else {
            averageMonthlyIncome = totalMonthlyIncome
        }
    }
    
    private func calculateYearlyIncome() {
        totalYearlyIncome = totalMonthlyIncome * 12
    }
    
    private func calculateIncomeBySource() {
        var sourceBreakdown: [IncomeSource: Double] = [:]
        
        for income in activeIncomes {
            let monthlyAmount: Double
            
            switch income.frequency {
            case .weekly:
                monthlyAmount = income.amount * 4.33
            case .biweekly:
                monthlyAmount = income.amount * 2.167
            case .monthly:
                monthlyAmount = income.amount
            case .quarterly:
                monthlyAmount = income.amount / 3
            case .semiAnnually:
                monthlyAmount = income.amount / 6
            case .yearly:
                monthlyAmount = income.amount / 12
            case .oneTime:
                monthlyAmount = income.amount / 12 // Spread over year
            }
            
            sourceBreakdown[income.source, default: 0] += monthlyAmount
        }
        
        incomeBySource = sourceBreakdown
            .map { (source: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }
    
    private func findNextExpectedIncome() {
        nextExpectedIncome = activeIncomes
            .filter { $0.nextDate > Date() }
            .min { $0.nextDate < $1.nextDate }
    }
    
    // MARK: - Income Projections
    
    func getIncomeProjection(for months: Int) -> IncomeProjection {
        let projectedTotal = totalMonthlyIncome * Double(months)
        let taxableAmount = activeIncomes
            .filter { $0.taxable }
            .reduce(0) { total, income in
                let monthlyAmount: Double
                switch income.frequency {
                case .weekly: monthlyAmount = income.amount * 4.33
                case .biweekly: monthlyAmount = income.amount * 2.167
                case .monthly: monthlyAmount = income.amount
                case .quarterly: monthlyAmount = income.amount / 3
                case .semiAnnually: monthlyAmount = income.amount / 6
                case .yearly: monthlyAmount = income.amount / 12
                case .oneTime: monthlyAmount = income.amount / 12
                }
                return total + monthlyAmount
            } * Double(months)
        
        return IncomeProjection(
            totalAmount: projectedTotal,
            taxableAmount: taxableAmount,
            nonTaxableAmount: projectedTotal - taxableAmount,
            months: months
        )
    }
    
    // MARK: - Helper Methods
    
    func getIncomeStatus(_ income: Income) -> (text: String, color: Color) {
        let calendar = Calendar.current
        let daysUntilNext = calendar.dateComponents([.day], from: Date(), to: income.nextDate).day ?? 0
        
        if !income.isActive {
            return ("Inactive", .secondary)
        } else if daysUntilNext < 0 {
            return ("Overdue", .red)
        } else if daysUntilNext == 0 {
            return ("Due Today", .green)
        } else if daysUntilNext == 1 {
            return ("Tomorrow", .orange)
        } else if daysUntilNext <= 7 {
            return ("In \(daysUntilNext) days", .yellow)
        } else {
            return ("In \(daysUntilNext) days", .secondary)
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = sessionViewModel.currentUser?.settings.currency ?? "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
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