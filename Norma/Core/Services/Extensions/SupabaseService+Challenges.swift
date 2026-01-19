//
//  SupabaseService+Challenges.swift
//  Norma
//
//  Created by Claude on 12/22/25.
//

import Foundation
import Supabase

extension SupabaseService {

    // MARK: - Challenge Methods

    /// Fetch all challenges for a user
    func fetchChallenges(userId: String) async throws -> [Challenge] {
        let response: [Challenge] = try await from("challenges")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value

        return response
    }

    /// Fetch the active challenge for a user (should only be one)
    func fetchActiveChallenge(userId: String) async throws -> Challenge? {
        let response: [Challenge] = try await from("challenges")
            .select()
            .eq("user_id", value: userId)
            .eq("status", value: "active")
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value

        return response.first
    }

    /// Create a new challenge
    func createChallenge(_ challenge: Challenge) async throws -> Challenge {
        let response: Challenge = try await from("challenges")
            .insert(challenge)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    /// Update existing challenge
    func updateChallenge(_ challenge: Challenge) async throws -> Challenge {
        let response: Challenge = try await from("challenges")
            .update(challenge)
            .eq("id", value: challenge.id ?? "")
            .select()
            .single()
            .execute()
            .value

        return response
    }

    /// Delete a challenge
    func deleteChallenge(_ challengeId: String) async throws {
        try await from("challenges")
            .delete()
            .eq("id", value: challengeId)
            .execute()
    }

    /// Mark all active challenges as completed or failed (cleanup before creating new)
    func completeActiveChallenge(userId: String, status: ChallengeStatus) async throws {
        _ = try await from("challenges")
            .update(["status": status.rawValue])
            .eq("user_id", value: userId)
            .eq("status", value: "active")
            .execute()
    }
}
