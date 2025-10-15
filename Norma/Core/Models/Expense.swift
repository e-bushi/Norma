//
//  Expense.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation

struct Expense: Identifiable, Codable, Equatable {
    var id: String?
    let userId: String
    let name: String
    let amount: Double
    let expenseDate: String
    let budgetId: String?
    let billId: String?
    let paymentMethod: PaymentMethod
    let isRecurring: Bool
    var recurringFrequency: ExpenseFrequency?
    let merchant: String?
    let location: String?
    let tags: [String]
    var createdAt: String?
    var updatedAt: String?
    var notes: String?
    var attachmentUrls: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case amount
        case expenseDate = "expense_date"
        case budgetId = "budget_id"
        case billId = "bill_id"
        case paymentMethod = "payment_method"
        case isRecurring = "is_recurring"
        case recurringFrequency = "recurring_frequency"
        case merchant
        case location
        case tags
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case notes
        case attachmentUrls = "attachment_urls"
    }
    
    init(
        id: String? = nil,
        userId: String,
        name: String,
        amount: Double,
        expenseDate: String,
        budgetId: String? = nil,
        billId: String? = nil,
        paymentMethod: PaymentMethod,
        isRecurring: Bool = false,
        recurringFrequency: ExpenseFrequency? = nil,
        merchant: String? = nil,
        location: String? = nil,
        tags: [String] = [],
        createdAt: String? = nil,
        updatedAt: String? = nil,
        notes: String? = nil,
        attachmentUrls: [String] = []
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.amount = amount
        self.expenseDate = expenseDate
        self.budgetId = budgetId
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
    }
}

enum PaymentMethod: String, Codable, CaseIterable {
    case cash = "Cash"
    case creditCard = "Credit Card"
    case debitCard = "Debit Card"
    case bankTransfer = "Bank Transfer"
    case digitalWallet = "Digital Wallet"
    case check = "Check"
    case other = "Other"
}

enum ExpenseFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case biWeekly = "Bi-Weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case annually = "Annually"
}