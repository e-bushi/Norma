//
//  UserReward.swift
//  Norma
//
//  Created by Claude on 12/31/25.
//

import Foundation

/// Represents a one-time milestone reward stored in Supabase
/// Only milestone rewards are persisted (first challenge, first bill, etc.)
struct UserReward: Identifiable, Codable, Equatable {
    var id: String?
    let userId: String
    let rewardType: String
    let earnedAt: Date
    var metadata: [String: String]?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case rewardType = "reward_type"
        case earnedAt = "earned_at"
        case metadata
    }

    init(
        id: String? = nil,
        userId: String,
        rewardType: String,
        earnedAt: Date = Date(),
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.userId = userId
        self.rewardType = rewardType
        self.earnedAt = earnedAt
        self.metadata = metadata
    }

    /// Create from a RewardType enum
    init(userId: String, type: RewardType, metadata: [String: String]? = nil) {
        self.init(
            userId: userId,
            rewardType: type.rawValue,
            earnedAt: Date(),
            metadata: metadata
        )
    }

    // Custom decoding to handle timestamp formats from Supabase
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        rewardType = try container.decode(String.self, forKey: .rewardType)
        metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata)

        // Handle earned_at date
        let earnedAtString = try container.decode(String.self, forKey: .earnedAt)

        // Try ISO8601 with fractional seconds first
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: earnedAtString) {
            self.earnedAt = date
        } else {
            // Try without fractional seconds
            isoFormatter.formatOptions = [.withInternetDateTime]
            if let date = isoFormatter.date(from: earnedAtString) {
                self.earnedAt = date
            } else {
                // Fallback to current date
                self.earnedAt = Date()
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(rewardType, forKey: .rewardType)
        try container.encodeIfPresent(metadata, forKey: .metadata)

        // Encode earned_at as ISO8601
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let earnedAtString = isoFormatter.string(from: earnedAt)
        try container.encode(earnedAtString, forKey: .earnedAt)
    }

    /// Convert rewardType string to RewardType enum
    var type: RewardType? {
        RewardType(rawValue: rewardType)
    }
}
