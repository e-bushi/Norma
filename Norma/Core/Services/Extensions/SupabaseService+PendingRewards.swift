//
//  SupabaseService+PendingRewards.swift
//  Norma
//
//  Created by Claude on 1/18/26.
//

import Foundation
import Supabase

extension SupabaseService {

    // MARK: - Pending Rewards Methods

    /// Fetch all unshown pending rewards for a user
    /// Returns rewards that have been earned but not yet shown to the user
    func fetchUnshownPendingRewards(userId: String) async throws -> [PendingReward] {
        // Fetch all pending rewards and filter client-side for unshown ones
        let allRewards: [PendingReward] = try await from("pending_rewards")
            .select()
            .eq("user_id", value: userId)
            .order("earned_at", ascending: true)
            .execute()
            .value

        // Filter for rewards that haven't been shown yet
        return allRewards.filter { $0.shownAt == nil }
    }

    /// Fetch all pending rewards for a user (shown and unshown)
    func fetchAllPendingRewards(userId: String) async throws -> [PendingReward] {
        let response: [PendingReward] = try await from("pending_rewards")
            .select()
            .eq("user_id", value: userId)
            .order("earned_at", ascending: false)
            .execute()
            .value

        return response
    }

    /// Insert a new pending reward
    func insertPendingReward(_ reward: PendingReward) async throws -> PendingReward {
        let response: PendingReward = try await from("pending_rewards")
            .insert(reward)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    /// Mark a pending reward as shown (presented to user)
    func markPendingRewardAsShown(rewardId: UUID) async throws {
        try await from("pending_rewards")
            .update(["shown_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: rewardId.uuidString)
            .execute()
    }

    /// Mark a pending reward as dismissed (user tapped continue/dismiss)
    func markPendingRewardAsDismissed(rewardId: UUID) async throws {
        try await from("pending_rewards")
            .update(["dismissed_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: rewardId.uuidString)
            .execute()
    }

    /// Mark multiple pending rewards as shown
    func markPendingRewardsAsShown(rewardIds: [UUID]) async throws {
        guard !rewardIds.isEmpty else { return }

        let idsString = rewardIds.map { $0.uuidString }
        try await from("pending_rewards")
            .update(["shown_at": ISO8601DateFormatter().string(from: Date())])
            .in("id", values: idsString)
            .execute()
    }

    /// Delete a pending reward (for cleanup/admin)
    func deletePendingReward(rewardId: UUID) async throws {
        try await from("pending_rewards")
            .delete()
            .eq("id", value: rewardId.uuidString)
            .execute()
    }

    /// Check if a specific pending reward type exists for user (unshown)
    func hasPendingReward(userId: String, rewardType: String) async throws -> Bool {
        // Fetch matching rewards and filter client-side for unshown ones
        let response: [PendingReward] = try await from("pending_rewards")
            .select()
            .eq("user_id", value: userId)
            .eq("reward_type", value: rewardType)
            .execute()
            .value

        // Check if any are unshown
        return response.contains { $0.shownAt == nil }
    }
}
