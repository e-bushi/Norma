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
    @EnvironmentObject private var profileViewModel: ProfileViewModel

    var body: some View {
        mainLayerContent
            .ignoresSafeArea(.keyboard)
            .onChange(of: appCoordinator.mainLayerView) { _, newView in
                AnalyticsService.shared.trackScreen(analyticsScreen(for: newView))
            }
            .onAppear {
                AnalyticsService.shared.trackScreen(analyticsScreen(for: appCoordinator.mainLayerView))
            }
    }

    // MARK: - Content

    @ViewBuilder
    private var mainLayerContent: some View {
        switch appCoordinator.mainLayerView {
        case .settings:
            SettingsView()
                .environmentObject(sessionViewModel)
                .environmentObject(dataManager)
                .environmentObject(appCoordinator)

        case .notes:
            // Runway-first: the arc home replaces the notes list as the primary
            // surface. Notes demote to a browse sheet reached from HomeView's
            // `+`. See plans/runway-first-home.md.
            HomeView()
        }
    }

    // MARK: - Analytics

    private func analyticsScreen(for view: MainLayerViewType) -> AnalyticsScreen {
        switch view {
        case .settings:
            return .settings
        case .notes:
            return .notes
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
