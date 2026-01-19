//
//  Reward.swift
//  Norma
//
//  Created by Claude on 12/31/25.
//

import Foundation
import SwiftUI

/// Represents all possible reward types in the Norma app
enum RewardType: String, Codable, CaseIterable {
    // Arc Rewards
    case arcEarned

    // Challenge Rewards
    case challengeStreakExtended
    case firstChallengeCompleted
    case challengeBeaten
    case birdUnlocked
    case firstChallengeStarted

    // Streak Milestone Rewards (one-time)
    case streak5Days
    case streak10Days
    case streak25Days
    case streak50Days
    case streak100Days

    // Transaction Rewards
    case firstPendingTransactionConfirmed

    // Bill Rewards
    case firstBillAddedViaChat

    /// Whether this reward type is a one-time milestone (stored in database)
    var isOneTimeMilestone: Bool {
        switch self {
        case .firstChallengeCompleted,
             .firstChallengeStarted,
             .firstPendingTransactionConfirmed,
             .firstBillAddedViaChat,
             .streak5Days,
             .streak10Days,
             .streak25Days,
             .streak50Days,
             .streak100Days:
            return true
        case .arcEarned, .challengeStreakExtended, .challengeBeaten, .birdUnlocked:
            return false
        }
    }
}

/// Icon display type for rewards
enum RewardIconType {
    case sfSymbol(name: String)
    case tierBird(tier: ChallengeTier)
    case coin(tier: CoinTier)
}

/// Stat to display in celebration (reuses MiniStatPill pattern)
struct RewardStat: Identifiable {
    let id = UUID()
    let icon: String
    let value: String
    let label: String
    let color: Color
}

/// Optional metadata for reward context
struct RewardMetadata: Equatable {
    var arcCount: Int?
    var streakCount: Int?
    var pointsEarned: Int?
    var birdTier: ChallengeTier?
    var coinTier: CoinTier?
    var challengeAmount: Double?
    var billName: String?
    var transactionMerchant: String?
    var difficulty: String?
}

/// Configuration for a reward celebration
struct Reward: Identifiable, Equatable {
    let id: UUID
    let type: RewardType
    let title: String
    let subtitle: String
    let iconType: RewardIconType
    let accentColor: Color
    let stats: [RewardStat]
    let timestamp: Date
    let metadata: RewardMetadata?

    init(
        type: RewardType,
        title: String,
        subtitle: String,
        iconType: RewardIconType,
        accentColor: Color,
        stats: [RewardStat] = [],
        metadata: RewardMetadata? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.iconType = iconType
        self.accentColor = accentColor
        self.stats = stats
        self.timestamp = Date()
        self.metadata = metadata
    }

    static func == (lhs: Reward, rhs: Reward) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Factory Methods

extension Reward {

    /// Arc earned reward - shows when user earns a new arc
    static func arcEarned(newArcCount: Int, previousArcCount: Int, coinTier: CoinTier) -> Reward {
        let arcsGained = newArcCount - previousArcCount
        return Reward(
            type: .arcEarned,
            title: "New Arc Earned!",
            subtitle: "You now have \(newArcCount) arc\(newArcCount == 1 ? "" : "s") of financial freedom",
            iconType: .coin(tier: coinTier),
            accentColor: coinTier.glowColor,
            stats: [
                RewardStat(
                    icon: "plus.circle.fill",
                    value: "+\(arcsGained)",
                    label: arcsGained == 1 ? "Arc" : "Arcs",
                    color: coinTier.glowColor
                ),
                RewardStat(
                    icon: "circle.hexagonpath",
                    value: "\(newArcCount)",
                    label: "Total",
                    color: Color("NormaPastelTeal")
                )
            ],
            metadata: RewardMetadata(arcCount: newArcCount, coinTier: coinTier)
        )
    }

    /// Challenge streak extended - shows when user extends their daily streak
    static func streakExtended(newStreak: Int) -> Reward {
        return Reward(
            type: .challengeStreakExtended,
            title: "Streak Extended!",
            subtitle: "You're on a \(newStreak) day streak.\nKeep it going!",
            iconType: .sfSymbol(name: "flame.fill"),
            accentColor: Color("NormaPastelCoral"),
            stats: [
                RewardStat(
                    icon: "flame.fill",
                    value: "\(newStreak)",
                    label: "Day Streak",
                    color: Color("NormaPastelCoral")
                )
            ],
            metadata: RewardMetadata(streakCount: newStreak)
        )
    }

    /// First challenge completed - one-time milestone
    static func firstChallengeCompleted(pointsEarned: Int) -> Reward {
        return Reward(
            type: .firstChallengeCompleted,
            title: "First Challenge Complete!",
            subtitle: "You're officially a Norma challenger",
            iconType: .sfSymbol(name: "trophy.fill"),
            accentColor: Color("NormaPastelTeal"),
            stats: [
                RewardStat(
                    icon: "star.fill",
                    value: "+\(pointsEarned)",
                    label: "Points",
                    color: Color("NormaPastelTeal")
                )
            ],
            metadata: RewardMetadata(pointsEarned: pointsEarned)
        )
    }

    /// Beat the challenge - shows for every successful challenge completion
    static func challengeBeaten(pointsEarned: Int, difficulty: String) -> Reward {
        return Reward(
            type: .challengeBeaten,
            title: "Challenge Complete!",
            subtitle: "You stayed within budget on \(difficulty) difficulty",
            iconType: .sfSymbol(name: "checkmark.seal.fill"),
            accentColor: Color("NormaPastelTeal"),
            stats: [
                RewardStat(
                    icon: "star.fill",
                    value: "+\(pointsEarned)",
                    label: "Points",
                    color: Color("NormaPastelTeal")
                )
            ],
            metadata: RewardMetadata(pointsEarned: pointsEarned, difficulty: difficulty)
        )
    }

