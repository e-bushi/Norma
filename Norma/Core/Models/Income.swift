//
//  Income.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation

struct Income: Identifiable, Codable {
    var id: String?
    let userId: String
    let name: String
    let amount: Double
    let frequency: IncomeFrequency
    let source: IncomeSource
    var nextDate: Date
    var endDate: Date?
    var isActive: Bool
    let taxable: Bool
    var lastReceivedDate: Date?
    var createdAt: String?
    var updatedAt: String?
    var notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case amount
        case frequency
        case source
        case nextDate = "next_date"
        case endDate = "end_date"
        case isActive = "is_active"
        case taxable
        case lastReceivedDate = "last_received_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case notes
    }
    
    init(
        id: String? = nil,
        userId: String,
        name: String,
        amount: Double,
        source: IncomeSource,
        frequency: IncomeFrequency,
        nextDate: Date,
        endDate: Date? = nil,
        isActive: Bool = true,
        taxable: Bool = true,
        lastReceivedDate: Date? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.amount = amount
        self.source = source
        self.frequency = frequency
        self.nextDate = nextDate
        self.endDate = endDate
        self.isActive = isActive
        self.taxable = taxable
        self.lastReceivedDate = lastReceivedDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.notes = notes
    }
}

enum IncomeFrequency: String, Codable, CaseIterable {
    case oneTime = "One Time"
    case weekly = "Weekly"
    case biweekly = "Bi-Weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case semiAnnually = "Semi-Annually"
    case yearly = "Annually"
}

enum IncomeSource: String, Codable, CaseIterable {
    case salary = "Salary"
    case freelance = "Freelance"
    case business = "Business"
    case investment = "Investment"
    case rental = "Rental"
    case pension = "Pension"
    case benefits = "Benefits"
    case other = "Other"
}