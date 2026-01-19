//
//  SupabaseService+UserRewards.swift
//  Norma
//
//  Created by Claude on 12/31/25.
//

import Foundation
import Supabase

extension SupabaseService {

    // MARK: - User Rewards Methods

    /// Fetch all rewards for a user (one-time milestones)
    func fetchUserRewards(userId: String) async throws -> [UserReward] {
        let response: [UserReward] = try await from("user_rewards")
            .select()
            .eq("user_id", value: userId)
            .order("earned_at", ascending: false)
            .execute()
            .value

        return response
    }

    /// Check if a specific reward type has been earned
    func hasUserReward(userId: String, rewardType: String) async throws -> Bool {
        let response: [UserReward] = try await from("user_rewards")
            .select()
            .eq("user_id", value: userId)
            .eq("reward_type", value: rewardType)
            .limit(1)
            .execute()
            .value

        return !response.isEmpty
    }

    /// Insert a new user reward (milestone achievement)
    func insertUserReward(_ reward: UserReward) async throws -> UserReward {
        let response: UserReward = try await from("user_rewards")
            .insert(reward)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    /// Delete a user reward (for testing/admin purposes)
    func deleteUserReward(_ rewardId: String) async throws {
        try await from("user_rewards")
            .delete()
            .eq("id", value: rewardId)
            .execute()
    }
}
