//
//  MainLayerView.swift
//  Norma
//
//  Created by Claude on 10/20/25.
//

import SwiftUI

struct MainLayerView: View {
    @EnvironmentObject private var appCoordinator: AppCoordinator
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var billViewModel: BillViewModel
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    @EnvironmentObject private var budgetViewModel: BudgetViewModel

    @State private var isMenuOpen = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Chat menu (left side, always behind)
                ChatMenuView(isMenuOpen: $isMenuOpen, mainLayerView: $appCoordinator.mainLayerView)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()

                // Main layer (switches between different views)
                mainLayerContent
                    .offset(x: isMenuOpen ? geometry.size.width * 0.85 : 0)
                    .shadow(color: Color.black.opacity(isMenuOpen ? 0.3 : 0), radius: 10)
                    .onTapGesture {
                        // Tap anywhere to close menu
                        if isMenuOpen {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isMenuOpen = false
                            }
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private var mainLayerContent: some View {
        switch appCoordinator.mainLayerView {
        case .chat:
            MainChatView(isMenuOpen: $isMenuOpen)
                .environmentObject(sessionViewModel)
                .environmentObject(dataManager)
                .environmentObject(billViewModel)
                .environmentObject(expenseViewModel)
                .environmentObject(budgetViewModel)

        case .settings:
            SettingsView(isMenuOpen: $isMenuOpen)
                .environmentObject(sessionViewModel)
                .environmentObject(dataManager)
        }
    }
}

#Preview {
    let appCoordinator = AppCoordinator()

    return MainLayerView()
        .environmentObject(appCoordinator)
        .environmentObject(appCoordinator.dataManager)
        .environmentObject(appCoordinator.sessionViewModel)
}
