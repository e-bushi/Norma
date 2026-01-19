//
//  PendingReward.swift
//  Norma
//
//  Created by Claude on 1/18/26.
//

import Foundation

/// Represents a reward stored in the backend pending_rewards table
/// Used for persistence and sync of rewards across sessions
struct PendingReward: Codable, Identifiable {
    let id: UUID
    let userId: String
    let rewardType: String
    let rewardData: PendingRewardData?
    let earnedAt: Date
    var shownAt: Date?
    var dismissedAt: Date?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case rewardType = "reward_type"
        case rewardData = "reward_data"
        case earnedAt = "earned_at"
        case shownAt = "shown_at"
        case dismissedAt = "dismissed_at"
        case createdAt = "created_at"
    }

    /// Create a new pending reward for insertion
    init(
        userId: String,
        rewardType: RewardType,
        rewardData: PendingRewardData? = nil
    ) {
        self.id = UUID()
        self.userId = userId
        self.rewardType = rewardType.rawValue
        self.rewardData = rewardData
        self.earnedAt = Date()
        self.shownAt = nil
        self.dismissedAt = nil
        self.createdAt = Date()
    }

    /// Convert to a Reward object for display
    func toReward() -> Reward? {
        guard let type = RewardType(rawValue: rewardType) else { return nil }

        switch type {
        case .arcEarned:
            guard let data = rewardData,
                  let arcCount = data.arcCount,
                  let previousArcCount = data.previousArcCount else { return nil }
            let coinTier = data.coinTierRaw.flatMap { CoinTier(rawValue: $0) } ?? .starter
            return .arcEarned(newArcCount: arcCount, previousArcCount: previousArcCount, coinTier: coinTier)

        case .challengeStreakExtended:
            guard let data = rewardData, let streak = data.streakCount else { return nil }
            return .streakExtended(newStreak: streak)

        case .firstChallengeCompleted:
            let points = rewardData?.pointsEarned ?? 0
            return .firstChallengeCompleted(pointsEarned: points)

        case .challengeBeaten:
            guard let data = rewardData else { return nil }
            let points = data.pointsEarned ?? 0
            let difficulty = data.difficulty ?? "Normal"
            return .challengeBeaten(pointsEarned: points, difficulty: difficulty)

        case .birdUnlocked:
            guard let data = rewardData,
                  let tierRaw = data.birdTierRaw,
                  let tier = ChallengeTier(rawValue: tierRaw) else { return nil }
            let points = data.pointsEarned ?? 0
            return .birdUnlocked(tier: tier, totalPoints: points)

        case .firstChallengeStarted:
            return .firstChallengeStarted()

        case .firstPendingTransactionConfirmed:
            return .firstPendingConfirmed(merchant: rewardData?.transactionMerchant)

        case .firstBillAddedViaChat:
            let billName = rewardData?.billName ?? "Bill"
            return .firstBillViaChat(billName: billName)

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
        }
    }
}

/// Data payload for pending rewards - stores metadata needed to reconstruct the Reward
struct PendingRewardData: Codable {
    var arcCount: Int?
    var previousArcCount: Int?
    var streakCount: Int?
    var pointsEarned: Int?
    var birdTierRaw: Int?
    var coinTierRaw: String?
    var challengeAmount: Double?
    var billName: String?
    var transactionMerchant: String?
    var difficulty: String?

    enum CodingKeys: String, CodingKey {
        case arcCount = "arc_count"
        case previousArcCount = "previous_arc_count"
        case streakCount = "streak_count"
        case pointsEarned = "points_earned"
        case birdTierRaw = "bird_tier"
        case coinTierRaw = "coin_tier"
        case challengeAmount = "challenge_amount"
        case billName = "bill_name"
        case transactionMerchant = "transaction_merchant"
        case difficulty
    }

    init(
        arcCount: Int? = nil,
        previousArcCount: Int? = nil,
        streakCount: Int? = nil,
        pointsEarned: Int? = nil,
        birdTier: ChallengeTier? = nil,
        coinTier: CoinTier? = nil,
        challengeAmount: Double? = nil,
        billName: String? = nil,
        transactionMerchant: String? = nil,
        difficulty: String? = nil
    ) {
        self.arcCount = arcCount
        self.previousArcCount = previousArcCount
        self.streakCount = streakCount
        self.pointsEarned = pointsEarned
        self.birdTierRaw = birdTier?.rawValue
        self.coinTierRaw = coinTier?.rawValue
        self.challengeAmount = challengeAmount
        self.billName = billName
        self.transactionMerchant = transactionMerchant
        self.difficulty = difficulty
    }
}

// MARK: - Factory Methods for Creating PendingReward from Reward

extension PendingReward {

    /// Create a PendingReward from a Reward object
    static func from(reward: Reward, userId: String) -> PendingReward {
        var data: PendingRewardData?

        if let metadata = reward.metadata {
            data = PendingRewardData(
                arcCount: metadata.arcCount,
                previousArcCount: nil, // We'll set this separately for arc rewards
                streakCount: metadata.streakCount,
                pointsEarned: metadata.pointsEarned,
                birdTier: metadata.birdTier,
                coinTier: metadata.coinTier,
                challengeAmount: metadata.challengeAmount,
                billName: metadata.billName,
                transactionMerchant: metadata.transactionMerchant,
                difficulty: metadata.difficulty
            )
        }

        return PendingReward(
            userId: userId,
            rewardType: reward.type,
            rewardData: data
        )
    }

    /// Create a PendingReward for arc earned
    static func arcEarned(
        userId: String,
        newArcCount: Int,
        previousArcCount: Int,
        coinTier: CoinTier
    ) -> PendingReward {
        let data = PendingRewardData(
            arcCount: newArcCount,
            previousArcCount: previousArcCount,
            coinTier: coinTier
        )
        return PendingReward(userId: userId, rewardType: .arcEarned, rewardData: data)
    }

    /// Create a PendingReward for streak extended
    static func streakExtended(userId: String, newStreak: Int) -> PendingReward {
        let data = PendingRewardData(streakCount: newStreak)
        return PendingReward(userId: userId, rewardType: .challengeStreakExtended, rewardData: data)
    }

    /// Create a PendingReward for challenge beaten
    static func challengeBeaten(userId: String, pointsEarned: Int, difficulty: String) -> PendingReward {
        let data = PendingRewardData(pointsEarned: pointsEarned, difficulty: difficulty)
        return PendingReward(userId: userId, rewardType: .challengeBeaten, rewardData: data)
    }

    /// Create a PendingReward for first challenge completed
    static func firstChallengeCompleted(userId: String, pointsEarned: Int) -> PendingReward {
        let data = PendingRewardData(pointsEarned: pointsEarned)
        return PendingReward(userId: userId, rewardType: .firstChallengeCompleted, rewardData: data)
    }

    /// Create a PendingReward for bird unlocked
    static func birdUnlocked(userId: String, tier: ChallengeTier, totalPoints: Int) -> PendingReward {
        let data = PendingRewardData(pointsEarned: totalPoints, birdTier: tier)
        return PendingReward(userId: userId, rewardType: .birdUnlocked, rewardData: data)
    }

    /// Create a PendingReward for streak milestones
    static func streakMilestone(userId: String, type: RewardType) -> PendingReward {
        return PendingReward(userId: userId, rewardType: type, rewardData: nil)
    }
}
