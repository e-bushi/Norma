//
//  LocalDataReset.swift
//  Norma
//
//  Wipes everything client-side on explicit sign-out / account deletion, so
//  the next account on this device starts clean. Only called on deliberate
//  logout — never on a mere session expiry, where unsynced offline data
//  would be lost.
//

import Foundation
import SwiftData

/// The app's single ModelContainer, published at launch so non-View code
/// (session/logout paths) can reach SwiftData.
enum AppModelContainer {
    static var shared: ModelContainer?
}

@MainActor
enum LocalDataReset {

    /// Per-user UserDefaults artifacts that must not leak across accounts.
    private static let userDefaultsKeys = [
        "reanchor.lastCelebratedStreak",
        "reanchor.lastFreedomMilestoneDays",
        "paydayNudge.dismissedTimestamp"
    ]

    /// Deletes every locally persisted row of every model, plus per-user
    /// defaults, and resets the sync session marker.
    static func wipeAll() {
        FreedomFundSync.reset()
        UserContentSync.reset()
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
