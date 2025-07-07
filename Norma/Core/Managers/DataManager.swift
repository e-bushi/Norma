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
        loadCachedBills()
        print("✅ [DEBUG] DataManager.setModelContext: loadCachedBills completed")
        loadCachedExpenses()
        print("✅ [DEBUG] DataManager.setModelContext: loadCachedExpenses completed")
    }
    
    // MARK: - User Profile Methods
    
    func getCurrentUserProfile() async throws -> Profile? {
        print("🔍 [DEBUG] DataManager.getCurrentUserProfile called")
        
        // Check if we have a current user from Supabase
        if let supabaseUser = supabaseService.currentUser {
            print("✅ [DEBUG] DataManager: Supabase user found: \(supabaseUser.id.uuidString)")
            
            // Fetch existing profile from database
            print("🔄 [DEBUG] DataManager: About to fetch profile from database...")
            if let existingProfile = try await supabaseService.fetchProfile(userId: supabaseUser.id.uuidString) {
                print("✅ [DEBUG] DataManager: Existing profile found: \(existingProfile)")
                currentProfile = existingProfile
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
    
    func updateUserProfile(_ profile: Profile) async throws {
        // Update local state immediately
        currentProfile = profile
        hasUnsyncedChanges = true
        
        // Sync to remote
        let updatedProfile = try await supabaseService.updateProfile(profile)
        currentProfile = updatedProfile
        
        print("Updated user profile")
    }
    
    func createUserProfile(_ profile: Profile) async throws {
        // Create profile in remote database
        let createdProfile = try await supabaseService.createProfile(profile)
        
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
        
        // Fetch all data concurrently
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { try await self.fetchExpenses(userId: userId) }
            group.addTask { try await self.fetchIncomes(userId: userId) }
            group.addTask { try await self.fetchBudgets(userId: userId) }
            group.addTask { try await self.fetchCategories(userId: userId) }
            group.addTask { try await self.fetchBills(userId: userId) }
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
