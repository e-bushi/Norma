//
//  LocalDataReset.swift
//  Norma
//
//  Wipes every piece of user data on the device. Backs "reset all data" in
//  Settings — there's no server copy, so this is irreversible.
//

import Foundation
import SwiftData
import UserNotifications

/// The app's single ModelContainer, published at launch so non-View code
/// (the reset path) can reach SwiftData.
enum AppModelContainer {
    static var shared: ModelContainer?
}

@MainActor
enum LocalDataReset {

    /// User-scoped UserDefaults artifacts — engagement state and engine caches.
    private static let userDefaultsKeys = [
        "reanchor.lastCelebratedStreak",
        "reanchor.lastFreedomMilestoneDays",
        "paydayNudge.dismissedTimestamp",
        "runwayInsight.lastRunAt",
        "runwayInsight.lastTier",
        "didBackfillBillReminders"
    ]

    /// Deletes every locally persisted row of every model, plus user-scoped
    /// defaults and any scheduled notifications.
    static func wipeAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        userDefaultsKeys.forEach { UserDefaults.standard.removeObject(forKey: $0) }

        guard let container = AppModelContainer.shared else { return }
        let context = container.mainContext
        do {
            try context.delete(model: NoteToken.self)
            try context.delete(model: CachedBill.self)
            try context.delete(model: FreedomFundEntry.self)
            try context.delete(model: CapturedTransaction.self)
            try context.delete(model: Insight.self)
            try context.delete(model: UserProfile.self)
            try context.save()
        } catch {
            print("LocalDataReset: wipe failed — \(error)")
        }
    }
}
