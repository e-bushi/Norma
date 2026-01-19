//
//  DataManager+ChallengeStats.swift
//  Norma
//
//  Created by Claude on 12/30/25.
//

import Foundation

extension DataManager {

    // MARK: - Challenge Stats Methods

    /// Fetch challenge stats for the current user
    func fetchChallengeStats(userId: String) async throws -> ChallengeStats? {
        do {
            // Try to fetch from Supabase
            if let stats = try await supabaseService.fetchChallengeStats(userId: userId) {
                print("Fetched challenge stats from server - Points: \(stats.totalPoints), Streak: \(stats.currentStreak)")
                return stats
            } else {
                // No stats exist yet, create initial stats
                print("No challenge stats found, creating initial stats for user")
                let newStats = try await supabaseService.initializeChallengeStats(userId: userId)
                return newStats
            }
        } catch {
            print("Failed to fetch challenge stats from server: \(error)")
            throw error
        }
    }

    /// Update challenge stats after completing a challenge
    func updateChallengeStatsOnCompletion(
        userId: String,
        currentStats: ChallengeStats,
        completed: Bool,
        difficulty: ChallengeDifficulty
    ) async throws -> ChallengeStats {
        let updatedStats: ChallengeStats

        if completed {
            updatedStats = currentStats.withChallengeCompleted(difficulty: difficulty)
        } else {
            updatedStats = currentStats.withChallengeFailed()
        }

        do {
            let savedStats = try await supabaseService.upsertChallengeStats(updatedStats)
            print("Updated challenge stats - Points: \(savedStats.totalPoints), Streak: \(savedStats.currentStreak)")
            return savedStats
        } catch {
            print("Failed to update challenge stats: \(error)")
            throw error
        }
    }

    /// Record points earned for a completed challenge
    func awardChallengePoints(
        userId: String,
        currentStats: ChallengeStats,
        difficulty: ChallengeDifficulty
    ) async throws -> (updatedStats: ChallengeStats, pointsEarned: Int, newTierUnlocked: ChallengeTier?) {
        let pointsEarned = currentStats.calculatePointsEarned(for: difficulty)
        let previousTier = currentStats.currentTier

        let updatedStats = currentStats.withChallengeCompleted(difficulty: difficulty)
        let newTier = updatedStats.currentTier

        do {
            let savedStats = try await supabaseService.upsertChallengeStats(updatedStats)

            // Check if a new tier was unlocked
            let tierUnlocked: ChallengeTier? = newTier.rawValue > previousTier.rawValue ? newTier : nil

            if let tier = tierUnlocked {
                print("New tier unlocked: \(tier.displayName)!")
            }

            return (savedStats, pointsEarned, tierUnlocked)
        } catch {
            print("Failed to award challenge points: \(error)")
            throw error
        }
    }

    /// Reset streak after a failed challenge
    func resetChallengeStreak(userId: String, currentStats: ChallengeStats) async throws -> ChallengeStats {
        let updatedStats = currentStats.withChallengeFailed()

        do {
            let savedStats = try await supabaseService.upsertChallengeStats(updatedStats)
            print("Challenge streak reset to 0")
            return savedStats
        } catch {
            print("Failed to reset challenge streak: \(error)")
            throw error
        }
    }

    /// Update challenge stats directly (for daily calculation updates)
    func updateChallengeStats(_ stats: ChallengeStats, userId: String) async throws {
        do {
            _ = try await supabaseService.upsertChallengeStats(stats)
            print("Updated challenge stats - Points: \(stats.totalPoints), Streak: \(stats.currentStreak), DaysUnderCap: \(stats.totalDaysUnderCap)")
        } catch {
            print("Failed to update challenge stats: \(error)")
            throw error
        }
    }
}
