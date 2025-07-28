//
//  CachedBudget.swift
//  Norma
//
//  Created by Claude on 7/20/25.
//

import Foundation
import SwiftData

@Model
final class CachedBudget {
    @Attribute(.unique) var id: String
    var userId: String
    var name: String
    var amount: Double
    var categoryId: String?
    var startDate: Date
    var endDate: Date?
    var isActive: Bool
    var currentSpent: Double
    var alertThreshold: Double
    var createdAt: Date
    var updatedAt: Date
    var notes: String?
    
    // Sync metadata
    var lastSyncedAt: Date
    var isFromCache: Bool = true
    
    init(
        id: String,
        userId: String,
        name: String,
        amount: Double,
        categoryId: String? = nil,
        startDate: Date,
        endDate: Date? = nil,
        isActive: Bool = true,
        currentSpent: Double = 0,
        alertThreshold: Double = 0.8,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        notes: String? = nil,
        lastSyncedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.amount = amount
        self.categoryId = categoryId
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.currentSpent = currentSpent
        self.alertThreshold = alertThreshold
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.notes = notes
        self.lastSyncedAt = lastSyncedAt
    }
    
    // Convert from Supabase Budget model
    convenience init(from budget: Budget) {
        let formatter = ISO8601DateFormatter()
        let createdDate = budget.createdAt.flatMap { formatter.date(from: $0) } ?? Date()
        let updatedDate = budget.updatedAt.flatMap { formatter.date(from: $0) } ?? Date()
        
        self.init(
            id: budget.id ?? UUID().uuidString,
            userId: budget.userId,
            name: budget.name,
            amount: budget.amount,
            categoryId: budget.categoryId,
            startDate: budget.startDate,
            endDate: budget.endDate,
            isActive: budget.isActive,
            currentSpent: budget.currentSpent,
            alertThreshold: budget.alertThreshold,
            createdAt: createdDate,
            updatedAt: updatedDate,
            notes: budget.notes,
            lastSyncedAt: Date()
        )
    }
    
    // Convert to Supabase Budget model
    func toBudget() -> Budget {
        let formatter = ISO8601DateFormatter()
        
        return Budget(
            id: id,
            userId: userId,
            name: name,
            amount: amount,
            categoryId: categoryId,
            startDate: startDate,
            endDate: endDate,
            isActive: isActive,
            currentSpent: currentSpent,
            alertThreshold: alertThreshold,
            createdAt: formatter.string(from: createdAt),
            updatedAt: formatter.string(from: updatedAt),
            notes: notes
        )
    }
}