    /// Bird (tier) unlocked - shows when user reaches a new tier
    static func birdUnlocked(tier: ChallengeTier, totalPoints: Int) -> Reward {
        return Reward(
            type: .birdUnlocked,
            title: "\(tier.displayName) Unlocked!",
            subtitle: "New tier reached - check your collection",
            iconType: .tierBird(tier: tier),
            accentColor: tier.glowColor,
            stats: [
                RewardStat(
                    icon: "bird.fill",
                    value: "Tier \(tier.rawValue + 1)",
                    label: tier.displayName,
                    color: tier.glowColor
                ),
                RewardStat(
                    icon: "star.fill",
                    value: "\(totalPoints)",
                    label: "Points",
                    color: Color("NormaPastelTeal")
                )
            ],
            metadata: RewardMetadata(pointsEarned: totalPoints, birdTier: tier)
        )
    }

    /// First pending transaction confirmed - one-time milestone
    static func firstPendingConfirmed(merchant: String?) -> Reward {
        return Reward(
            type: .firstPendingTransactionConfirmed,
            title: "First Transaction Confirmed!",
            subtitle: merchant != nil ? "From \(merchant!)" : "Share Extension is working",
            iconType: .sfSymbol(name: "checkmark.circle.fill"),
            accentColor: Color("NormaPastelTeal"),
            metadata: RewardMetadata(transactionMerchant: merchant)
        )
    }

    /// First bill added via chat - one-time milestone
    static func firstBillViaChat(billName: String) -> Reward {
        return Reward(
            type: .firstBillAddedViaChat,
            title: "First Bill Added!",
            subtitle: "You used Norma chat to add \"\(billName)\"",
            iconType: .sfSymbol(name: "text.bubble.fill"),
            accentColor: Color("NormaPastelTeal"),
            metadata: RewardMetadata(billName: billName)
        )
    }

    /// First challenge started - one-time milestone
    static func firstChallengeStarted() -> Reward {
        return Reward(
            type: .firstChallengeStarted,
            title: "Challenge Accepted!",
            subtitle: "Your spending challenge journey begins",
            iconType: .sfSymbol(name: "flag.fill"),
            accentColor: Color("NormaPastelCoral")
        )
    }

    // MARK: - Streak Milestone Factory Methods

    /// 5 day streak milestone
    static func streak5Days() -> Reward {
        return Reward(
            type: .streak5Days,
            title: "5 Day Streak!",
            subtitle: "You're building momentum.\nKeep it up!",
            iconType: .sfSymbol(name: "flame.fill"),
            accentColor: Color("NormaPastelCoral"),
            stats: [
                RewardStat(
                    icon: "flame.fill",
                    value: "5",
                    label: "Days",
                    color: Color("NormaPastelCoral")
                )
            ],
            metadata: RewardMetadata(streakCount: 5)
        )
    }

    /// 10 day streak milestone
    static func streak10Days() -> Reward {
        return Reward(
            type: .streak10Days,
            title: "10 Day Streak!",
            subtitle: "A week and a half of discipline.\nYou're on fire!",
            iconType: .sfSymbol(name: "flame.fill"),
            accentColor: Color("NormaPastelCoral"),
            stats: [
                RewardStat(
                    icon: "flame.fill",
                    value: "10",
                    label: "Days",
                    color: Color("NormaPastelCoral")
                )
            ],
            metadata: RewardMetadata(streakCount: 10)
        )
    }

    /// 25 day streak milestone - shows ember bird
    static func streak25Days() -> Reward {
        return Reward(
            type: .streak25Days,
            title: "25 Day Streak!",
            subtitle: "Nearly a month of staying under cap.\nIncredible!",
            iconType: .tierBird(tier: .ember),
            accentColor: ChallengeTier.ember.glowColor,
            stats: [
                RewardStat(
                    icon: "flame.fill",
                    value: "25",
                    label: "Days",
                    color: ChallengeTier.ember.glowColor
                )
            ],
            metadata: RewardMetadata(streakCount: 25)
        )
    }

    /// 50 day streak milestone - shows blaze bird
    static func streak50Days() -> Reward {
        return Reward(
            type: .streak50Days,
            title: "50 Day Streak!",
            subtitle: "Half a hundred days of control.\nYou're unstoppable!",
            iconType: .tierBird(tier: .blaze),
            accentColor: Color("NormaPastelTeal"),
            stats: [
                RewardStat(
                    icon: "flame.fill",
                    value: "50",
                    label: "Days",
                    color: Color("NormaPastelTeal")
                )
            ],
            metadata: RewardMetadata(streakCount: 50)
        )
    }

    /// 100 day streak milestone - shows phoenix bird with gold accent
    static func streak100Days() -> Reward {
        return Reward(
            type: .streak100Days,
            title: "100 Day Streak!",
            subtitle: "A hundred days of financial discipline.\nYou've mastered your spending!",
            iconType: .tierBird(tier: .phoenix),
            accentColor: Color(red: 1.0, green: 0.84, blue: 0.0),
            stats: [
                RewardStat(
                    icon: "flame.fill",
                    value: "100",
                    label: "Days",
                    color: Color(red: 1.0, green: 0.84, blue: 0.0)
                )
            ],
            metadata: RewardMetadata(streakCount: 100)
        )
    }
}
