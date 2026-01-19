//
//  DataManager+UserRewards.swift
//  Norma
//
//  Created by Claude on 12/31/25.
//

import Foundation
import SwiftData

extension DataManager {

    // MARK: - User Rewards Methods

    /// Fetch all rewards for a user from Supabase
    func fetchUserRewards(for userId: String) async throws -> [UserReward] {
        do {
            // Try to fetch from Supabase first
            let fetchedRewards = try await supabaseService.fetchUserRewards(userId: userId)

            // Cache rewards in SwiftData
            await cacheUserRewards(fetchedRewards)

            print("Fetched \(fetchedRewards.count) user rewards from server")
            return fetchedRewards
        } catch {
            // If fetch fails (offline), load from cache
            print("Failed to fetch user rewards from server: \(error). Loading from cache...")

            let cachedRewards = await loadCachedUserRewards(for: userId)
            return cachedRewards.map { $0.toUserReward() }
        }
    }

    /// Save a new user reward to Supabase
    func saveUserReward(_ reward: UserReward) async throws {
        do {
            // Save to Supabase
            let savedReward = try await supabaseService.insertUserReward(reward)

            // Cache the reward locally
            await cacheUserRewards([savedReward])

            print("Saved user reward: \(savedReward.rewardType)")
        } catch {
            print("Failed to save user reward to server: \(error)")

            // Cache locally for offline mode
            var rewardToCache = reward
            if rewardToCache.id == nil {
                rewardToCache = UserReward(
                    id: UUID().uuidString,
                    userId: reward.userId,
                    rewardType: reward.rewardType,
                    earnedAt: reward.earnedAt,
                    metadata: reward.metadata
                )
            }

            await cacheUserRewards([rewardToCache])
            hasUnsyncedChanges = true

            throw error
        }
    }

    /// Check if user has a specific milestone reward
    func hasUserReward(userId: String, type: RewardType) async throws -> Bool {
        return try await supabaseService.hasUserReward(userId: userId, rewardType: type.rawValue)
    }

    // MARK: - SwiftData Caching

    private func cacheUserRewards(_ rewardsToCache: [UserReward]) async {
        guard let modelContext = modelContext else { return }

        do {
            for reward in rewardsToCache {
                // Check if already cached
                guard let rewardId = reward.id else { continue }

                let descriptor = FetchDescriptor<CachedUserReward>(
                    predicate: #Predicate { cached in
                        cached.id == rewardId
                    }
                )

                let existing = try modelContext.fetch(descriptor)
                if existing.isEmpty {
                    // Only insert if not already cached
                    let cachedReward = CachedUserReward(from: reward)
                    modelContext.insert(cachedReward)
                }
            }

            try modelContext.save()
            print("Successfully cached \(rewardsToCache.count) user rewards")
        } catch {
            print("Failed to cache user rewards: \(error)")
        }
    }

    private func loadCachedUserRewards(for userId: String) async -> [CachedUserReward] {
        guard let modelContext = modelContext else { return [] }

        do {
            let descriptor = FetchDescriptor<CachedUserReward>(
                predicate: #Predicate { cached in
                    cached.userId == userId
                }
            )

            let cachedRewards = try modelContext.fetch(descriptor)
            print("Loaded \(cachedRewards.count) user rewards from cache")
            return cachedRewards
        } catch {
            print("Failed to load cached user rewards: \(error)")
            return []
        }
    }
}
