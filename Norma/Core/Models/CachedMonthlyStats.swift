//
//  CachedMonthlyStats.swift
//  Norma
//
//  Created by Claude on 12/31/25.
//

import Foundation
import SwiftData

@Model
final class CachedMonthlyStats {
    @Attribute(.unique) var id: String
    var userId: String
    var month: Int
    var year: Int
    var totalSpent: Double
    var arcsAdded: Int
    var challengesCompleted: Int
    var fundsLeftOver: Double
    var createdAt: Date
    var updatedAt: Date

    // Sync metadata
    var lastSyncedAt: Date
    var isFromCache: Bool = true

    init(
        id: String,
        userId: String,
        month: Int,
        year: Int,
        totalSpent: Double = 0,
        arcsAdded: Int = 0,
        challengesCompleted: Int = 0,
        fundsLeftOver: Double = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastSyncedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.month = month
        self.year = year
        self.totalSpent = totalSpent
        self.arcsAdded = arcsAdded
        self.challengesCompleted = challengesCompleted
        self.fundsLeftOver = fundsLeftOver
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastSyncedAt = lastSyncedAt
    }

    // Convert from Supabase MonthlyStats model
    convenience init(from stats: MonthlyStats) {
        let formatter = ISO8601DateFormatter()
        let createdDate = stats.createdAt.flatMap { formatter.date(from: $0) } ?? Date()
        let updatedDate = stats.updatedAt.flatMap { formatter.date(from: $0) } ?? Date()

        self.init(
            id: stats.id ?? UUID().uuidString,
            userId: stats.userId,
            month: stats.month,
            year: stats.year,
            totalSpent: stats.totalSpent,
            arcsAdded: stats.arcsAdded,
            challengesCompleted: stats.challengesCompleted,
            fundsLeftOver: stats.fundsLeftOver,
            createdAt: createdDate,
            updatedAt: updatedDate,
            lastSyncedAt: Date()
        )
    }

    // Convert to Supabase MonthlyStats model
    func toMonthlyStats() -> MonthlyStats {
        let formatter = ISO8601DateFormatter()

        return MonthlyStats(
            id: id,
            userId: userId,
            month: month,
            year: year,
            totalSpent: totalSpent,
            arcsAdded: arcsAdded,
            challengesCompleted: challengesCompleted,
            fundsLeftOver: fundsLeftOver,
            createdAt: formatter.string(from: createdAt),
            updatedAt: formatter.string(from: updatedAt)
        )
    }
}
