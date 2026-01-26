//
//  DataManager+MonthlyStats.swift
//  Norma
//
//  Created by Claude on 12/31/25.
//

import Foundation
import SwiftData

extension DataManager {

    // MARK: - Monthly Stats Methods

    /// Fetch all monthly stats for the current user
    func fetchMonthlyStats(userId: String) async throws {
        do {
            // Try to fetch from Supabase first
            let fetchedStats = try await supabaseService.fetchMonthlyStats(userId: userId)
            monthlyStats = fetchedStats

            // Cache monthly stats in SwiftData
            await cacheMonthlyStats(fetchedStats)

            print("Fetched \(fetchedStats.count) monthly stats from server")
        } catch {
            // If fetch fails (offline), load from cache
            print("Failed to fetch monthly stats from server: \(error). Loading from cache...")

            // Load from cache
            await loadMonthlyStatsFromCache(userId: userId)

            // If we have cached data, don't throw the error
            if !monthlyStats.isEmpty {
                print("Loaded \(monthlyStats.count) monthly stats from cache")
            } else {
                throw error
            }
        }
    }

    /// Get monthly stats history sorted by most recent, limited to specified count
    func getMonthlyStatsHistory(limit: Int = 12) -> [MonthlyStats] {
        return Array(monthlyStats.sorted { $0.sortKey > $1.sortKey }.prefix(limit))
    }

    /// Get stats for a specific month
    func getMonthlyStats(month: Int, year: Int) -> MonthlyStats? {
        return monthlyStats.first { $0.month == month && $0.year == year }
    }

    /// Update or create monthly stats for the current month
    func updateOrCreateCurrentMonthStats(
        userId: String,
        totalSpent: Double,
        arcsAdded: Int,
        challengesCompleted: Int,
        fundsLeftOver: Double
    ) async throws {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)

