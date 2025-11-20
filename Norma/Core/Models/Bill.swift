//
//  Bill.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation

struct Bill: Identifiable, Codable, Equatable {
    var id: String?
    let userId: String
    var name: String
    var dueDate: Date
    var nextDueDate: Date?
    var amount: Double
    var status: BillStatus
    var frequency: BillFrequency
    var categoryId: String?
    var merchant: String?
    var isReminderOn: Bool
    var reminderDays: Int?
    var isActive: Bool?
    var createdAt: String?
    var updatedAt: String?
    var notes: String?
    var verificationDate: String?
    var isMostCritical: Bool? // Marks the most important bill (usually rent/mortgage) for arc calculation

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case dueDate = "due_date"
        case nextDueDate = "next_due_date"
        case amount
        case status
        case frequency
        case categoryId = "category_id"
        case merchant
        case isReminderOn = "is_reminder_on"
        case reminderDays = "reminder_days"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case notes
        case verificationDate = "verification_date"
        case isMostCritical = "is_most_critical"
    }
    
    // Custom decoding to handle date formats from Supabase
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        name = try container.decode(String.self, forKey: .name)
        amount = try container.decode(Double.self, forKey: .amount)
        status = try container.decode(BillStatus.self, forKey: .status)
        frequency = try container.decode(BillFrequency.self, forKey: .frequency)
        categoryId = try container.decodeIfPresent(String.self, forKey: .categoryId)
        merchant = try container.decodeIfPresent(String.self, forKey: .merchant)
        isReminderOn = try container.decode(Bool.self, forKey: .isReminderOn)
        reminderDays = try container.decodeIfPresent(Int.self, forKey: .reminderDays)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        verificationDate = try container.decodeIfPresent(String.self, forKey: .verificationDate)
        isMostCritical = try container.decodeIfPresent(Bool.self, forKey: .isMostCritical)

        // Handle date decoding with multiple formats
        let dueDateString = try container.decode(String.self, forKey: .dueDate)
        
        // Try ISO8601 with time component first (since Supabase returns this format)
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: dueDateString) {
            // Convert to local date at midnight to avoid timezone issues
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            self.dueDate = calendar.date(from: components) ?? date
        } else {
            // Fallback to YYYY-MM-DD format
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone.current
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            if let date = dateFormatter.date(from: dueDateString) {
                self.dueDate = date
            } else {
                throw DecodingError.dataCorruptedError(forKey: .dueDate,
                                                      in: container,
                                                      debugDescription: "Invalid date format: \(dueDateString)")
            }
        }
        
        // Handle nextDueDate decoding (optional field)
        if let nextDueDateString = try container.decodeIfPresent(String.self, forKey: .nextDueDate) {
            // Try ISO8601 with time component first
            let isoFormatter = ISO8601DateFormatter()
            if let date = isoFormatter.date(from: nextDueDateString) {
                // Convert to local date at midnight to avoid timezone issues
                let calendar = Calendar.current
                let components = calendar.dateComponents([.year, .month, .day], from: date)
                self.nextDueDate = calendar.date(from: components) ?? date
            } else {
                // Fallback to YYYY-MM-DD format
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.timeZone = TimeZone.current
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                self.nextDueDate = dateFormatter.date(from: nextDueDateString)
            }
        } else {
            self.nextDueDate = nil
        }
    }
    
    // Custom encoding to ensure dates are sent in YYYY-MM-DD format
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(name, forKey: .name)
        try container.encode(amount, forKey: .amount)
        try container.encode(status, forKey: .status)
        try container.encode(frequency, forKey: .frequency)
        try container.encodeIfPresent(categoryId, forKey: .categoryId)
        try container.encodeIfPresent(merchant, forKey: .merchant)
        try container.encode(isReminderOn, forKey: .isReminderOn)
        try container.encodeIfPresent(reminderDays, forKey: .reminderDays)
        try container.encodeIfPresent(isActive, forKey: .isActive)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(verificationDate, forKey: .verificationDate)
        try container.encodeIfPresent(isMostCritical, forKey: .isMostCritical)

        // Encode dates as YYYY-MM-DD string
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let dueDateString = dateFormatter.string(from: dueDate)
        try container.encode(dueDateString, forKey: .dueDate)
        
        if let nextDueDate = nextDueDate {
            let nextDueDateString = dateFormatter.string(from: nextDueDate)
            try container.encode(nextDueDateString, forKey: .nextDueDate)
        }
    }
    
    init(
        id: String? = nil,
        userId: String,
        name: String,
        dueDate: Date,
        nextDueDate: Date? = nil,
        amount: Double,
        status: BillStatus,
        frequency: BillFrequency,
        categoryId: String? = nil,
        merchant: String? = nil,
        isReminderOn: Bool = false,
        reminderDays: Int? = nil,
        isActive: Bool? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil,
        notes: String? = nil,
        verificationDate: String? = nil,
        isMostCritical: Bool? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.dueDate = dueDate
        self.nextDueDate = nextDueDate
        self.amount = amount
        self.status = status
        self.frequency = frequency
        self.categoryId = categoryId
        self.merchant = merchant
        self.isReminderOn = isReminderOn
        self.reminderDays = reminderDays
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.notes = notes
        self.verificationDate = verificationDate
        self.isMostCritical = isMostCritical
    }
}

