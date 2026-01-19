//
//  CachedChallenge.swift
//  Norma
//
//  Created by Claude on 12/22/25.
//

import Foundation
import SwiftData

@Model
final class CachedChallenge {
    @Attribute(.unique) var id: String
    var userId: String
    var amountTotal: Double
    var amountRemaining: Double
    var currency: String
    var startDate: Date
    var endDate: Date
    var status: String
    var difficulty: String = "medium"
    var pointsEarned: Int = 0
    var createdAt: Date
    var updatedAt: Date

    // Sync metadata
    var lastSyncedAt: Date
    var isFromCache: Bool = true

    init(
        id: String,
        userId: String,
        amountTotal: Double,
        amountRemaining: Double,
        currency: String = "USD",
        startDate: Date,
        endDate: Date,
        status: String = "active",
        difficulty: String = "medium",
        pointsEarned: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastSyncedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.amountTotal = amountTotal
        self.amountRemaining = amountRemaining
        self.currency = currency
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.difficulty = difficulty
        self.pointsEarned = pointsEarned
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastSyncedAt = lastSyncedAt
    }

    // Convert from Supabase Challenge model
    convenience init(from challenge: Challenge) {
        let formatter = ISO8601DateFormatter()
        let createdDate = challenge.createdAt.flatMap { formatter.date(from: $0) } ?? Date()
        let updatedDate = challenge.updatedAt.flatMap { formatter.date(from: $0) } ?? Date()

        self.init(
            id: challenge.id ?? UUID().uuidString,
            userId: challenge.userId,
            amountTotal: challenge.amountTotal,
            amountRemaining: challenge.amountRemaining,
            currency: challenge.currency,
            startDate: challenge.startDate,
            endDate: challenge.endDate,
            status: challenge.status.rawValue,
            difficulty: challenge.difficulty.rawValue,
            pointsEarned: challenge.pointsEarned,
            createdAt: createdDate,
            updatedAt: updatedDate,
            lastSyncedAt: Date()
        )
    }

    // Convert to Supabase Challenge model
    func toChallenge() -> Challenge {
        let formatter = ISO8601DateFormatter()

        return Challenge(
            id: id,
            userId: userId,
            amountTotal: amountTotal,
            amountRemaining: amountRemaining,
            currency: currency,
            startDate: startDate,
            endDate: endDate,
            status: ChallengeStatus(rawValue: status) ?? .active,
            difficulty: ChallengeDifficulty(rawValue: difficulty) ?? .medium,
            pointsEarned: pointsEarned,
            createdAt: formatter.string(from: createdAt),
            updatedAt: formatter.string(from: updatedAt)
        )
    }
}
