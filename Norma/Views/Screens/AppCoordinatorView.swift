//
//  AppCoordinatorView.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import SwiftUI

struct AppCoordinatorView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    
    var body: some View {
        ZStack {
            // Base layer background
            Color("NormaBackground")
                .ignoresSafeArea()

            Group {
                if appCoordinator.isReady {
                    appCoordinator.currentViewContent
                } else {
                    LoadingView()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: appCoordinator.currentView)
        }
    }
}

#Preview {
    AppCoordinatorView()
        .environmentObject(AppCoordinator())
}