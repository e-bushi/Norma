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

    @ObservedObject private var rewardQueue = RewardQueueManager.shared

    var body: some View {
        ViewModelContainer(dataManager: dataManager, sessionViewModel: sessionViewModel) {
            MainLayerView()
                .environmentObject(appCoordinator)
        }
        .onAppear {
            // Set the model context on DataManager
            dataManager.setModelContext(modelContext)
        }
        .task(id: sessionViewModel.currentUser?.userId) {
            // Load user data when main app becomes active (only once per user session)
            if let _ = sessionViewModel.currentUser?.userId {
                do {
                    // Refresh user profile first
                    await sessionViewModel.fetchUserProfile()
                    // Then fetch financial data
                    try await dataManager.fetchAllFinancialData()
                } catch {
                    print("Failed to load financial data: \(error)")
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

    init(dataManager: DataManager, sessionViewModel: SessionViewModel, @ViewBuilder content: () -> Content) {
        self.dataManager = dataManager
        self.sessionViewModel = sessionViewModel
        self.content = content()

        // Initialize view models with proper dependencies
        self._billViewModel = StateObject(wrappedValue: BillViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
        self._expenseViewModel = StateObject(wrappedValue: ExpenseViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
        self._incomeViewModel = StateObject(wrappedValue: IncomeViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
        self._challengeViewModel = StateObject(wrappedValue: ChallengeViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
        self._profileViewModel = StateObject(wrappedValue: ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
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
            .onAppear {
                // Set up ChallengeViewModel dependencies
                challengeViewModel.setExpenseViewModel(expenseViewModel)
                challengeViewModel.setBillViewModel(billViewModel)
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