        // Check if stats already exist for this month
        if var existingStats = getMonthlyStats(month: currentMonth, year: currentYear) {
            existingStats.totalSpent = totalSpent
            existingStats.arcsAdded = arcsAdded
            existingStats.challengesCompleted = challengesCompleted
            existingStats.fundsLeftOver = fundsLeftOver

            let updatedStats = try await supabaseService.upsertMonthlyStats(existingStats)

            // Update local state
            if let index = monthlyStats.firstIndex(where: { $0.month == currentMonth && $0.year == currentYear }) {
                monthlyStats[index] = updatedStats
            }

            // Update cache
            await updateCachedMonthlyStats(updatedStats)

            print("Updated monthly stats for \(currentMonth)/\(currentYear)")
        } else {
            // Create new stats for this month
            let newStats = MonthlyStats(
                userId: userId,
                month: currentMonth,
                year: currentYear,
                totalSpent: totalSpent,
                arcsAdded: arcsAdded,
                challengesCompleted: challengesCompleted,
                fundsLeftOver: fundsLeftOver
            )

            let createdStats = try await supabaseService.createMonthlyStats(newStats)
            monthlyStats.append(createdStats)

            // Cache the new stats
            await cacheMonthlyStats([createdStats])

            print("Created monthly stats for \(currentMonth)/\(currentYear)")
        }
    }

    /// Increment the arcs added count for the current month
    func incrementArcsAdded(userId: String) async throws {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)

        if var existingStats = getMonthlyStats(month: currentMonth, year: currentYear) {
            existingStats.arcsAdded += 1
            let updatedStats = try await supabaseService.upsertMonthlyStats(existingStats)

            if let index = monthlyStats.firstIndex(where: { $0.month == currentMonth && $0.year == currentYear }) {
                monthlyStats[index] = updatedStats
            }
            await updateCachedMonthlyStats(updatedStats)
        } else {
            // Create new stats with 1 arc
            let newStats = MonthlyStats(userId: userId, month: currentMonth, year: currentYear, arcsAdded: 1)
            let createdStats = try await supabaseService.createMonthlyStats(newStats)
            monthlyStats.append(createdStats)
            await cacheMonthlyStats([createdStats])
        }
    }

    /// Increment challenges completed count for the current month
    func incrementChallengesCompleted(userId: String) async throws {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)

        if var existingStats = getMonthlyStats(month: currentMonth, year: currentYear) {
            existingStats.challengesCompleted += 1
            let updatedStats = try await supabaseService.upsertMonthlyStats(existingStats)

            if let index = monthlyStats.firstIndex(where: { $0.month == currentMonth && $0.year == currentYear }) {
                monthlyStats[index] = updatedStats
            }
            await updateCachedMonthlyStats(updatedStats)
        } else {
            // Create new stats with 1 challenge
            let newStats = MonthlyStats(userId: userId, month: currentMonth, year: currentYear, challengesCompleted: 1)
            let createdStats = try await supabaseService.createMonthlyStats(newStats)
            monthlyStats.append(createdStats)
            await cacheMonthlyStats([createdStats])
        }
    }

    /// Update spending totals for the current month
    func updateCurrentMonthSpending(userId: String, totalSpent: Double, fundsLeftOver: Double) async throws {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)

        if var existingStats = getMonthlyStats(month: currentMonth, year: currentYear) {
            existingStats.totalSpent = totalSpent
            existingStats.fundsLeftOver = fundsLeftOver
            let updatedStats = try await supabaseService.upsertMonthlyStats(existingStats)

            if let index = monthlyStats.firstIndex(where: { $0.month == currentMonth && $0.year == currentYear }) {
                monthlyStats[index] = updatedStats
            }
            await updateCachedMonthlyStats(updatedStats)
        } else {
            let newStats = MonthlyStats(
                userId: userId,
                month: currentMonth,
                year: currentYear,
                totalSpent: totalSpent,
                fundsLeftOver: fundsLeftOver
            )
            let createdStats = try await supabaseService.createMonthlyStats(newStats)
            monthlyStats.append(createdStats)
            await cacheMonthlyStats([createdStats])
        }
    }

    /// Refresh the current month's snapshot with latest expense data
    /// Call this after adding expenses to keep the snapshot current
    func refreshCurrentMonthSnapshot() async {
        guard let userId = currentProfile?.userId else { return }

        let calendar = Calendar.current
        let now = Date()
        let start = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let end = calendar.date(byAdding: .month, value: 1, to: start) ?? now
        let currentMonthRange = DateInterval(start: start, end: end)

        let totalSpent = getTotalExpenses(for: currentMonthRange)
        let monthlyIncome = currentProfile?.settings.monthlyIncome ?? 0
        let discretionaryIncome = max(0, monthlyIncome - totalMonthlyBills)
        let fundsLeftOver = discretionaryIncome - totalSpent

        do {
            try await updateCurrentMonthSpending(
                userId: userId,
                totalSpent: totalSpent,
                fundsLeftOver: fundsLeftOver
            )
            print("Refreshed current month snapshot: spent=\(totalSpent), leftOver=\(fundsLeftOver)")
        } catch {
            print("Failed to refresh current month snapshot: \(error)")
        }
    }

    // MARK: - SwiftData Caching

    private func cacheMonthlyStats(_ statsToCache: [MonthlyStats]) async {
        guard let modelContext = modelContext else { return }

        do {
            // First, clear existing cached stats for this user
            if let userId = currentProfile?.userId {
                let descriptor = FetchDescriptor<CachedMonthlyStats>(
                    predicate: #Predicate { cached in
                        cached.userId == userId
                    }
                )

                let existingCached = try modelContext.fetch(descriptor)
                for cached in existingCached {
                    modelContext.delete(cached)
                }
            }

            // Then insert new cached stats
            for stats in statsToCache {
                let cachedStats = CachedMonthlyStats(from: stats)
                modelContext.insert(cachedStats)
            }

            try modelContext.save()
            print("Successfully cached \(statsToCache.count) monthly stats")
        } catch {
            print("Failed to cache monthly stats: \(error)")
        }
    }

    private func updateCachedMonthlyStats(_ stats: MonthlyStats) async {
        guard let modelContext = modelContext,
              let statsId = stats.id else { return }

        do {
            let descriptor = FetchDescriptor<CachedMonthlyStats>(
                predicate: #Predicate { cached in
                    cached.id == statsId
                }
            )

            if let existingCached = try modelContext.fetch(descriptor).first {
                // Update existing cached stats
                existingCached.totalSpent = stats.totalSpent
                existingCached.arcsAdded = stats.arcsAdded
                existingCached.challengesCompleted = stats.challengesCompleted
                existingCached.fundsLeftOver = stats.fundsLeftOver
                existingCached.updatedAt = Date()
                existingCached.lastSyncedAt = Date()
            } else {
                // Create new cached stats if not found
                let cachedStats = CachedMonthlyStats(from: stats)
                modelContext.insert(cachedStats)
            }

            try modelContext.save()
            print("Updated cached monthly stats: \(statsId)")
        } catch {
            print("Failed to update cached monthly stats: \(error)")
        }
    }

    private func loadMonthlyStatsFromCache(userId: String) async {
        guard let modelContext = modelContext else { return }

        do {
            let descriptor = FetchDescriptor<CachedMonthlyStats>(
                predicate: #Predicate { cached in
                    cached.userId == userId
                }
            )

            let cachedStats = try modelContext.fetch(descriptor)
            monthlyStats = cachedStats.map { $0.toMonthlyStats() }
            print("Loaded \(monthlyStats.count) monthly stats from cache")
        } catch {
            print("Failed to load monthly stats from cache: \(error)")
        }
    }
}
