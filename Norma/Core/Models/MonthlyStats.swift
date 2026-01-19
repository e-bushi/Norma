//
//  MonthlyStats.swift
//  Norma
//
//  Created by Claude on 12/31/25.
//

import Foundation

/// Tracks monthly financial statistics for the History section
struct MonthlyStats: Identifiable, Codable, Equatable {
    var id: String?
    var userId: String
    var month: Int           // 1-12
    var year: Int            // e.g., 2025
    var totalSpent: Double
    var arcsAdded: Int
    var challengesCompleted: Int
    var fundsLeftOver: Double
    var createdAt: String?
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case month
        case year
        case totalSpent = "total_spent"
        case arcsAdded = "arcs_added"
        case challengesCompleted = "challenges_completed"
        case fundsLeftOver = "funds_left_over"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Computed Properties

    /// Returns the month name (e.g., "December")
    var monthName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        var components = DateComponents()
        components.month = month
        components.year = year
        components.day = 1
        guard let date = Calendar.current.date(from: components) else {
            return ""
        }
        return dateFormatter.string(from: date)
    }

    /// Returns formatted display string (e.g., "December 2025")
    var displayTitle: String {
        "\(monthName) \(year)"
    }

    /// Check if this is the current month
    var isCurrentMonth: Bool {
        let calendar = Calendar.current
        let now = Date()
        return calendar.component(.month, from: now) == month &&
               calendar.component(.year, from: now) == year
    }

    /// Returns a sort key for ordering (most recent first)
    var sortKey: Int {
        year * 100 + month
    }

    // MARK: - Custom Decoding

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        month = try container.decode(Int.self, forKey: .month)
        year = try container.decode(Int.self, forKey: .year)
        totalSpent = try container.decodeIfPresent(Double.self, forKey: .totalSpent) ?? 0
        arcsAdded = try container.decodeIfPresent(Int.self, forKey: .arcsAdded) ?? 0
        challengesCompleted = try container.decodeIfPresent(Int.self, forKey: .challengesCompleted) ?? 0
        fundsLeftOver = try container.decodeIfPresent(Double.self, forKey: .fundsLeftOver) ?? 0
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
    }

    // MARK: - Custom Encoding

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(month, forKey: .month)
        try container.encode(year, forKey: .year)
        try container.encode(totalSpent, forKey: .totalSpent)
        try container.encode(arcsAdded, forKey: .arcsAdded)
        try container.encode(challengesCompleted, forKey: .challengesCompleted)
        try container.encode(fundsLeftOver, forKey: .fundsLeftOver)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }

    // MARK: - Initializer

    init(
        id: String? = nil,
        userId: String,
        month: Int,
        year: Int,
        totalSpent: Double = 0,
        arcsAdded: Int = 0,
        challengesCompleted: Int = 0,
        fundsLeftOver: Double = 0,
        createdAt: String? = nil,
        updatedAt: String? = nil
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
    }

    // MARK: - Factory Methods

    /// Creates a MonthlyStats for the current month
    static func forCurrentMonth(userId: String) -> MonthlyStats {
        let calendar = Calendar.current
        let now = Date()
        return MonthlyStats(
            userId: userId,
            month: calendar.component(.month, from: now),
            year: calendar.component(.year, from: now)
        )
    }
}
