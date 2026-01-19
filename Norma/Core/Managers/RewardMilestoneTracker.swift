//
//  RewardMilestoneTracker.swift
//  Norma
//
//  Created by Claude on 12/31/25.
//

import Foundation

/// Tracks one-time milestone achievements
/// Syncs with Supabase for persistence across devices
/// Uses in-memory cache for fast lookups during session
@MainActor
class RewardMilestoneTracker: ObservableObject {

    // MARK: - Singleton

    static let shared = RewardMilestoneTracker()

    // MARK: - UserDefaults Keys (for local state only)

    private enum Keys {
        static let prefix = "com.norma.reward."
        static let lastArcCount = "lastArcCount"
    }

    // MARK: - Private Properties

    /// In-memory cache of earned milestones (loaded from Supabase on login)
    private var earnedMilestones: Set<RewardType> = []

    /// Current user ID
    private var currentUserId: String?

    /// Reference to DataManager for Supabase operations
    private weak var dataManager: DataManager?

    /// Whether milestones have been loaded for current user
    private var milestonesLoaded: Bool = false

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Load milestones from Supabase on login
    /// Should be called after user authentication
    func loadMilestones(for userId: String, dataManager: DataManager) async {
        self.currentUserId = userId
        self.dataManager = dataManager
        self.milestonesLoaded = false
        self.earnedMilestones.removeAll()

        do {
            let userRewards = try await dataManager.fetchUserRewards(for: userId)

            // Populate in-memory cache
            for reward in userRewards {
                if let type = RewardType(rawValue: reward.rewardType) {
                    earnedMilestones.insert(type)
                }
            }

            milestonesLoaded = true
            print("RewardMilestoneTracker: Loaded \(earnedMilestones.count) milestones for user")
        } catch {
            print("RewardMilestoneTracker: Failed to load milestones: \(error)")
            // Still mark as loaded so we don't block the app
            milestonesLoaded = true
        }
    }

    /// Check if a milestone has been earned
    func hasMilestone(_ type: RewardType) -> Bool {
        guard type.isOneTimeMilestone else {
            // Non-milestone rewards always return false (they're repeatable)
            return false
        }
        return earnedMilestones.contains(type)
    }

    /// Check if this is a first-time event and mark it if so
    /// Returns true if this was the first time (should show reward)
    /// Returns false if already earned (don't show reward)
    func checkAndMarkFirstTime(_ type: RewardType) async -> Bool {
        guard type.isOneTimeMilestone else {
            // Non-milestone rewards don't need tracking
            return true
        }

        guard let userId = currentUserId else {
            print("RewardMilestoneTracker: No user ID set")
            return false
        }

        // Check in-memory cache first
        if earnedMilestones.contains(type) {
            return false
        }

        // Mark as earned in memory immediately to prevent duplicates
        earnedMilestones.insert(type)

        // Save to Supabase in background
        Task {
            await saveToSupabase(type: type, userId: userId)
        }

        return true
    }

    /// Clear user data on logout
    func clearUser() {
        currentUserId = nil
        dataManager = nil
        earnedMilestones.removeAll()
        milestonesLoaded = false
    }

    // MARK: - Arc Count Tracking (Local Only)

    /// Get the last known arc count (stored locally)
    func getLastArcCount() -> Int {
        guard let userId = currentUserId else { return 0 }
        let key = "\(Keys.prefix)\(userId).\(Keys.lastArcCount)"
        return UserDefaults.standard.integer(forKey: key)
    }

    /// Set the last known arc count (stored locally)
    func setLastArcCount(_ count: Int) {
        guard let userId = currentUserId else { return }
        let key = "\(Keys.prefix)\(userId).\(Keys.lastArcCount)"
        UserDefaults.standard.set(count, forKey: key)
    }

    // MARK: - Streak Milestone Detection

    /// Check if a new streak count triggers a milestone reward
    /// Returns the milestone RewardType if one was just crossed, nil otherwise
    /// - Parameters:
    ///   - newStreak: The new streak count after update
    ///   - previousStreak: The previous streak count before update
    /// - Returns: The milestone type if threshold was just crossed, nil otherwise
    static func getStreakMilestone(for newStreak: Int, previousStreak: Int) -> RewardType? {
        // Check each milestone threshold
        // Only trigger if we just crossed the threshold (previous < threshold <= new)
        if previousStreak < 5 && newStreak >= 5 {
            return .streak5Days
        } else if previousStreak < 10 && newStreak >= 10 {
            return .streak10Days
        } else if previousStreak < 25 && newStreak >= 25 {
            return .streak25Days
        } else if previousStreak < 50 && newStreak >= 50 {
            return .streak50Days
        } else if previousStreak < 100 && newStreak >= 100 {
            return .streak100Days
        }
        return nil
    }

    /// Get the Reward object for a streak milestone type
    /// - Parameter type: The streak milestone RewardType
    /// - Returns: The corresponding Reward object, or nil if not a streak milestone
    static func getStreakMilestoneReward(for type: RewardType) -> Reward? {
        switch type {
        case .streak5Days:
            return .streak5Days()
        case .streak10Days:
            return .streak10Days()
        case .streak25Days:
            return .streak25Days()
        case .streak50Days:
            return .streak50Days()
        case .streak100Days:
            return .streak100Days()
        default:
            return nil
        }
    }

    // MARK: - Private Methods

    private func saveToSupabase(type: RewardType, userId: String) async {
        guard let dataManager = dataManager else {
            print("RewardMilestoneTracker: DataManager not available")
            return
        }

        let userReward = UserReward(
            userId: userId,
            type: type
        )

        do {
            try await dataManager.saveUserReward(userReward)
            print("RewardMilestoneTracker: Saved milestone '\(type.rawValue)' to Supabase")
        } catch {
            print("RewardMilestoneTracker: Failed to save milestone to Supabase: \(error)")
            // Milestone is still in memory, will be synced on next load
        }
    }

    // MARK: - Debug/Testing

    /// Reset all milestones for testing (removes from memory only)
    func resetAllMilestones() {
        earnedMilestones.removeAll()
    }

    /// Check if milestones have been loaded
    var isLoaded: Bool {
        milestonesLoaded
    }
}
