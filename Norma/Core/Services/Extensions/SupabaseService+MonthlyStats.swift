//
//  SupabaseService+MonthlyStats.swift
//  Norma
//
//  Created by Claude on 12/31/25.
//

import Foundation
import Supabase

extension SupabaseService {

    // MARK: - Monthly Stats Methods

    /// Fetch all monthly stats for a user
    func fetchMonthlyStats(userId: String) async throws -> [MonthlyStats] {
        let response: [MonthlyStats] = try await from("monthly_stats")
            .select()
            .eq("user_id", value: userId)
            .order("year", ascending: false)
            .order("month", ascending: false)
            .execute()
            .value

        return response
    }

    /// Fetch monthly stats for a specific month/year
    func fetchMonthlyStats(userId: String, month: Int, year: Int) async throws -> MonthlyStats? {
        let response: [MonthlyStats] = try await from("monthly_stats")
            .select()
            .eq("user_id", value: userId)
            .eq("month", value: month)
            .eq("year", value: year)
            .limit(1)
            .execute()
            .value

        return response.first
    }

    /// Create or update monthly stats (upsert on user_id, month, year)
    func upsertMonthlyStats(_ stats: MonthlyStats) async throws -> MonthlyStats {
        let response: MonthlyStats = try await from("monthly_stats")
            .upsert(stats, onConflict: "user_id,month,year")
            .select()
            .single()
            .execute()
            .value

        return response
    }

    /// Create new monthly stats
    func createMonthlyStats(_ stats: MonthlyStats) async throws -> MonthlyStats {
        let response: MonthlyStats = try await from("monthly_stats")
            .insert(stats)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    /// Update existing monthly stats
    func updateMonthlyStats(_ stats: MonthlyStats) async throws -> MonthlyStats {
        guard let statsId = stats.id else {
            throw NSError(domain: "SupabaseService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Monthly stats ID is required for update"])
        }

        let response: MonthlyStats = try await from("monthly_stats")
            .update(stats)
            .eq("id", value: statsId)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    /// Initialize stats for the current month
    func initializeCurrentMonthStats(userId: String) async throws -> MonthlyStats {
        let newStats = MonthlyStats.forCurrentMonth(userId: userId)
        return try await createMonthlyStats(newStats)
    }
}
