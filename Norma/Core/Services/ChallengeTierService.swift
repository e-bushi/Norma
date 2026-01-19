//
//  ChallengeTierService.swift
//  Norma
//
//  Created by Claude on 12/30/25.
//

import Foundation

/// Service for determining challenge tier based on total points
struct ChallengeTierService {

    /// Returns the highest unlocked challenge tier for a given point count
    /// - Parameter points: The user's total challenge points
    /// - Returns: The highest ChallengeTier the user has unlocked
    static func currentTier(for points: Int) -> ChallengeTier {
        // Find the highest tier where requiredPoints <= points
        let unlockedTiers = ChallengeTier.allTiersInOrder.filter { $0.requiredPoints <= points }
        return unlockedTiers.last ?? .starter
    }

    /// Returns the file name for the current challenge tier's bird
    /// - Parameter points: The user's total challenge points
    /// - Returns: The USDZ file name (without extension)
    static func currentBirdFileName(for points: Int) -> String {
        currentTier(for: points).fileName
    }

    /// Checks if a specific challenge tier is unlocked
    /// - Parameters:
    ///   - tier: The tier to check
    ///   - points: The user's total challenge points
    /// - Returns: True if the tier is unlocked
    static func isTierUnlocked(_ tier: ChallengeTier, for points: Int) -> Bool {
        tier.requiredPoints <= points
    }

    /// Returns all unlocked tiers for a given point count
    /// - Parameter points: The user's total challenge points
    /// - Returns: Array of unlocked ChallengeTiers in order
    static func unlockedTiers(for points: Int) -> [ChallengeTier] {
        ChallengeTier.allTiersInOrder.filter { $0.requiredPoints <= points }
    }

    /// Returns the next tier to unlock (if any)
    /// - Parameter points: The user's total challenge points
    /// - Returns: The next ChallengeTier to unlock, or nil if all are unlocked
    static func nextTierToUnlock(for points: Int) -> ChallengeTier? {
        ChallengeTier.allTiersInOrder.first { $0.requiredPoints > points }
    }

    /// Returns the number of points needed to unlock the next tier
    /// - Parameter points: The user's total challenge points
    /// - Returns: Number of points needed, or 0 if all tiers are unlocked
    static func pointsToNextTier(for points: Int) -> Int {
        guard let nextTier = nextTierToUnlock(for: points) else {
            return 0 // All tiers unlocked
        }
        return nextTier.requiredPoints - points
    }

    /// Returns the progress percentage toward the next tier (0.0 to 1.0)
    /// - Parameter points: The user's total challenge points
    /// - Returns: Progress percentage, or 1.0 if at max tier
    static func progressToNextTier(for points: Int) -> Double {
        let current = currentTier(for: points)
        guard let next = nextTierToUnlock(for: points) else {
            return 1.0 // At max tier
        }

        let pointsInCurrentTier = points - current.requiredPoints
        let pointsNeeded = next.requiredPoints - current.requiredPoints

        guard pointsNeeded > 0 else { return 1.0 }
        return Double(pointsInCurrentTier) / Double(pointsNeeded)
    }

    /// Returns the count of unlocked tiers
    /// - Parameter points: The user's total challenge points
    /// - Returns: Number of tiers unlocked (1-10)
    static func unlockedTierCount(for points: Int) -> Int {
        unlockedTiers(for: points).count
    }
}
