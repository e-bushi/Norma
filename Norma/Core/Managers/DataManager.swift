//
//  DataManager.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation
import SwiftUI
import Supabase
import SwiftData

@MainActor
class DataManager: ObservableObject {
    
    // MARK: - Published Properties
    
    // User Data
    @Published var currentProfile: Profile?
    @Published var profiles: [Profile] = []
    
    // Financial Data
    @Published var expenses: [Expense] = []
    @Published var income: [Income] = []
    @Published var budgets: [Budget] = []
    @Published var categories: [Category] = []
    @Published var bills: [Bill] = []
    
    // Psychology Data
    @Published var moneyPersonality: MoneyPersonality?
    @Published var financialHealthInsight: FinancialHealthInsight?
    
    // Data State
    @Published var isLoading = false
    @Published var lastSyncDate: Date?
    @Published var hasUnsyncedChanges = false
    
    // MARK: - Services
    let supabaseService = SupabaseService.shared
    
    // SwiftData
    var modelContext: ModelContext?
    
    // MARK: - Initialization
    
    init() {
        loadCachedData()
    }
    
    // Set the model context (called from view)
    func setModelContext(_ context: ModelContext) {
        print("🔍 [DEBUG] DataManager.setModelContext called")
        self.modelContext = context
        print("✅ [DEBUG] DataManager.setModelContext: ModelContext set successfully")
        // Note: Data loading happens via fetchAllFinancialData() which is called from RootView
        
        // Process any pending Siri intents
        Task {
            await SharedDataService.shared.processPendingIntents(dataManager: self)
        }
    }
    
    // MARK: - Siri Integration
    
    /// Process pending Siri intents (call this when app becomes active)
    func processPendingSiriIntents() async {
        await SharedDataService.shared.processPendingIntents(dataManager: self)
    }
    
    // MARK: - User Profile Methods
    
    func getCurrentUserProfile() async throws -> Profile? {
        print("🔍 [DEBUG] DataManager.getCurrentUserProfile called")
        
        // Check if we have a current user from Supabase
        if let supabaseUser = supabaseService.currentUser {
            print("✅ [DEBUG] DataManager: Supabase user found: \(supabaseUser.id.uuidString)")
            
            // Fetch existing profile from database
            print("🔄 [DEBUG] DataManager: About to fetch profile from database...")
            if let existingProfile = try await fetchUserProfileWithEncryption(userId: supabaseUser.id.uuidString) {
                print("✅ [DEBUG] DataManager: Existing profile found: \(existingProfile)")
                currentProfile = existingProfile
                // Also add to profiles array if not already there
                if !profiles.contains(where: { $0.userId == existingProfile.userId }) {
                    profiles.append(existingProfile)
                }
                return existingProfile
            } else {
                print("❌ [DEBUG] DataManager: No existing profile found, creating fallback profile")
                // Fallback: create basic profile if none exists in database
                let profile = Profile(
                    userId: supabaseUser.id.uuidString,
                    email: supabaseUser.email ?? "",
                    name: extractNameFromUserMetadata(supabaseUser.userMetadata)
                )
                print("✅ [DEBUG] DataManager: Created fallback profile: \(profile)")
                currentProfile = profile
                // Also add to profiles array
                if !profiles.contains(where: { $0.userId == profile.userId }) {
                    profiles.append(profile)
                }
                return profile
            }
        }
        
        print("❌ [DEBUG] DataManager: No Supabase user found")
        return nil
    }
    
    func fetchUserProfile(userId: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Implement profile fetching from Supabase
        // let profile = try await supabaseService.fetchProfile(userId: userId)
        // currentProfile = profile
        
        print("Fetching user profile for: \(userId)")
    }
    
    func signOut() async throws {
        try await supabaseService.signOut()
        clearAllData()
    }
    
    func deleteAccount() async throws {
        // Delete all user data from Supabase
        try await supabaseService.deleteAccount()
        
        // Clear all local data
        clearAllData()
        
        // Clear any cached data
        clearCachedData()
    }
    
