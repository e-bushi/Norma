//
//  ChallengeStats.swift
//  Norma
//
//  Created by Claude on 12/30/25.
//

import Foundation

/// Tracks a user's overall challenge progress and statistics
struct ChallengeStats: Identifiable, Codable, Equatable {
    var id: String?
    var userId: String
    var totalPoints: Int
    var currentStreak: Int          // Now tracks consecutive DAYS under cap (not challenges)
    var longestStreak: Int
    var totalCompleted: Int
    var totalFailed: Int
    var easyCompleted: Int
    var mediumCompleted: Int
    var hardCompleted: Int
    var totalDaysUnderCap: Int      // Cumulative count of days under cap (never resets)
    var lastCalculatedDate: Date?   // Last day we processed for calculations
    var lastChallengeDate: Date?
    var createdAt: String?
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case totalPoints = "total_points"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case totalCompleted = "total_completed"
        case totalFailed = "total_failed"
        case easyCompleted = "easy_completed"
        case mediumCompleted = "medium_completed"
        case hardCompleted = "hard_completed"
        case totalDaysUnderCap = "total_days_under_cap"
        case lastCalculatedDate = "last_calculated_date"
        case lastChallengeDate = "last_challenge_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Computed Properties

    /// The current tier based on total points
    var currentTier: ChallengeTier {
        ChallengeTier.allTiersInOrder.last { $0.requiredPoints <= totalPoints } ?? .starter
    }

    /// The next tier to unlock, if any
    var nextTier: ChallengeTier? {
        currentTier.nextTier
    }

    /// Points needed to reach the next tier
    var pointsToNextTier: Int {
        guard let next = nextTier else { return 0 }
        return next.requiredPoints - totalPoints
    }

    /// Progress percentage toward the next tier (0.0 to 1.0)
    var progressToNextTier: Double {
        guard let next = nextTier else { return 1.0 } // Already at max tier
        let currentTierPoints = currentTier.requiredPoints
        let pointsInCurrentTier = totalPoints - currentTierPoints
        let pointsNeededForNextTier = next.requiredPoints - currentTierPoints
        guard pointsNeededForNextTier > 0 else { return 1.0 }
        return Double(pointsInCurrentTier) / Double(pointsNeededForNextTier)
    }

    /// Streak multiplier based on current streak
    /// - Streak 0-2: 1x (no bonus)
    /// - Streak 3-6: 1.5x
    /// - Streak 7+: 2x
    var streakMultiplier: Double {
        if currentStreak >= 7 {
            return 2.0
        } else if currentStreak >= 3 {
            return 1.5
        } else {
            return 1.0
        }
    }

    /// Success rate as a percentage (0-100)
    var successRate: Double {
        let total = totalCompleted + totalFailed
        guard total > 0 else { return 0 }
        return (Double(totalCompleted) / Double(total)) * 100
    }

    /// Total number of challenges attempted
    var totalAttempted: Int {
        totalCompleted + totalFailed
    }

    /// Calculate points earned for a challenge at the given difficulty
    /// Applies the streak multiplier
    func calculatePointsEarned(for difficulty: ChallengeDifficulty) -> Int {
        let basePoints = difficulty.pointReward
        let multipliedPoints = Double(basePoints) * streakMultiplier
        return Int(multipliedPoints.rounded())
    }

