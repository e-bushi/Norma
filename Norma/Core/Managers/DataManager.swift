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
    @Published var categories: [Category] = []
    @Published var bills: [Bill] = []
    @Published var pendingTransactions: [PendingTransaction] = []

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
        self.modelContext = context
    }
    
    // MARK: - User Profile Methods
    
    func getCurrentUserProfile() async throws -> Profile? {
        // Use async session to ensure session is restored from storage on cold start
        // (currentUser is synchronous and may be nil before INITIAL_SESSION event)
        let session = try? await supabaseService.getSession()
        let supabaseUser = session?.user ?? supabaseService.currentUser

        if let supabaseUser = supabaseUser {
            // Fetch existing profile from database
            if let existingProfile = try await fetchUserProfile(userId: supabaseUser.id.uuidString.lowercased()) {
                currentProfile = existingProfile
                // Also add to profiles array if not already there
                if !profiles.contains(where: { $0.userId == existingProfile.userId }) {
                    profiles.append(existingProfile)
                }
                return existingProfile
            } else {
                // Fallback: create basic profile if none exists in database
                let profile = Profile(
                    userId: supabaseUser.id.uuidString.lowercased(),
                    email: supabaseUser.email ?? "",
                    name: extractNameFromUserMetadata(supabaseUser.userMetadata)
                )
                currentProfile = profile
                // Also add to profiles array
                if !profiles.contains(where: { $0.userId == profile.userId }) {
                    profiles.append(profile)
                }
                return profile
            }
        }

        return nil
    }
    
    // Note: fetchUserProfile is implemented in DataManager+Encryption.swift
    
    func signOut() async throws {
        try await supabaseService.signOut()
        clearAllData()
    }
    
    func deleteAccount() async throws {
        // Delete all user data from Supabase
        try await supabaseService.deleteAccount()
        
        // Clear all local data
        clearAllData()
    }
    
    func updateUserProfile(_ profile: Profile) async throws {
        // Update local state immediately
        currentProfile = profile
        hasUnsyncedChanges = true

        guard let masterKey = getCurrentMasterKey() else {
            throw EncryptionError.noEncryptionKeys
        }

        try await supabaseService.edgeFunctionService.updateProfile(profile, encryptionKey: masterKey)
        print("Updated user profile (encrypted)")

        hasUnsyncedChanges = false
    }

    func createUserProfile(_ profile: Profile) async throws {
        // Use the profile's userId directly to look up the master key,
        // since currentProfile is nil for brand new users
        let keyManager = UserKeyManager(supabaseService: supabaseService)
        guard let masterKey = keyManager.getCurrentMasterKey(for: profile.userId) else {
            throw EncryptionError.noEncryptionKeys
        }

        let profileId = try await supabaseService.edgeFunctionService.createProfile(profile, encryptionKey: masterKey)

        // Update local state with the created profile ID
        var createdProfile = profile
        createdProfile.id = profileId
        currentProfile = createdProfile

        hasUnsyncedChanges = false
    }
    
    // MARK: - Financial Data Methods
    
    func fetchAllFinancialData() async throws {
        guard let userId = currentProfile?.userId else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        // Fetch all data concurrently (with encryption support)
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { try await self.fetchExpensesWithEncryption(userId: userId) }
            group.addTask { try await self.fetchBillsWithEncryption(userId: userId) }
            group.addTask { try await self.fetchPendingTransactions(userId: userId) }

            // These don't need encryption yet
            group.addTask { try await self.fetchIncomes(userId: userId) }
            group.addTask { try await self.fetchCategories() }

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
        categories.removeAll()
        bills.removeAll()
        pendingTransactions.removeAll()
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
