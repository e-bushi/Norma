//
//  EncryptableBill.swift
//  Norma
//
//  Created by Claude on 7/28/25.
//  Updated: 2/6/26 - Simplified for Edge Function encryption architecture
//

import Foundation
import CryptoKit

/// Represents bill data as stored in the database (encrypted)
/// - `name` and `amount` contain encrypted ciphertext
/// - Use `toBill(using:)` to decrypt for display
struct EncryptableBill: Identifiable, Codable {
    var id: String?
    let userId: String

    // Encrypted fields (ciphertext strings)
    var name: String           // encrypted
    var amount: String         // encrypted (was numeric, now text for encryption)
    var merchant: String?      // encrypted
    var notes: String?         // encrypted

    // Unencrypted fields (for server-side queries)
    var dueDate: Date
    var nextDueDate: Date?
    var status: BillStatus
    var frequency: BillFrequency
    var categoryId: String?
    var isReminderOn: Bool
    var reminderDays: Int?
    var isActive: Bool?
    var createdAt: String?
    var updatedAt: String?
    var verificationDate: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case amount
        case dueDate = "due_date"
        case nextDueDate = "next_due_date"
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
    }

    // Custom decoding to handle date formats from Supabase
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        name = try container.decode(String.self, forKey: .name)
        amount = try container.decode(String.self, forKey: .amount)
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

    /// Decrypt and convert to Bill for display
    /// - Parameter masterKey: The user's master encryption key
    /// - Returns: Decrypted Bill, or nil if decryption fails
    func toBill(using masterKey: SymmetricKey) -> Bill? {
        // Decrypt sensitive fields
        guard let decryptedName = EncryptionService.shared.decrypt(name, with: masterKey),
              let decryptedAmount = EncryptionService.shared.decryptAmount(amount, with: masterKey) else {
            return nil
        }

        // Decrypt optional fields
        let decryptedMerchant = merchant.flatMap { EncryptionService.shared.decrypt($0, with: masterKey) }
        let decryptedNotes = notes.flatMap { EncryptionService.shared.decrypt($0, with: masterKey) }

        return Bill(
            id: id,
            userId: userId,
            name: decryptedName,
            dueDate: dueDate,
            nextDueDate: nextDueDate,
            amount: decryptedAmount,
            status: status,
            frequency: frequency,
            categoryId: categoryId,
            merchant: decryptedMerchant,
            isReminderOn: isReminderOn,
            reminderDays: reminderDays,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            notes: decryptedNotes,
            verificationDate: verificationDate
        )
    }
}

extension EncryptableBill {
    // Initializer for creating instances directly
    init(
        id: String? = nil,
        userId: String,
        name: String,
        amount: String,
        dueDate: Date,
        nextDueDate: Date? = nil,
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
        verificationDate: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.amount = amount
        self.dueDate = dueDate
        self.nextDueDate = nextDueDate
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
    }
}
