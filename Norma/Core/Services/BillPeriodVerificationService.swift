//
//  BillPeriodVerificationService.swift
//  Norma
//
//  Created by Claude on 7/29/25.
//

import Foundation
import SwiftUI

@MainActor
class BillPeriodVerificationService: ObservableObject {
    @Published var needsVerification = false
    @Published var billsToVerify: [Bill] = []
    @Published var showVerificationPrompt = false
    
    private let dataManager: DataManager
    private let calendar = Calendar.current
    
    init(dataManager: DataManager) {
        self.dataManager = dataManager
    }
    
    // MARK: - Period Verification Check
    
    func checkForNewPeriod(bills: [Bill], expenses: [Expense]) {
        let today = Date()
        
        // Find bills that need verification
        let billsNeedingVerification = findBillsNeedingVerification(bills: bills, expenses: expenses, currentDate: today)
        
        if !billsNeedingVerification.isEmpty {
            billsToVerify = billsNeedingVerification
            needsVerification = true
            showVerificationPrompt = true
        }
    }
    
    private func findBillsNeedingVerification(bills: [Bill], expenses: [Expense], currentDate: Date) -> [Bill] {
        return bills.filter { bill in
            // Check if we're in a new period since last verification
            let isInNewPeriod = isInNewBillingPeriod(bill: bill, currentDate: currentDate)
            
            if isInNewPeriod {
                // Check if there's an expense in the current period
                let hasExpenseInPeriod = hasExpenseInCurrentPeriod(
                    bill: bill,
                    expenses: expenses,
                    currentDate: currentDate
                )
                
                // Need verification if no expense found in current period
                return !hasExpenseInPeriod
            }
            
            return false
        }
    }
    
    private func isInNewBillingPeriod(bill: Bill, currentDate: Date) -> Bool {
        // If no verification date, assume we need to verify
        guard let verificationDateString = bill.verificationDate else {
            return true
        }
        
        // Parse verification date - try multiple formats
        var verificationDate: Date?
        
        // Try ISO8601 with time first
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.timeZone = TimeZone.current
        verificationDate = iso8601Formatter.date(from: verificationDateString)
        
        // If that fails, try simple date format (YYYY-MM-DD)
        if verificationDate == nil {
            let simpleDateFormatter = DateFormatter()
            simpleDateFormatter.dateFormat = "yyyy-MM-dd"
            simpleDateFormatter.timeZone = TimeZone.current
            verificationDate = simpleDateFormatter.date(from: verificationDateString)
        }
        
        guard let parsedVerificationDate = verificationDate else {
            return true // If can't parse, assume needs verification
        }
        
        let billDueDate = bill.dueDate
        
        switch bill.frequency {
        case .monthly:
            // Check if we're in a different month than the verification date
            let currentMonth = calendar.component(.month, from: currentDate)
            let currentYear = calendar.component(.year, from: currentDate)
            let verificationMonth = calendar.component(.month, from: parsedVerificationDate)
            let verificationYear = calendar.component(.year, from: parsedVerificationDate)
            
            return currentMonth != verificationMonth || currentYear != verificationYear
            
        case .quarterly:
            // Check if we're in a different quarter than the verification date
            let currentQuarter = calendar.component(.quarter, from: currentDate)
            let currentYear = calendar.component(.year, from: currentDate)
            let verificationQuarter = calendar.component(.quarter, from: parsedVerificationDate)
            let verificationYear = calendar.component(.year, from: parsedVerificationDate)
            
            return currentQuarter != verificationQuarter || currentYear != verificationYear
            
        case .yearly:
            // Check if we're in a different year than the verification date
            let currentYear = calendar.component(.year, from: currentDate)
            let verificationYear = calendar.component(.year, from: parsedVerificationDate)
            
            return currentYear != verificationYear
        }
    }
    
    private func hasExpenseInCurrentPeriod(bill: Bill, expenses: [Expense], currentDate: Date) -> Bool {
        guard let billId = bill.id else { return false }
        
        // Get expenses for this bill
        let billExpenses = expenses.filter { $0.billId == billId }
        
        // Get the period range for this bill
        let periodRange = getCurrentPeriodRange(for: bill, date: currentDate)
        
        // Check if any expense falls within the current period
        let expenseDateFormatter = ISO8601DateFormatter()
        expenseDateFormatter.timeZone = TimeZone.current
        
        return billExpenses.contains { expense in
            if let expenseDate = expenseDateFormatter.date(from: expense.expenseDate) {
                return expenseDate >= periodRange.start && expenseDate <= periodRange.end
            }
            return false
        }
    }
    
