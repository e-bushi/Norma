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
        VStack(spacing: 32) {
            // Hero + Sentences grouped together
            VStack(spacing: 8) {
                // Hero Section - Today's remaining budget
                ChallengeHeroView(
                    challenge: challenge,
                    stats: challengeViewModel.challengeStats,
                    totalPoints: challengeViewModel.totalPoints,
                    tierFileName: challengeViewModel.currentTier.fileName,
                    todaysCap: challengeViewModel.todaysDailyCap,
                    todaysRemaining: challengeViewModel.todaysDailyCap - challengeViewModel.todaySpending,
                    onPointsTapped: {
                        showBirdCollection = true
                    }
                )

                // Contextual sentences - cap change info
                ChallengeContextSentences(
                    capChange: challengeViewModel.capChange,
                    isPastFirstDay: challengeViewModel.isPastFirstDayOfChallenge,
                    formatCurrency: { profileViewModel.formatCurrency($0) }
                )
            }
            .scaleEffect(heroAppeared ? 1 : 0.95)
            .opacity(heroAppeared ? 1 : 0)
            .offset(y: heroAppeared ? 0 : 20)

            // Contribution Graph - GitHub-style monthly view (with skeleton while loading)
            Group {
                if challengeViewModel.isStatsLoading {
                    ContributionGraphSkeleton()
                        .transition(.opacity)
                } else {
                    ContributionGraphView(
                        dayResults: challengeViewModel.currentMonthResults,
                        selectedDate: selectedDay?.date,
                        currentStreak: challengeViewModel.currentStreak,
                        challengeRemaining: challenge.amountRemaining,
                        daysRemaining: challenge.daysRemaining,
                        formatCurrency: { profileViewModel.formatCurrency($0) }
                    )
                    .transition(.opacity)
                }
            }
            .scaleEffect(graphAppeared ? 1 : 0.97)
            .opacity(graphAppeared ? 1 : 0)
            .offset(y: graphAppeared ? 0 : 15)

            // Combined Calendar + Stats View
            VStack(alignment: .leading, spacing: 12) {
                Text("CHALLENGE DAYS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(1.5)

                ChallengeDayCalendarView(
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
                ChallengeExpenseList(
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

// MARK: - Challenge Context Sentences

/// Contextual sentences showing cap change info
private struct ChallengeContextSentences: View {
    let capChange: Double
    let isPastFirstDay: Bool
    let formatCurrency: (Double) -> String

    private var showCapChange: Bool {
        isPastFirstDay && abs(capChange) > 0.01
    }

    var body: some View {
        VStack(spacing: 10) {
            // Cap change sentence (or day 1 encouragement)
            if showCapChange {
                if capChange > 0 {
                    (Text("Today's cap is ")
                        .foregroundColor(.primary)
                    + Text(formatCurrency(capChange))
                        .foregroundColor(Color("NormaPastelTeal"))
                    + Text(" higher than previous days.")
                        .foregroundColor(.primary))
                        .font(.custom(FontFamily.Rubik.medium, size: 22))
                        .lineSpacing(10)
                } else {
                    (Text("Today's cap is ")
                        .foregroundColor(.primary)
                    + Text(formatCurrency(abs(capChange)))
                        .foregroundColor(Color("NormaPastelCoral"))
                    + Text(" lower than previous days.")
                        .foregroundColor(.primary))
                        .font(.custom(FontFamily.Rubik.medium, size: 22))
                        .lineSpacing(10)
                }
            } else {
                // Day 1 or no cap change - show encouragement
                Text("Stay under your cap to boost tomorrow.")
                    .font(.custom(FontFamily.Rubik.medium, size: 22))
                    .foregroundColor(.primary)
                    .lineSpacing(10)
            }
        }
        .frame(maxWidth: 300)
        .multilineTextAlignment(.center)
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
