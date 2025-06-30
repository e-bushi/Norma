//
//  NormaApp.swift
//  Norma
//
//  Created by Chris Mauldin on 5/8/25.
//

import SwiftUI
import SwiftData

@main
struct NormaApp: App {
    @StateObject private var appCoordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            AppCoordinatorView()
                .environmentObject(appCoordinator)
        }
    }
}
