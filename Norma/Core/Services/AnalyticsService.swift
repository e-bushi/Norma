//
//  AnalyticsService.swift
//  Norma
//
//  Created by Claude on 1/25/26.
//

import Foundation
import PostHog

// MARK: - Auth Method

enum AuthMethod: String {
    case email = "email"
    case apple = "apple"
    case google = "google"
}

// MARK: - Creation Source

enum CreationSource: String {
    case chat = "chat"
    case manual = "manual"
    case voice = "voice"
    case imported = "import"
    case notification = "notification"
}

// MARK: - Analytics Screen

enum AnalyticsScreen: String {
    // Onboarding
    case landing = "Landing"
    case welcome = "Welcome"
    case signUp = "Sign Up"
    case login = "Login"
    case verification = "Verification"
    case notificationsPermission = "Notifications Permission"
    case howDidYouHear = "How Did You Hear"
    case normaChat = "Norma Chat"
    case onboardingComplete = "Onboarding Complete"
    case previewMode = "Preview Mode"

    // Main App
    case chat = "Chat"
    case overview = "Overview"
    case settings = "Settings"
    case currencyConverter = "Currency Converter"

    // Bills
    case myBills = "My Bills"
    case billDetail = "Bill Detail"
    case createBill = "Create Bill"
    case editBill = "Edit Bill"

    // Expenses
    case myExpenses = "My Expenses"
    case expenseDetail = "Expense Detail"
    case createExpense = "Create Expense"

    // Income
    case incomeDetail = "Income Detail"

    // Challenges
    case challenges = "Challenges"

    // Other
    case paywall = "Paywall"
    case welcomePaywall = "Welcome Paywall"
    case freeTrial = "Free Trial"
    case profile = "Profile"
    case upcomingNotifications = "Upcoming Notifications"
}

// MARK: - Analytics Event

enum AnalyticsEvent {
    // Auth Events
    case signUpStarted(method: AuthMethod)
    case signUpCompleted(method: AuthMethod)
    case signUpFailed(method: AuthMethod, error: String)
    case signInStarted(method: AuthMethod)
    case signInCompleted(method: AuthMethod)
    case signInFailed(method: AuthMethod, error: String)
    case signOut
    case accountDeleted

    // Onboarding Events
    case onboardingStepViewed(step: String, index: Int)
    case onboardingStepCompleted(step: String, index: Int)
    case onboardingCompleted(durationSeconds: Double)
    case previewModeStarted
    case previewModeDataTransferred(billCount: Int, expenseCount: Int)

    // Bill Events
    case billCreated(amount: Double, frequency: String, hasReminder: Bool, source: CreationSource)
    case billUpdated(billId: String, field: String)
    case billDeleted(billId: String)
    case billMarkedPaid(amount: Double, paymentMethod: String, daysBeforeDue: Int)
    case billMarkedUnpaid(billId: String)

    // Expense Events
    case expenseCreated(amount: Double, paymentMethod: String, hasCategory: Bool, source: CreationSource)
    case expenseUpdated(expenseId: String, field: String)
    case expenseDeleted(expenseId: String)

    // Income Events
    case incomeCreated(amount: Double, frequency: String, source: CreationSource)
    case incomeUpdated(incomeId: String, field: String)
    case incomeDeleted(incomeId: String)

    // Challenge Events
    case challengeStarted(difficulty: String, amount: Double, durationDays: Int)
    case challengeCompleted(difficulty: String, pointsEarned: Int, underBudgetAmount: Double)
    case challengeFailed(difficulty: String, overBudgetAmount: Double)
    case challengeExpenseRecorded(amount: Double, remainingBudget: Double)

    // Reward Events
    case rewardEarned(type: String, points: Int)
    case rewardViewed(type: String)
    case rewardDismissed(type: String)
    case tierUnlocked(tier: String, totalPoints: Int)
    case streakExtended(streakDays: Int)
    case arcEarned(newCount: Int, previousCount: Int)

    // Feature Usage
    case chatMessageSent(isVoice: Bool, hasToolUse: Bool)
    case voiceModeActivated
    case voiceModeDeactivated(durationSeconds: Double)
    case currencyConverterUsed(fromCurrency: String, toCurrency: String)
    case reminderToggled(enabled: Bool, daysBefore: Int)

    // Notification Events
    case notificationPermissionRequested
    case notificationPermissionGranted
    case notificationPermissionDenied

    // Subscription Events
    case paywallViewed(source: String)
    case subscriptionStarted(planType: String)
    case trialStarted(planType: String)

    // Error Events
    case errorOccurred(screen: String, error: String)

