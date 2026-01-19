//
//  ActiveChallengeContent.swift
//  Norma
//
//  Created by Claude on 1/17/26.
//

import SwiftUI

/// Main content view for an active challenge
struct ActiveChallengeContent: View {
    let challenge: Challenge
    @Binding var heroAppeared: Bool
    @Binding var statsAppeared: Bool
    @Binding var calendarAppeared: Bool
    @Binding var transactionsAppeared: Bool
    @Binding var showBirdCollection: Bool

    @EnvironmentObject var challengeViewModel: ChallengeViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @State private var selectedDay: ChallengeDay?
    @State private var graphAppeared = false

    private func dailyBudget(for challenge: Challenge) -> Double {
        let days = max(1, challenge.daysRemaining)
        return challenge.amountRemaining / Double(days)
    }

    var body: some View {
        VStack(spacing: 24) {
            // Hero Section - Big number at top with badges
            ChallengeHeroView(
                challenge: challenge,
                stats: challengeViewModel.challengeStats,
                totalPoints: challengeViewModel.totalPoints,
                tierFileName: challengeViewModel.currentTier.fileName,
                onPointsTapped: {
                    showBirdCollection = true
                }
            )
            .scaleEffect(heroAppeared ? 1 : 0.95)
            .opacity(heroAppeared ? 1 : 0)
            .offset(y: heroAppeared ? 0 : 20)

            // Stats Row (conversational inline SF symbols)
            // Uses todaysDailyCap which is fixed for the day (doesn't change with transactions)
            ChallengeStatsRow(
                currentStreak: challengeViewModel.currentStreak,
                formattedDailyCap: profileViewModel.formatCurrency(challengeViewModel.todaysDailyCap),
                formattedTodaySpent: profileViewModel.formatCurrency(challengeViewModel.todaySpending),
                formattedRemaining: profileViewModel.formatCurrency(abs(challengeViewModel.todaysDailyCap - challengeViewModel.todaySpending)),
                isOverBudget: challengeViewModel.todaySpending > challengeViewModel.todaysDailyCap
            )
            .scaleEffect(statsAppeared ? 1 : 0.97)
            .opacity(statsAppeared ? 1 : 0)
            .offset(y: statsAppeared ? 0 : 15)

            // Cap Trend Indicator - shows if cap went up or down from banking/overspending
            // Only show from day 2 onwards (no previous spending behavior on day 1)
            if challengeViewModel.isPastFirstDayOfChallenge && abs(challengeViewModel.capChange) > 0.01 {
                CapTrendIndicator(
                    capChange: challengeViewModel.capChange,
                    initialCap: challengeViewModel.initialDailyCap,
                    formatCurrency: { profileViewModel.formatCurrency($0) }
                )
                .scaleEffect(statsAppeared ? 1 : 0.97)
                .opacity(statsAppeared ? 1 : 0)
                .offset(y: statsAppeared ? 0 : 15)
            }

            // Contribution Graph - GitHub-style monthly view (with skeleton while loading)
            Group {
                if challengeViewModel.isStatsLoading {
                    ContributionGraphSkeleton()
                        .transition(.opacity)
                } else {
                    ContributionGraphView(
                        dayResults: challengeViewModel.currentMonthResults,
                        selectedDate: selectedDay?.date
                    )
                    .transition(.opacity)
                }
            }
            .scaleEffect(graphAppeared ? 1 : 0.97)
            .opacity(graphAppeared ? 1 : 0)
            .offset(y: graphAppeared ? 0 : 15)

            // Mini Calendar (2 weeks view)
            VStack(alignment: .leading, spacing: 12) {
                Text("CHALLENGE DAYS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(1.5)

                ChallengeMiniCalendar(
                    challenge: challenge,
                    challengeDays: challengeViewModel.getChallengeDays(),
                    selectedDay: $selectedDay
                )
            }
            .scaleEffect(calendarAppeared ? 1 : 0.97)
            .opacity(calendarAppeared ? 1 : 0)
            .offset(y: calendarAppeared ? 0 : 15)

            // Transactions for selected day
            if let day = selectedDay {
                ChallengeTransactionsView(
                    selectedDay: day,
                    expenses: challengeViewModel.getExpenses(for: day.date)
                )
                .scaleEffect(transactionsAppeared ? 1 : 0.97)
                .opacity(transactionsAppeared ? 1 : 0)
                .offset(y: transactionsAppeared ? 0 : 15)
            }

            Spacer(minLength: 40)
        }
        .onAppear {
            // Select today by default
            let days = challengeViewModel.getChallengeDays()
            selectedDay = days.first { $0.isToday } ?? days.first

            // Staggered entrance animations
            animateEntrance()
        }
    }

    private func animateEntrance() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            heroAppeared = true
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
            statsAppeared = true
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
            graphAppeared = true
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3)) {
            calendarAppeared = true
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4)) {
            transactionsAppeared = true
        }
    }
}

// MARK: - Previews

#Preview("Active Challenge - Day 1") {
    ScrollView(showsIndicators: false) {
        ActiveChallengeContent(
            challenge: Challenge(
                id: "preview-1",
                userId: "user",
                amountTotal: 500,
                amountRemaining: 500,
                currency: "USD",
                startDate: Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date(),
                status: .active,
                difficulty: .medium,
                durationDays: 5
            ),
            heroAppeared: .constant(true),
            statsAppeared: .constant(true),
            calendarAppeared: .constant(true),
            transactionsAppeared: .constant(true),
            showBirdCollection: .constant(false)
        )
        .padding(.horizontal, 20)
    }
    .background(Color("NormaBackground"))
    .environmentObject(ChallengeViewModel(
        dataManager: DataManager(),
        sessionViewModel: SessionViewModel(dataManager: DataManager())
    ))
    .environmentObject(ProfileViewModel(
        dataManager: DataManager(),
        sessionViewModel: SessionViewModel(dataManager: DataManager())
    ))
}

#Preview("Active Challenge - Mid Challenge") {
    ScrollView(showsIndicators: false) {
        ActiveChallengeContent(
            challenge: Challenge(
                id: "preview-2",
                userId: "user",
                amountTotal: 500,
                amountRemaining: 320,
                currency: "USD",
                startDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(),
                status: .active,
                difficulty: .hard,
                durationDays: 5
            ),
            heroAppeared: .constant(true),
            statsAppeared: .constant(true),
            calendarAppeared: .constant(true),
            transactionsAppeared: .constant(true),
            showBirdCollection: .constant(false)
        )
        .padding(.horizontal, 20)
    }
    .background(Color("NormaBackground"))
    .environmentObject(ChallengeViewModel(
        dataManager: DataManager(),
        sessionViewModel: SessionViewModel(dataManager: DataManager())
    ))
    .environmentObject(ProfileViewModel(
        dataManager: DataManager(),
        sessionViewModel: SessionViewModel(dataManager: DataManager())
    ))
}
