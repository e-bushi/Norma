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

    @ObservedObject private var plaidService = PlaidService.shared

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

                // If the user has wired a specific account to their freedom
                // fund, record any balance change as a ledger entry.
                recordArcBalanceIfChanged(userId: userId, accounts: accounts)
            }

            print("Plaid sync complete: \(accounts.count) accounts loaded")
        } catch {
            print("Plaid sync failed: \(error)")
        }
    }

    private func recordArcBalanceIfChanged(userId: String, accounts: [PlaidService.PlaidAccount]) {
        guard let arcAccountId = sessionViewModel.currentUser?.settings.arcAccountId,
              let account = accounts.first(where: { $0.accountId == arcAccountId }),
              let balance = account.balances.current else { return }

        FreedomFundLedger.recordIfChanged(
            in: modelContext,
            userId: userId,
            newBalance: balance,
            source: .linkedAccountSync
        )
    }
}

// MARK: - ViewModelContainer

struct ViewModelContainer<Content: View>: View {
    let dataManager: DataManager
    let sessionViewModel: SessionViewModel
    let content: Content

    @StateObject private var billViewModel: BillViewModel
    @StateObject private var incomeViewModel: IncomeViewModel
    @StateObject private var profileViewModel: ProfileViewModel
    @StateObject private var coinColorViewModel: CoinColorViewModel

    init(dataManager: DataManager, sessionViewModel: SessionViewModel, @ViewBuilder content: () -> Content) {
        self.dataManager = dataManager
        self.sessionViewModel = sessionViewModel
        self.content = content()

        let billVM = BillViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel)
        self._billViewModel = StateObject(wrappedValue: billVM)
        self._incomeViewModel = StateObject(wrappedValue: IncomeViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
        self._profileViewModel = StateObject(wrappedValue: ProfileViewModel(dataManager: dataManager, sessionViewModel: sessionViewModel))
        self._coinColorViewModel = StateObject(wrappedValue: CoinColorViewModel(sessionViewModel: sessionViewModel, billViewModel: billVM))
    }

    var body: some View {
        content
            .environmentObject(dataManager)
            .environmentObject(sessionViewModel)
            .environmentObject(billViewModel)
            .environmentObject(incomeViewModel)
            .environmentObject(profileViewModel)
            .environmentObject(coinColorViewModel)
            .onAppear {
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
