//
//  BillViewModel.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class BillViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var bills: [Bill] = []
    @Published var activeBills: [Bill] = []
    @Published var upcomingBills: [Bill] = []
    @Published var overdueBills: [Bill] = []
    
    // UI State
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var searchText = ""
    @Published var selectedStatus: BillStatus?
    @Published var selectedBill: Bill?
    
    // Task Management
    private var refreshTask: Task<Void, Never>?
    
    // Statistics
    @Published var totalMonthlyBills: Double = 0
    @Published var nextBillDue: Bill?
    @Published var billsDueSoon: [Bill] = []

    var totalBillsThisMonth: Double {
        let calendar = Calendar.current
        let currentMonth = Date()

        return activeBills
            .filter { bill in
                calendar.isDate(bill.dueDate, equalTo: currentMonth, toGranularity: .month)
            }
            .reduce(0) { $0 + $1.amount }
    }
    
    // MARK: - Dependencies
    
    private let dataManager: DataManager
    private let sessionViewModel: SessionViewModel
    @Published var verificationService: BillPeriodVerificationService
    
    // MARK: - Initialization
    
    init(dataManager: DataManager, sessionViewModel: SessionViewModel) {
        self.dataManager = dataManager
        self.sessionViewModel = sessionViewModel
        self.verificationService = BillPeriodVerificationService(dataManager: dataManager)
        
        setupObservers()
        loadBills()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observe DataManager bills changes
        dataManager.$bills
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadBills()
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Data Loading
    
    func loadBills() {
        // Update overdue status for bills past their due date
        updateOverdueBills()

        bills = dataManager.bills
        activeBills = dataManager.getActiveBills()
        upcomingBills = dataManager.getUpcomingBills()
        overdueBills = dataManager.getOverdueBills()
        billsDueSoon = dataManager.getBillsDueSoon()
        totalMonthlyBills = dataManager.getTotalMonthlyBills()
        nextBillDue = dataManager.getNextBillDue()

        // Check for bill verification after loading
        checkForBillVerification()
    }
    
    private func updateOverdueBills() {
        let today = Date()
        let billsNeedingUpdate = dataManager.bills.filter { bill in
            // Only update bills that are scheduled but past their due date
            bill.status == .scheduled && bill.dueDate < today
        }
        
        // Update each overdue bill
        for bill in billsNeedingUpdate {
            Task {
                var updatedBill = bill
                updatedBill.status = .overdue
                
                // Update verification date to track when status was changed
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.timeZone = TimeZone.current
                updatedBill.verificationDate = dateFormatter.string(from: today)
                
                do {
                    try await dataManager.updateBillWithEncryption(updatedBill)
                } catch {
                    print("Failed to update overdue status for bill \(bill.name): \(error)")
                }
            }
        }
    }
    
    private func checkForBillVerification() {
        // Get expenses from dataManager to check for verification
        let expenses = dataManager.expenses
        verificationService.checkForNewPeriod(bills: bills, expenses: expenses)
    }
    
    func refreshBills() async {
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
            try await dataManager.fetchBills(userId: userId)
            loadBills()
        } catch {
            if !Task.isCancelled {
                showError(error.localizedDescription)
            }
        }
        
        isLoading = false
    }
    
    // MARK: - Bill Management
    
    func addBill(
        name: String,
        amount: Double,
        dueDate: Date,
        frequency: BillFrequency,
        status: BillStatus = .scheduled,
        categoryId: String? = nil,
        merchant: String? = nil,
        isReminderOn: Bool = false,
        reminderDays: Int? = nil,
        notes: String? = nil,
        isMostCritical: Bool? = nil
    ) async -> Bill? {
        print("🔍 [DEBUG] BillViewModel.addBill called with name: \(name), amount: \(amount)")
        
        guard let userId = sessionViewModel.currentUser?.userId else {
            print("❌ [DEBUG] BillViewModel.addBill: No user ID found")
            showError("No user found")
            return nil
        }
        
        print("✅ [DEBUG] BillViewModel.addBill: User ID found: \(userId)")
        
        isLoading = true
        clearError()
        
        // Format current date for verification_date
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        let todayString = dateFormatter.string(from: Date())
        
        let newBill = Bill(
            userId: userId,
            name: name,
            dueDate: dueDate,
            amount: amount,
            status: status,
            frequency: frequency,
            categoryId: categoryId,
            merchant: merchant,
            isReminderOn: isReminderOn,
            reminderDays: reminderDays ?? sessionViewModel.currentUser?.settings.billReminderDays,
            notes: notes,
            verificationDate: todayString
        )
        
        print("🔄 [DEBUG] BillViewModel.addBill: About to call dataManager.addBill...")
        print("🔄 [DEBUG] BillViewModel.addBill: Bill object: \(newBill)")
        
        do {
            try await dataManager.addBillWithEncryption(newBill)
            print("✅ [DEBUG] BillViewModel.addBill: dataManager.addBill completed successfully")
            loadBills()
            print("✅ [DEBUG] BillViewModel.addBill: loadBills completed")

            // Track bill created
            AnalyticsService.shared.track(.billCreated(
                amount: amount,
                frequency: frequency.rawValue,
                hasReminder: isReminderOn,
                source: .manual
            ))

            // Find and return the created bill
            let createdBill = bills.first { $0.name == name && $0.amount == amount && $0.userId == userId }
            isLoading = false
            print("🔄 [DEBUG] BillViewModel.addBill: Method completed, returning bill with ID: \(createdBill?.id ?? "nil")")
            return createdBill
        } catch {
            print("❌ [DEBUG] BillViewModel.addBill: dataManager.addBill failed with error: \(error)")
            showError("Failed to add bill: \(error.localizedDescription)")
            isLoading = false
            return nil
        }
    }
    
    func updateBill(_ bill: Bill) async {
        isLoading = true
        clearError()

        do {
            try await dataManager.updateBillWithEncryption(bill)
            loadBills()

            // Track bill updated
            AnalyticsService.shared.track(.billUpdated(billId: bill.id ?? "", field: "multiple"))

            // Check if reducing bill amount increased arcs
            sessionViewModel.checkArcIncreaseAfterBillChange(bills: bills)
        } catch {
            showError("Failed to update bill: \(error.localizedDescription)")
        }

        isLoading = false
    }

    func deleteBill(_ bill: Bill) async {
        isLoading = true
        clearError()

        do {
            try await dataManager.deleteBill(bill)
            loadBills()

            // Track bill deleted
            AnalyticsService.shared.track(.billDeleted(billId: bill.id ?? ""))

            // Check if deleting bill increased arcs
            sessionViewModel.checkArcIncreaseAfterBillChange(bills: bills)
        } catch {
            showError("Failed to delete bill: \(error.localizedDescription)")
        }

        isLoading = false
    }
    
    func markBillAsPaid(_ bill: Bill, paymentMethod: PaymentMethod = .debitCard, notes: String? = nil) async {
        isLoading = true
        clearError()

        do {
            try await dataManager.markBillAsPaid(bill, paymentMethod: paymentMethod, notes: notes)
            loadBills()

            // Calculate days before due
            let calendar = Calendar.current
            let daysBeforeDue = calendar.dateComponents([.day], from: Date(), to: bill.dueDate).day ?? 0

            // Track bill marked as paid
            AnalyticsService.shared.track(.billMarkedPaid(
                amount: bill.amount,
                paymentMethod: paymentMethod.rawValue,
                daysBeforeDue: daysBeforeDue
            ))

            // Deduct bill amount from freedom fund and show toast
            await sessionViewModel.deductFreedomFundForBillPayment(amount: bill.amount, bills: bills)
        } catch {
            showError("Failed to mark bill as paid: \(error.localizedDescription)")
        }

        isLoading = false
    }
    
    func markBillAsUnpaid(_ bill: Bill) async {
        isLoading = true
        clearError()
        
        do {
            // Create date formatter with correct timezone
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.timeZone = TimeZone.current
            
            // Determine the appropriate status based on current date
            let status: BillStatus = Date() > bill.dueDate ? .overdue : .scheduled
            
            // Calculate next due date (one period ahead of current due date)
            let nextDueDate = calculateNextDueDateFrom(bill.dueDate, frequency: bill.frequency)
            
            // Create updated bill keeping original dueDate
            let updatedBill = Bill(
                id: bill.id,
                userId: bill.userId,
                name: bill.name,
                dueDate: bill.dueDate,  // Keep the original due date
                nextDueDate: nextDueDate,  // Set next due date one period ahead
                amount: bill.amount,
                status: status,  // Set to scheduled or overdue based on current date
                frequency: bill.frequency,
                categoryId: bill.categoryId,
                merchant: bill.merchant,
                isReminderOn: bill.isReminderOn,
                reminderDays: bill.reminderDays,
                isActive: bill.isActive,
                createdAt: bill.createdAt,
                updatedAt: dateFormatter.string(from: Date()),
                notes: bill.notes,
                verificationDate: bill.verificationDate
            )
            
            try await dataManager.updateBillWithEncryption(updatedBill)

            // Delete the associated expense payment if any
            let expenses = dataManager.expenses.filter { $0.billId == bill.id }
            for expense in expenses {
                // Only delete expenses that are bill payments (have a billId)
                if expense.billId == bill.id {
                    try await dataManager.deleteExpense(expense)
                }
            }

            loadBills()

            // Track bill marked as unpaid
            AnalyticsService.shared.track(.billMarkedUnpaid(billId: bill.id ?? ""))
        } catch {
            showError("Failed to mark bill as unpaid: \(error.localizedDescription)")
        }

        isLoading = false
    }
    
    private func calculateNextDueDateFrom(_ date: Date, frequency: BillFrequency) -> Date {
        let calendar = Calendar.current
        
        switch frequency {
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: date) ?? date
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date) ?? date
        }
    }
    
    // MARK: - Filtering and Searching
    
    var filteredBills: [Bill] {
        var filtered = bills
        
        // Filter by status
        if let status = selectedStatus {
            filtered = filtered.filter { $0.status == status }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { bill in
                bill.name.localizedCaseInsensitiveContains(searchText) ||
                (bill.merchant?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return filtered.sorted { $0.dueDate < $1.dueDate }
    }
    
    // MARK: - Statistics
    
    var monthlyBillsBreakdown: [(category: String, amount: Double)] {
        var breakdown: [String: Double] = [:]
        
        for bill in activeBills {
            let categoryName = bill.categoryId ?? "Uncategorized"
            let monthlyAmount: Double
            
            switch bill.frequency {
            case .monthly:
                monthlyAmount = bill.amount
            case .quarterly:
                monthlyAmount = bill.amount * 4 / 12
            case .yearly:
                monthlyAmount = bill.amount / 12
            }
            
            breakdown[categoryName, default: 0] += monthlyAmount
        }
        
        return breakdown.map { (category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }
    
    var upcomingBillsTotal: Double {
        upcomingBills.reduce(0) { $0 + $1.amount }
    }
    
    var overdueTotal: Double {
        overdueBills.reduce(0) { $0 + $1.amount }
    }
    
    /// Calculate paid bills this month based on expense payments
    func paidBillsThisMonth(expenses: [Expense]) -> Double {
        return bills
            .filter { bill in
                // Use calculated status based on expense payments
                bill.calculateStatus(from: expenses) == .paid
            }
            .filter { bill in
                // Only include bills due this month
                Calendar.current.isDate(bill.dueDate, equalTo: Date(), toGranularity: .month)
            }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Get bills with their calculated status based on expenses
    func getBillsWithCalculatedStatus(expenses: [Expense]) -> [(bill: Bill, status: BillStatus)] {
        return bills.map { bill in
            (bill: bill, status: bill.calculateStatus(from: expenses))
        }
    }
    
    // MARK: - Helper Methods
    
    func getDueDateStatus(for bill: Bill) -> (text: String, color: Color) {
        let calendar = Calendar.current
        let daysUntilDue = calendar.dateComponents([.day], from: Date(), to: bill.dueDate).day ?? 0
        
        switch bill.status {
        case .paid:
            return ("Paid", .green)
        case .overdue:
            return ("Overdue", .red)
        case .scheduled:
            if daysUntilDue == 0 {
                return ("Due Today", .orange)
            } else if daysUntilDue == 1 {
                return ("Due Tomorrow", .orange)
            } else if daysUntilDue <= 3 {
                return ("Due in \(daysUntilDue) days", .yellow)
            } else {
                return ("Due in \(daysUntilDue) days", .secondary)
            }
        case .scheduled:
            if daysUntilDue < 0 {
                return ("Overdue by \(abs(daysUntilDue)) days", .red)
            } else if daysUntilDue == 0 {
                return ("Due Today", .orange)
            } else if daysUntilDue == 1 {
                return ("Due Tomorrow", .orange)
            } else if daysUntilDue <= 3 {
                return ("Due in \(daysUntilDue) days", .yellow)
            } else {
                return ("Due in \(daysUntilDue) days", .secondary)
            }
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
