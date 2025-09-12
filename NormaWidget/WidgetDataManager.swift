//
//  WidgetDataManager.swift
//  NormaWidget
//
//  Created by Claude on 8/19/25.
//

import Foundation

class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    private let sharedDefaults = UserDefaults(suiteName: "group.com.myndfruit.norma")
    
    private init() {
        if sharedDefaults == nil {
            print("❌ [WIDGET] ERROR: Failed to initialize UserDefaults with app group 'group.com.myndfruit.norma'")
            print("❌ [WIDGET] Check that the App Group capability is enabled for the widget extension target")
        } else {
            print("✅ [WIDGET] Successfully initialized UserDefaults with app group")
            // List all keys to debug
            if let keys = sharedDefaults?.dictionaryRepresentation().keys {
                print("📱 [WIDGET] Available keys in UserDefaults: \(keys)")
            }
        }
    }
    
    // MARK: - Data Retrieval Methods
    
    func getTodaysSpending() -> Double {
        let value = sharedDefaults?.double(forKey: "todaysSpending") ?? 0.0
        print("📱 [WIDGET READ] Today's spending: $\(value)")
        return value
    }
    
    func getMonthlySpending() -> Double {
        let value = sharedDefaults?.double(forKey: "monthlySpending") ?? 0.0
        print("📱 [WIDGET READ] Monthly spending: $\(value)")
        return value
    }
    
    func getMonthlyBills() -> Double {
        let value = sharedDefaults?.double(forKey: "monthlyBills") ?? 0.0
        print("📱 [WIDGET READ] Monthly bills: $\(value)")
        return value
    }
    
    func getUpcomingBills() -> [WidgetBill] {
        guard let data = sharedDefaults?.data(forKey: "upcomingBills"),
              let bills = try? JSONDecoder().decode([WidgetBillData].self, from: data) else {
            print("📱 [WIDGET READ] No upcoming bills found")
            return []
        }
        
        let widgetBills = bills.map { billData in
            WidgetBill(
                name: billData.name,
                amount: billData.amount,
                dueDate: billData.dueDate,
                status: WidgetBillStatus(rawValue: billData.status) ?? .scheduled
            )
        }
        print("📱 [WIDGET READ] Upcoming bills: \(widgetBills.count)")
        return widgetBills
    }
    
    func getMonthlyIncome() -> Double {
        let value = sharedDefaults?.double(forKey: "monthlyIncome") ?? 3000.0 // Default to 3000 if not set
        print("📱 [WIDGET READ] Monthly income: $\(value)")
        return value
    }
    
    func getLatestAIInsight() -> String? {
        return sharedDefaults?.string(forKey: "latestAIInsight")
    }
    
    func getCurrencyCode() -> String {
        return sharedDefaults?.string(forKey: "currencyCode") ?? "USD"
    }
    
    func getCurrencySymbol() -> String {
        return sharedDefaults?.string(forKey: "currencySymbol") ?? "$"
    }
    
    func formatCurrency(_ amount: Double) -> String {
        let symbol = getCurrencySymbol()
        return "\(symbol)\(String(format: "%.2f", amount))"
    }
    
    // MARK: - Data Storage Methods (for main app to call)
    
    func updateTodaysSpending(_ amount: Double) {
        sharedDefaults?.set(amount, forKey: "todaysSpending")
    }
    
    func updateMonthlySpending(_ amount: Double) {
        sharedDefaults?.set(amount, forKey: "monthlySpending")
    }
    
    func updateUpcomingBills(_ bills: [WidgetBillData]) {
        if let data = try? JSONEncoder().encode(bills) {
            sharedDefaults?.set(data, forKey: "upcomingBills")
        }
    }
    
    func updateAIInsight(_ insight: String) {
        sharedDefaults?.set(insight, forKey: "latestAIInsight")
    }
    
    func triggerWidgetRefresh() {
        sharedDefaults?.set(Date(), forKey: "lastUpdated")
    }
}

// MARK: - Data Models

struct WidgetBillData: Codable {
    let name: String
    let amount: Double
    let dueDate: Date
    let status: String
}