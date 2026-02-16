//
//  EncryptableProfile.swift
//  Norma
//
//  Created by Claude on 7/28/25.
//  Updated: 2/7/26 - Full encryption support for sensitive profile fields
//

import Foundation
import CryptoKit

/// Represents profile data as stored in the database (encrypted)
/// - `name`, `monthly_income`, `freedom_fund`, `pain_point` contain encrypted ciphertext
/// - `settings` and `onboarding_insights` are encrypted JSON strings
/// - Use `toProfile(using:)` to decrypt for display
struct EncryptableProfile: Identifiable, Codable, Equatable {
    var id: String?
    let userId: String
    let email: String  // Not encrypted (needed for queries)

    // Encrypted fields (ciphertext strings)
    var name: String                    // encrypted
    var monthlyIncome: String?          // encrypted (was numeric)
    var freedomFund: String?            // encrypted (was numeric)
    var painPoint: String?              // encrypted
    var settings: String?               // encrypted JSON string
    var onboardingInsights: String?     // encrypted JSON string

    // Unencrypted fields
    var createdAt: String?
    var updatedAt: String?
    var profileImageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case email
        case name
        case monthlyIncome = "monthly_income"
        case freedomFund = "freedom_fund"
        case painPoint = "pain_point"
        case settings
        case onboardingInsights = "onboarding_insights"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case profileImageUrl = "profile_image_url"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        email = try container.decode(String.self, forKey: .email)
        name = try container.decode(String.self, forKey: .name)
        monthlyIncome = try container.decodeIfPresent(String.self, forKey: .monthlyIncome)
        freedomFund = try container.decodeIfPresent(String.self, forKey: .freedomFund)
        painPoint = try container.decodeIfPresent(String.self, forKey: .painPoint)
        settings = try container.decodeIfPresent(String.self, forKey: .settings)
        onboardingInsights = try container.decodeIfPresent(String.self, forKey: .onboardingInsights)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
    }

    init(
        id: String? = nil,
        userId: String,
        email: String,
        name: String,
        monthlyIncome: String? = nil,
        freedomFund: String? = nil,
        painPoint: String? = nil,
        settings: String? = nil,
        onboardingInsights: String? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil,
        profileImageUrl: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.email = email
        self.name = name
        self.monthlyIncome = monthlyIncome
        self.freedomFund = freedomFund
        self.painPoint = painPoint
        self.settings = settings
        self.onboardingInsights = onboardingInsights
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.profileImageUrl = profileImageUrl
    }

    /// Decrypt and convert to Profile for display
    /// - Parameter masterKey: The user's master encryption key
    /// - Returns: Decrypted Profile, or nil if decryption fails
    func toProfile(using masterKey: SymmetricKey) -> Profile? {
        print("🔓 [DECRYPT-DEBUG] EncryptableProfile.toProfile(key): START — name.count=\(name.count), monthlyIncome.count=\(monthlyIncome?.count ?? 0), freedomFund.count=\(freedomFund?.count ?? 0), settings.count=\(settings?.count ?? 0)")

        // Decrypt name (required field)
        guard let decryptedName = EncryptionService.shared.decrypt(name, with: masterKey) else {
            // If name doesn't look encrypted (short, not base64), use as-is (legacy data)
            let likelyEncrypted = isLikelyEncrypted(name)
            let nameToUse = likelyEncrypted ? "" : name
            print("🔓 [DECRYPT-DEBUG] EncryptableProfile.toProfile(key): ❌ NAME decrypt failed — isLikelyEncrypted=\(likelyEncrypted), using name='\(nameToUse)' — returning plaintext fallback")
            return createProfileWithPlaintext(name: nameToUse)
        }
        print("🔓 [DECRYPT-DEBUG] EncryptableProfile.toProfile(key): ✅ NAME decrypted = '\(decryptedName)'")

        // Decrypt optional numeric fields
        let decryptedMonthlyIncome: Double? = monthlyIncome.flatMap { encrypted in
            EncryptionService.shared.decryptAmount(encrypted, with: masterKey)
        }
        print("🔓 [DECRYPT-DEBUG] EncryptableProfile.toProfile(key): monthlyIncome = \(decryptedMonthlyIncome.map { String($0) } ?? "nil (decrypt failed or empty)")")

        let decryptedFreedomFund: Double? = freedomFund.flatMap { encrypted in
            EncryptionService.shared.decryptAmount(encrypted, with: masterKey)
        }
        print("🔓 [DECRYPT-DEBUG] EncryptableProfile.toProfile(key): freedomFund = \(decryptedFreedomFund.map { String($0) } ?? "nil (decrypt failed or empty)")")

        // Decrypt optional string fields
        let decryptedPainPoint = painPoint.flatMap { encrypted in
            EncryptionService.shared.decrypt(encrypted, with: masterKey)
        }

        // Decrypt and parse settings JSON
        let decryptedSettings: ProfileSettings = {
            guard let encryptedSettings = settings,
                  let decryptedJson = EncryptionService.shared.decrypt(encryptedSettings, with: masterKey),
                  let jsonData = decryptedJson.data(using: .utf8),
                  let parsed = try? JSONDecoder().decode(ProfileSettings.self, from: jsonData) else {
                print("🔓 [DECRYPT-DEBUG] EncryptableProfile.toProfile(key): ⚠️ SETTINGS decrypt/parse failed — using defaults")
                return ProfileSettings()
            }
            print("🔓 [DECRYPT-DEBUG] EncryptableProfile.toProfile(key): ✅ SETTINGS decrypted — income=\(parsed.monthlyIncome), freedomFund=\(parsed.freedomFund)")
            return parsed
        }()

        // Decrypt and parse onboarding insights JSON
        let decryptedOnboardingInsights: OnboardingInsights? = {
            guard let encryptedInsights = onboardingInsights,
                  let decryptedJson = EncryptionService.shared.decrypt(encryptedInsights, with: masterKey),
                  let jsonData = decryptedJson.data(using: .utf8),
                  let parsed = try? JSONDecoder().decode(OnboardingInsights.self, from: jsonData) else {
                return nil
            }
            return parsed
        }()

        return Profile(
            id: id,
            userId: userId,
            email: email,
            name: decryptedName,
            createdAt: createdAt,
            updatedAt: updatedAt,
            profileImageUrl: profileImageUrl,
            monthlyIncome: decryptedMonthlyIncome,
            freedomFund: decryptedFreedomFund,
            painPoint: decryptedPainPoint,
            settings: decryptedSettings,
            onboardingInsights: decryptedOnboardingInsights
        )
    }

    /// Convert to Profile without decryption (for legacy unencrypted data)
    /// Note: This attempts to parse settings/insights as JSON if not encrypted
    func toProfile() -> Profile {
        print("🔓 [DECRYPT-DEBUG] EncryptableProfile.toProfile() NO-KEY FALLBACK — name='\(name)', monthlyIncome='\(monthlyIncome ?? "nil")', freedomFund='\(freedomFund ?? "nil")'")

        // Try to parse settings as JSON (legacy unencrypted format)
        let parsedSettings: ProfileSettings = {
            guard let settingsStr = settings,
                  let jsonData = settingsStr.data(using: .utf8),
                  let parsed = try? JSONDecoder().decode(ProfileSettings.self, from: jsonData) else {
                print("🔓 [DECRYPT-DEBUG] EncryptableProfile.toProfile(): ⚠️ Settings JSON parse failed — using defaults (income=0)")
                return ProfileSettings()
            }
            print("🔓 [DECRYPT-DEBUG] EncryptableProfile.toProfile(): Settings parsed as JSON — income=\(parsed.monthlyIncome), freedomFund=\(parsed.freedomFund)")
            return parsed
        }()

        // Try to parse onboarding insights as JSON
        let parsedInsights: OnboardingInsights? = {
            guard let insightsStr = onboardingInsights,
                  let jsonData = insightsStr.data(using: .utf8),
                  let parsed = try? JSONDecoder().decode(OnboardingInsights.self, from: jsonData) else {
                return nil
            }
            return parsed
        }()

        // Try to parse numeric fields
        let parsedMonthlyIncome = monthlyIncome.flatMap { Double($0) }
        let parsedFreedomFund = freedomFund.flatMap { Double($0) }
        print("🔓 [DECRYPT-DEBUG] EncryptableProfile.toProfile(): Parsed monthlyIncome=\(parsedMonthlyIncome.map { String($0) } ?? "nil (not a number)"), freedomFund=\(parsedFreedomFund.map { String($0) } ?? "nil (not a number)")")

        return Profile(
            id: id,
            userId: userId,
            email: email,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt,
            profileImageUrl: profileImageUrl,
            monthlyIncome: parsedMonthlyIncome,
            freedomFund: parsedFreedomFund,
            painPoint: painPoint,
            settings: parsedSettings,
            onboardingInsights: parsedInsights
        )
    }

    // MARK: - Private Helpers

    private func isLikelyEncrypted(_ value: String) -> Bool {
        // Encrypted values are base64 strings > 50 chars
        return value.count > 50 && value.range(of: "^[A-Za-z0-9+/=]+$", options: .regularExpression) != nil
    }

    private func createProfileWithPlaintext(name: String) -> Profile {
        return Profile(
            id: id,
            userId: userId,
            email: email,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt,
            profileImageUrl: profileImageUrl,
            monthlyIncome: monthlyIncome.flatMap { Double($0) },
            freedomFund: freedomFund.flatMap { Double($0) },
            painPoint: painPoint,
            settings: ProfileSettings(),
            onboardingInsights: nil
        )
    }
}
