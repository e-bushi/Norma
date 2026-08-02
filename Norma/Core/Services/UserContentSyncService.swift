//
//  UserContentSyncService.swift
//  Norma
//
//  Mirror-sync for user-authored SwiftData content (note tokens + captured
//  transactions). Unlike the freedom-fund ledger — which pushes on each of
//  its few write paths — tokens are written from many places (chat
//  extraction, forecast edits, bill payments, month-end sweeps), so this
//  syncs by snapshot instead of by hook:
//
//    - restore: local empty + server populated (first appear after the
//      post-logout wipe) → pull everything down.
//    - mirror:  otherwise local is truth → upsert all local rows up and
//      delete server rows that no longer exist locally.
//
//  Runs on home appear (throttled) and when the app resigns active, so the
//  server copy is at most one session-moment stale.
//

import Foundation
import SwiftData
import UIKit

@MainActor
enum UserContentSync {
    private static var activeUserId: String?
    /// Guards the restore pass: once a user has restored (or had nothing to
    /// restore), an intentionally emptied local set must not resurrect.
    private static var restoredForUser: String?
    private static var lastMirror: Date = .distantPast
    private static var observerInstalled = false

    /// Entry point — call whenever the home appears with a logged-in user.
    static func activate(context: ModelContext, userId: String) async {
        guard !userId.isEmpty else { return }
        activeUserId = userId
        installObserverIfNeeded()
        await sync(context: context, force: restoredForUser != userId)
    }

    /// Forget session state on logout so the next login restores cleanly.
    static func reset() {
        activeUserId = nil
        restoredForUser = nil
        lastMirror = .distantPast
    }

    /// Push a final snapshot when the app leaves the foreground — catches
    /// everything written since the last home appear without per-site hooks.
    private static func installObserverIfNeeded() {
        guard !observerInstalled else { return }
        observerInstalled = true
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                guard let container = AppModelContainer.shared else { return }
                await sync(context: container.mainContext, force: true)
            }
        }
    }

    private static func sync(context: ModelContext, force: Bool) async {
        guard let userId = activeUserId else { return }
        guard force || Date().timeIntervalSince(lastMirror) > 30 else { return }
        lastMirror = Date()
        await syncTokens(context: context, userId: userId)
        await syncCaptured(context: context, userId: userId)
        restoredForUser = userId
    }

    private static func syncTokens(context: ModelContext, userId: String) async {
        do {
            let server = try await SupabaseService.shared.fetchNoteTokens(userId: userId)
            let local = (try? context.fetch(FetchDescriptor<NoteToken>())) ?? []

            if local.isEmpty, !server.isEmpty, restoredForUser != userId {
                for record in server { context.insert(record.makeToken()) }
                try? context.save()
                return
            }

            try await SupabaseService.shared.upsertNoteTokens(
                local.map { NoteTokenRecord(token: $0, userId: userId) }
            )
            let localIds = Set(local.map { $0.id.uuidString.lowercased() })
            let stale = server.map(\.id).filter { !localIds.contains($0.lowercased()) }
            try await SupabaseService.shared.deleteNoteTokens(ids: stale)
        } catch {
            print("UserContentSync: token sync failed — \(error)")
        }
    }

    private static func syncCaptured(context: ModelContext, userId: String) async {
        do {
            let server = try await SupabaseService.shared.fetchCapturedTransactions(userId: userId)
            let local = ((try? context.fetch(FetchDescriptor<CapturedTransaction>())) ?? [])
                .filter { $0.userId == userId }

            if local.isEmpty, !server.isEmpty, restoredForUser != userId {
                for record in server { context.insert(record.makeTransaction()) }
                try? context.save()
                return
            }

            try await SupabaseService.shared.upsertCapturedTransactions(
                local.map(CapturedTransactionRecord.init)
            )
            let localIds = Set(local.map { $0.id.lowercased() })
            let stale = server.map(\.id).filter { !localIds.contains($0.lowercased()) }
            try await SupabaseService.shared.deleteCapturedTransactions(ids: stale)
        } catch {
            print("UserContentSync: captured sync failed — \(error)")
        }
    }
}
