//
//  EncryptableBill.swift
//  Norma
//
//  Created by Claude on 7/28/25.
//

import Foundation
import CryptoKit

// This model represents the raw data from the database that may or may not be encrypted
struct EncryptableBill: Identifiable, Codable {
    var id: String?
    let userId: String
    
    // Original fields (for backward compatibility)
    var name: String
    var amount: Double
    
    // Encrypted fields (new)
    let encryptedName: String?
    let encryptedAmount: String?
    let isEncrypted: Bool
    
    // Other fields (remain unencrypted)
    var dueDate: Date
    var status: BillStatus
    var frequency: BillFrequency
    var categoryId: String?
    var merchant: String?
    var isAutoPayEnabled: Bool
    var reminderDays: Int?
    var isActive: Bool?
    var createdAt: String?
    var updatedAt: String?
    var notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case amount
        case encryptedName = "encrypted_name"
        case encryptedAmount = "encrypted_amount"
        case isEncrypted = "is_encrypted"
        case dueDate = "due_date"
        case status
        case frequency
        case categoryId = "category_id"
        case merchant
        case isAutoPayEnabled = "is_auto_pay_enabled"
        case reminderDays = "reminder_days"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case notes
    }
    
    // Custom decoding to handle date formats from Supabase
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        name = try container.decode(String.self, forKey: .name)
        amount = try container.decode(Double.self, forKey: .amount)
        encryptedName = try container.decodeIfPresent(String.self, forKey: .encryptedName)
        encryptedAmount = try container.decodeIfPresent(String.self, forKey: .encryptedAmount)
        isEncrypted = try container.decodeIfPresent(Bool.self, forKey: .isEncrypted) ?? false
        status = try container.decode(BillStatus.self, forKey: .status)
        frequency = try container.decode(BillFrequency.self, forKey: .frequency)
        categoryId = try container.decodeIfPresent(String.self, forKey: .categoryId)
        merchant = try container.decodeIfPresent(String.self, forKey: .merchant)
        isAutoPayEnabled = try container.decode(Bool.self, forKey: .isAutoPayEnabled)
        reminderDays = try container.decodeIfPresent(Int.self, forKey: .reminderDays)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        
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
    }
    
    // Custom encoding to ensure dates are sent in YYYY-MM-DD format
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(name, forKey: .name)
        try container.encode(amount, forKey: .amount)
        try container.encodeIfPresent(encryptedName, forKey: .encryptedName)
        try container.encodeIfPresent(encryptedAmount, forKey: .encryptedAmount)
        try container.encode(isEncrypted, forKey: .isEncrypted)
        try container.encode(status, forKey: .status)
        try container.encode(frequency, forKey: .frequency)
        try container.encodeIfPresent(categoryId, forKey: .categoryId)
        try container.encodeIfPresent(merchant, forKey: .merchant)
        try container.encode(isAutoPayEnabled, forKey: .isAutoPayEnabled)
        try container.encodeIfPresent(reminderDays, forKey: .reminderDays)
        try container.encodeIfPresent(isActive, forKey: .isActive)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(notes, forKey: .notes)
        
        // Encode date as YYYY-MM-DD string
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        let dueDateString = dateFormatter.string(from: dueDate)
        try container.encode(dueDateString, forKey: .dueDate)
    }
    
    // Convert to regular Bill for display (decrypting if necessary)
    func toBill(using masterKey: SymmetricKey?) -> Bill? {
        let displayName: String
        let displayAmount: Double
        
        if isEncrypted {
            // Decrypt the data
            guard let key = masterKey,
                  let encryptedName = encryptedName,
                  let encryptedAmount = encryptedAmount,
                  let decryptedName = EncryptionService.shared.decrypt(encryptedName, with: key),
                  let decryptedAmount = EncryptionService.shared.decryptAmount(encryptedAmount, with: key) else {
                return nil
            }
            displayName = decryptedName
            displayAmount = decryptedAmount
        } else {
            // Use plain data
            displayName = name
            displayAmount = amount
        }
        
        return Bill(
            id: id,
            userId: userId,
            name: displayName,
            dueDate: dueDate,
            amount: displayAmount,
            status: status,
            frequency: frequency,
            categoryId: categoryId,
            merchant: merchant,
            isAutoPayEnabled: isAutoPayEnabled,
            reminderDays: reminderDays,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            notes: notes
        )
    }
}

// Extension to create EncryptableBill from regular Bill
extension Bill {
    func toEncryptable(encrypt: Bool = false, using masterKey: SymmetricKey? = nil) -> EncryptableBill? {
        if encrypt {
            guard let key = masterKey,
                  let encryptedName = EncryptionService.shared.encrypt(name, with: key),
                  let encryptedAmount = EncryptionService.shared.encryptAmount(amount, with: key) else {
                return nil
            }
            
            return EncryptableBill(
                id: id,
                userId: userId,
                name: name, // Keep original for migration purposes
                amount: amount, // Keep original for migration purposes
                encryptedName: encryptedName,
                encryptedAmount: encryptedAmount,
                isEncrypted: true,
                dueDate: dueDate,
                status: status,
                frequency: frequency,
                categoryId: categoryId,
                merchant: merchant,
                isAutoPayEnabled: isAutoPayEnabled,
                reminderDays: reminderDays,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                notes: notes
            )
        } else {
            // Create unencrypted version
            return EncryptableBill(
                id: id,
                userId: userId,
                name: name,
                amount: amount,
                encryptedName: nil,
                encryptedAmount: nil,
                isEncrypted: false,
                dueDate: dueDate,
                status: status,
                frequency: frequency,
                categoryId: categoryId,
                merchant: merchant,
                isAutoPayEnabled: isAutoPayEnabled,
                reminderDays: reminderDays,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                notes: notes
            )
        }
    }
}

extension EncryptableBill {
    // Initializer for creating instances
    init(
        id: String? = nil,
        userId: String,
        name: String,
        amount: Double,
        encryptedName: String? = nil,
        encryptedAmount: String? = nil,
        isEncrypted: Bool = false,
        dueDate: Date,
        status: BillStatus,
        frequency: BillFrequency,
        categoryId: String? = nil,
        merchant: String? = nil,
        isAutoPayEnabled: Bool = false,
        reminderDays: Int? = nil,
        isActive: Bool? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.amount = amount
        self.encryptedName = encryptedName
        self.encryptedAmount = encryptedAmount
        self.isEncrypted = isEncrypted
        self.dueDate = dueDate
        self.status = status
        self.frequency = frequency
        self.categoryId = categoryId
        self.merchant = merchant
        self.isAutoPayEnabled = isAutoPayEnabled
        self.reminderDays = reminderDays
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.notes = notes
    }
}