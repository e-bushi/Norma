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
    @Published var income: [Income] = []
    @Published var bills: [Bill] = []

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
        // Capture userId *before* the remote delete clears the session, so we
        // can use it to scope keychain / shared-keychain cleanup below.
        let userId = currentProfile?.userId
            ?? supabaseService.currentUser?.id.uuidString.lowercased()

        // Delete all user data from Supabase (cascades through auth.users FKs)
        try await supabaseService.deleteAccount()

        // Wipe local persistence so a fresh sign-in starts from zero.
        wipeLocalSwiftData()
        wipeLocalKeychain(for: userId)
        wipeLocalUserDefaults()

        // Clear in-memory state.
        clearAllData()
    }

    /// Deletes every SwiftData entity managed by this app's container. Called
    /// from `deleteAccount` so the next sign-in starts with an empty local
    /// store. Failures are logged but don't block the delete — a partial wipe
    /// is better than blocking the whole flow on a SwiftData hiccup.
    private func wipeLocalSwiftData() {
        guard let context = modelContext else {
            print("⚠️ deleteAccount: no modelContext, skipping SwiftData wipe")
            return
        }
        do {
            try context.delete(model: Note.self)
            try context.delete(model: NoteToken.self)
            try context.delete(model: CachedBill.self)
            try context.delete(model: FreedomFundEntry.self)
            try context.delete(model: Insight.self)
            try context.delete(model: UserProfile.self)
            try context.save()
            print("✅ deleteAccount: local SwiftData wiped")
        } catch {
            print("⚠️ deleteAccount: SwiftData wipe failed: \(error)")
        }
    }

    private func wipeLocalKeychain(for userId: String?) {
        if let userId {
            KeychainHelper.clearAllKeys(for: userId)
        }
        SharedKeychainHelper.clearAllSharedData()
        print("✅ deleteAccount: keychain wiped")
    }

    private func wipeLocalUserDefaults() {
        let defaults = UserDefaults.standard
        // User-scoped caches and engine state — anything that would mislead
        // the next account signing in on this device.
        defaults.removeObject(forKey: "cachedArcCount")
        defaults.removeObject(forKey: "cachedFreedomFund")
        defaults.removeObject(forKey: "insightEngine.lastRunAt")
        defaults.removeObject(forKey: "insightEngine.lastNoteHash")
        print("✅ deleteAccount: user-scoped UserDefaults cleared")
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
            group.addTask { try await self.fetchBillsWithEncryption(userId: userId) }

            // These don't need encryption yet
            group.addTask { try await self.fetchIncomes(userId: userId) }

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
        income.removeAll()
        bills.removeAll()
        hasUnsyncedChanges = false
        lastSyncDate = nil
    }
    
    // MARK: - Computed Properties
    
    var totalMonthlyIncome: Double {
        getTotalMonthlyIncome()
    }

    var totalMonthlyBills: Double {
        getTotalMonthlyBills()
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
