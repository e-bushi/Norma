//
//  Bill.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation

struct Bill: Identifiable, Codable, Equatable {
    var id: String?
    var userId: String
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
    /// Timestamp of the most recent mark-paid action. The bill's display status
    /// is derived: paid for the cycle containing `paidAt`, scheduled/overdue
    /// otherwise. Auto-renews when the calendar moves past the cycle.
    var paidAt: Date?

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
        case paidAt = "paid_at"
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

        if let paidAtString = try container.decodeIfPresent(String.self, forKey: .paidAt) {
            paidAt = ISO8601DateFormatter().date(from: paidAtString)
        } else {
            paidAt = nil
        }

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

        if let paidAt {
            try container.encode(ISO8601DateFormatter().string(from: paidAt), forKey: .paidAt)
        }

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
        isMostCritical: Bool? = nil,
        paidAt: Date? = nil
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
        self.paidAt = paidAt
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
    case oneTime = "OneTime"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"
}

// MARK: - Recurrence (anchor-day model)
extension Bill {

    /// Day-of-month anchor derived from the original due date. Recurring bills
    /// fall on this day every cycle.
    var dayOfMonth: Int {
        Calendar.current.component(.day, from: dueDate)
    }

    /// The due date for the bill's *current* billing cycle (the cycle containing
    /// today). For `.oneTime`, this is just the literal anchor. For recurring
    /// bills, the anchor is projected into the current calendar period — month,
    /// quarter, or year — clamping day-of-month to the last day where needed.
    var effectiveDueDate: Date {
        let now = Date()
        switch frequency {
        case .oneTime:
            return dueDate
        case .monthly:
            return Self.projectAnchor(dueDate, into: now, period: .month, monthStride: 1) ?? dueDate
        case .quarterly:
            return Self.projectAnchor(dueDate, into: now, period: .quarter, monthStride: 3) ?? dueDate
        case .yearly:
            return Self.projectAnchor(dueDate, into: now, period: .year, monthStride: 12) ?? dueDate
        }
    }

    /// Is the given expense date inside the bill's current billing cycle (the
    /// period containing today)? `.oneTime` bills accept any expense.
    func isInCurrentCycle(expenseDate: Date) -> Bool {
        let cal = Calendar.current
        let now = Date()
        switch frequency {
        case .oneTime:
            return true
        case .monthly:
            return cal.isDate(expenseDate, equalTo: now, toGranularity: .month)
        case .quarterly:
            return cal.isDate(expenseDate, equalTo: now, toGranularity: .quarter)
        case .yearly:
            return cal.isDate(expenseDate, equalTo: now, toGranularity: .year)
        }
    }

    private static func projectAnchor(
        _ anchor: Date,
        into reference: Date,
        period: Calendar.Component,
        monthStride: Int
    ) -> Date? {
        let cal = Calendar.current
        if cal.isDate(anchor, equalTo: reference, toGranularity: period) {
            return clampToMonth(anchor, dayOfMonth: cal.component(.day, from: anchor))
        }
        let day = cal.component(.day, from: anchor)
        var current = anchor
        let step = anchor < reference ? monthStride : -monthStride
        for _ in 0..<2400 { // safety: ~200 years of monthly steps
            guard let next = cal.date(byAdding: .month, value: step, to: current) else { return current }
            current = next
            if cal.isDate(current, equalTo: reference, toGranularity: period) {
                return clampToMonth(current, dayOfMonth: day)
            }
        }
        return current
    }

    private static func clampToMonth(_ date: Date, dayOfMonth: Int) -> Date {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month], from: date)
        let lastDay = cal.range(of: .day, in: .month, for: date)?.last ?? 28
        comps.day = min(dayOfMonth, lastDay)
        return cal.date(from: comps) ?? date
    }
}

// MARK: - Bill Status Calculation
extension Bill {

    /// Derived status for the current cycle. The stored `paidAt` carries the
    /// most recent mark-paid timestamp; once the calendar moves past that
    /// cycle, the bill auto-flips back to `.scheduled` (or `.overdue`) without
    /// any background work — the cycle filter narrows what counts.
    func calculateStatus(now: Date = Date()) -> BillStatus {
        if let paidAt, isInCurrentCycle(expenseDate: paidAt) {
            return .paid
        }
        return effectiveDueDate < now ? .overdue : .scheduled
    }

    /// Legacy compatibility shim: the old expense-driven calculator. Kept for
    /// callsites still wired into the legacy Expense ledger (UpcomingBillsSection).
    /// New code should prefer the no-arg `calculateStatus(now:)` above.
    func calculateStatus(from expenses: [Expense]) -> BillStatus {
        if let paidAt, isInCurrentCycle(expenseDate: paidAt) {
            return .paid
        }
        if isFullyPaid(from: expenses) { return .paid }
        return effectiveDueDate < Date() ? .overdue : .scheduled
    }

    /// Total amount paid for this bill in the current billing cycle.
    func getAmountPaidThisPeriod(from expenses: [Expense]) -> Double {
        let dateFormatter = ISO8601DateFormatter()
        return expenses
            .filter { expense in
                guard expense.billId == self.id,
                      let expenseDate = dateFormatter.date(from: expense.expenseDate) else { return false }
                return self.isInCurrentCycle(expenseDate: expenseDate)
            }
            .reduce(0) { $0 + $1.amount }
    }

    /// Has the bill's current cycle been fully paid?
    func isFullyPaid(from expenses: [Expense]) -> Bool {
        getAmountPaidThisPeriod(from: expenses) >= amount
    }
}