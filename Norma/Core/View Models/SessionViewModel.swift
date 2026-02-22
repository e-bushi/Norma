//
//  SessionViewModel.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation
import SwiftUI

@MainActor
class SessionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    // Authentication State
    @Published var isAuthenticated = false
    @Published var currentUser: Profile?
    @Published var isLoadingAuth = true
    
    // App Navigation State
    @Published var hasCompletedOnboarding = false
    @Published var hasCompletedInitialSetup = false
    @Published var shouldShowOnboarding = false
    
    // App State
    @Published var isOffline = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    
    // MARK: - Services
    private let dataManager: DataManager
    private var authStateTask: Task<Void, Never>?

    // MARK: - Initialization

    init(dataManager: DataManager) {
        self.dataManager = dataManager

        Task {
            await checkAuthenticationState()
        }

        // Start listening for auth state changes (token refreshes)
        startAuthStateListener()
    }

    deinit {
        authStateTask?.cancel()
    }

    // MARK: - Auth State Listener

    private func startAuthStateListener() {
        authStateTask = Task { [weak dataManager] in
            guard let dataManager = dataManager else { return }

            for await authChange in dataManager.supabaseService.authStateChanges {
                guard !Task.isCancelled else { break }

                // Update keychain whenever we get a new token (store all credentials to fix race conditions)
                if let session = authChange.session {
                    let userId = session.user.id.uuidString.lowercased()
                    _ = SharedKeychainHelper.storeUserId(userId)
                    let tokenStored = SharedKeychainHelper.storeAuthToken(session.accessToken, for: userId)
                    let refreshStored = SharedKeychainHelper.storeRefreshToken(session.refreshToken, for: userId)
                    print("🔄 Auth state change (\(authChange.event)) - keychain updated: token=\(tokenStored), refresh=\(refreshStored)")
                }
            }
        }
    }
    
    // MARK: - Authentication Methods
    
    func checkAuthenticationState() async {
        isLoadingAuth = true

        do {
            // Use DataManager to check authentication state
            let profile = try await dataManager.getCurrentUserProfile()

            if let profile = profile {
                await handleAuthenticationSuccess(user: profile)
            } else {
                await handleNoAuthentication()
            }

        } catch {
            await handleNoAuthentication()
        }

        isLoadingAuth = false
    }
    
    func handleAuthenticationSuccess(user: Profile? = nil) async {
        isAuthenticated = true

        if let user = user {
            currentUser = user
        } else {
            // Fetch user profile if not provided
            await fetchUserProfile()
        }

        // Store credentials in shared keychain for Share Extension
        if let userId = currentUser?.userId {
            let userIdStored = SharedKeychainHelper.storeUserId(userId)
            print("🔑 Shared keychain - userId stored: \(userIdStored)")

            if let session = try? await dataManager.supabaseService.getSession() {
                let tokenStored = SharedKeychainHelper.storeAuthToken(session.accessToken, for: userId)
                print("🔑 Shared keychain - authToken stored: \(tokenStored)")

                let refreshStored = SharedKeychainHelper.storeRefreshToken(session.refreshToken, for: userId)
                print("🔑 Shared keychain - refreshToken stored: \(refreshStored)")
            } else {
                print("⚠️ Shared keychain - no session available to store tokens")
            }

            // Store Supabase config so share extension can refresh tokens independently
            let configStored = SharedKeychainHelper.storeSupabaseConfig(
                url: SupabaseService.supabaseURLString,
                anonKey: SupabaseService.supabaseAnonKey
            )
            print("🔑 Shared keychain - supabase config stored: \(configStored)")
        } else {
            print("⚠️ Shared keychain - no userId available to store")
        }

        // Check if user has completed initial setup
        await checkInitialSetupStatus()

        // Load reward milestones for this user
        if let userId = currentUser?.userId {
            await RewardMilestoneTracker.shared.loadMilestones(for: userId, dataManager: dataManager)

            // Configure RewardQueueManager for backend sync
            RewardQueueManager.shared.configure(
                supabaseService: dataManager.supabaseService,
                userId: userId
            )

            // Note: fetchAndQueuePendingRewards() is called later by AppCoordinator
            // after runDailyCalculations() has created any pending rewards
        }

        // Identify user in analytics
        if let profile = currentUser {
            AnalyticsService.shared.identify(profile: profile)
        }

        print("🔐 Auth success - isAuthenticated: \(isAuthenticated), hasCompletedOnboarding: \(hasCompletedOnboarding), hasCompletedInitialSetup: \(hasCompletedInitialSetup), currentUser: \(currentUser?.name ?? "nil")")
    }
    
    func handleNoAuthentication() async {
        isAuthenticated = false
        currentUser = nil
        shouldShowOnboarding = true
        hasCompletedOnboarding = false
        hasCompletedInitialSetup = false

        // Clear shared keychain data for Share Extension
        SharedKeychainHelper.clearAllSharedData()

        // Reset analytics identity
        AnalyticsService.shared.reset()
    }
    
    func logout() async {
        do {
            // Track sign out before clearing state
            AnalyticsService.shared.track(.signOut)

            try await dataManager.signOut()

            // Clear reward tracking state
            RewardMilestoneTracker.shared.clearUser()
            RewardQueueManager.shared.clearQueue()

            await handleNoAuthentication()
        } catch {
            showError(error.localizedDescription)
        }
    }
    
    func deleteAccount() async throws {
        // Track account deletion before clearing state
        AnalyticsService.shared.track(.accountDeleted)

        // Delete all user data and sign out
        try await dataManager.deleteAccount()
        await handleNoAuthentication()
    }
    
    // MARK: - User Profile Methods
    
    func fetchUserProfile() async {
        guard isAuthenticated else {
            print("⚠️ fetchUserProfile: Not authenticated, skipping")
            return
        }

        do {
            let profile = try await dataManager.getCurrentUserProfile()
            currentUser = profile
            print("✅ fetchUserProfile: Loaded profile - \(profile?.name ?? "nil"), income: \(profile?.settings.monthlyIncome ?? 0)")
        } catch {
            print("❌ fetchUserProfile: Failed - \(error)")
            showError("Failed to load user profile")
        }
    }
    
    func updateUserProfile(_ profile: Profile) async {
        currentUser = profile
        do {
            try await dataManager.updateUserProfile(profile)
        } catch {
            showError("Failed to update profile")
        }
    }

    /// Update user profile with arc change detection
    /// If arc count increased, queues arc reward celebration
    /// - Parameters:
    ///   - profile: Updated profile with new freedom fund
    ///   - bills: Current bills array for arc calculation
    func updateUserProfileWithArcCheck(_ profile: Profile, bills: [Bill]) async {
        // Calculate previous arc count before update
        let previousFreedomFund = currentUser?.settings.freedomFund ?? 0
        let previousArcCount = ArcCalculationService.calculateArcs(freedomFund: previousFreedomFund, bills: bills)

        // Calculate new arc count
        let newArcCount = ArcCalculationService.calculateArcs(freedomFund: profile.settings.freedomFund, bills: bills)

        // Update the profile
        currentUser = profile
        do {
            try await dataManager.updateUserProfile(profile)

            // Check if arcs increased
            if newArcCount > previousArcCount {
                let coinTier = CoinTierService.currentCoinTier(for: newArcCount)
                let reward = Reward.arcEarned(
                    newArcCount: newArcCount,
                    previousArcCount: previousArcCount,
                    coinTier: coinTier
                )
                RewardQueueManager.shared.enqueue(reward)

                // Update last known arc count
                RewardMilestoneTracker.shared.setLastArcCount(newArcCount)

                // Track arc earned event
                AnalyticsService.shared.track(.arcEarned(newCount: newArcCount, previousCount: previousArcCount))

                print("🏆 Arc reward queued: \(previousArcCount) → \(newArcCount) arcs")
            }
        } catch {
            showError("Failed to update profile")
        }
    }

    /// Check for arc increase after bill changes (delete/reduce)
    /// - Parameters:
    ///   - bills: Updated bills array after change
    func checkArcIncreaseAfterBillChange(bills: [Bill]) {
        guard let profile = currentUser else { return }

        let previousArcCount = RewardMilestoneTracker.shared.getLastArcCount()
        let newArcCount = ArcCalculationService.calculateArcs(freedomFund: profile.settings.freedomFund, bills: bills)

        if newArcCount > previousArcCount && previousArcCount > 0 {
            let coinTier = CoinTierService.currentCoinTier(for: newArcCount)
            let reward = Reward.arcEarned(
                newArcCount: newArcCount,
                previousArcCount: previousArcCount,
                coinTier: coinTier
            )
            RewardQueueManager.shared.enqueue(reward)

            // Update last known arc count
            RewardMilestoneTracker.shared.setLastArcCount(newArcCount)

            print("🏆 Arc reward queued (bill change): \(previousArcCount) → \(newArcCount) arcs")
        }
    }

    // MARK: - Freedom Fund Management

    /// Deduct bill amount from freedom fund when a bill is paid
    /// Shows appropriate toast notification based on the result
    /// - Parameters:
    ///   - amount: The bill amount to deduct
    ///   - bills: Current bills array for arc calculation
    func deductFreedomFundForBillPayment(amount: Double, bills: [Bill]) async {
        guard var profile = currentUser else { return }

        let currency = profile.settings.currency
        let currentFreedomFund = profile.settings.freedomFund

        // Case 1: Freedom fund is empty or zero - prompt to add funds
        if currentFreedomFund <= 0 {
            ToastManager.shared.show(.freedomFundEmpty())
            print("💰 Freedom fund is empty - showing prompt to add funds")
            return
        }

        // Calculate new freedom fund (minimum 0, can't go negative)
        let newFreedomFund = max(0, currentFreedomFund - amount)
        let actualDeduction = currentFreedomFund - newFreedomFund

        // Update profile with new freedom fund (only update settings - encrypted_settings blob is source of truth)
        profile.settings.freedomFund = newFreedomFund
        currentUser = profile

        do {
            try await dataManager.updateUserProfile(profile)

            // Calculate new arc count
            let newArcCount = ArcCalculationService.calculateArcs(freedomFund: newFreedomFund, bills: bills)

            // Update last known arc count
            RewardMilestoneTracker.shared.setLastArcCount(newArcCount)

            // Case 2: Freedom fund is now depleted (reached 0)
            if newFreedomFund == 0 {
                ToastManager.shared.show(.freedomFundDepleted(amount: actualDeduction, currency: currency))
                print("💰 Freedom fund depleted: -\(actualDeduction) → 0 remaining")
            }
            // Case 3: Normal deduction with remaining balance
            else {
                ToastManager.shared.show(.freedomFundDeducted(
                    amount: actualDeduction,
                    arcsRemaining: newArcCount,
                    currency: currency
                ))
                print("💰 Freedom fund deducted: -\(actualDeduction) → \(newFreedomFund) remaining (\(newArcCount) arcs)")
            }

        } catch {
            print("❌ Failed to update freedom fund: \(error)")
            // Revert local change on failure (only update settings - encrypted_settings blob is source of truth)
            currentUser?.settings.freedomFund = currentFreedomFund
        }
    }

    // MARK: - Setup and Onboarding
    
    func checkInitialSetupStatus() async {
        guard let user = currentUser else {
            print("⚠️ checkInitialSetupStatus: No currentUser, cannot check setup status")
            return
        }

        // Ensure default categories are created for authenticated users
        await ensureDefaultCategoriesExist()

        // Check if user has completed initial financial setup
        // Only require monthlyIncome to be set - painPoint is optional for legacy users
        // Check both settings.monthlyIncome AND top-level monthlyIncome as fallback
        // (settings is an encrypted JSON blob that may fail to decrypt independently)
        let hasIncome = user.settings.monthlyIncome > 0 || (user.monthlyIncome ?? 0) > 0

        print("📊 Setup check - settings.income: \(user.settings.monthlyIncome), profile.income: \(user.monthlyIncome ?? 0), painPoint: '\(user.settings.painPoint)', hasIncome: \(hasIncome)")

        if hasIncome {
            hasCompletedInitialSetup = true
            hasCompletedOnboarding = true
        } else {
            hasCompletedInitialSetup = false
            hasCompletedOnboarding = false
        }
    }
    
    func ensureDefaultCategoriesExist() async {
        do {
            // Fetch all categories (shared across all users)
            try await dataManager.fetchCategories()

            // Clean up any duplicate categories
            try await dataManager.removeDuplicateCategories()

            // Check if we have any system categories (default categories)
            let systemCategories = dataManager.getSystemCategories()

            if systemCategories.isEmpty {
                print("📝 Creating default categories (shared globally)")
                try await dataManager.createDefaultCategories()
                print("✅ Default categories created successfully")
            } else {
                print("✅ Default categories already exist (\(systemCategories.count) found)")
            }

        } catch {
            print("❌ Failed to ensure default categories exist: \(error.localizedDescription)")
            // Don't throw the error - we want the app to continue working even if category setup fails
        }
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        hasCompletedInitialSetup = true
        shouldShowOnboarding = false
    }
    
    // MARK: - Encryption Support Methods

    func setupEncryptionForNewUser(password: String) async throws -> String {
        return try await dataManager.setupEncryption(password: password)
    }

    /// Unlock encryption for a returning user by deriving the master key from their password
    func unlockEncryptionForReturningUser(password: String) async throws {
        try await dataManager.unlockEncryption(password: password)
    }

    func createUserProfile(_ profile: Profile) async throws {
        try await dataManager.createUserProfile(profile)
        currentUser = dataManager.currentProfile
    }

    func addBill(_ bill: Bill) async throws {
        try await dataManager.addBillWithEncryption(bill)
    }

    func addExpense(_ expense: Expense) async throws {
        try await dataManager.addExpenseWithEncryption(expense)
    }

    var supabaseService: SupabaseService {
        return dataManager.supabaseService
    }
    
    func completeInitialSetup(with data: UserOnboardingData) async {
        // If not authenticated yet, authenticate first (after email verification)
        if !isAuthenticated {
            await handleAuthenticationSuccess()
        }
        
        do {
            // Save onboarding data to user profile
            try await saveOnboardingData(data)
            
            hasCompletedInitialSetup = true
            hasCompletedOnboarding = true
            shouldShowOnboarding = false
            
        } catch {
            showError("Failed to save setup data: \(error.localizedDescription)")
        }
    }
    
    // MARK: - App State Management
    
    func handleAppBecomeActive() async {
        // Refresh authentication when app becomes active
        if isAuthenticated {
            await fetchUserProfile()
        }
    }
    
    func handleAppEnterBackground() {
        // Handle any cleanup when app enters background
    }
    
    func setOfflineMode(_ offline: Bool) {
        isOffline = offline
    }
    
    // MARK: - Navigation Helpers
    
    var shouldShowMainApp: Bool {
        isAuthenticated && hasCompletedOnboarding && hasCompletedInitialSetup
    }
    
    var shouldShowAuthFlow: Bool {
        !isAuthenticated
    }
    
    var shouldShowInitialSetup: Bool {
        isAuthenticated && !hasCompletedInitialSetup
    }
    
    // MARK: - Private Methods
    
    private func saveOnboardingData(_ data: UserOnboardingData) async throws {
        // Get current authenticated user
        guard let supabaseUser = dataManager.supabaseService.currentUser else {
            throw NSError(domain: "SessionViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }
        
        // Convert reminder preference to days
        let reminderDays: Int
        switch data.reminderPreference {
        case "1 day before":
            reminderDays = 1
        case "3 days before":
            reminderDays = 3
        case "1 week before":
            reminderDays = 7
        case "No reminders":
            reminderDays = 0
        default:
            reminderDays = 3
        }
        
        // Create profile settings
        let settings = ProfileSettings(
            currency: data.currency,
            monthlyIncome: data.monthlyIncome,
            freedomFund: data.freedomFund,
            painPoint: data.painPoint,
            notificationsEnabled: data.reminderPreference != "No reminders",
            billReminderDays: reminderDays
        )
        
        // Check if profile already exists
        if let existingProfile = try await dataManager.supabaseService.fetchProfile(userId: supabaseUser.id.uuidString.lowercased()) {
            // Update existing profile
            var updatedProfile = existingProfile
            updatedProfile.settings = settings
            try await dataManager.updateUserProfile(updatedProfile)
            currentUser = updatedProfile
        } else {
            // Create new profile
            let newProfile = Profile(
                userId: supabaseUser.id.uuidString.lowercased(),
                email: supabaseUser.email ?? "",
                name: data.name,
                settings: settings
            )
            try await dataManager.createUserProfile(newProfile)
            currentUser = newProfile
        }
        
        print("Successfully saved onboarding data for user: \(data.name)")
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showError = true
        
        // Auto-hide error after 5 seconds
        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            await MainActor.run {
                showError = false
            }
        }
    }
}

