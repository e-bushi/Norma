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

            appCoordinator.currentViewContent
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