//
//  CachedBill.swift
//  Norma
//
//  Created by Claude on 7/5/25.
//
//  The on-device store for bills. `Bill` stays the value type the UI works
//  with; this @Model is its persisted form.
//

import Foundation
import SwiftData

@Model
final class CachedBill {
    @Attribute(.unique) var id: String
    var userId: String
    var name: String
    var dueDate: Date
    var nextDueDate: Date?
    var amount: Double
    var status: String
    var frequency: String
    var categoryId: String?
    var merchant: String?
    var isReminderOn: Bool = false
    var reminderDays: Int?
    var isActive: Bool?
    var isMostCritical: Bool?
    var paidAt: Date?
    var createdAt: Date
    var updatedAt: Date
    var notes: String?
    var verificationDate: String?

    // Legacy sync metadata, kept so existing stores migrate without a schema bump.
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
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.dueDate = dueDate
        self.amount = amount
        self.status = status
        self.frequency = frequency
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastSyncedAt = Date()
    }

    convenience init(from bill: Bill) {
        let createdDate = ISO8601DateFormatter().date(from: bill.createdAt ?? "") ?? Date()
        self.init(
            id: bill.id ?? UUID().uuidString,
            userId: bill.userId,
            name: bill.name,
            dueDate: bill.dueDate,
            amount: bill.amount,
            status: bill.status.rawValue,
            frequency: bill.frequency.rawValue,
            createdAt: createdDate
        )
        update(from: bill)
    }

    /// Copies every mutable field from `bill`. Identity and `createdAt` stay put.
    func update(from bill: Bill) {
        name = bill.name
        dueDate = bill.dueDate
        nextDueDate = bill.nextDueDate
        amount = bill.amount
        status = bill.status.rawValue
        frequency = bill.frequency.rawValue
        categoryId = bill.categoryId
        merchant = bill.merchant
        isReminderOn = bill.isReminderOn
        reminderDays = bill.reminderDays
        isActive = bill.isActive
        isMostCritical = bill.isMostCritical
        paidAt = bill.paidAt
        notes = bill.notes
        verificationDate = bill.verificationDate
        updatedAt = Date()
    }

    func toBill() -> Bill {
        let formatter = ISO8601DateFormatter()
        return Bill(
            id: id,
            userId: userId,
            name: name,
            dueDate: dueDate,
            nextDueDate: nextDueDate,
            amount: amount,
            status: BillStatus(rawValue: status) ?? .scheduled,
            frequency: BillFrequency(rawValue: frequency) ?? .monthly,
            categoryId: categoryId,
            merchant: merchant,
            isReminderOn: isReminderOn,
            reminderDays: reminderDays,
            isActive: isActive,
            createdAt: formatter.string(from: createdAt),
            updatedAt: formatter.string(from: updatedAt),
            notes: notes,
            verificationDate: verificationDate,
            isMostCritical: isMostCritical,
            paidAt: paidAt
        )
    }
}
