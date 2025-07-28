//
//  EncryptableProfile.swift
//  Norma
//
//  Created by Claude on 7/28/25.
//

import Foundation
import CryptoKit

// This model represents the raw profile data from the database that may or may not be encrypted
struct EncryptableProfile: Identifiable, Codable, Equatable {
    var id: String?
    let userId: String
    let email: String
    let name: String
    var createdAt: String?
    var updatedAt: String?
    var profileImageUrl: String?
    
    // Original settings (for backward compatibility)
    var settings: ProfileSettings
    
    // Encrypted settings (new)
    let encryptedSettings: String?
    let settingsEncrypted: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case email
        case name
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case profileImageUrl = "profile_image_url"
        case settings
        case encryptedSettings = "encrypted_settings"
        case settingsEncrypted = "settings_encrypted"
    }
    
    // Custom decoder to handle missing encryption fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        email = try container.decode(String.self, forKey: .email)
        name = try container.decode(String.self, forKey: .name)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
        settings = try container.decode(ProfileSettings.self, forKey: .settings)
        
        // Handle optional encryption fields
        encryptedSettings = try container.decodeIfPresent(String.self, forKey: .encryptedSettings)
        settingsEncrypted = try container.decodeIfPresent(Bool.self, forKey: .settingsEncrypted) ?? false
    }
    
    init(
        id: String? = nil,
        userId: String,
        email: String,
        name: String,
        createdAt: String? = nil,
        updatedAt: String? = nil,
        profileImageUrl: String? = nil,
        settings: ProfileSettings = ProfileSettings(),
        encryptedSettings: String? = nil,
        settingsEncrypted: Bool? = false
    ) {
        self.id = id
        self.userId = userId
        self.email = email
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.profileImageUrl = profileImageUrl
        self.settings = settings
        self.encryptedSettings = encryptedSettings
        self.settingsEncrypted = settingsEncrypted
    }
    
    // Convert to regular Profile for display (decrypting if necessary)
    func toProfile(using masterKey: SymmetricKey?) -> Profile? {
        let displaySettings: ProfileSettings
        
        if settingsEncrypted == true {
            // Decrypt the settings
            guard let key = masterKey,
                  let encryptedSettings = encryptedSettings,
                  let decryptedSettings = decryptSettings(encryptedSettings, with: key) else {
                return nil
            }
            displaySettings = decryptedSettings
        } else {
            // Use plain settings
            displaySettings = settings
        }
        
        return Profile(
            id: id,
            userId: userId,
            email: email,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt,
            profileImageUrl: profileImageUrl,
            settings: displaySettings
        )
    }
    
    // Decrypt settings from encrypted JSON string
    private func decryptSettings(_ encryptedString: String, with key: SymmetricKey) -> ProfileSettings? {
        guard let decryptedJSON = EncryptionService.shared.decrypt(encryptedString, with: key),
              let jsonData = decryptedJSON.data(using: .utf8) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(ProfileSettings.self, from: jsonData)
        } catch {
            print("Failed to decode decrypted settings: \(error)")
            return nil
        }
    }
}

// Extension to create EncryptableProfile from regular Profile
extension Profile {
    func toEncryptable(encrypt: Bool = false, using masterKey: SymmetricKey? = nil) -> EncryptableProfile? {
        if encrypt {
            guard let key = masterKey,
                  let encryptedSettings = encryptSettings(settings, with: key) else {
                return nil
            }
            
            return EncryptableProfile(
                id: id,
                userId: userId,
                email: email,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                profileImageUrl: profileImageUrl,
                settings: settings, // Keep original for migration purposes
                encryptedSettings: encryptedSettings,
                settingsEncrypted: true
            )
        } else {
            // Create unencrypted version
            return EncryptableProfile(
                id: id,
                userId: userId,
                email: email,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                profileImageUrl: profileImageUrl,
                settings: settings,
                encryptedSettings: nil,
                settingsEncrypted: false
            )
        }
    }
    
    // Encrypt settings to JSON string
    private func encryptSettings(_ settings: ProfileSettings, with key: SymmetricKey) -> String? {
        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(settings)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                return nil
            }
            return EncryptionService.shared.encrypt(jsonString, with: key)
        } catch {
            print("Failed to encode settings for encryption: \(error)")
            return nil
        }
    }
}

// Encrypted version of ProfileSettings for selective field encryption
struct EncryptedProfileSettings: Codable, Equatable {
    // Non-sensitive fields (plain)
    var currency: String
    var primaryGoal: String
    var notificationsEnabled: Bool
    var billReminderDays: Int
    var monthlyBudgetAlert: Bool
    var darkModeEnabled: Bool
    
    // Sensitive fields (encrypted)
    var encryptedMonthlyIncome: String
    
    enum CodingKeys: String, CodingKey {
        case currency
        case primaryGoal = "primary_goal"
        case notificationsEnabled = "notifications_enabled"
        case billReminderDays = "bill_reminder_days"
        case monthlyBudgetAlert = "monthly_budget_alert"
        case darkModeEnabled = "dark_mode_enabled"
        case encryptedMonthlyIncome = "encrypted_monthly_income"
    }
    
    // Convert from regular ProfileSettings
    init(from settings: ProfileSettings, using key: SymmetricKey) throws {
        self.currency = settings.currency
        self.primaryGoal = settings.primaryGoal
        self.notificationsEnabled = settings.notificationsEnabled
        self.billReminderDays = settings.billReminderDays
        self.monthlyBudgetAlert = settings.monthlyBudgetAlert
        self.darkModeEnabled = settings.darkModeEnabled
        
        // Encrypt the monthly income
        guard let encrypted = EncryptionService.shared.encryptAmount(settings.monthlyIncome, with: key) else {
            throw EncryptionError.encryptionFailed
        }
        self.encryptedMonthlyIncome = encrypted
    }
    
    // Convert to regular ProfileSettings
    func toProfileSettings(using key: SymmetricKey) -> ProfileSettings? {
        guard let monthlyIncome = EncryptionService.shared.decryptAmount(encryptedMonthlyIncome, with: key) else {
            return nil
        }
        
        return ProfileSettings(
            currency: currency,
            monthlyIncome: monthlyIncome,
            primaryGoal: primaryGoal,
            notificationsEnabled: notificationsEnabled,
            billReminderDays: billReminderDays,
            monthlyBudgetAlert: monthlyBudgetAlert,
            darkModeEnabled: darkModeEnabled
        )
    }
}