    var name: String {
        switch self {
        // Auth
        case .signUpStarted: return "sign_up_started"
        case .signUpCompleted: return "sign_up_completed"
        case .signUpFailed: return "sign_up_failed"
        case .signInStarted: return "sign_in_started"
        case .signInCompleted: return "sign_in_completed"
        case .signInFailed: return "sign_in_failed"
        case .signOut: return "sign_out"
        case .accountDeleted: return "account_deleted"

        // Onboarding
        case .onboardingStepViewed: return "onboarding_step_viewed"
        case .onboardingStepCompleted: return "onboarding_step_completed"
        case .onboardingCompleted: return "onboarding_completed"
        case .previewModeStarted: return "preview_mode_started"
        case .previewModeDataTransferred: return "preview_mode_data_transferred"

        // Bills
        case .billCreated: return "bill_created"
        case .billUpdated: return "bill_updated"
        case .billDeleted: return "bill_deleted"
        case .billMarkedPaid: return "bill_marked_paid"
        case .billMarkedUnpaid: return "bill_marked_unpaid"

        // Expenses
        case .expenseCreated: return "expense_created"
        case .expenseUpdated: return "expense_updated"
        case .expenseDeleted: return "expense_deleted"

        // Income
        case .incomeCreated: return "income_created"
        case .incomeUpdated: return "income_updated"
        case .incomeDeleted: return "income_deleted"

        // Challenges
        case .challengeStarted: return "challenge_started"
        case .challengeCompleted: return "challenge_completed"
        case .challengeFailed: return "challenge_failed"
        case .challengeExpenseRecorded: return "challenge_expense_recorded"

        // Rewards
        case .rewardEarned: return "reward_earned"
        case .rewardViewed: return "reward_viewed"
        case .rewardDismissed: return "reward_dismissed"
        case .tierUnlocked: return "tier_unlocked"
        case .streakExtended: return "streak_extended"
        case .arcEarned: return "arc_earned"

        // Features
        case .chatMessageSent: return "chat_message_sent"
        case .voiceModeActivated: return "voice_mode_activated"
        case .voiceModeDeactivated: return "voice_mode_deactivated"
        case .currencyConverterUsed: return "currency_converter_used"
        case .reminderToggled: return "reminder_toggled"

        // Notifications
        case .notificationPermissionRequested: return "notification_permission_requested"
        case .notificationPermissionGranted: return "notification_permission_granted"
        case .notificationPermissionDenied: return "notification_permission_denied"

        // Subscription
        case .paywallViewed: return "paywall_viewed"
        case .subscriptionStarted: return "subscription_started"
        case .trialStarted: return "trial_started"

        // Errors
        case .errorOccurred: return "error_occurred"
        }
    }

