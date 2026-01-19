//
//  CoinTierService.swift
//  Norma
//
//  Created by Claude on 12/29/25.
//

import Foundation

/// Service for determining coin tier based on arc count
struct CoinTierService {

    /// Returns the highest unlocked coin tier for a given arc count
    /// - Parameter arcCount: The user's current arc count
    /// - Returns: The highest CoinTier the user has unlocked
    static func currentCoinTier(for arcCount: Int) -> CoinTier {
        // Find the highest tier where requiredArcs <= arcCount
        let unlockedTiers = CoinTier.allTiersInOrder.filter { $0.requiredArcs <= arcCount }
        return unlockedTiers.last ?? .starter
    }

    /// Returns the file name for the current coin tier
    /// - Parameter arcCount: The user's current arc count
    /// - Returns: The USDZ file name (without extension)
    static func currentCoinFileName(for arcCount: Int) -> String {
        currentCoinTier(for: arcCount).fileName
    }

    /// Checks if a specific coin tier is unlocked
    /// - Parameters:
    ///   - tier: The tier to check
    ///   - arcCount: The user's current arc count
    /// - Returns: True if the tier is unlocked
    static func isTierUnlocked(_ tier: CoinTier, for arcCount: Int) -> Bool {
        tier.requiredArcs <= arcCount
    }

    /// Returns all unlocked tiers for a given arc count
    /// - Parameter arcCount: The user's current arc count
    /// - Returns: Array of unlocked CoinTiers in order
    static func unlockedTiers(for arcCount: Int) -> [CoinTier] {
        CoinTier.allTiersInOrder.filter { $0.requiredArcs <= arcCount }
    }

    /// Returns the next tier to unlock (if any)
    /// - Parameter arcCount: The user's current arc count
    /// - Returns: The next CoinTier to unlock, or nil if all are unlocked
    static func nextTierToUnlock(for arcCount: Int) -> CoinTier? {
        CoinTier.allTiersInOrder.first { $0.requiredArcs > arcCount }
    }

    /// Returns the number of arcs needed to unlock the next tier
    /// - Parameter arcCount: The user's current arc count
    /// - Returns: Number of arcs needed, or 0 if all tiers are unlocked
    static func arcsToNextTier(for arcCount: Int) -> Int {
        guard let nextTier = nextTierToUnlock(for: arcCount) else {
            return 0 // All tiers unlocked
        }
        return nextTier.requiredArcs - arcCount
    }
}
