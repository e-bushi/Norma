//
//  DataManager+Bills.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation

extension DataManager {
    
    // MARK: - Bill Methods
    
    func fetchBills(userId: String) async throws {
        let fetchedBills = try await supabaseService.fetchBills(userId: userId)
        bills = fetchedBills
        
        print("Fetching bills for user: \(userId)")
    }
    
    func addBill(_ bill: Bill) async throws {
        let createdBill = try await supabaseService.createBill(bill)
        bills.append(createdBill)
        hasUnsyncedChanges = true
        
        print("Added bill: \(bill.name)")
    }
    
    func updateBill(_ bill: Bill) async throws {
        let updatedBill = try await supabaseService.updateBill(bill)
        
        if let index = bills.firstIndex(where: { $0.id == bill.id }) {
            bills[index] = updatedBill
            hasUnsyncedChanges = true
        }
        
        print("Updated bill: \(bill.name)")
    }
    
    func deleteBill(_ bill: Bill) async throws {
        guard let billId = bill.id else {
            throw NSError(domain: "DataManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bill ID is required for deletion"])
        }
        
        try await supabaseService.deleteBill(billId)
        bills.removeAll { $0.id == bill.id }
        hasUnsyncedChanges = true
        
        print("Deleted bill: \(bill.name)")
    }
    
    // MARK: - Bill Queries
    
    func getActiveBills() -> [Bill] {
        return bills.filter { $0.status == .active }
            .sorted { $0.dueDate < $1.dueDate }
    }
    
    func getUpcomingBills(days: Int = 7) -> [Bill] {
        let endDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        
        return getActiveBills().filter { bill in
            bill.dueDate >= Date() && bill.dueDate <= endDate
        }
    }
    
    func getOverdueBills() -> [Bill] {
        return bills.filter { $0.status == .overdue }
            .sorted { $0.dueDate < $1.dueDate }
    }
    
    func getBillsByStatus(_ status: BillStatus) -> [Bill] {
        return bills.filter { $0.status == status }
            .sorted { $0.dueDate < $1.dueDate }
    }
    
    func getTotalMonthlyBills() -> Double {
        return getActiveBills().reduce(0) { total, bill in
            switch bill.frequency {
            case .monthly:
                return total + bill.amount
            case .quarterly:
                return total + (bill.amount * 4 / 12)
            case .yearly:
                return total + (bill.amount / 12)
            }
        }
    }
    
    func getBillsDueSoon(within days: Int = 3) -> [Bill] {
        let endDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        
        return getActiveBills().filter { bill in
            bill.dueDate >= Date() && bill.dueDate <= endDate
        }
    }
    
    func getNextBillDue() -> Bill? {
        return getActiveBills()
            .filter { $0.dueDate >= Date() }
            .min { $0.dueDate < $1.dueDate }
    }
    
    func markBillAsPaid(_ bill: Bill) async throws {
        var updatedBill = bill
        updatedBill.status = .paid
        
        // For recurring bills, calculate next due date and mark as active
        updatedBill.dueDate = calculateNextDueDate(for: bill)
        updatedBill.status = .active
        
        try await updateBill(updatedBill)
    }
    
    private func calculateNextDueDate(for bill: Bill) -> Date {
        let calendar = Calendar.current
        
        switch bill.frequency {
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: bill.dueDate) ?? bill.dueDate
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: bill.dueDate) ?? bill.dueDate
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: bill.dueDate) ?? bill.dueDate
        }
    }
}