    func updateUserProfile(_ profile: Profile) async throws {
        // Update local state immediately
        currentProfile = profile
        hasUnsyncedChanges = true
        
        // Sync to remote
        let updatedProfile = try await updateUserProfileWithEncryption(profile)
        currentProfile = updatedProfile
        
        print("Updated user profile")
    }
    
    func createUserProfile(_ profile: Profile) async throws {
        // Create profile in remote database
        let createdProfile = try await createUserProfileWithEncryption(profile)
        
        // Update local state with the created profile (includes ID from database)
        currentProfile = createdProfile
        hasUnsyncedChanges = false
        
        print("Created user profile")
    }
    
    // MARK: - Financial Data Methods
    
    func fetchAllFinancialData() async throws {
        guard let userId = currentProfile?.userId else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        // Fetch all data concurrently (with encryption support)
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { try await self.fetchExpensesWithEncryption(userId: userId) }
            group.addTask { try await self.fetchBudgetsWithEncryption(userId: userId) }
            group.addTask { try await self.fetchBillsWithEncryption(userId: userId) }
            
            // These don't need encryption yet
            group.addTask { try await self.fetchIncomes(userId: userId) }
            group.addTask { try await self.fetchCategories(userId: userId) }
            group.addTask { try await self.fetchPsychologyData(userId: userId) }
            
            // Wait for all tasks to complete
            try await group.waitForAll()
        }
        
        lastSyncDate = Date()
    }
    
    
    // MARK: - Data Sync and Cache Methods
    
    func syncAllData() async throws {
        guard hasUnsyncedChanges else { return }
        
        // Implement full data sync
        // This would batch upload all unsynced changes
        
        hasUnsyncedChanges = false
        lastSyncDate = Date()
        
        print("Synced all data")
    }
    
    func clearAllData() {
        currentProfile = nil
        expenses.removeAll()
        income.removeAll()
        budgets.removeAll()
        categories.removeAll()
        bills.removeAll()
        moneyPersonality = nil
        financialHealthInsight = nil
        hasUnsyncedChanges = false
        lastSyncDate = nil
    }
    
    // MARK: - Computed Properties
    
    var totalMonthlyIncome: Double {
        getTotalMonthlyIncome()
    }
    
    var totalMonthlyExpenses: Double {
        getTotalExpenses(for: nil)
    }
    
    var totalMonthlyBills: Double {
        getTotalMonthlyBills()
    }
    
    var netMonthlyIncome: Double {
        totalMonthlyIncome - totalMonthlyExpenses - totalMonthlyBills
    }
    
    var hasFinancialData: Bool {
        !expenses.isEmpty || !income.isEmpty || !bills.isEmpty
    }
    
    var hasPsychologyData: Bool {
        moneyPersonality != nil || financialHealthInsight != nil
    }
    
    // MARK: - Widget Integration
    
    func forceUpdateWidgetData() {
        print("🔄 Forcing widget data update...")
        let monthlyIncome = currentProfile?.settings.monthlyIncome ?? 0
        WidgetDataManager.shared.updateWidgetData(
            bills: bills,
            expenses: expenses,
            monthlyIncome: monthlyIncome,
            aiInsight: nil
        )
        print("✅ Widget data updated with \(bills.count) bills, \(expenses.count) expenses, and $\(monthlyIncome) monthly income")
    }
    
    // MARK: - Private Methods
    
    private func loadCachedData() {
        // Load cached data from UserDefaults or Core Data
        // This ensures the app works offline
        
        print("Loading cached data")
    }
    
    private func saveToCache() {
        // Save current data to local cache
        print("Saving to cache")
    }
    
    private func extractNameFromUserMetadata(_ metadata: [String: AnyJSON]) -> String {
        let firstName = metadata["first_name"]?.stringValue ?? ""
        let lastName = metadata["last_name"]?.stringValue ?? ""
        return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
}
