//
//  PreviewModeViewModel.swift
//  Norma
//
//  Created by Claude on 10/25/25.
//

import Foundation
import SwiftUI

@MainActor
class PreviewModeViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var bills: [Bill] = []
    @Published var expenses: [Expense] = []

    // Onboarding data
    @Published var userName: String?
    @Published var userCurrency: String?
    @Published var userIncome: Double?
    @Published var userFreedomFund: Double?

    // Modal state
    @Published var showSaveProgressModal = false

    // MARK: - Computed Properties

    var totalBills: Double {
        bills.reduce(0) { $0 + $1.amount }
    }

    var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    /// All 5 onboarding data points have been collected
    var onboardingDataComplete: Bool {
        userName != nil &&
        userCurrency != nil &&
        !bills.isEmpty &&
        userIncome != nil &&
        userFreedomFund != nil
    }

    // MARK: - Initialization

    init() { }

    // MARK: - Data Management

    func addBill(_ bill: Bill) {
        bills.append(bill)
    }

    func addExpense(_ expense: Expense) {
        expenses.append(expense)
    }

    func removeBill(_ bill: Bill) {
        bills.removeAll { $0.id == bill.id }
    }

    func removeExpense(_ expense: Expense) {
        expenses.removeAll { $0.id == expense.id }
    }

    // MARK: - Reset

    func reset() {
        bills.removeAll()
        expenses.removeAll()
        userName = nil
        userCurrency = nil
        userIncome = nil
        userFreedomFund = nil
        showSaveProgressModal = false
    }

    // MARK: - Data Transfer

    /// Get bills ready for transfer to a real account
    func getUserBillsForTransfer(withUserId userId: String) -> [Bill] {
        return bills.map { bill in
            var updatedBill = bill
            updatedBill.userId = userId
            return updatedBill
        }
    }

    /// Get expenses ready for transfer to a real account
    func getUserExpensesForTransfer(withUserId userId: String) -> [Expense] {
        return expenses.map { expense in
            var updatedExpense = expense
            updatedExpense.userId = userId
            return updatedExpense
        }
    }

    /// Check if there's user data to transfer
    var hasUserDataToTransfer: Bool {
        !bills.isEmpty || !expenses.isEmpty
    }
}
