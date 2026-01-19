//
//  Challenge.swift
//  Norma
//
//  Created by Claude on 12/22/25.
//

import Foundation

enum ChallengeStatus: String, Codable {
    case active = "active"
    case completed = "completed"
    case failed = "failed"
}

struct Challenge: Identifiable, Codable, Equatable {
    var id: String?
    var userId: String
    let amountTotal: Double
    var amountRemaining: Double
    let currency: String
    let startDate: Date
    let endDate: Date
    var status: ChallengeStatus
    var difficulty: ChallengeDifficulty
    var pointsEarned: Int
    var durationDays: Int  // Random 2-5 days, set at creation
    var createdAt: String?
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case amountTotal = "amount_total"
        case amountRemaining = "amount_remaining"
        case currency
        case startDate = "start_date"
        case endDate = "end_date"
        case status
        case difficulty
        case pointsEarned = "points_earned"
        case durationDays = "duration_days"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Custom decoding to handle date formats from Supabase
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        amountTotal = try container.decode(Double.self, forKey: .amountTotal)
        amountRemaining = try container.decode(Double.self, forKey: .amountRemaining)
        currency = try container.decode(String.self, forKey: .currency)
        status = try container.decode(ChallengeStatus.self, forKey: .status)
        difficulty = try container.decodeIfPresent(ChallengeDifficulty.self, forKey: .difficulty) ?? .medium
        pointsEarned = try container.decodeIfPresent(Int.self, forKey: .pointsEarned) ?? 0
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)

        // durationDays with fallback to 5 for existing challenges
        durationDays = try container.decodeIfPresent(Int.self, forKey: .durationDays) ?? 5

        // Handle date decoding with multiple formats
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // Decode startDate
        let startDateString = try container.decode(String.self, forKey: .startDate)
        if let date = dateFormatter.date(from: startDateString) {
            self.startDate = date
        } else {
            // Try ISO8601 format as fallback
            let isoFormatter = ISO8601DateFormatter()
            if let date = isoFormatter.date(from: startDateString) {
                let calendar = Calendar.current
                let components = calendar.dateComponents([.year, .month, .day], from: date)
                self.startDate = calendar.date(from: components) ?? date
            } else {
                throw DecodingError.dataCorruptedError(forKey: .startDate,
                                                      in: container,
                                                      debugDescription: "Invalid date format: \(startDateString)")
            }
        }

        // Decode endDate
        let endDateString = try container.decode(String.self, forKey: .endDate)
        if let date = dateFormatter.date(from: endDateString) {
            self.endDate = date
        } else {
            // Try ISO8601 format as fallback
            let isoFormatter = ISO8601DateFormatter()
            if let date = isoFormatter.date(from: endDateString) {
                let calendar = Calendar.current
                let components = calendar.dateComponents([.year, .month, .day], from: date)
                self.endDate = calendar.date(from: components) ?? date
            } else {
                throw DecodingError.dataCorruptedError(forKey: .endDate,
                                                      in: container,
                                                      debugDescription: "Invalid date format: \(endDateString)")
            }
        }
    }

    // Custom encoding to ensure dates are sent in YYYY-MM-DD format
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(amountTotal, forKey: .amountTotal)
        try container.encode(amountRemaining, forKey: .amountRemaining)
        try container.encode(currency, forKey: .currency)
        try container.encode(status, forKey: .status)
        try container.encode(difficulty, forKey: .difficulty)
        try container.encode(pointsEarned, forKey: .pointsEarned)
        try container.encode(durationDays, forKey: .durationDays)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)

        // Encode dates as YYYY-MM-DD strings
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        let startDateString = dateFormatter.string(from: startDate)
        try container.encode(startDateString, forKey: .startDate)

        let endDateString = dateFormatter.string(from: endDate)
        try container.encode(endDateString, forKey: .endDate)
    }

    init(
        id: String? = nil,
        userId: String,
        amountTotal: Double,
        amountRemaining: Double? = nil,
        currency: String = "USD",
        startDate: Date = Date(),
        endDate: Date,
        status: ChallengeStatus = .active,
        difficulty: ChallengeDifficulty = .medium,
        pointsEarned: Int = 0,
        durationDays: Int = 5,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.amountTotal = amountTotal
        self.amountRemaining = amountRemaining ?? amountTotal
        self.currency = currency
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.difficulty = difficulty
        self.pointsEarned = pointsEarned
        self.durationDays = durationDays
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    var daysRemaining: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: endDate)
        let components = calendar.dateComponents([.day], from: today, to: end)
        return max(0, (components.day ?? 0) + 1) // +1 to include end day
    }

    var totalDays: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        let components = calendar.dateComponents([.day], from: start, to: end)
        return max(1, (components.day ?? 0) + 1)
    }

    var isExpired: Bool {
        // Check if we're past the END of the end date (11:59:59 PM)
        // endDate is typically midnight (00:00) so we need to check against the next day
        let calendar = Calendar.current
        let dayAfterEndDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate)) ?? endDate
        return Date() >= dayAfterEndDate
    }

    var percentageRemaining: Double {
        guard amountTotal > 0 else { return 0 }
        return (amountRemaining / amountTotal) * 100
    }

    var percentageSpent: Double {
        guard amountTotal > 0 else { return 0 }
        return ((amountTotal - amountRemaining) / amountTotal) * 100
    }

    var amountSpent: Double {
        amountTotal - amountRemaining
    }

    var isOverBudget: Bool {
        amountRemaining < 0
    }

    var formattedDaysRemaining: String {
        daysRemaining == 1 ? "1 day" : "\(daysRemaining) days"
    }

    var shortDaysRemaining: String {
        "\(daysRemaining)d"
    }

    /// Dynamic daily cap based on remaining budget and remaining days
    /// Used for the new daily points system
    var dailyCap: Double {
        guard daysRemaining > 0 else { return 0 }
        return amountRemaining / Double(daysRemaining)
    }

    /// Completion bonus based on challenge duration
    var completionBonus: Int {
        switch durationDays {
        case 2: return 2
        case 3: return 4
        case 4: return 6
        case 5: return 10
        default: return durationDays >= 5 ? 10 : 2
        }
    }
}
