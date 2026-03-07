//
//  Profile.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation

struct Profile: Identifiable, Codable, Equatable {
    var id: String?
    let userId: String
    let email: String
    let name: String
    var createdAt: String?
    var updatedAt: String?
    var profileImageUrl: String?

    // Direct columns for onboarding data (also in settings JSONB for backwards compatibility)
    var monthlyIncome: Double?
    var freedomFund: Double?
    var painPoint: String?

    var settings: ProfileSettings
    var onboardingInsights: OnboardingInsights?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case email
        case name
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case profileImageUrl = "profile_image_url"
        case monthlyIncome = "monthly_income"
        case freedomFund = "freedom_fund"
        case painPoint = "pain_point"
        case settings
        case onboardingInsights = "onboarding_insights"
    }

    init(
        id: String? = nil,
        userId: String,
        email: String,
        name: String,
        createdAt: String? = nil,
        updatedAt: String? = nil,
        profileImageUrl: String? = nil,
        monthlyIncome: Double? = nil,
        freedomFund: Double? = nil,
        painPoint: String? = nil,
        settings: ProfileSettings = ProfileSettings(),
        onboardingInsights: OnboardingInsights? = nil
    ) {
        self.id = id
        self.userId = userId
        self.email = email
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.profileImageUrl = profileImageUrl
        self.monthlyIncome = monthlyIncome
        self.freedomFund = freedomFund
        self.painPoint = painPoint
        self.settings = settings
        self.onboardingInsights = onboardingInsights
    }
}

struct OnboardingInsights: Codable, Equatable {
    var nomadType: String?            // slowmad, explorer, base_trips, nomad_family
    var runwayStatus: String?
    var nomadChallenges: String?      // comma-separated for multi-select
    var moneyStoppedYou: String?
    var winningLooksLike: String?     // comma-separated for multi-select

    enum CodingKeys: String, CodingKey {
        case nomadType = "nomad_type"
        case runwayStatus = "runway_status"
        case nomadChallenges = "nomad_challenges"
        case moneyStoppedYou = "money_stopped_you"
        case winningLooksLike = "winning_looks_like"
    }

    init(
        nomadType: String? = nil,
        runwayStatus: String? = nil,
        nomadChallenges: String? = nil,
        moneyStoppedYou: String? = nil,
        winningLooksLike: String? = nil
    ) {
        self.nomadType = nomadType
        self.runwayStatus = runwayStatus
        self.nomadChallenges = nomadChallenges
        self.moneyStoppedYou = moneyStoppedYou
        self.winningLooksLike = winningLooksLike
    }
}

struct ProfileSettings: Codable, Equatable {
    var currency: String
    var spendingCurrency: String?
    var monthlyIncome: Double  // After-tax monthly income
    var freedomFund: Double
    var painPoint: String
    var notificationsEnabled: Bool
    var billReminderDays: Int
    var monthlyBudgetAlert: Bool
    var darkModeEnabled: Bool
    var hasReceivedWelcome: Bool

    enum CodingKeys: String, CodingKey {
        case currency
        case spendingCurrency = "spending_currency"
        case monthlyIncome = "monthly_income"
        case freedomFund = "freedom_fund"
        case painPoint = "pain_point"
        case notificationsEnabled = "notifications_enabled"
        case billReminderDays = "bill_reminder_days"
        case monthlyBudgetAlert = "monthly_budget_alert"
        case darkModeEnabled = "dark_mode_enabled"
        case hasReceivedWelcome = "has_received_welcome"
    }

    init(
        currency: String = "USD",
        spendingCurrency: String? = nil,
        monthlyIncome: Double = 0,
        freedomFund: Double = 0,
        painPoint: String = "",
        notificationsEnabled: Bool = true,
        billReminderDays: Int = 3,
        monthlyBudgetAlert: Bool = true,
        darkModeEnabled: Bool = false,
        hasReceivedWelcome: Bool = false
    ) {
        self.currency = currency
        self.spendingCurrency = spendingCurrency
        self.monthlyIncome = monthlyIncome
        self.freedomFund = freedomFund
        self.painPoint = painPoint
        self.notificationsEnabled = notificationsEnabled
        self.billReminderDays = billReminderDays
        self.monthlyBudgetAlert = monthlyBudgetAlert
        self.darkModeEnabled = darkModeEnabled
        self.hasReceivedWelcome = hasReceivedWelcome
    }

    // Custom decoder to handle missing fields with default values
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        currency = try container.decodeIfPresent(String.self, forKey: .currency) ?? "USD"
        spendingCurrency = try container.decodeIfPresent(String.self, forKey: .spendingCurrency)
        monthlyIncome = try container.decodeIfPresent(Double.self, forKey: .monthlyIncome) ?? 0
        freedomFund = try container.decodeIfPresent(Double.self, forKey: .freedomFund) ?? 0
        painPoint = try container.decodeIfPresent(String.self, forKey: .painPoint) ?? ""
        notificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? true
        billReminderDays = try container.decodeIfPresent(Int.self, forKey: .billReminderDays) ?? 3
        monthlyBudgetAlert = try container.decodeIfPresent(Bool.self, forKey: .monthlyBudgetAlert) ?? true
        darkModeEnabled = try container.decodeIfPresent(Bool.self, forKey: .darkModeEnabled) ?? false
        hasReceivedWelcome = try container.decodeIfPresent(Bool.self, forKey: .hasReceivedWelcome) ?? false
    }
}