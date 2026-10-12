//
//  NormaApp.swift
//  Norma
//
//  Created by Chris Mauldin on 5/8/25.
//

import SwiftData
import SwiftUI

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
            let configuration = ModelConfiguration(
                "Norma",
                isStoredInMemoryOnly: isUITesting || ScreenshotMode.isActive
            )
            modelContainer = try ModelContainer(for: Bill.self, UserProfile.self, configurations: configuration)
            ScreenshotMode.seed(modelContainer)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            root
        }
        .modelContainer(modelContainer)
    }

    @ViewBuilder
    private var root: some View {
        // Dark mode is locked with UIUserInterfaceStyle in Info.plist so the
        // keyboard, alerts, and share sheets follow the app. A root-view
        // preferredColorScheme does not reach those.
        if ScreenshotMode.isActive {
            RootView()
                .dynamicTypeSize(ScreenshotMode.dynamicTypeSize)
                .statusBarHidden(true)
                .persistentSystemOverlays(.hidden)
                .transaction { $0.disablesAnimations = true }
        } else {
            RootView()
                .background(alignment: .topLeading) {
                    if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
                        InterfaceStyleProbe()
                            .frame(width: 1, height: 1)
                            .allowsHitTesting(false)
                    }
                }
        }
    }
}
