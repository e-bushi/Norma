//
//  ChallengeViewModel.swift
//  Norma
//
//  Created by Claude on 12/22/25.
//

import Foundation
import SwiftUI
import Combine
import UIKit

@MainActor
class ChallengeViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var activeChallenge: Challenge?
    @Published var challengeHistory: [Challenge] = []

    // Category Breakdown for Active Challenge
    @Published var categoryBreakdown: [CategorySpending] = []
    @Published var totalTransactionCount: Int = 0

    // Challenge State
    @Published var challengeState: ChallengeState = .noChallenge

    // Challenge Stats & Progression
    @Published var challengeStats: ChallengeStats?
    @Published var selectedDifficulty: ChallengeDifficulty = .medium
    @Published var newlyUnlockedTier: ChallengeTier?
    @Published var lastPointsEarned: Int = 0

    // Daily Calculation Results (for contribution graph)
    @Published var dayResults: [DayResult] = []
    @Published var currentMonthResults: [DayResult] = []

    // Fixed daily cap - stored once per day, doesn't change with transactions
    private var fixedDailyCap: Double?
    private var fixedCapDate: Date?
    private var fixedCapChallengeId: String?

    // UI State
    @Published var isLoading = false
    @Published var isStatsLoading = true  // For contribution graph skeleton
    @Published var showError = false
    @Published var errorMessage = ""

    // Daily Recap State
    @Published var showDailyRecap = false
    @Published var dailyRecapData: DailyRecapData?
    private let lastRecapShownKey = "lastDailyRecapShownDate"

    // MARK: - Dependencies

    private let dataManager: DataManager
    private let sessionViewModel: SessionViewModel
    private var expenseViewModel: ExpenseViewModel?
    private var billViewModel: BillViewModel?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(dataManager: DataManager, sessionViewModel: SessionViewModel) {
        self.dataManager = dataManager
        self.sessionViewModel = sessionViewModel

        setupObservers()
        loadChallenge()

        // Load stats and run daily calculations on init
        // This ensures points are calculated even if user doesn't open ChallengesView
        Task {
            await loadChallengeStats()
            await runDailyCalculations()
        }
    }

    func setExpenseViewModel(_ expenseViewModel: ExpenseViewModel) {
        self.expenseViewModel = expenseViewModel
        setupExpenseObserver()
        updateCategoryBreakdown()
    }

    func setBillViewModel(_ billViewModel: BillViewModel) {
        self.billViewModel = billViewModel
    }

    // MARK: - Computed Properties (Tier & Stats)

    /// Current challenge tier based on total points
    var currentTier: ChallengeTier {
        challengeStats?.currentTier ?? .starter
    }

    /// Next tier to unlock
    var nextTier: ChallengeTier? {
        challengeStats?.nextTier
    }

    /// Points needed to reach next tier
    var pointsToNextTier: Int {
        challengeStats?.pointsToNextTier ?? 0
    }

    /// Progress toward next tier (0.0 to 1.0)
    var progressToNextTier: Double {
        challengeStats?.progressToNextTier ?? 0
    }

    /// Current streak count
    var currentStreak: Int {
        challengeStats?.currentStreak ?? 0
    }

    /// Total points earned
    var totalPoints: Int {
        challengeStats?.totalPoints ?? 0
    }

    /// Streak multiplier for next challenge
    var streakMultiplier: Double {
        challengeStats?.streakMultiplier ?? 1.0
    }

    /// Total days under cap (cumulative, never resets)
    var totalDaysUnderCap: Int {
        challengeStats?.totalDaysUnderCap ?? 0
    }

    /// Today's daily cap - fixed for the day, doesn't change when transactions are added
    var todaysDailyCap: Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let challenge = activeChallenge else { return 0 }

        // If we have a fixed cap for today AND same challenge, use it
        if let fixedCap = fixedDailyCap,
           let fixedDate = fixedCapDate,
           let fixedId = fixedCapChallengeId,
           calendar.isDate(fixedDate, inSameDayAs: today),
           fixedId == challenge.id {
            return fixedCap
        }

        // No fixed cap yet, or different day/challenge - calculate and store it
        let cap: Double
        let challengeStart = calendar.startOfDay(for: challenge.startDate)
        let daysRemaining = challenge.daysRemaining

        guard daysRemaining > 0 else { return 0 }

        if today == challengeStart {
            // Day 1: use initial cap (total / duration)
            cap = challenge.amountTotal / Double(challenge.durationDays)
        } else {
            // Calculate what amountRemaining was at start of today
            // by adding back today's spending to current remaining
            let amountAtStartOfDay = challenge.amountRemaining + todaySpending
            cap = amountAtStartOfDay / Double(daysRemaining)
        }

        // Store for subsequent accesses today
        fixedDailyCap = cap
        fixedCapDate = today
        fixedCapChallengeId = challenge.id

        return cap
    }

    /// Current daily cap (alias for todaysDailyCap)
    var currentDailyCap: Double {
        todaysDailyCap
    }

    /// Initial daily cap (what it would be without any banking)
    var initialDailyCap: Double {
        guard let challenge = activeChallenge else { return 0 }
        return challenge.amountTotal / Double(challenge.durationDays)
    }

    /// Cap change from initial (positive = banked budget, negative = overspent)
    var capChange: Double {
        todaysDailyCap - initialDailyCap
    }

    /// Reset the fixed daily cap (called when day changes or challenge changes)
    func resetFixedDailyCap() {
        fixedDailyCap = nil
        fixedCapDate = nil
        fixedCapChallengeId = nil
    }

    /// Whether we're past the first day of the challenge (cap trend only makes sense from day 2+)
    var isPastFirstDayOfChallenge: Bool {
        guard let challenge = activeChallenge else { return false }
        let calendar = Calendar.current
        let challengeStart = calendar.startOfDay(for: challenge.startDate)
        let today = calendar.startOfDay(for: Date())
        return today > challengeStart
    }

    /// Today's spending (sum of expenses for today)
    var todaySpending: Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        let todayExpenses = expenseViewModel?.expenses.filter { expense in
            guard let expenseDate = parseExpenseDate(expense.expenseDate) else { return false }
            return expenseDate >= today && expenseDate < tomorrow
        } ?? []

        return todayExpenses.reduce(0) { $0 + $1.amount }
    }

    /// Count of unlocked tiers
    var unlockedTierCount: Int {
        ChallengeTierService.unlockedTierCount(for: totalPoints)
    }

    /// Total tiers available
    var totalTierCount: Int {
        ChallengeTier.allCases.count
    }

    /// Whether user can create a new challenge (false if already started one today)
    var canCreateChallenge: Bool {
        !hasChallengeStartedToday()
    }

    // MARK: - Setup

    private func setupObservers() {
        // Observe DataManager challenges changes
        dataManager.$challenges
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadChallenge()
            }
            .store(in: &cancellables)

        // Observe app foreground to run daily calculations
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.loadChallengeStats()
                    await self?.runDailyCalculations()
                }
            }
            .store(in: &cancellables)
    }

    private func setupExpenseObserver() {
        // Observe expense changes to update category breakdown
        expenseViewModel?.$expenses
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateCategoryBreakdown()
                self?.checkChallengeStatus()
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Loading

    func loadChallenge() {
        // Get active challenge from DataManager
        activeChallenge = dataManager.getActiveChallenge()
        challengeHistory = dataManager.getChallengeHistory()

        // Update challenge state
        updateChallengeState()
        updateCategoryBreakdown()
    }

    func refreshChallenge() async {
        guard let userId = sessionViewModel.currentUser?.userId else { return }

        isLoading = true
        isStatsLoading = true  // Reset stats loading for skeleton
        clearError()

        do {
            try await dataManager.fetchChallenges(userId: userId)
            await loadChallengeStats()
            loadChallenge()

            // Run daily calculations to process any missed days
            await runDailyCalculations()
        } catch {
            showError(error.localizedDescription)
        }

        isLoading = false
    }

    /// Load challenge stats for the current user
    func loadChallengeStats() async {
        guard let userId = sessionViewModel.currentUser?.userId else { return }

        print("🔍 DEBUG: Attempting to load challenge stats for userId: \(userId)")

        do {
            challengeStats = try await dataManager.fetchChallengeStats(userId: userId)
        } catch {
            print("Failed to load challenge stats: \(error)")
            // Don't show error to user, stats are not critical for basic functionality
        }
    }

    /// Run daily calculations for the active challenge
    /// This calculates points for any days that haven't been processed yet
    func runDailyCalculations() async {
        guard let challenge = activeChallenge,
              let stats = challengeStats,
              challenge.status == .active else {
            dayResults = []
            // Still update contribution graph even without active challenge
            await updateCurrentMonthResults()
            return
        }

        // Get expenses for the challenge period
        let expenses = getChallengeExpenses()

        // Run the calculation
        let result = ChallengeCalculationService.calculateMissingDays(
            challenge: challenge,
            stats: stats,
            expenses: expenses
        )

        // Update local state
        dayResults = result.dayResults
        challengeStats = result.updatedStats
        activeChallenge = result.updatedChallenge

        // Persist changes if any calculations were done OR if challenge was finalized
        if !result.dayResults.isEmpty || result.challengeCompleted || result.challengeFailed {
            print("🔄 DEBUG: Persisting changes - completed: \(result.challengeCompleted), failed: \(result.challengeFailed), dayResults: \(result.dayResults.count)")
            do {
                try await dataManager.updateChallenge(result.updatedChallenge)
                if let userId = sessionViewModel.currentUser?.userId {
                    try await dataManager.updateChallengeStats(result.updatedStats, userId: userId)
                }
                print("✅ DEBUG: Successfully persisted challenge and stats")

                // Handle challenge completion/failure
                if result.challengeCompleted {
                    print("🏆 DEBUG: Challenge completed! Processing rewards...")
                    lastPointsEarned = result.completionBonusAwarded + result.dayResults.reduce(0) { $0 + $1.pointsEarned }
                    challengeState = .completed

                    // Queue rewards using consolidated method
                    await queueChallengeCompletionRewards(
                        challenge: challenge,
                        pointsEarned: lastPointsEarned,
                        previousStats: stats,
                        updatedStats: result.updatedStats
                    )
                } else if result.challengeFailed {
                    challengeState = .failed
                }

                loadChallenge()
            } catch {
                print("Failed to persist calculation results: \(error)")
            }
        }

        // Also update current month results for contribution graph
        await updateCurrentMonthResults()
    }

    /// Update the contribution graph data for the current month
    func updateCurrentMonthResults() async {
        let expenses = expenseViewModel?.expenses ?? []

        currentMonthResults = ChallengeCalculationService.getCurrentMonthResults(
            activeChallenge: activeChallenge,
            stats: challengeStats ?? ChallengeStats(userId: sessionViewModel.currentUser?.userId ?? ""),
            expenses: expenses,
            allChallenges: challengeHistory
        )

        // Mark stats as loaded (for skeleton transition)
        if isStatsLoading {
            isStatsLoading = false
        }
    }

    // MARK: - Daily Recap

    /// Check if we should show a daily recap for the previous day
    /// This should be called when the ChallengesView appears
    func checkForDailyRecap() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Check if we've already shown the recap today
        if let lastShown = UserDefaults.standard.object(forKey: lastRecapShownKey) as? Date {
            let lastShownDay = calendar.startOfDay(for: lastShown)
            if lastShownDay >= today {
                // Already shown today
                return
            }
        }

        // Look for yesterday's result in currentMonthResults
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return }
        let yesterdayStart = calendar.startOfDay(for: yesterday)

        // Find yesterday's day result
        guard let yesterdayResult = currentMonthResults.first(where: {
            calendar.isDate($0.date, inSameDayAs: yesterdayStart)
        }) else {
            // No data for yesterday (no active challenge or no spending)
            return
        }

        // Build the recap data
        let previousStreak = max(0, (challengeStats?.currentStreak ?? 0) - (yesterdayResult.wasUnderCap ? 1 : 0))
        let currentStreak = challengeStats?.currentStreak ?? 0
        let streakBroken = !yesterdayResult.wasUnderCap && previousStreak > 0

        dailyRecapData = DailyRecapData(
            date: yesterdayResult.date,
            dailyCap: yesterdayResult.dailyCap,
            amountSpent: yesterdayResult.amountSpent,
            wasUnderCap: yesterdayResult.wasUnderCap,
            pointsEarned: yesterdayResult.pointsEarned,
            previousStreak: previousStreak,
            currentStreak: currentStreak,
            streakBroken: streakBroken
        )

        showDailyRecap = true
    }

    /// Mark the daily recap as shown for today
    func markRecapShown() {
        UserDefaults.standard.set(Date(), forKey: lastRecapShownKey)
        showDailyRecap = false
        dailyRecapData = nil
    }

    /// Dismiss the daily recap
    func dismissDailyRecap() {
        markRecapShown()
    }

    // MARK: - Reward Processing

    /// Consolidated method to queue all rewards for a successful challenge completion
    /// - Parameters:
    ///   - challenge: The completed challenge
    ///   - pointsEarned: Total points earned from this challenge
    ///   - previousStats: The stats BEFORE completion (for tier comparison)
    ///   - updatedStats: The stats AFTER completion
    private func queueChallengeCompletionRewards(
        challenge: Challenge,
        pointsEarned: Int,
        previousStats: ChallengeStats,
        updatedStats: ChallengeStats
    ) async {
        print("🎉 DEBUG: queueChallengeCompletionRewards called with pointsEarned: \(pointsEarned)")
        var rewardsToQueue: [Reward] = []

        // 1. Check for first challenge completed (one-time milestone)
        let isFirstCompletion = await RewardMilestoneTracker.shared.checkAndMarkFirstTime(.firstChallengeCompleted)
        if isFirstCompletion {
            rewardsToQueue.append(.firstChallengeCompleted(pointsEarned: pointsEarned))
        }

        // 2. Add "Beat the Challenge" reward for every successful completion
        rewardsToQueue.append(.challengeBeaten(
            pointsEarned: pointsEarned,
            difficulty: challenge.difficulty.displayName
        ))

        // 3. Check for streak extension (show if streak > 1)
        if updatedStats.currentStreak > 1 {
            rewardsToQueue.append(.streakExtended(newStreak: updatedStats.currentStreak))
        }

        // 4. Check for streak milestones (5, 10, 25, 50, 100 days)
        if let milestoneType = RewardMilestoneTracker.getStreakMilestone(
            for: updatedStats.currentStreak,
            previousStreak: previousStats.currentStreak
        ) {
            let isFirstTime = await RewardMilestoneTracker.shared.checkAndMarkFirstTime(milestoneType)
            if isFirstTime, let milestoneReward = RewardMilestoneTracker.getStreakMilestoneReward(for: milestoneType) {
                rewardsToQueue.append(milestoneReward)
            }
        }

        // 5. Check for new tier unlock
        let oldTier = ChallengeTierService.currentTier(for: previousStats.totalPoints)
        let newTier = ChallengeTierService.currentTier(for: updatedStats.totalPoints)
        if newTier.rawValue > oldTier.rawValue {
            newlyUnlockedTier = newTier
            rewardsToQueue.append(.birdUnlocked(
                tier: newTier,
                totalPoints: updatedStats.totalPoints
            ))
        }

        // Queue all rewards at once
        if !rewardsToQueue.isEmpty {
            print("🎉 DEBUG: Queuing \(rewardsToQueue.count) rewards")
            RewardQueueManager.shared.enqueue(rewardsToQueue)
        } else {
            print("⚠️ DEBUG: No rewards to queue")
        }
    }

    // MARK: - Challenge Generation

    /// Generate initial challenge on signup or when no active challenge exists
    func generateInitialChallenge() async {
        await generateChallengeWithDifficulty(selectedDifficulty)
    }

    /// Check if a challenge was already started today
    /// Returns true if user has already created a challenge today (prevents spam)
    func hasChallengeStartedToday() -> Bool {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())

        // Check active challenge
        if let active = activeChallenge {
            if calendar.isDate(active.startDate, inSameDayAs: todayStart) {
                return true
            }
        }

        // Check challenge history for any challenge started today
        for challenge in challengeHistory {
            if calendar.isDate(challenge.startDate, inSameDayAs: todayStart) {
                return true
            }
        }

        return false
    }

    /// Generate a challenge with a specific difficulty level
    func generateChallengeWithDifficulty(_ difficulty: ChallengeDifficulty) async {
        guard let userId = sessionViewModel.currentUser?.userId else {
            showError("No user found")
            return
        }

        // Check if user already started a challenge today (one per day limit)
        if hasChallengeStartedToday() {
            showError("You can only start one challenge per day. Try again tomorrow!")
            return
        }

        isLoading = true
        isStatsLoading = true  // Reset stats loading for skeleton
        clearError()

        // Load stats if not already loaded
        if challengeStats == nil {
            await loadChallengeStats()
        }

        // Get monthly income and bills
        let monthlyIncome = sessionViewModel.currentUser?.settings.monthlyIncome ?? 0
        let totalBills = billViewModel?.totalMonthlyBills ?? dataManager.totalMonthlyBills

        // Calculate daily rate and challenge amount
        let calendar = Calendar.current
        let today = Date()
        let daysInMonth = calendar.range(of: .day, in: .month, for: today)?.count ?? 30
        let dayOfMonth = calendar.component(.day, from: today)
        let rawDaysRemaining = daysInMonth - dayOfMonth + 1

        // Random challenge duration between 2-5 days (capped to remaining days in month)
        let randomDuration = ChallengeCalculationService.generateRandomDuration()
        let challengeDuration = min(randomDuration, rawDaysRemaining)

        // Formula: (monthly_income - bills) / days_in_month * challenge_duration
        let discretionaryIncome = max(0, monthlyIncome - totalBills)
        let dailyRate = discretionaryIncome / Double(daysInMonth)
        let baseAmount = dailyRate * Double(challengeDuration)

        // Apply difficulty multiplier
        let challengeAmount = baseAmount * difficulty.budgetMultiplier

        // End date based on challenge duration
        let endDate = calendar.date(byAdding: .day, value: challengeDuration - 1, to: today) ?? today

        let currency = sessionViewModel.currentUser?.settings.currency ?? "USD"

        let challenge = Challenge(
            userId: userId,
            amountTotal: challengeAmount,
            amountRemaining: challengeAmount,
            currency: currency,
            startDate: today,
            endDate: endDate,
            status: .active,
            difficulty: difficulty,
            pointsEarned: 0,
            durationDays: challengeDuration
        )

        do {
            try await dataManager.addChallenge(challenge)
            loadChallenge()
            challengeState = .active

            // Run daily calculations to populate stats and contribution graph
            await runDailyCalculations()

            // Check for first challenge started milestone
            let isFirstStart = await RewardMilestoneTracker.shared.checkAndMarkFirstTime(.firstChallengeStarted)
            if isFirstStart {
                RewardQueueManager.shared.enqueue(.firstChallengeStarted())
            }
        } catch {
            showError("Failed to create challenge: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Generate next challenge after previous one completes (uses selected difficulty)
    func generateNextChallenge() async {
        await generateChallengeWithDifficulty(selectedDifficulty)
    }

    /// Start a new challenge with the currently selected difficulty
    func startNewChallenge() async {
        await generateChallengeWithDifficulty(selectedDifficulty)
    }

    /// Calculate next challenge duration based on success rate (2-5 days)
    private func calculateNextChallengeDuration() -> Int {
        let completedChallenges = challengeHistory.filter { $0.status == .completed }
        let failedChallenges = challengeHistory.filter { $0.status == .failed }

        let totalCompleted = completedChallenges.count + failedChallenges.count

        guard totalCompleted > 0 else {
            return 3 // Default for new users
        }

        let successRate = Double(completedChallenges.count) / Double(totalCompleted)

        // Higher success rate = longer challenges
        if successRate >= 0.8 {
            return 5
        } else if successRate >= 0.6 {
            return 4
        } else if successRate >= 0.4 {
            return 3
        } else {
            return 2
        }
    }

    // MARK: - Challenge Status

    private func updateChallengeState() {
        guard let challenge = activeChallenge else {
            challengeState = .noChallenge
            return
        }

        if challenge.isExpired {
            if challenge.amountRemaining >= 0 {
                challengeState = .completed
            } else {
                challengeState = .failed
            }
        } else if challenge.isOverBudget {
            challengeState = .failed
        } else {
            challengeState = .active
        }
    }

    /// Check and handle challenge completion
    func checkChallengeStatus() {
        guard let challenge = activeChallenge else { return }

        updateChallengeState()

        // Handle state transitions
        switch challengeState {
        case .completed:
            handleChallengeCompletion(success: true)
        case .failed:
            handleChallengeCompletion(success: false)
        default:
            break
        }
    }

    private func handleChallengeCompletion(success: Bool) {
        // Delegate to runDailyCalculations which handles all stats updates and rewards
        // This ensures a single code path for challenge completion
        Task {
            // Ensure stats are loaded before running calculations
            if challengeStats == nil {
                await loadChallengeStats()
            }
            // runDailyCalculations will detect the challenge has ended and process accordingly
            await runDailyCalculations()
        }
    }

    /// Record an expense against the active challenge
    func recordExpense(amount: Double) async {
        guard var challenge = activeChallenge else { return }

        challenge.amountRemaining -= amount

        // Check if challenge failed
        if challenge.amountRemaining < 0 {
            challenge.status = .failed
        }

        do {
            try await dataManager.updateChallenge(challenge)
            loadChallenge()
        } catch {
            showError("Failed to update challenge: \(error.localizedDescription)")
        }
    }

    // MARK: - Category Breakdown

    private func updateCategoryBreakdown() {
        guard let challenge = activeChallenge,
              let expenseViewModel = expenseViewModel else {
            categoryBreakdown = []
            totalTransactionCount = 0
            return
        }

        // Get expenses within challenge date range
        let challengeExpenses = getChallengeExpenses()

        // Group by expense name (since Expense doesn't have categoryId)
        var nameTotals: [String: (amount: Double, count: Int)] = [:]

        for expense in challengeExpenses {
            let name = expense.name
            if var existing = nameTotals[name] {
                existing.amount += expense.amount
                existing.count += 1
                nameTotals[name] = existing
            } else {
                nameTotals[name] = (expense.amount, 1)
            }
        }

        // Sort by amount and take top 3
        let sorted = nameTotals
            .sorted { $0.value.amount > $1.value.amount }

        categoryBreakdown = sorted.prefix(3).map { item in
            CategorySpending(
                categoryName: item.key,
                categoryIcon: "cart.fill",
                categoryColor: "#888888",
                totalAmount: item.value.amount,
                transactionCount: item.value.count
            )
        }

        totalTransactionCount = challengeExpenses.count
    }

    /// Get expenses within the active challenge's date range that were created after the challenge started
    /// This ensures expenses made before committing to a challenge don't count against it
    func getChallengeExpenses() -> [Expense] {
        guard let challenge = activeChallenge,
              let expenseViewModel = expenseViewModel else {
            return []
        }

        let dateFormatter = ISO8601DateFormatter()

        return expenseViewModel.expenses.filter { expense in
            guard let expenseDate = dateFormatter.date(from: expense.expenseDate) else { return false }

            // Expense must be within the challenge date range
            let isWithinDateRange = expenseDate >= challenge.startDate && expenseDate <= challenge.endDate

            // Expense must have been created AFTER the challenge was created
            // This prevents pre-existing expenses from counting against a newly created challenge
            var wasCreatedAfterChallenge = true
            if let challengeCreatedAt = challenge.createdAt,
               let expenseCreatedAt = expense.createdAt,
               let challengeCreatedDate = dateFormatter.date(from: challengeCreatedAt),
               let expenseCreatedDate = dateFormatter.date(from: expenseCreatedAt) {
                wasCreatedAfterChallenge = expenseCreatedDate >= challengeCreatedDate
            }

            return isWithinDateRange && wasCreatedAfterChallenge
        }
    }

    /// Recalculate amountRemaining based on actual expenses in the challenge period
    /// Called when ChallengesView loads to ensure accuracy
    func recalculateAmountRemaining() async {
        guard var challenge = activeChallenge else { return }

        // Get all expenses within challenge date range
        let challengeExpenses = getChallengeExpenses()

        // Sum total expenses in period
        let totalExpensesInPeriod = challengeExpenses.reduce(0) { $0 + $1.amount }

        // Calculate correct amountRemaining
        let computedRemaining = challenge.amountTotal - totalExpensesInPeriod

        // Only update if different (with small tolerance for floating point)
        let tolerance = 0.01
        if abs(computedRemaining - challenge.amountRemaining) > tolerance {
            challenge.amountRemaining = computedRemaining

            // Check if challenge failed (went over budget)
            if challenge.amountRemaining < 0 && challenge.status == .active {
                challenge.status = .failed
            }

            do {
                try await dataManager.updateChallenge(challenge)
                loadChallenge()
                print("Recalculated amountRemaining: \(computedRemaining) (was: \(activeChallenge?.amountRemaining ?? 0))")
            } catch {
                print("Failed to update recalculated amount: \(error)")
            }
        }
    }

    /// Get overflow count (transactions beyond top 3 categories)
    var overflowTransactionCount: Int {
        let topThreeCount = categoryBreakdown.reduce(0) { $0 + $1.transactionCount }
        return max(0, totalTransactionCount - topThreeCount)
    }

    /// Parse expense date string to Date
    private func parseExpenseDate(_ dateString: String) -> Date? {
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: dateString) {
            return date
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let date = dateFormatter.date(from: dateString) {
            return date
        }

        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return dateFormatter.date(from: dateString)
    }

    // MARK: - Calendar Days

    /// Get array of dates for the challenge calendar row
    func getChallengeDays() -> [ChallengeDay] {
        guard let challenge = activeChallenge else { return [] }

        let calendar = Calendar.current
        var days: [ChallengeDay] = []

        var currentDate = challenge.startDate
        while currentDate <= challenge.endDate {
            let isToday = calendar.isDateInToday(currentDate)
            let isPast = currentDate < calendar.startOfDay(for: Date())

            // Get spending for this day
            let daySpending = getSpendingForDate(currentDate)

            // Get daily cap from currentMonthResults if available
            let dayResult = currentMonthResults.first { calendar.isDate($0.date, inSameDayAs: currentDate) }
            let dailyCap: Double? = if isToday {
                todaysDailyCap
            } else {
                dayResult?.dailyCap
            }

            days.append(ChallengeDay(
                date: currentDate,
                isToday: isToday,
                isPast: isPast,
                spending: daySpending,
                dailyCap: dailyCap
            ))

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return days
    }

    private func getSpendingForDate(_ date: Date) -> Double {
        guard let expenseViewModel = expenseViewModel else { return 0 }

        let calendar = Calendar.current
        let dateFormatter = ISO8601DateFormatter()

        return expenseViewModel.expenses
            .filter { expense in
                guard let expenseDate = dateFormatter.date(from: expense.expenseDate) else { return false }
                return calendar.isDate(expenseDate, inSameDayAs: date)
            }
            .reduce(0) { $0 + $1.amount }
    }

    /// Get expenses for a specific date
    func getExpenses(for date: Date) -> [Expense] {
        guard let expenseViewModel = expenseViewModel else { return [] }

        let calendar = Calendar.current
        let dateFormatter = ISO8601DateFormatter()

        return expenseViewModel.expenses.filter { expense in
            guard let expenseDate = dateFormatter.date(from: expense.expenseDate) else { return false }
            return calendar.isDate(expenseDate, inSameDayAs: date)
        }
    }

    // MARK: - Helper Methods

    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = activeChallenge?.currency ?? sessionViewModel.currentUser?.settings.currency ?? "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
    }

    // MARK: - Error Handling

    private func clearError() {
        showError = false
        errorMessage = ""
    }

    private func showError(_ message: String) {
        errorMessage = message
        showError = true

        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            await MainActor.run {
                clearError()
            }
        }
    }
}

// MARK: - Supporting Types

enum ChallengeState {
    case noChallenge
    case active
    case completed
    case failed
}

struct CategorySpending: Identifiable {
    let id = UUID()
    let categoryName: String
    let categoryIcon: String
    let categoryColor: String
    let totalAmount: Double
    let transactionCount: Int
}

struct ChallengeDay: Identifiable {
    let id = UUID()
    let date: Date
    let isToday: Bool
    let isPast: Bool
    let spending: Double
    let dailyCap: Double?

    var isOverBudget: Bool {
        guard let cap = dailyCap else { return false }
        return spending > cap
    }

    var dayAbbreviation: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }
}
