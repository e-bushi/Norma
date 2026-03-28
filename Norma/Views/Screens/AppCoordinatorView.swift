//
//  AppCoordinatorView.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import SwiftUI

struct AppCoordinatorView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .dark

    var body: some View {
        ZStack {
            // Base layer background
            Color("NormaBackground")
                .ignoresSafeArea()

            Group {
                if appCoordinator.isReady {
                    appCoordinator.currentViewContent
                } else if appCoordinator.shouldShowAppLoadingView {
                    // Show fancy loading view for authenticated users
                    AppLoadingView(
                        isDataReady: appCoordinator.dataLoaded,
                        onStart: {
                            appCoordinator.userTappedStart()
                        }
                    )
                }
                // If not ready and not authenticated, just show background
            }
            .animation(.easeInOut(duration: 0.3), value: appCoordinator.currentView)
        }
        .toastOverlay()
        .preferredColorScheme(appearanceMode.colorScheme)
    }
}

#Preview {
    AppCoordinatorView()
        .environmentObject(AppCoordinator())
}