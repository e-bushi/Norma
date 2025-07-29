//
//  CachedBill.swift
//  Norma
//
//  Created by Claude on 7/5/25.
//

import Foundation
import SwiftData

@Model
final class CachedBill {
    @Attribute(.unique) var id: String
    var userId: String
    var name: String
    var dueDate: Date
    var amount: Double
    var status: String
    var frequency: String
    var categoryId: String?
    var merchant: String?
    var isReminderOn: Bool = false
    var reminderDays: Int?
    var createdAt: Date
    var updatedAt: Date
    var notes: String?
    var verificationDate: String?
    
    // Sync metadata
    var lastSyncedAt: Date
    var isFromCache: Bool = true
    
    init(
        id: String,
        userId: String,
        name: String,
        dueDate: Date,
        amount: Double,
        status: String,
        frequency: String,
        categoryId: String? = nil,
        merchant: String? = nil,
        isReminderOn: Bool = false,
        reminderDays: Int? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        notes: String? = nil,
        verificationDate: String? = nil,
        lastSyncedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.dueDate = dueDate
        self.amount = amount
        self.status = status
        self.frequency = frequency
        self.categoryId = categoryId
        self.merchant = merchant
        self.isReminderOn = isReminderOn
        self.reminderDays = reminderDays
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.notes = notes
        self.verificationDate = verificationDate
        self.lastSyncedAt = lastSyncedAt
    }
    
    // Convert from Supabase Bill model
    convenience init(from bill: Bill) {
        let createdDate = ISO8601DateFormatter().date(from: bill.createdAt ?? "") ?? Date()
        let updatedDate = ISO8601DateFormatter().date(from: bill.updatedAt ?? "") ?? Date()
        
        self.init(
            id: bill.id ?? UUID().uuidString,
            userId: bill.userId,
            name: bill.name,
            dueDate: bill.dueDate,
            amount: bill.amount,
            status: bill.status.rawValue,
            frequency: bill.frequency.rawValue,
            categoryId: bill.categoryId,
            merchant: bill.merchant,
            isReminderOn: bill.isReminderOn,
            reminderDays: bill.reminderDays,
            createdAt: createdDate,
            updatedAt: updatedDate,
            notes: bill.notes,
            verificationDate: bill.verificationDate,
            lastSyncedAt: Date()
        )
    }
    
    // Convert to Supabase Bill model
    func toBill() -> Bill {
        let formatter = ISO8601DateFormatter()
        
        return Bill(
            id: id,
            userId: userId,
            name: name,
            dueDate: dueDate,
            amount: amount,
            status: BillStatus(rawValue: status) ?? .scheduled,
            frequency: BillFrequency(rawValue: frequency) ?? .monthly,
            categoryId: categoryId,
            merchant: merchant,
            isReminderOn: isReminderOn,
            reminderDays: reminderDays,
            createdAt: formatter.string(from: createdAt),
            updatedAt: formatter.string(from: updatedAt),
            notes: notes,
            verificationDate: verificationDate
        )
    }
}