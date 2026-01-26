//
//  NormaApp.swift
//  Norma
//
//  Created by Chris Mauldin on 5/8/25.
//

import SwiftUI
import SwiftData
import RevenueCat
import PostHog

@main
struct NormaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appCoordinator = AppCoordinator()

    let modelContainer: ModelContainer

    init() {
        do {
            self.modelContainer = try ModelContainer(for: CachedBill.self, CachedExpense.self, CachedChallenge.self, CachedCategory.self, CachedPendingTransaction.self, CachedUserReward.self)
            Purchases.logLevel = .debug
            Purchases.configure(withAPIKey: "appl_yYpBhkamzaQglHiLXRoRouGgjTf", appUserID: nil)

            // PostHog Analytics
            let config = PostHogConfig(
                apiKey: "phc_t1kD6Jxu4T8LtnVCEKP1vZW3SrVW8t03vJJ5dhY3ND9",
                host: "https://us.i.posthog.com"
            )
            config.debug = true  // Enable debug logging to see events in console
            config.flushAt = 1   // Flush after every event for testing (remove in production)
            PostHogSDK.shared.setup(config)
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
