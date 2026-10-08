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
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let modelContainer: ModelContainer

    init() {
        do {
            // A fresh store name: the bills-and-income schema shares nothing
            // with the old runway store, so starting clean avoids a migration.
            // UI tests launch with `--ui-testing` to start from an empty store every run.
            let isUITesting = ProcessInfo.processInfo.arguments.contains("--ui-testing")
            let configuration = ModelConfiguration("Norma", isStoredInMemoryOnly: isUITesting)
            modelContainer = try ModelContainer(for: Bill.self, UserProfile.self, configurations: configuration)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(modelContainer)
    }
}
