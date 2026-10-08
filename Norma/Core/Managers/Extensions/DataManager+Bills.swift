//
//  DataManager+Bills.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation
import SwiftData

extension DataManager {

    // MARK: - Bill CRUD

    /// Loads every persisted bill for this install into `bills`.
    func loadBills() {
        guard let modelContext else { return }
        let userId = LocalStore.userId
        let descriptor = FetchDescriptor<CachedBill>(
            predicate: #Predicate { $0.userId == userId },
            sortBy: [SortDescriptor(\.dueDate)]
        )
        do {
            bills = try modelContext.fetch(descriptor).map { $0.toBill() }
        } catch {
            print("DataManager.loadBills: fetch failed — \(error)")
        }
    }

    func addBill(_ bill: Bill) throws {
        var billToAdd = bill
        if billToAdd.id == nil {
            billToAdd.id = UUID().uuidString
        }
        if billToAdd.createdAt == nil {
            billToAdd.createdAt = ISO8601DateFormatter().string(from: Date())
        }
        modelContext?.insert(CachedBill(from: billToAdd))
        try modelContext?.save()
        bills.append(billToAdd)
    }

    func updateBill(_ bill: Bill) throws {
        guard let billId = bill.id else { throw BillStoreError.missingId }
        if let stored = try storedBill(id: billId) {
            stored.update(from: bill)
        } else {
            modelContext?.insert(CachedBill(from: bill))
        }
        try modelContext?.save()
        if let index = bills.firstIndex(where: { $0.id == billId }) {
            bills[index] = bill
        }
    }

    func deleteBill(_ bill: Bill) throws {
        guard let billId = bill.id else { throw BillStoreError.missingId }
        if let stored = try storedBill(id: billId) {
            modelContext?.delete(stored)
            try modelContext?.save()
        }
        bills.removeAll { $0.id == billId }
    }

    private func storedBill(id: String) throws -> CachedBill? {
        let descriptor = FetchDescriptor<CachedBill>(predicate: #Predicate { $0.id == id })
        return try modelContext?.fetch(descriptor).first
    }

    // MARK: - Bill Queries

    func getActiveBills() -> [Bill] {
        // Show all bills (scheduled, overdue, and paid)
        bills.sorted { $0.effectiveDueDate < $1.effectiveDueDate }
    }

    func getUpcomingBills(days: Int = 7) -> [Bill] {
        let endDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        return getActiveBills().filter { bill in
            bill.effectiveDueDate >= Date() && bill.effectiveDueDate <= endDate
        }
    }

    func getOverdueBills() -> [Bill] {
        bills.filter { $0.calculateStatus() == .overdue }
            .sorted { $0.effectiveDueDate < $1.effectiveDueDate }
    }

    func getBillsByStatus(_ status: BillStatus) -> [Bill] {
        bills.filter { $0.calculateStatus() == status }
            .sorted { $0.effectiveDueDate < $1.effectiveDueDate }
    }

    func getTotalMonthlyBills() -> Double {
        ArcCalculationService.calculateMonthlyBillsTotal(bills: getActiveBills())
    }

    func getBillsDueSoon(within days: Int = 3) -> [Bill] {
        let endDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        return getActiveBills().filter { bill in
            bill.effectiveDueDate >= Date() && bill.effectiveDueDate <= endDate
        }
    }

    func getNextBillDue() -> Bill? {
        getActiveBills()
            .filter { $0.effectiveDueDate >= Date() }
            .min { $0.effectiveDueDate < $1.effectiveDueDate }
    }
}

enum BillStoreError: LocalizedError {
    case missingId

    var errorDescription: String? {
        switch self {
        case .missingId: return "Bill ID is required."
        }
    }
}
