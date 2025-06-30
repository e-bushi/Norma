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
        bills = dataManager.bills
        activeBills = dataManager.getActiveBills()
        upcomingBills = dataManager.getUpcomingBills()
        overdueBills = dataManager.getOverdueBills()
        billsDueSoon = dataManager.getBillsDueSoon()
        totalMonthlyBills = dataManager.getTotalMonthlyBills()
        nextBillDue = dataManager.getNextBillDue()
    }
    
    func refreshBills() async {
        guard let userId = sessionViewModel.currentUser?.userId else { return }
        
        isLoading = true
        clearError()
        
        do {
            try await dataManager.fetchBills(userId: userId)
            loadBills()
        } catch {
            showError(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    // MARK: - Bill Management
    
    func addBill(
        name: String,
        amount: Double,
        dueDate: Date,
        frequency: BillFrequency,
        categoryId: String? = nil,
        merchant: String? = nil,
        isAutoPayEnabled: Bool = false,
        reminderDays: Int? = nil,
        notes: String? = nil
    ) async {
        guard let userId = sessionViewModel.currentUser?.userId else {
            showError("No user found")
            return
        }
        
        isLoading = true
        clearError()
        
        let newBill = Bill(
            userId: userId,
            name: name,
            dueDate: dueDate,
            amount: amount,
            status: .active,
            frequency: frequency,
            categoryId: categoryId,
            merchant: merchant,
            isAutoPayEnabled: isAutoPayEnabled,
            reminderDays: reminderDays ?? sessionViewModel.currentUser?.settings.billReminderDays,
            notes: notes
        )
        
        do {
            try await dataManager.addBill(newBill)
            loadBills()
        } catch {
            showError("Failed to add bill: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func updateBill(_ bill: Bill) async {
        isLoading = true
        clearError()
        
        do {
            try await dataManager.updateBill(bill)
            loadBills()
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
        } catch {
            showError("Failed to delete bill: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func markBillAsPaid(_ bill: Bill) async {
        isLoading = true
        clearError()
        
        do {
            try await dataManager.markBillAsPaid(bill)
            loadBills()
        } catch {
            showError("Failed to mark bill as paid: \(error.localizedDescription)")
        }
        
        isLoading = false
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
        case .active:
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