// Bill status enum
enum BillStatus: String, Codable, CaseIterable {
    case paid = "Paid"
    case overdue = "Overdue"
    case scheduled = "Scheduled"
}

// Bill frequency enum
enum BillFrequency: String, Codable, CaseIterable {
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"
}

// MARK: - Bill Status Calculation
extension Bill {
    
    /// Calculate the bill status based on payment history (expenses with matching billId)
    func calculateStatus(from expenses: [Expense]) -> BillStatus {
        let calendar = Calendar.current
        let now = Date()
        
        // Check if bill was paid this billing period
        let dateFormatter = ISO8601DateFormatter()
        let billPayments = expenses.filter { expense in
            guard expense.billId == self.id,
                  let expenseDate = dateFormatter.date(from: expense.expenseDate) else { return false }
            return isSameBillingPeriod(expenseDate: expenseDate, billDueDate: self.dueDate)
        }
        
        // If we found payment(s), bill is paid
        if !billPayments.isEmpty {
            return .paid
        }
        
        // No payments found - check if overdue
        if dueDate < now {
            return .overdue
        }
        
        // Future or today's due date with no payment = scheduled
        return .scheduled
    }
    
    /// Check if an expense date is in the current billing period for this bill
    private func isSameBillingPeriod(expenseDate: Date, billDueDate: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        switch frequency {
        case .monthly:
            // For monthly bills, check if the expense is in the current month
            return calendar.isDate(expenseDate, equalTo: now, toGranularity: .month)
        case .quarterly:
            // For quarterly bills, check if the expense is in the current quarter
            return calendar.isDate(expenseDate, equalTo: now, toGranularity: .quarter)
        case .yearly:
            // For yearly bills, check if the expense is in the current year
            return calendar.isDate(expenseDate, equalTo: now, toGranularity: .year)
        }
    }
    
    /// Get the total amount paid for this bill in the current billing period
    func getAmountPaidThisPeriod(from expenses: [Expense]) -> Double {
        let dateFormatter = ISO8601DateFormatter()
        return expenses
            .filter { expense in
                guard expense.billId == self.id,
                      let expenseDate = dateFormatter.date(from: expense.expenseDate) else { return false }
                return isSameBillingPeriod(expenseDate: expenseDate, billDueDate: self.dueDate)
            }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Check if this bill is fully paid this period
    func isFullyPaid(from expenses: [Expense]) -> Bool {
        let amountPaid = getAmountPaidThisPeriod(from: expenses)
        return amountPaid >= amount
    }
}