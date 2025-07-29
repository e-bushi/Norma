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
    
    // Encryption Migration State
    @Published var shouldShowEncryptionMigration = false
    @Published var hasCheckedEncryptionStatus = false
    
    // MARK: - Services
    private let dataManager: DataManager
    
    // MARK: - Initialization
    
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        
        Task {
            await checkAuthenticationState()
        }
    }
    
    // MARK: - Authentication Methods
    
    func checkAuthenticationState() async {
        print("🔍 [DEBUG] SessionViewModel.checkAuthenticationState called")
        isLoadingAuth = true
        
        do {
            // Use DataManager to check authentication state
            print("🔄 [DEBUG] SessionViewModel: About to get current user profile...")
            let profile = try await dataManager.getCurrentUserProfile()
            
            if let profile = profile {
                print("✅ [DEBUG] SessionViewModel: Profile found: \(profile)")
                await handleAuthenticationSuccess(user: profile)
            } else {
                print("❌ [DEBUG] SessionViewModel: No profile found")
                await handleNoAuthentication()
            }
            
        } catch {
            print("❌ [DEBUG] SessionViewModel: Auth check failed: \(error.localizedDescription)")
            await handleNoAuthentication()
        }
        
        isLoadingAuth = false
        print("🔄 [DEBUG] SessionViewModel.checkAuthenticationState completed")
    }
    
    func handleAuthenticationSuccess(user: Profile? = nil) async {
        isAuthenticated = true
        
        if let user = user {
            currentUser = user
        } else {
            // Fetch user profile if not provided
            await fetchUserProfile()
        }
        
        // Check if user has completed initial setup
        await checkInitialSetupStatus()
        
        // Check encryption status for migration popup
        await checkEncryptionMigrationStatus()
    }
    
    func handleNoAuthentication() async {
        isAuthenticated = false
        currentUser = nil
        shouldShowOnboarding = true
        hasCompletedOnboarding = false
        hasCompletedInitialSetup = false
        
        // Reset encryption migration state
        shouldShowEncryptionMigration = false
        hasCheckedEncryptionStatus = false
    }
    
    func logout() async {
        do {
            try await dataManager.signOut()
            await handleNoAuthentication()
        } catch {
            showError(error.localizedDescription)
        }
    }
    
    // MARK: - User Profile Methods
    
    func fetchUserProfile() async {
        guard isAuthenticated else { return }
        
        do {
            let profile = try await dataManager.getCurrentUserProfile()
            currentUser = profile
        } catch {
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
    
    // MARK: - Setup and Onboarding
    
    func checkInitialSetupStatus() async {
        guard let user = currentUser else { return }
        
        // Ensure default categories are created for authenticated users
        await ensureDefaultCategoriesExist()
        
        // Check if user has completed initial financial setup
        // Check if they have essential onboarding data (income, currency, etc.)
        if user.settings.monthlyIncome > 0 && !user.settings.primaryGoal.isEmpty {
            hasCompletedInitialSetup = true
            hasCompletedOnboarding = true
        } else {
            hasCompletedInitialSetup = false
            hasCompletedOnboarding = false
        }
    }
    
    func ensureDefaultCategoriesExist() async {
        guard let userId = currentUser?.userId else { return }
        
        do {
            // First, try to fetch existing categories
            try await dataManager.fetchCategories(userId: userId)
            
            // Clean up any duplicate categories
            try await dataManager.removeDuplicateCategories()
            
            // Check if we have any system categories (default categories)
            let systemCategories = dataManager.getSystemCategories()
            
            if systemCategories.isEmpty {
                print("📝 Creating default categories for user: \(userId)")
                try await dataManager.createDefaultCategories(for: userId)
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
        shouldShowOnboarding = false
    }
    
    // MARK: - Encryption Migration Methods
    
    func checkEncryptionMigrationStatus() async {
        guard let userId = currentUser?.userId,
              !hasCheckedEncryptionStatus else { return }
        
        hasCheckedEncryptionStatus = true
        
        do {
            // First, clean up any duplicate encryption keys
            try await dataManager.supabaseService.cleanupDuplicateEncryptionKeys(userId: userId)
            
            let hasEncryption = await dataManager.hasEncryptionEnabled()
            
            // Show migration popup only if user doesn't have encryption enabled
            if !hasEncryption {
                shouldShowEncryptionMigration = true
            }
        } catch {
            print("Failed to check encryption status: \(error.localizedDescription)")
        }
    }
    
    func dismissEncryptionMigration() {
        shouldShowEncryptionMigration = false
    }
    
    func setupEncryptionForNewUser(password: String) async throws -> String {
        return try await dataManager.setupEncryption(password: password)
    }
    
    var supabaseService: SupabaseService {
        return dataManager.supabaseService
    }
    
    func startEncryptionMigration(password: String) async throws {
        print("🔐 Starting encryption migration with verified password...")
        
        do {
            // Step 1: Setup encryption for the user with verified password
            print("📍 [DEBUG] SessionViewModel: Step 1 - Setting up encryption...")
            let recoveryPhrase = try await dataManager.setupEncryption(password: password)
            print("✅ Encryption setup complete. Recovery phrase generated.")
            
            // Step 2: Store recovery phrase securely for Settings access
            print("📍 [DEBUG] SessionViewModel: Step 2 - Storing recovery phrase...")
            guard let userId = currentUser?.userId else {
                throw NSError(domain: "SessionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "User ID not available"])
            }
            
            let userKeyManager = UserKeyManager(supabaseService: dataManager.supabaseService)
            userKeyManager.storeRecoveryPhrase(recoveryPhrase, for: userId)
            print("✅ Recovery phrase stored securely.")
            
            // Step 3: Migrate all existing data to encrypted format
            print("📍 [DEBUG] SessionViewModel: Step 3 - Migrating data...")
            try await dataManager.migrateAllDataToEncryption()
            print("✅ Data migration complete.")
            
            // Step 4: Mark encryption as enabled (prevent future popups)
            hasCheckedEncryptionStatus = true
            
            print("🎉 Encryption migration completed successfully!")
            
        } catch {
            print("❌ Encryption migration failed: \(error)")
            print("❌ Error description: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("❌ Error domain: \(nsError.domain)")
                print("❌ Error code: \(nsError.code)")
                print("❌ Error userInfo: \(nsError.userInfo)")
            }
            // The popup will handle displaying the error
            throw error
        }
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
            primaryGoal: data.primaryGoal,
            notificationsEnabled: data.reminderPreference != "No reminders",
            billReminderDays: reminderDays
        )
        
        // Check if profile already exists
        if let existingProfile = try await dataManager.supabaseService.fetchProfile(userId: supabaseUser.id.uuidString) {
            // Update existing profile
            var updatedProfile = existingProfile
            updatedProfile.settings = settings
            try await dataManager.updateUserProfile(updatedProfile)
            currentUser = updatedProfile
        } else {
            // Create new profile
            let newProfile = Profile(
                userId: supabaseUser.id.uuidString,
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

