//
//  SupabaseService+ChallengeStats.swift
//  Norma
//
//  Created by Claude on 12/30/25.
//

import Foundation
import Supabase

extension SupabaseService {

    // MARK: - Challenge Stats Methods

    /// Fetch challenge stats for a user
    func fetchChallengeStats(userId: String) async throws -> ChallengeStats? {
        let response: [ChallengeStats] = try await from("challenge_stats")
            .select()
            .eq("user_id", value: userId)
            .limit(1)
            .execute()
            .value

        return response.first
    }

    /// Create or update challenge stats (upsert)
    func upsertChallengeStats(_ stats: ChallengeStats) async throws -> ChallengeStats {
        let response: ChallengeStats = try await from("challenge_stats")
            .upsert(stats, onConflict: "user_id")
            .select()
            .single()
            .execute()
            .value

        return response
    }

    /// Create new challenge stats for a user
    func createChallengeStats(_ stats: ChallengeStats) async throws -> ChallengeStats {
        let response: ChallengeStats = try await from("challenge_stats")
            .insert(stats)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    /// Update existing challenge stats
    func updateChallengeStats(_ stats: ChallengeStats) async throws -> ChallengeStats {
        let response: ChallengeStats = try await from("challenge_stats")
            .update(stats)
            .eq("user_id", value: stats.userId)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    /// Initialize stats for a new user (creates with default values)
    func initializeChallengeStats(userId: String) async throws -> ChallengeStats {
        let newStats = ChallengeStats(userId: userId)
        return try await createChallengeStats(newStats)
    }
}