    var properties: [String: Any] {
        switch self {
        // Auth
        case .signUpStarted(let method):
            return ["method": method.rawValue]
        case .signUpCompleted(let method):
            return ["method": method.rawValue]
        case .signUpFailed(let method, let error):
            return ["method": method.rawValue, "error": error]
        case .signInStarted(let method):
            return ["method": method.rawValue]
        case .signInCompleted(let method):
            return ["method": method.rawValue]
        case .signInFailed(let method, let error):
            return ["method": method.rawValue, "error": error]
        case .signOut:
            return [:]
        case .accountDeleted:
            return [:]

        // Onboarding
        case .onboardingStepViewed(let step, let index):
            return ["step": step, "step_index": index]
        case .onboardingStepCompleted(let step, let index):
            return ["step": step, "step_index": index]
        case .onboardingCompleted(let durationSeconds):
            return ["duration_seconds": durationSeconds]
        case .previewModeStarted:
            return [:]
        case .previewModeDataTransferred(let billCount, let expenseCount):
            return ["bill_count": billCount, "expense_count": expenseCount]

        // Bills
        case .billCreated(let amount, let frequency, let hasReminder, let source):
            return ["amount": amount, "frequency": frequency, "has_reminder": hasReminder, "source": source.rawValue]
        case .billUpdated(let billId, let field):
            return ["bill_id": billId, "field": field]
        case .billDeleted(let billId):
            return ["bill_id": billId]
        case .billMarkedPaid(let amount, let paymentMethod, let daysBeforeDue):
            return ["amount": amount, "payment_method": paymentMethod, "days_before_due": daysBeforeDue]
        case .billMarkedUnpaid(let billId):
            return ["bill_id": billId]

        // Expenses
        case .expenseCreated(let amount, let paymentMethod, let hasCategory, let source):
            return ["amount": amount, "payment_method": paymentMethod, "has_category": hasCategory, "source": source.rawValue]
        case .expenseUpdated(let expenseId, let field):
            return ["expense_id": expenseId, "field": field]
        case .expenseDeleted(let expenseId):
            return ["expense_id": expenseId]

        // Income
        case .incomeCreated(let amount, let frequency, let source):
            return ["amount": amount, "frequency": frequency, "source": source.rawValue]
        case .incomeUpdated(let incomeId, let field):
            return ["income_id": incomeId, "field": field]
        case .incomeDeleted(let incomeId):
            return ["income_id": incomeId]

        // Challenges
        case .challengeStarted(let difficulty, let amount, let durationDays):
            return ["difficulty": difficulty, "amount": amount, "duration_days": durationDays]
        case .challengeCompleted(let difficulty, let pointsEarned, let underBudgetAmount):
            return ["difficulty": difficulty, "points_earned": pointsEarned, "under_budget_amount": underBudgetAmount]
        case .challengeFailed(let difficulty, let overBudgetAmount):
            return ["difficulty": difficulty, "over_budget_amount": overBudgetAmount]
        case .challengeExpenseRecorded(let amount, let remainingBudget):
            return ["amount": amount, "remaining_budget": remainingBudget]

        // Rewards
        case .rewardEarned(let type, let points):
            return ["reward_type": type, "points": points]
        case .rewardViewed(let type):
            return ["reward_type": type]
        case .rewardDismissed(let type):
            return ["reward_type": type]
        case .tierUnlocked(let tier, let totalPoints):
            return ["tier": tier, "total_points": totalPoints]
        case .streakExtended(let streakDays):
            return ["streak_days": streakDays]
        case .arcEarned(let newCount, let previousCount):
            return ["new_count": newCount, "previous_count": previousCount]

        // Features
        case .chatMessageSent(let isVoice, let hasToolUse):
            return ["is_voice": isVoice, "has_tool_use": hasToolUse]
        case .voiceModeActivated:
            return [:]
        case .voiceModeDeactivated(let durationSeconds):
            return ["duration_seconds": durationSeconds]
        case .currencyConverterUsed(let fromCurrency, let toCurrency):
            return ["from_currency": fromCurrency, "to_currency": toCurrency]
        case .reminderToggled(let enabled, let daysBefore):
            return ["enabled": enabled, "days_before": daysBefore]

        // Notifications
        case .notificationPermissionRequested:
            return [:]
        case .notificationPermissionGranted:
            return [:]
        case .notificationPermissionDenied:
            return [:]

        // Subscription
        case .paywallViewed(let source):
            return ["source": source]
        case .subscriptionStarted(let planType):
            return ["plan_type": planType]
        case .trialStarted(let planType):
            return ["plan_type": planType]

        // Errors
        case .errorOccurred(let screen, let error):
            return ["screen": screen, "error": error]
        }
    }
}

// MARK: - Analytics Service

@MainActor
class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()

    private var userId: String?

    private init() {}

    // MARK: - User Identification

    func identify(userId: String, properties: [String: Any] = [:]) {
        self.userId = userId
        print("📊 [Analytics] Identifying user: \(userId) with properties: \(properties)")
        PostHogSDK.shared.identify(userId, userProperties: properties)
    }

    func identify(profile: Profile, stats: ChallengeStats? = nil) {
        self.userId = profile.userId

        var properties: [String: Any] = [
            "email": profile.email,
            "name": profile.name,
            "currency": profile.settings.currency,
            "monthly_income": profile.settings.monthlyIncome,
            "freedom_fund": profile.settings.freedomFund,
            "notifications_enabled": profile.settings.notificationsEnabled
        ]

        if let stats = stats {
            properties["tier"] = stats.currentTier.rawValue
            properties["total_points"] = stats.totalPoints
            properties["current_streak"] = stats.currentStreak
            properties["challenges_completed"] = stats.totalCompleted
        }

        if let createdAt = profile.createdAt {
            properties["created_at"] = createdAt
        }

        print("📊 [Analytics] Identifying user: \(profile.userId) with profile properties")
        PostHogSDK.shared.identify(profile.userId, userProperties: properties)
    }

    func reset() {
        print("📊 [Analytics] Resetting user identity")
        userId = nil
        PostHogSDK.shared.reset()
    }

    // MARK: - Event Tracking

    func track(_ event: AnalyticsEvent) {
        print("📊 [Analytics] Tracking event: \(event.name) with properties: \(event.properties)")
        PostHogSDK.shared.capture(event.name, properties: event.properties)
    }

    // MARK: - Screen Tracking

    func trackScreen(_ screen: AnalyticsScreen) {
        print("📊 [Analytics] Screen viewed: \(screen.rawValue)")
        PostHogSDK.shared.screen(screen.rawValue)
    }

    func trackScreen(_ screenName: String) {
        print("📊 [Analytics] Screen viewed: \(screenName)")
        PostHogSDK.shared.screen(screenName)
    }
}
