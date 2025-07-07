//
//  CachedExpense.swift
//  Norma
//
//  Created by Claude on 7/7/25.
//

import Foundation
import SwiftData

@Model
final class CachedExpense {
    @Attribute(.unique) var id: String
    var userId: String
    var name: String
    var amount: Double
    var expenseDate: String
    var categoryId: String?
    var billId: String?
    var paymentMethod: String
    var isRecurring: Bool
    var recurringFrequency: String?
    var merchant: String?
    var location: String?
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date
    var notes: String?
    var attachmentUrls: [String]
    
    // Sync metadata
    var lastSyncedAt: Date
    var isFromCache: Bool = true
    
    init(
        id: String,
        userId: String,
        name: String,
        amount: Double,
        expenseDate: String,
        categoryId: String? = nil,
        billId: String? = nil,
        paymentMethod: String,
        isRecurring: Bool = false,
        recurringFrequency: String? = nil,
        merchant: String? = nil,
        location: String? = nil,
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        notes: String? = nil,
        attachmentUrls: [String] = [],
        lastSyncedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.amount = amount
        self.expenseDate = expenseDate
        self.categoryId = categoryId
        self.billId = billId
        self.paymentMethod = paymentMethod
        self.isRecurring = isRecurring
        self.recurringFrequency = recurringFrequency
        self.merchant = merchant
        self.location = location
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.notes = notes
        self.attachmentUrls = attachmentUrls
        self.lastSyncedAt = lastSyncedAt
    }
    
    // Convert from Supabase Expense model
    convenience init(from expense: Expense) {
        let createdDate = ISO8601DateFormatter().date(from: expense.createdAt ?? "") ?? Date()
        let updatedDate = ISO8601DateFormatter().date(from: expense.updatedAt ?? "") ?? Date()
        
        self.init(
            id: expense.id ?? UUID().uuidString,
            userId: expense.userId,
            name: expense.name,
            amount: expense.amount,
            expenseDate: expense.expenseDate,
            categoryId: expense.categoryId,
            billId: expense.billId,
            paymentMethod: expense.paymentMethod.rawValue,
            isRecurring: expense.isRecurring,
            recurringFrequency: expense.recurringFrequency?.rawValue,
            merchant: expense.merchant,
            location: expense.location,
            tags: expense.tags,
            createdAt: createdDate,
            updatedAt: updatedDate,
            notes: expense.notes,
            attachmentUrls: expense.attachmentUrls,
            lastSyncedAt: Date()
        )
    }
    
    // Convert to Supabase Expense model
    func toExpense() -> Expense {
        let formatter = ISO8601DateFormatter()
        
        return Expense(
            id: id,
            userId: userId,
            name: name,
            amount: amount,
            expenseDate: expenseDate,
            categoryId: categoryId,
            billId: billId,
            paymentMethod: PaymentMethod(rawValue: paymentMethod) ?? .cash,
            isRecurring: isRecurring,
            recurringFrequency: recurringFrequency != nil ? ExpenseFrequency(rawValue: recurringFrequency!) : nil,
            merchant: merchant,
            location: location,
            tags: tags,
            createdAt: formatter.string(from: createdAt),
            updatedAt: formatter.string(from: updatedAt),
            notes: notes,
            attachmentUrls: attachmentUrls
        )
    }
}