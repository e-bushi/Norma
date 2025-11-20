//
//  NormaApp.swift
//  Norma
//
//  Created by Chris Mauldin on 5/8/25.
//

import SwiftUI
import SwiftData
import RevenueCat

@main
struct NormaApp: App {
    @StateObject private var appCoordinator = AppCoordinator()
    
    let modelContainer: ModelContainer
    
    init() {
        do {
            self.modelContainer = try ModelContainer(for: CachedBill.self, CachedExpense.self, CachedBudget.self, CachedCategory.self)
//            Purchases.logLevel = .debug
//            Purchases.configure(withAPIKey: "appl_yYpBhkamzaQglHiLXRoRouGgjTf", appUserID: nil)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppCoordinatorView()
                .environmentObject(appCoordinator)
                .modelContainer(modelContainer)
        }
    }
}
