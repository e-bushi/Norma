//
//  EncryptableBudget.swift
//  Norma
//
//  Created by Claude on 7/28/25.
//

import Foundation
import CryptoKit

// This model represents the raw data from the database that may or may not be encrypted
struct EncryptableBudget: Identifiable, Codable {
    var id: String?
    let userId: String
    
    // Original fields (for backward compatibility)
    let name: String
    let amount: Double
    
    // Encrypted fields (new)
    let encryptedName: String?
    let isEncrypted: Bool
    
    // Other fields (remain unencrypted for analytics)
    let categoryId: String?
    let startDate: Date
    var endDate: Date?
    var isActive: Bool
    var currentSpent: Double
    let alertThreshold: Double
    var createdAt: String?
    var updatedAt: String?
    var notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case amount
        case encryptedName = "encrypted_name"
        case isEncrypted = "is_encrypted"
        case categoryId = "category_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case isActive = "is_active"
        case currentSpent = "current_spent"
        case alertThreshold = "alert_threshold"
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
        isEncrypted = try container.decodeIfPresent(Bool.self, forKey: .isEncrypted) ?? false
        categoryId = try container.decodeIfPresent(String.self, forKey: .categoryId)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        currentSpent = try container.decode(Double.self, forKey: .currentSpent)
        alertThreshold = try container.decode(Double.self, forKey: .alertThreshold)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        
        // Handle date decoding with multiple formats
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Decode startDate
        let startDateString = try container.decode(String.self, forKey: .startDate)
        if let date = dateFormatter.date(from: startDateString) {
            self.startDate = date
        } else {
            // Try ISO8601 format as fallback
            let isoFormatter = ISO8601DateFormatter()
            if let date = isoFormatter.date(from: startDateString) {
                // Convert to local date at midnight
                let calendar = Calendar.current
                let components = calendar.dateComponents([.year, .month, .day], from: date)
                self.startDate = calendar.date(from: components) ?? date
            } else {
                throw DecodingError.dataCorruptedError(forKey: .startDate,
                                                      in: container,
                                                      debugDescription: "Invalid date format: \(startDateString)")
            }
        }
        
        // Decode endDate if present
        if let endDateString = try container.decodeIfPresent(String.self, forKey: .endDate) {
            if let date = dateFormatter.date(from: endDateString) {
                self.endDate = date
            } else {
                // Try ISO8601 format as fallback
                let isoFormatter = ISO8601DateFormatter()
                if let date = isoFormatter.date(from: endDateString) {
                    // Convert to local date at midnight
                    let calendar = Calendar.current
                    let components = calendar.dateComponents([.year, .month, .day], from: date)
                    self.endDate = calendar.date(from: components) ?? date
                } else {
                    throw DecodingError.dataCorruptedError(forKey: .endDate,
                                                          in: container,
                                                          debugDescription: "Invalid date format: \(endDateString)")
                }
            }
        } else {
            self.endDate = nil
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
        try container.encode(isEncrypted, forKey: .isEncrypted)
        try container.encodeIfPresent(categoryId, forKey: .categoryId)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(currentSpent, forKey: .currentSpent)
        try container.encode(alertThreshold, forKey: .alertThreshold)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(notes, forKey: .notes)
        
        // Encode dates as YYYY-MM-DD strings
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let startDateString = dateFormatter.string(from: startDate)
        try container.encode(startDateString, forKey: .startDate)
        
        if let endDate = endDate {
            let endDateString = dateFormatter.string(from: endDate)
            try container.encode(endDateString, forKey: .endDate)
        }
    }
    
    // Convert to regular Budget for display (decrypting if necessary)
    func toBudget(using masterKey: SymmetricKey?) -> Budget? {
        let displayName: String
        
        if isEncrypted {
            // Decrypt the name
            guard let key = masterKey,
                  let encryptedName = encryptedName,
                  let decryptedName = EncryptionService.shared.decrypt(encryptedName, with: key) else {
                return nil
            }
            displayName = decryptedName
        } else {
            // Use plain data
            displayName = name
        }
        
        return Budget(
            id: id,
            userId: userId,
            name: displayName,
            amount: amount,
            categoryId: categoryId,
            startDate: startDate,
            endDate: endDate,
            isActive: isActive,
            currentSpent: currentSpent,
            alertThreshold: alertThreshold,
            createdAt: createdAt,
            updatedAt: updatedAt,
            notes: notes
        )
    }
}

// Extension to create EncryptableBudget from regular Budget
extension Budget {
    func toEncryptable(encrypt: Bool = false, using masterKey: SymmetricKey? = nil) -> EncryptableBudget? {
        if encrypt {
            guard let key = masterKey,
                  let encryptedName = EncryptionService.shared.encrypt(name, with: key) else {
                return nil
            }
            
            return EncryptableBudget(
                id: id,
                userId: userId,
                name: name, // Keep original for migration purposes
                amount: amount, // Keep amount unencrypted for analytics
                encryptedName: encryptedName,
                isEncrypted: true,
                categoryId: categoryId,
                startDate: startDate,
                endDate: endDate,
                isActive: isActive,
                currentSpent: currentSpent,
                alertThreshold: alertThreshold,
                createdAt: createdAt,
                updatedAt: updatedAt,
                notes: notes
            )
        } else {
            // Create unencrypted version
            return EncryptableBudget(
                id: id,
                userId: userId,
                name: name,
                amount: amount,
                encryptedName: nil,
                isEncrypted: false,
                categoryId: categoryId,
                startDate: startDate,
                endDate: endDate,
                isActive: isActive,
                currentSpent: currentSpent,
                alertThreshold: alertThreshold,
                createdAt: createdAt,
                updatedAt: updatedAt,
                notes: notes
            )
        }
    }
    
    // Initializer for creating EncryptableBudget
    init(
        id: String? = nil,
        userId: String,
        name: String,
        amount: Double,
        encryptedName: String? = nil,
        isEncrypted: Bool = false,
        categoryId: String? = nil,
        startDate: Date = Date(),
        endDate: Date? = nil,
        isActive: Bool = true,
        currentSpent: Double = 0,
        alertThreshold: Double = 0.8,
        createdAt: String? = nil,
        updatedAt: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.amount = amount
        self.categoryId = categoryId
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.currentSpent = currentSpent
        self.alertThreshold = alertThreshold
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.notes = notes
    }
}

extension EncryptableBudget {
    // Initializer for creating instances
    init(
        id: String? = nil,
        userId: String,
        name: String,
        amount: Double,
        encryptedName: String? = nil,
        isEncrypted: Bool = false,
        categoryId: String? = nil,
        startDate: Date = Date(),
        endDate: Date? = nil,
        isActive: Bool = true,
        currentSpent: Double = 0,
        alertThreshold: Double = 0.8,
        createdAt: String? = nil,
        updatedAt: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.amount = amount
        self.encryptedName = encryptedName
        self.isEncrypted = isEncrypted
        self.categoryId = categoryId
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.currentSpent = currentSpent
        self.alertThreshold = alertThreshold
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.notes = notes
    }
}