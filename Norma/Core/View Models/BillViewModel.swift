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
    
    // Statistics
    @Published var totalMonthlyBills: Double = 0
    @Published var nextBillDue: Bill?
    @Published var billsDueSoon: [Bill] = []

    var totalBillsThisMonth: Double {
        let calendar = Calendar.current
        let currentMonth = Date()

        return activeBills
            .filter { bill in
                calendar.isDate(bill.effectiveDueDate, equalTo: currentMonth, toGranularity: .month)
            }
            .reduce(0) { $0 + $1.amount }
    }
    
    // MARK: - Dependencies
    
    private let dataManager: DataManager
    private let sessionViewModel: SessionViewModel
    // MARK: - Initialization
    
    init(dataManager: DataManager, sessionViewModel: SessionViewModel) {
        self.dataManager = dataManager
        self.sessionViewModel = sessionViewModel
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
        // Status (scheduled/overdue/paid) is derived on read via
        // Bill.calculateStatus() — no need to persist transitions here.
        bills = dataManager.bills
        activeBills = dataManager.getActiveBills()
        upcomingBills = dataManager.getUpcomingBills()
        overdueBills = dataManager.getOverdueBills()
        billsDueSoon = dataManager.getBillsDueSoon()
        totalMonthlyBills = dataManager.getTotalMonthlyBills()
        nextBillDue = dataManager.getNextBillDue()

        armRemindersAtLaunch()
    }

    /// Once per launch, after bills first load: backfill the reminder flag onto
    /// any legacy bills that predate the "all bills notify" default, then
    /// re-arm the current cycle's notifications. Recurring local notifications
    /// are one-shot, so a bill that rolled into a new cycle needs re-arming —
    /// app launch is our reliable trigger for that.
    private var didArmRemindersThisLaunch = false
    private func armRemindersAtLaunch() {
        guard !didArmRemindersThisLaunch, !bills.isEmpty else { return }
        didArmRemindersThisLaunch = true
        Task {
            await backfillReminderFlagIfNeeded()
            await NotificationService.shared.rearmAllBillReminders(for: dataManager.bills)
        }
    }

    /// One-time migration: flip `isReminderOn` true on bills created before the
    /// default changed. No prior bill could have been intentionally muted (the
    /// per-bill toggle ships alongside this), so flipping every false is safe.
    private func backfillReminderFlagIfNeeded() async {
        let key = "didBackfillBillReminders"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        for bill in dataManager.bills where !bill.isReminderOn {
            var updated = bill
            updated.isReminderOn = true
            try? dataManager.updateBill(updated)
        }
        UserDefaults.standard.set(true, forKey: key)
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
        isReminderOn: Bool = true,
        reminderDays: Int? = nil,
        notes: String? = nil,
        isMostCritical: Bool? = nil
    ) async -> Bill? {
        let userId = LocalStore.userId

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
        
        do {
            try dataManager.addBill(newBill)
            loadBills()

            // Track bill created
            AnalyticsService.shared.track(.billCreated(
                amount: amount,
                frequency: frequency.rawValue,
                hasReminder: isReminderOn,
                source: .manual
            ))

            // Find and return the created bill
            let createdBill = bills.first { $0.name == name && $0.amount == amount && $0.userId == userId }

            // Schedule reminder notifications for the new bill (day before by default).
            if let createdBill, createdBill.isReminderOn {
                await NotificationService.shared.scheduleBillReminders(for: createdBill)
            }

            isLoading = false
            return createdBill
        } catch {
            showError("Failed to add bill: \(error.localizedDescription)")
            isLoading = false
            return nil
        }
    }
    
    /// Batch mark-paid for the journal-driven bills flow. Sets `paidAt` on each
    /// bill so the BillsView reflects paid status for the current cycle. The
    /// matching `.billPayment` NoteToken creation is handled by the caller (it
    /// needs `ModelContext`).
    func markBillsAsPaid(_ bills: [Bill]) async {
        guard !bills.isEmpty else { return }
        isLoading = true
        clearError()

        let now = Date()
        for bill in bills {
            var updated = bill
            updated.paidAt = now
            updated.status = .paid
            do {
                try dataManager.updateBill(updated)
            } catch {
                showError("Failed to mark bill paid: \(error.localizedDescription)")
            }
        }
        loadBills()
        isLoading = false
    }

    func updateBill(_ bill: Bill) async {
        isLoading = true
        clearError()

        do {
            try dataManager.updateBill(bill)
            loadBills()

            // Reschedule (or cancel) reminder notifications to reflect the new state.
            if bill.isReminderOn {
                await NotificationService.shared.scheduleBillReminders(for: bill)
            } else {
                await NotificationService.shared.cancelNotifications(for: bill)
            }

            // Track bill updated
            AnalyticsService.shared.track(.billUpdated(billId: bill.id ?? "", field: "multiple"))
        } catch {
            showError("Failed to update bill: \(error.localizedDescription)")
        }

        isLoading = false
    }

    func deleteBill(_ bill: Bill) async {
        isLoading = true
        clearError()

        do {
            try dataManager.deleteBill(bill)
            loadBills()

            // Cancel any scheduled reminder notifications for this bill.
            await NotificationService.shared.cancelNotifications(for: bill)

            // Track bill deleted
            AnalyticsService.shared.track(.billDeleted(billId: bill.id ?? ""))
        } catch {
            showError("Failed to delete bill: \(error.localizedDescription)")
        }

        isLoading = false
    }
    
    func markBillAsUnpaid(_ bill: Bill) async {
        isLoading = true
        clearError()

        do {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.timeZone = TimeZone.current

            var updatedBill = bill
            // Clearing paidAt is what actually un-pays the bill — display status
            // is derived from it. The stored status is just a persistence snapshot.
            updatedBill.paidAt = nil
            updatedBill.status = bill.effectiveDueDate < Date() ? .overdue : .scheduled
            updatedBill.updatedAt = dateFormatter.string(from: Date())

            try dataManager.updateBill(updatedBill)

            loadBills()

            AnalyticsService.shared.track(.billMarkedUnpaid(billId: bill.id ?? ""))
        } catch {
            showError("Failed to mark bill as unpaid: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - Filtering and Searching
    
    var filteredBills: [Bill] {
        var filtered = bills
        
        // Filter by status
        if let status = selectedStatus {
            filtered = filtered.filter { $0.calculateStatus() == status }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { bill in
                bill.name.localizedCaseInsensitiveContains(searchText) ||
                (bill.merchant?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return filtered.sorted { $0.effectiveDueDate < $1.effectiveDueDate }
    }
    
    // MARK: - Statistics
    
    var monthlyBillsBreakdown: [(category: String, amount: Double)] {
        var breakdown: [String: Double] = [:]
        
        for bill in activeBills {
            let categoryName = bill.categoryId ?? "Uncategorized"
            let monthlyAmount: Double
            
            switch bill.frequency {
            case .oneTime:
                monthlyAmount = 0
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
    
    // MARK: - Helper Methods
    
    func getDueDateStatus(for bill: Bill) -> (text: String, color: Color) {
        let calendar = Calendar.current
        let daysUntilDue = calendar.dateComponents([.day], from: Date(), to: bill.effectiveDueDate).day ?? 0

        switch bill.calculateStatus() {
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
