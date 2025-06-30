//
//  Budget.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation

struct Budget: Identifiable, Codable {
    var id: String?
    let userId: String
    let name: String
    let amount: Double
    let period: BudgetPeriod
    let categoryId: String?
    let startDate: Date
    var endDate: Date?
    var isActive: Bool
    var currentSpent: Double
    let alertThreshold: Double
    var createdAt: String?
    var updatedAt: String?
    var notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case amount
        case period
        case categoryId = "category_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case isActive = "is_active"
        case currentSpent = "current_spent"
        case alertThreshold = "alert_threshold"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case notes
    }
    
    init(
        id: String? = nil,
        userId: String,
        name: String,
        amount: Double,
        period: BudgetPeriod,
        categoryId: String? = nil,
        startDate: Date = Date(),
        endDate: Date? = nil,
        isActive: Bool = true,
        currentSpent: Double = 0,
        alertThreshold: Double = 0.8,
        createdAt: String? = nil,
        updatedAt: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.amount = amount
        self.period = period
        self.categoryId = categoryId
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.currentSpent = currentSpent
        self.alertThreshold = alertThreshold
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.notes = notes
    }
    
    var remainingAmount: Double {
        amount - currentSpent
    }
    
    var percentageUsed: Double {
        guard amount > 0 else { return 0 }
        return (currentSpent / amount) * 100
    }
    
    var isOverBudget: Bool {
        currentSpent > amount
    }
    
    var isNearThreshold: Bool {
        percentageUsed >= (alertThreshold * 100)
    }
}

enum BudgetPeriod: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case biWeekly = "Bi-Weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case annually = "Annually"
    case custom = "Custom"
}