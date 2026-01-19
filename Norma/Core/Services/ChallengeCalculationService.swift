//
//  ChallengeCalculationService.swift
//  Norma
//
//  Created by Claude on 1/7/26.
//

import Foundation

/// Represents the result of a single day's calculation
struct DayResult: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let dailyCap: Double
    let amountSpent: Double
    let wasUnderCap: Bool
    let pointsEarned: Int
    let streakAfter: Int

    init(
        date: Date,
        dailyCap: Double,
        amountSpent: Double,
        wasUnderCap: Bool,
        pointsEarned: Int,
        streakAfter: Int
    ) {
        self.id = UUID()
        self.date = date
        self.dailyCap = dailyCap
        self.amountSpent = amountSpent
        self.wasUnderCap = wasUnderCap
        self.pointsEarned = pointsEarned
        self.streakAfter = streakAfter
    }
}

/// Result of the calculation operation
struct CalculationResult {
    let updatedChallenge: Challenge
    let updatedStats: ChallengeStats
    let dayResults: [DayResult]
    let challengeCompleted: Bool
    let challengeFailed: Bool
    let completionBonusAwarded: Int
}

/// Service for calculating daily challenge results
/// Handles retroactive calculations when user hasn't opened the app
struct ChallengeCalculationService {

    // MARK: - Public Methods

    /// Generate a random challenge duration (2-5 days)
    static func generateRandomDuration() -> Int {
        Int.random(in: 2...5)
    }

