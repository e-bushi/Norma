//
//  ChallengesView.swift
//  Norma
//
//  Created by Claude on 12/22/25.
//

import SwiftUI

struct ChallengesView: View {
    @EnvironmentObject var challengeViewModel: ChallengeViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showBirdCollection = false

    // Skeleton timer - always show skeleton briefly on appear
    @State private var showSkeleton = true
    private let skeletonDuration: TimeInterval = 0.8

    // Animation states
    @State private var heroAppeared = false
    @State private var statsAppeared = false
    @State private var calendarAppeared = false
    @State private var transactionsAppeared = false

    /// Whether to show skeleton (either timed skeleton or actual loading)
    private var shouldShowSkeleton: Bool {
        showSkeleton || challengeViewModel.isLoading
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    if shouldShowSkeleton && challengeViewModel.activeChallenge != nil {
                        // Show skeleton for active challenge state
                        ActiveChallengeContentSkeleton()
                    } else if let challenge = challengeViewModel.activeChallenge {
                        ActiveChallengeContent(
                            challenge: challenge,
                            heroAppeared: $heroAppeared,
                            statsAppeared: $statsAppeared,
                            calendarAppeared: $calendarAppeared,
                            transactionsAppeared: $transactionsAppeared,
                            showBirdCollection: $showBirdCollection
                        )
                    } else if shouldShowSkeleton {
                        // Show skeleton while we don't know if there's a challenge yet
                        ActiveChallengeContentSkeleton()
                    } else {
                        EmptyChallengeContent()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color("NormaBackground"))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("My Challenge")
                        .font(.normaTitle(20))
                }
            }
            .refreshable {
                // Reset states before refresh
                showSkeleton = true
                heroAppeared = false
                statsAppeared = false
                calendarAppeared = false
                transactionsAppeared = false
                await challengeViewModel.refreshChallenge()
                // Hide skeleton after duration
                try? await Task.sleep(for: .seconds(skeletonDuration))
                showSkeleton = false
            }
            .task {
                // Start skeleton timer
                Task {
                    try? await Task.sleep(for: .seconds(skeletonDuration))
                    withAnimation(.easeOut(duration: 0.2)) {
                        showSkeleton = false
                    }
                }

                // Load stats on appear
                await challengeViewModel.loadChallengeStats()
                // Recalculate amountRemaining based on actual expenses
                await challengeViewModel.recalculateAmountRemaining()
                // Run daily calculations and update contribution graph
                await challengeViewModel.runDailyCalculations()
                // Check if we should show daily recap (after data is loaded)
                challengeViewModel.checkForDailyRecap()
            }
            .onChange(of: challengeViewModel.isLoading) { _, isLoading in
                // Reset animation states when loading finishes
                if !isLoading {
                    heroAppeared = false
                    statsAppeared = false
                    calendarAppeared = false
                    transactionsAppeared = false
                }
            }
            .sheet(isPresented: $showBirdCollection) {
                BirdCollectionView(totalPoints: challengeViewModel.totalPoints)
            }
            .sheet(isPresented: $challengeViewModel.showDailyRecap) {
                if let recapData = challengeViewModel.dailyRecapData {
                    DailyRecapView(
                        recapData: recapData,
                        formatCurrency: { profileViewModel.formatCurrency($0) },
                        onDismiss: {
                            challengeViewModel.dismissDailyRecap()
                        }
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.hidden)
                }
            }
        }
    }
}

#Preview {
    ChallengesView()
        .environmentObject(ChallengeViewModel(
            dataManager: DataManager(),
            sessionViewModel: SessionViewModel(dataManager: DataManager())
        ))
        .environmentObject(ProfileViewModel(
            dataManager: DataManager(),
            sessionViewModel: SessionViewModel(dataManager: DataManager())
        ))
}
