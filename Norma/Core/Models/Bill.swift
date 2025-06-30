//
//  Bill.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation

struct Bill: Identifiable, Codable {
    var id: String?
    let userId: String
    let name: String
    var dueDate: Date
    let amount: Double
    var status: BillStatus
    let frequency: BillFrequency
    let categoryId: String?
    let merchant: String?
    let isAutoPayEnabled: Bool
    let reminderDays: Int?
    var createdAt: String?
    var updatedAt: String?
    var notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case dueDate = "due_date"
        case amount
        case status
        case frequency
        case categoryId = "category_id"
        case merchant
        case isAutoPayEnabled = "is_auto_pay_enabled"
        case reminderDays = "reminder_days"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case notes
    }
    
    init(
        id: String? = nil,
        userId: String,
        name: String,
        dueDate: Date,
        amount: Double,
        status: BillStatus,
        frequency: BillFrequency,
        categoryId: String? = nil,
        merchant: String? = nil,
        isAutoPayEnabled: Bool = false,
        reminderDays: Int? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil,
        notes: String? = nil
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
        self.isAutoPayEnabled = isAutoPayEnabled
        self.reminderDays = reminderDays
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.notes = notes
    }
}

// Bill status enum
enum BillStatus: String, Codable {
    case paid = "Paid"
    case overdue = "Overdue"
    case scheduled = "Scheduled"
    case active = "Active"
}

// Bill frequency enum
enum BillFrequency: String, Codable {
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"
}