    private func getCurrentPeriodRange(for bill: Bill, date: Date) -> (start: Date, end: Date) {
        switch bill.frequency {
        case .monthly:
            let startOfMonth = calendar.dateInterval(of: .month, for: date)?.start ?? date
            let endOfMonth = calendar.dateInterval(of: .month, for: date)?.end ?? date
            return (startOfMonth, endOfMonth)
            
        case .quarterly:
            let quarter = calendar.component(.quarter, from: date)
            let year = calendar.component(.year, from: date)
            let startMonth = (quarter - 1) * 3 + 1
            
            var components = DateComponents()
            components.year = year
            components.month = startMonth
            components.day = 1
            
            let startOfQuarter = calendar.date(from: components) ?? date
            let endOfQuarter = calendar.date(byAdding: .month, value: 3, to: startOfQuarter)?.addingTimeInterval(-1) ?? date
            
            return (startOfQuarter, endOfQuarter)
            
        case .yearly:
            let startOfYear = calendar.dateInterval(of: .year, for: date)?.start ?? date
            let endOfYear = calendar.dateInterval(of: .year, for: date)?.end ?? date
            return (startOfYear, endOfYear)
        }
    }
    
    // MARK: - Verification Actions
    
    func confirmAllBills() async {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        let todayString = dateFormatter.string(from: Date())
        
        // Reset all bills to scheduled status and update dates for new period
        for bill in billsToVerify {
            var updatedBill = bill
            updatedBill.status = .scheduled
            updatedBill.verificationDate = todayString
            
            // Update dates for the new billing period
            let newDates = calculateNewPeriodDates(for: bill)
            updatedBill.dueDate = newDates.dueDate
            updatedBill.nextDueDate = newDates.nextDueDate
            
            try? await dataManager.updateBillWithEncryption(updatedBill)
        }
        
        // Clear the verification state
        clearVerificationState()
    }
    
    func reviewBills(selectedBillIds: Set<String>) async {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        let todayString = dateFormatter.string(from: Date())
        
        // Update selected bills to scheduled status and dates for new period
        for bill in billsToVerify {
            if let billId = bill.id, selectedBillIds.contains(billId) {
                var updatedBill = bill
                updatedBill.status = .scheduled
                updatedBill.verificationDate = todayString
                
                // Update dates for the new billing period
                let newDates = calculateNewPeriodDates(for: bill)
                updatedBill.dueDate = newDates.dueDate
                updatedBill.nextDueDate = newDates.nextDueDate
                
                try? await dataManager.updateBillWithEncryption(updatedBill)
            } else {
                // Remove unselected bills
                try? await dataManager.deleteBill(bill)
            }
        }
        
        // Clear the verification state
        clearVerificationState()
    }
    
    private func clearVerificationState() {
        billsToVerify = []
        needsVerification = false
        showVerificationPrompt = false
    }
    
    // MARK: - Helper Methods
    
    private func calculateNewPeriodDates(for bill: Bill) -> (dueDate: Date, nextDueDate: Date) {
        // Use nextDueDate as the new dueDate if it exists, otherwise calculate from current dueDate
        let newDueDate: Date
        if let existingNextDueDate = bill.nextDueDate {
            newDueDate = existingNextDueDate
        } else {
            // Fallback: calculate next period from current due date
            newDueDate = calculateNextDueDateFromCurrent(bill.dueDate, frequency: bill.frequency)
        }
        
        // Calculate the next due date after the new due date
        let nextDueDate = calculateNextDueDateFromCurrent(newDueDate, frequency: bill.frequency)
        
        return (dueDate: newDueDate, nextDueDate: nextDueDate)
    }
    
    private func calculateNextDueDateFromCurrent(_ date: Date, frequency: BillFrequency) -> Date {
        switch frequency {
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: date) ?? date
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date) ?? date
        }
    }
    
    func getBillPeriodDescription(for bill: Bill) -> String {
        switch bill.frequency {
        case .monthly:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: Date())
        case .quarterly:
            let quarter = calendar.component(.quarter, from: Date())
            let year = calendar.component(.year, from: Date())
            return "Q\(quarter) \(year)"
        case .yearly:
            let year = calendar.component(.year, from: Date())
            return "\(year)"
        }
    }
}