    /// Calculate results for all uncalculated days
    /// This is the main entry point for the calculation logic
    /// - Parameters:
    ///   - challenge: The active challenge
    ///   - stats: The user's current challenge stats
    ///   - expenses: All expenses during the challenge period
    /// - Returns: CalculationResult with updated challenge, stats, and day-by-day results
    static func calculateMissingDays(
        challenge: Challenge,
        stats: ChallengeStats,
        expenses: [Expense]
    ) -> CalculationResult {
        let calendar = Calendar.current

        // Determine which days need calculation
        let startDate = calendar.startOfDay(for: challenge.startDate)
        let endDate = calendar.startOfDay(for: challenge.endDate)
        let today = calendar.startOfDay(for: Date())

        // Last calculated date, or day before challenge start if never calculated
        let lastCalculated: Date
        if let lastCalc = stats.lastCalculatedDate {
            lastCalculated = calendar.startOfDay(for: lastCalc)
        } else {
            // Start from the day before challenge start (so we calculate from day 1)
            lastCalculated = calendar.date(byAdding: .day, value: -1, to: startDate) ?? startDate
        }

        // Calculate up to today or endDate, whichever is earlier
        let calculateUpTo = min(today, endDate)

        // If we've already calculated up to today, check if challenge needs finalizing
        if lastCalculated >= calculateUpTo {
            // Even if all days calculated, challenge may not have been finalized
            // (e.g., if persistence failed or app closed before completion was processed)
            if calculateUpTo >= endDate && challenge.status == .active {
                var finalChallenge = challenge
                var finalStats = stats
                var challengeCompleted = false
                var challengeFailed = false
                var completionBonusAwarded = 0

                if challenge.amountRemaining >= 0 {
                    challengeCompleted = true
                    finalChallenge.status = .completed
                    completionBonusAwarded = challenge.completionBonus
                    finalStats.totalPoints += completionBonusAwarded
                    finalStats.totalCompleted += 1
                    finalStats.lastChallengeDate = Date()

                    switch challenge.difficulty {
                    case .easy:
                        finalStats.easyCompleted += 1
                    case .medium:
                        finalStats.mediumCompleted += 1
                    case .hard:
                        finalStats.hardCompleted += 1
                    }
                } else {
                    challengeFailed = true
                    finalChallenge.status = .failed
                    finalStats.totalFailed += 1
                    finalStats.lastChallengeDate = Date()
                }

                return CalculationResult(
                    updatedChallenge: finalChallenge,
                    updatedStats: finalStats,
                    dayResults: [],
                    challengeCompleted: challengeCompleted,
                    challengeFailed: challengeFailed,
                    completionBonusAwarded: completionBonusAwarded
                )
            }

            return CalculationResult(
                updatedChallenge: challenge,
                updatedStats: stats,
                dayResults: [],
                challengeCompleted: false,
                challengeFailed: false,
                completionBonusAwarded: 0
            )
        }

        // Calculate each day sequentially
        var currentChallenge = challenge
        var currentStats = stats
        var dayResults: [DayResult] = []
        var remainingBudget = challenge.amountRemaining
        var currentDate = calendar.date(byAdding: .day, value: 1, to: lastCalculated)!

        while currentDate <= calculateUpTo {
            // Calculate remaining days from this day's perspective
            let daysFromCurrentToEnd = calendar.dateComponents([.day], from: currentDate, to: endDate).day ?? 0
            let remainingDays = max(1, daysFromCurrentToEnd + 1) // +1 to include end day

            // Calculate dynamic daily cap
            let dailyCap = remainingBudget / Double(remainingDays)

            // Get expenses for this day
            let dayExpenses = expensesForDay(currentDate, from: expenses)
            let amountSpent = dayExpenses.reduce(0) { $0 + $1.amount }

            // Determine if under cap (strictly less than)
            let wasUnderCap = amountSpent < dailyCap

            // Calculate points
            let pointsEarned: Int
            if wasUnderCap {
                pointsEarned = challenge.difficulty.pointReward
                currentStats.currentStreak += 1
                currentStats.totalDaysUnderCap += 1
                currentStats.totalPoints += pointsEarned
            } else {
                pointsEarned = 0
                currentStats.currentStreak = 0
            }

            // Update longest streak if needed
            if currentStats.currentStreak > currentStats.longestStreak {
                currentStats.longestStreak = currentStats.currentStreak
            }

            // Create day result
            let dayResult = DayResult(
                date: currentDate,
                dailyCap: dailyCap,
                amountSpent: amountSpent,
                wasUnderCap: wasUnderCap,
                pointsEarned: pointsEarned,
                streakAfter: currentStats.currentStreak
            )
            dayResults.append(dayResult)

            // Update remaining budget for next day's calculation
            remainingBudget -= amountSpent

            // Move to next day
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        // Update challenge's amountRemaining based on actual spending
        currentChallenge.amountRemaining = remainingBudget
        currentChallenge.pointsEarned = dayResults.reduce(0) { $0 + $1.pointsEarned }

        // Update last calculated date
        currentStats.lastCalculatedDate = calculateUpTo

        // Check if challenge is complete (we've processed the end date)
        let challengeEnded = calculateUpTo >= endDate
        var challengeCompleted = false
        var challengeFailed = false
        var completionBonusAwarded = 0

        if challengeEnded {
            // Challenge has ended - determine success or failure
            if remainingBudget >= 0 {
                // Success! Total spending was under total budget
                challengeCompleted = true
                currentChallenge.status = .completed

                // Award completion bonus
                completionBonusAwarded = currentChallenge.completionBonus
                currentStats.totalPoints += completionBonusAwarded
                currentStats.totalCompleted += 1
                currentStats.lastChallengeDate = Date()

                // Update difficulty-specific counters
                switch challenge.difficulty {
                case .easy:
                    currentStats.easyCompleted += 1
                case .medium:
                    currentStats.mediumCompleted += 1
                case .hard:
                    currentStats.hardCompleted += 1
                }
            } else {
                // Failed - spent more than total budget
                challengeFailed = true
                currentChallenge.status = .failed
                currentStats.totalFailed += 1
                currentStats.lastChallengeDate = Date()
            }
        }

        return CalculationResult(
            updatedChallenge: currentChallenge,
            updatedStats: currentStats,
            dayResults: dayResults,
            challengeCompleted: challengeCompleted,
            challengeFailed: challengeFailed,
            completionBonusAwarded: completionBonusAwarded
        )
    }

    /// Get day results for the current month (for contribution graph)
    /// Uses dynamic cap calculation matching the streak logic
    /// - Parameters:
    ///   - challenge: The active challenge (or nil if no active challenge)
    ///   - stats: The user's challenge stats
    ///   - expenses: All expenses for the month
    ///   - allChallenges: All challenges (for looking up historical data)
    /// - Returns: Array of DayResult for each day in the current month
    static func getCurrentMonthResults(
        activeChallenge: Challenge?,
        stats: ChallengeStats,
        expenses: [Expense],
        allChallenges: [Challenge]
    ) -> [DayResult] {
        let calendar = Calendar.current
        let today = Date()

        // Get start and end of current month
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!

        // Collect all unique challenges that overlap with this month
        var relevantChallenges: [Challenge] = []
        for challenge in allChallenges {
            let challengeStart = calendar.startOfDay(for: challenge.startDate)
            let challengeEnd = calendar.startOfDay(for: challenge.endDate)
            if challengeEnd >= monthStart && challengeStart <= monthEnd {
                relevantChallenges.append(challenge)
            }
        }
        if let active = activeChallenge, !relevantChallenges.contains(where: { $0.id == active.id }) {
            let challengeStart = calendar.startOfDay(for: active.startDate)
            let challengeEnd = calendar.startOfDay(for: active.endDate)
            if challengeEnd >= monthStart && challengeStart <= monthEnd {
                relevantChallenges.append(active)
            }
        }

        // Pre-calculate dynamic caps for each challenge
        // Maps challenge ID -> (date string -> dynamic cap for that day)
        var challengeDynamicCaps: [String: [String: Double]] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for challenge in relevantChallenges {
            guard let challengeId = challenge.id else { continue }

            var dayToCap: [String: Double] = [:]
            let challengeStart = calendar.startOfDay(for: challenge.startDate)
            let challengeEnd = calendar.startOfDay(for: challenge.endDate)
            var remainingBudget = challenge.amountTotal
            var currentChallengeDate = challengeStart

            // Process each day of the challenge sequentially
            while currentChallengeDate <= challengeEnd {
                let daysFromCurrentToEnd = calendar.dateComponents([.day], from: currentChallengeDate, to: challengeEnd).day ?? 0
                let remainingDays = max(1, daysFromCurrentToEnd + 1)

                // Calculate dynamic cap for this day
                let dynamicCap = remainingBudget / Double(remainingDays)
                let dateKey = dateFormatter.string(from: currentChallengeDate)
                dayToCap[dateKey] = dynamicCap

                // Get spending for this day to update remaining budget
                let dayExpenses = expensesForDay(currentChallengeDate, from: expenses)
                let amountSpent = dayExpenses.reduce(0) { $0 + $1.amount }
                remainingBudget -= amountSpent

                currentChallengeDate = calendar.date(byAdding: .day, value: 1, to: currentChallengeDate)!
            }

            challengeDynamicCaps[challengeId] = dayToCap
        }

        // Now build results for each day of the month
        var results: [DayResult] = []
        var currentDate = monthStart

        while currentDate <= min(today, monthEnd) {
            let dateKey = dateFormatter.string(from: currentDate)

            // Find which challenge was active on this day
            let challengeForDay = findChallenge(for: currentDate, in: allChallenges, activeChallenge: activeChallenge)

            if let challenge = challengeForDay,
               let challengeId = challenge.id,
               let dynamicCaps = challengeDynamicCaps[challengeId],
               let dynamicCap = dynamicCaps[dateKey] {

                let dayExpenses = expensesForDay(currentDate, from: expenses)
                let amountSpent = dayExpenses.reduce(0) { $0 + $1.amount }

                let wasUnderCap = amountSpent < dynamicCap
                let pointsEarned = wasUnderCap ? challenge.difficulty.pointReward : 0

                results.append(DayResult(
                    date: currentDate,
                    dailyCap: dynamicCap,
                    amountSpent: amountSpent,
                    wasUnderCap: wasUnderCap,
                    pointsEarned: pointsEarned,
                    streakAfter: 0
                ))
            } else {
                // No challenge active on this day
                results.append(DayResult(
                    date: currentDate,
                    dailyCap: 0,
                    amountSpent: 0,
                    wasUnderCap: false,
                    pointsEarned: 0,
                    streakAfter: 0
                ))
            }

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return results
    }

    // MARK: - Private Helpers

    /// Get expenses for a specific day
    private static func expensesForDay(_ date: Date, from expenses: [Expense]) -> [Expense] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        return expenses.filter { expense in
            // Parse the expense date
            guard let expenseDate = parseExpenseDate(expense.expenseDate) else {
                return false
            }
            return expenseDate >= dayStart && expenseDate < dayEnd
        }
    }

    /// Parse expense date string to Date
    private static func parseExpenseDate(_ dateString: String) -> Date? {
        // Try ISO8601 first
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: dateString) {
            return date
        }

        // Try yyyy-MM-dd format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let date = dateFormatter.date(from: dateString) {
            return date
        }

        // Try yyyy-MM-dd'T'HH:mm:ss format
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = dateFormatter.date(from: dateString) {
            return date
        }

        return nil
    }

    /// Find which challenge was active on a given date
    private static func findChallenge(
        for date: Date,
        in challenges: [Challenge],
        activeChallenge: Challenge?
    ) -> Challenge? {
        let calendar = Calendar.current
        let dateStart = calendar.startOfDay(for: date)

        // Check active challenge first
        if let active = activeChallenge {
            let challengeStart = calendar.startOfDay(for: active.startDate)
            let challengeEnd = calendar.startOfDay(for: active.endDate)
            if dateStart >= challengeStart && dateStart <= challengeEnd {
                return active
            }
        }

        // Check historical challenges
        for challenge in challenges {
            let challengeStart = calendar.startOfDay(for: challenge.startDate)
            let challengeEnd = calendar.startOfDay(for: challenge.endDate)
            if dateStart >= challengeStart && dateStart <= challengeEnd {
                return challenge
            }
        }

        return nil
    }
}
