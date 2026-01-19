//
//  CachedUserReward.swift
//  Norma
//
//  Created by Claude on 12/31/25.
//

import Foundation
import SwiftData

@Model
final class CachedUserReward {
    @Attribute(.unique) var id: String
    var userId: String
    var rewardType: String
    var earnedAt: Date
    var metadataJSON: String?

    // Sync metadata
    var lastSyncedAt: Date
    var isFromCache: Bool = true

    init(
        id: String,
        userId: String,
        rewardType: String,
        earnedAt: Date = Date(),
        metadataJSON: String? = nil,
        lastSyncedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.rewardType = rewardType
        self.earnedAt = earnedAt
        self.metadataJSON = metadataJSON
        self.lastSyncedAt = lastSyncedAt
    }

    // Convert from Supabase UserReward model
    convenience init(from userReward: UserReward) {
        var metadataString: String? = nil
        if let metadata = userReward.metadata {
            if let jsonData = try? JSONEncoder().encode(metadata) {
                metadataString = String(data: jsonData, encoding: .utf8)
            }
        }

        self.init(
            id: userReward.id ?? UUID().uuidString,
            userId: userReward.userId,
            rewardType: userReward.rewardType,
            earnedAt: userReward.earnedAt,
            metadataJSON: metadataString,
            lastSyncedAt: Date()
        )
    }

    // Convert to Supabase UserReward model
    func toUserReward() -> UserReward {
        var metadata: [String: String]? = nil
        if let metadataJSON = metadataJSON,
           let jsonData = metadataJSON.data(using: .utf8) {
            metadata = try? JSONDecoder().decode([String: String].self, from: jsonData)
        }

        return UserReward(
            id: id,
            userId: userId,
            rewardType: rewardType,
            earnedAt: earnedAt,
            metadata: metadata
        )
    }

    /// Convert rewardType string to RewardType enum
    var type: RewardType? {
        RewardType(rawValue: rewardType)
    }
}