    // MARK: - Custom Decoding

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        totalPoints = try container.decodeIfPresent(Int.self, forKey: .totalPoints) ?? 0
        currentStreak = try container.decodeIfPresent(Int.self, forKey: .currentStreak) ?? 0
        longestStreak = try container.decodeIfPresent(Int.self, forKey: .longestStreak) ?? 0
        totalCompleted = try container.decodeIfPresent(Int.self, forKey: .totalCompleted) ?? 0
        totalFailed = try container.decodeIfPresent(Int.self, forKey: .totalFailed) ?? 0
        easyCompleted = try container.decodeIfPresent(Int.self, forKey: .easyCompleted) ?? 0
        mediumCompleted = try container.decodeIfPresent(Int.self, forKey: .mediumCompleted) ?? 0
        hardCompleted = try container.decodeIfPresent(Int.self, forKey: .hardCompleted) ?? 0
        totalDaysUnderCap = try container.decodeIfPresent(Int.self, forKey: .totalDaysUnderCap) ?? 0
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)

        // Handle lastCalculatedDate decoding
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        if let dateString = try container.decodeIfPresent(String.self, forKey: .lastCalculatedDate) {
            if let date = dateFormatter.date(from: dateString) {
                self.lastCalculatedDate = date
            } else {
                let isoFormatter = ISO8601DateFormatter()
                self.lastCalculatedDate = isoFormatter.date(from: dateString)
            }
        } else {
            self.lastCalculatedDate = nil
        }

        // Handle lastChallengeDate decoding
        if let dateString = try container.decodeIfPresent(String.self, forKey: .lastChallengeDate) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let date = dateFormatter.date(from: dateString) {
                self.lastChallengeDate = date
            } else {
                // Try ISO8601 as fallback
                let isoFormatter = ISO8601DateFormatter()
                self.lastChallengeDate = isoFormatter.date(from: dateString)
            }
        } else {
            self.lastChallengeDate = nil
        }
    }

    // MARK: - Custom Encoding

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(totalPoints, forKey: .totalPoints)
        try container.encode(currentStreak, forKey: .currentStreak)
        try container.encode(longestStreak, forKey: .longestStreak)
        try container.encode(totalCompleted, forKey: .totalCompleted)
        try container.encode(totalFailed, forKey: .totalFailed)
        try container.encode(easyCompleted, forKey: .easyCompleted)
        try container.encode(mediumCompleted, forKey: .mediumCompleted)
        try container.encode(hardCompleted, forKey: .hardCompleted)
        try container.encode(totalDaysUnderCap, forKey: .totalDaysUnderCap)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        if let date = lastCalculatedDate {
            let dateString = dateFormatter.string(from: date)
            try container.encode(dateString, forKey: .lastCalculatedDate)
        }

        if let date = lastChallengeDate {
            let dateString = dateFormatter.string(from: date)
            try container.encode(dateString, forKey: .lastChallengeDate)
        }
    }

    // MARK: - Initializer

    init(
        id: String? = nil,
        userId: String,
        totalPoints: Int = 0,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        totalCompleted: Int = 0,
        totalFailed: Int = 0,
        easyCompleted: Int = 0,
        mediumCompleted: Int = 0,
        hardCompleted: Int = 0,
        totalDaysUnderCap: Int = 0,
        lastCalculatedDate: Date? = nil,
        lastChallengeDate: Date? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.totalPoints = totalPoints
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.totalCompleted = totalCompleted
        self.totalFailed = totalFailed
        self.easyCompleted = easyCompleted
        self.mediumCompleted = mediumCompleted
        self.hardCompleted = hardCompleted
        self.totalDaysUnderCap = totalDaysUnderCap
        self.lastCalculatedDate = lastCalculatedDate
        self.lastChallengeDate = lastChallengeDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Mutation Helpers

    /// Returns a new ChallengeStats with updated values after completing a challenge
    func withChallengeCompleted(difficulty: ChallengeDifficulty) -> ChallengeStats {
        var updated = self
        let pointsEarned = calculatePointsEarned(for: difficulty)

        updated.totalPoints += pointsEarned
        updated.currentStreak += 1
        updated.totalCompleted += 1
        updated.lastChallengeDate = Date()

        if updated.currentStreak > updated.longestStreak {
            updated.longestStreak = updated.currentStreak
        }

        switch difficulty {
        case .easy:
            updated.easyCompleted += 1
        case .medium:
            updated.mediumCompleted += 1
        case .hard:
            updated.hardCompleted += 1
        }

        return updated
    }

    /// Returns a new ChallengeStats with updated values after failing a challenge
    func withChallengeFailed() -> ChallengeStats {
        var updated = self
        updated.currentStreak = 0
        updated.totalFailed += 1
        updated.lastChallengeDate = Date()
        return updated
    }
}
