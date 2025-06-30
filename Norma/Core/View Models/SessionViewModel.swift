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
    
    // MARK: - Initialization
    
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        
        Task {
            await checkAuthenticationState()
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
            print("Auth check failed: \(error.localizedDescription)")
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
        
        // Check if user has completed initial setup
        await checkInitialSetupStatus()
    }
    
    func handleNoAuthentication() async {
        isAuthenticated = false
        currentUser = nil
        shouldShowOnboarding = true
        hasCompletedOnboarding = false
        hasCompletedInitialSetup = false
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
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        shouldShowOnboarding = false
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

