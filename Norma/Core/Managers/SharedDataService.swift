//
//  SharedDataService.swift
//  Norma
//
//  Created by Claude on 8/24/25.
//

import Foundation
import WidgetKit

class SharedDataService {
    static let shared = SharedDataService()
    
    private let sharedDefaults = UserDefaults(suiteName: "group.com.myndfruit.norma")
    
    private init() {}
    
    // MARK: - Intent Actions (for App Extensions)
    
    /// Create an expense from Siri/Widget - stores intent for main app to process
    func createExpenseFromIntent(
        amount: Double,
        description: String,
        category: String? = nil,
        billId: String? = nil
    ) async throws -> String {
        
        let intentData: [String: Any] = [
            "type": "create_expense",
            "amount": amount,
            "description": description,
            "category": category ?? "Other",
            "billId": billId as Any,
            "timestamp": Date().timeIntervalSince1970,
            "id": UUID().uuidString
        ]
        
        // Store the intent for the main app to process
        var pendingIntents = sharedDefaults?.array(forKey: "pendingIntents") as? [[String: Any]] ?? []
        pendingIntents.append(intentData)
        sharedDefaults?.set(pendingIntents, forKey: "pendingIntents")
        
        // Trigger background app refresh to process intent
        WidgetCenter.shared.reloadAllTimelines()
        
        return intentData["id"] as! String
    }
    
    
    // MARK: - Main App Processing
    
    /// Process pending intents from main app (call this from DataManager)
    @MainActor
    func processPendingIntents(dataManager: DataManager) async {
        guard let pendingIntents = sharedDefaults?.array(forKey: "pendingIntents") as? [[String: Any]],
              !pendingIntents.isEmpty else { 
            return 
        }
        
        print("📱 [SHARED] Processing \(pendingIntents.count) pending intents...")
        
        var processedIntents: [[String: Any]] = []
        
        for intentData in pendingIntents {
            do {
                try await processIntent(intentData, dataManager: dataManager)
                print("✅ [SHARED] Successfully processed intent: \(intentData["id"] ?? "unknown")")
            } catch {
                print("❌ [SHARED] Failed to process intent: \(error)")
                // Keep failed intents for retry
                processedIntents.append(intentData)
            }
        }
        
        // Update pending intents (remove successful ones, keep failed ones)
        if processedIntents.isEmpty {
            sharedDefaults?.removeObject(forKey: "pendingIntents")
        } else {
            sharedDefaults?.set(processedIntents, forKey: "pendingIntents")
        }
        
        // Update widget data after processing
        WidgetDataManager.shared.updateWidgetData(
            bills: dataManager.bills,
            expenses: dataManager.expenses,
            monthlyIncome: dataManager.currentProfile?.settings.monthlyIncome ?? 0
        )
    }
    
    @MainActor
    private func processIntent(_ intentData: [String: Any], dataManager: DataManager) async throws {
        guard let type = intentData["type"] as? String else {
            throw NSError(domain: "SharedDataService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid intent type"])
        }
        
        switch type {
        case "create_expense":
            try await processCreateExpenseIntent(intentData, dataManager: dataManager)
        case "update_bill_payment":
            try await processBillPaymentIntent(intentData, dataManager: dataManager)
        default:
            throw NSError(domain: "SharedDataService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Unknown intent type: \(type)"])
        }
    }
    
    @MainActor
    private func processCreateExpenseIntent(_ intentData: [String: Any], dataManager: DataManager) async throws {
        guard let amount = intentData["amount"] as? Double,
              let description = intentData["description"] as? String,
              let category = intentData["category"] as? String,
              let timestamp = intentData["timestamp"] as? TimeInterval,
              let currentProfile = dataManager.currentProfile else {
            throw NSError(domain: "SharedDataService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid expense intent data"])
        }
        
        // Create the expense
        let expenseDate = Date(timeIntervalSince1970: timestamp)
        let billId = intentData["billId"] as? String
        
        let expense = Expense(
            id: nil, // Let DataManager assign ID
            userId: currentProfile.userId,
            name: description,
            amount: amount,
            expenseDate: ISO8601DateFormatter().string(from: expenseDate),
            budgetId: nil, // Could map category to budget in the future
            billId: billId,
            paymentMethod: .other,
            isRecurring: false,
            recurringFrequency: nil,
            merchant: nil,
            location: nil,
            tags: [category],
            createdAt: nil,
            updatedAt: nil,
            notes: "Created via Siri"
        )
        
        try await dataManager.addExpense(expense)
        print("✅ [SHARED] Created expense via intent: \(description) - $\(amount)")
    }
    
    @MainActor
    private func processBillPaymentIntent(_ intentData: [String: Any], dataManager: DataManager) async throws {
        guard let billName = intentData["billName"] as? String,
              let paymentAmount = intentData["paymentAmount"] as? Double,
              let paymentTimestamp = intentData["paymentDate"] as? TimeInterval else {
            throw NSError(domain: "SharedDataService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid bill payment intent data"])
        }
        
        // Find the bill by name
        guard let bill = dataManager.bills.first(where: { 
            $0.name.lowercased() == billName.lowercased()
        }) else {
            print("⚠️ [SHARED] Bill not found for payment update: \(billName)")
            return // Don't throw error, expense was already created
        }
        
        var updatedBill = bill
        let paymentDate = Date(timeIntervalSince1970: paymentTimestamp)
        
        // Update bill status to paid
        updatedBill.status = .paid
        
        // Update verification date to track when status was changed
        let dateFormatter = ISO8601DateFormatter()
        updatedBill.verificationDate = dateFormatter.string(from: paymentDate)
        
        // For recurring bills, advance the next due date
        if let nextDueDate = updatedBill.nextDueDate {
            updatedBill.nextDueDate = advanceDate(nextDueDate, by: updatedBill.frequency)
        } else {
            // If no nextDueDate set, advance from current due date
            updatedBill.nextDueDate = advanceDate(updatedBill.dueDate, by: updatedBill.frequency)
        }
        
        try await dataManager.updateBill(updatedBill)
        print("✅ [SHARED] Updated bill status and next due date: \(billName)")
    }
    
    // MARK: - Helper Methods
    
    private func advanceDate(_ date: Date, by frequency: BillFrequency) -> Date {
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
}