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
    var howDidYouHear: String?
    var settings: ProfileSettings
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case email
        case name
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case profileImageUrl = "profile_image_url"
        case howDidYouHear = "how_did_you_hear"
        case settings
    }
    
    init(
        id: String? = nil,
        userId: String,
        email: String,
        name: String,
        createdAt: String? = nil,
        updatedAt: String? = nil,
        profileImageUrl: String? = nil,
        howDidYouHear: String? = nil,
        settings: ProfileSettings = ProfileSettings()
    ) {
        self.id = id
        self.userId = userId
        self.email = email
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.profileImageUrl = profileImageUrl
        self.howDidYouHear = howDidYouHear
        self.settings = settings
    }
}

struct ProfileSettings: Codable, Equatable {
    var currency: String
    var monthlyIncome: Double
    var primaryGoal: String
    var notificationsEnabled: Bool
    var billReminderDays: Int
    var monthlyBudgetAlert: Bool
    var darkModeEnabled: Bool
    
    enum CodingKeys: String, CodingKey {
        case currency
        case monthlyIncome = "monthly_income"
        case primaryGoal = "primary_goal"
        case notificationsEnabled = "notifications_enabled"
        case billReminderDays = "bill_reminder_days"
        case monthlyBudgetAlert = "monthly_budget_alert"
        case darkModeEnabled = "dark_mode_enabled"
    }
    
    init(
        currency: String = "USD",
        monthlyIncome: Double = 0,
        primaryGoal: String = "All of the above",
        notificationsEnabled: Bool = true,
        billReminderDays: Int = 3,
        monthlyBudgetAlert: Bool = true,
        darkModeEnabled: Bool = false
    ) {
        self.currency = currency
        self.monthlyIncome = monthlyIncome
        self.primaryGoal = primaryGoal
        self.notificationsEnabled = notificationsEnabled
        self.billReminderDays = billReminderDays
        self.monthlyBudgetAlert = monthlyBudgetAlert
        self.darkModeEnabled = darkModeEnabled
    }
}