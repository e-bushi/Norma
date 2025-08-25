//
//  SharedDataService.swift
//  NormaWidget
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
        
        // For now, also update widget data immediately for better UX
        let widgetManager = WidgetDataManager.shared
        let currentSpending = widgetManager.getTodaysSpending()
        let monthlySpending = widgetManager.getMonthlySpending()
        
        widgetManager.updateTodaysSpending(currentSpending + amount)
        widgetManager.updateMonthlySpending(monthlySpending + amount)
        widgetManager.triggerWidgetRefresh()
        
        return intentData["id"] as! String
    }
    
    /// Mark bill as paid from Siri/Widget
    func payBillFromIntent(billName: String, amount: Double? = nil) async throws -> (String, Double) {
        
        // Get bill data to find matching bill
        let widgetManager = WidgetDataManager.shared
        let bills = widgetManager.getUpcomingBills()
        
        guard let matchingBill = bills.first(where: { 
            $0.name.lowercased().contains(billName.lowercased()) 
        }) else {
            throw NSError(
                domain: "SharedDataService", 
                code: 404, 
                userInfo: [NSLocalizedDescriptionKey: "Bill not found: \(billName)"]
            )
        }
        
        let paymentAmount = amount ?? matchingBill.amount
        
        // Create both expense and bill update intents
        let expenseIntentData: [String: Any] = [
            "type": "create_expense",
            "amount": paymentAmount,
            "description": "Payment for \(matchingBill.name)",
            "category": "Bills",
            "billId": matchingBill.name, // This will need to be the actual bill ID in processing
            "timestamp": Date().timeIntervalSince1970,
            "id": UUID().uuidString
        ]
        
        let billUpdateIntentData: [String: Any] = [
            "type": "update_bill_payment",
            "billName": matchingBill.name,
            "paymentAmount": paymentAmount,
            "paymentDate": Date().timeIntervalSince1970,
            "id": UUID().uuidString
        ]
        
        // Store both intents for the main app to process
        var pendingIntents = sharedDefaults?.array(forKey: "pendingIntents") as? [[String: Any]] ?? []
        pendingIntents.append(expenseIntentData)
        pendingIntents.append(billUpdateIntentData)
        sharedDefaults?.set(pendingIntents, forKey: "pendingIntents")
        
        // Trigger background app refresh to process intents
        WidgetCenter.shared.reloadAllTimelines()
        
        // Update widget data immediately for better UX
        let currentSpending = widgetManager.getTodaysSpending()
        let monthlySpending = widgetManager.getMonthlySpending()
        
        widgetManager.updateTodaysSpending(currentSpending + paymentAmount)
        widgetManager.updateMonthlySpending(monthlySpending + paymentAmount)
        widgetManager.triggerWidgetRefresh()
        
        return (expenseIntentData["id"] as! String, paymentAmount)
    }
}