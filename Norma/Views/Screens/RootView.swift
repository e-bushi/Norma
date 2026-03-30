//
//  RootView.swift
//  Collector
//
//  Created by Chris Mauldin on 5/8/25.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var sessionViewModel: SessionViewModel
    @EnvironmentObject var appCoordinator: AppCoordinator
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @ObservedObject private var rewardQueue = RewardQueueManager.shared
    @ObservedObject private var plaidService = PlaidService.shared

    var body: some View {
        ViewModelContainer(dataManager: dataManager, sessionViewModel: sessionViewModel) {
            MainLayerView()
                .environmentObject(appCoordinator)
        }
        .onAppear {
            // Set the model context on DataManager
            dataManager.setModelContext(modelContext)

            // Signal to RewardQueueManager that the view is ready
            // This handles the case where rewards were fetched before this view was mounted
            rewardQueue.onViewAppear()
        }
        .onDisappear {
            rewardQueue.onViewDisappear()
        }
        .task(id: sessionViewModel.currentUser?.userId) {
            // Load user data when main app becomes active (only once per user session)
            if let userId = sessionViewModel.currentUser?.userId {
                do {
                    // Refresh user profile first
                    await sessionViewModel.fetchUserProfile()
                    // Then fetch financial data
                    try await dataManager.fetchAllFinancialData()
                    // Sync Plaid transactions if connected
                    await syncPlaidBalances(userId: userId)
                } catch {
                    print("Failed to load financial data: \(error)")
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active, let userId = sessionViewModel.currentUser?.userId {
                Task {
                    await syncPlaidBalances(userId: userId)
                }
            }
        }
        .sheet(isPresented: $rewardQueue.isShowingCelebration) {
            RewardCelebrationView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled()
        }
    }

    private func syncPlaidBalances(userId: String) async {
        do {
            let plaidItems = try await dataManager.supabaseService.fetchPlaidItems(userId: userId)
            guard let plaidItem = plaidItems.first else { return }

            // Populate institution info
            await MainActor.run {
                plaidService.institutionName = plaidItem.institutionName
                plaidService.itemId = plaidItem.itemId
            }

            // Fetch balances
            let accounts = try await PlaidService.shared.fetchBalances(userId: userId)

            await MainActor.run {
                plaidService.connectedAccounts = accounts
                plaidService.isConnected = true
            }

            print("Plaid sync complete: \(accounts.count) accounts loaded")
        } catch {
            print("Plaid sync failed: \(error)")
        }
    }
}

// MARK: - ViewModelContainer

struct ViewModelContainer<Content: View>: View {
    let dataManager: DataManager
    let sessionViewModel: SessionViewModel
    let content: Content

    @StateObject private var billViewModel: BillViewModel
    @StateObject private var expenseViewModel: ExpenseViewModel
    @StateObject private var incomeViewModel: IncomeViewModel
    @StateObject private var challengeViewModel: ChallengeViewModel
    @StateObject private var profileViewModel: ProfileViewModel
    @StateObject private var coinColorViewModel: CoinColorViewModel

    init(dataManager: DataManager, sessionViewModel: SessionViewModel, @ViewBuilder content: () -> Content) {
        self.dataManager = dataManager
        self.sessionViewModel = sessionViewModel
        self.content = content()

        // Initialize view models with proper dependencies
        let billVM = BillViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
        self._billViewModel = StateObject(wrappedValue: billVM)
        self._expenseViewModel = StateObject(wrappedValue: ExpenseViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
        self._incomeViewModel = StateObject(wrappedValue: IncomeViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
        self._challengeViewModel = StateObject(wrappedValue: ChallengeViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
        self._profileViewModel = StateObject(wrappedValue: ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
        self._coinColorViewModel = StateObject(wrappedValue: CoinColorViewModel(sessionViewModel: sessionViewModel, billViewModel: billVM))
    }

    var body: some View {
        content
            .environmentObject(dataManager)
            .environmentObject(sessionViewModel)
            .environmentObject(billViewModel)
            .environmentObject(expenseViewModel)
            .environmentObject(incomeViewModel)
            .environmentObject(challengeViewModel)
            .environmentObject(profileViewModel)
            .environmentObject(coinColorViewModel)
            .onAppear {
                // Set up ChallengeViewModel dependencies
                challengeViewModel.setExpenseViewModel(expenseViewModel)
                challengeViewModel.setBillViewModel(billViewModel)
                coinColorViewModel.updateColor()
            }
    }
}

#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    
    return RootView()
        .environmentObject(dataManager)
        .environmentObject(sessionViewModel)
        .preferredColorScheme(.light)
}
