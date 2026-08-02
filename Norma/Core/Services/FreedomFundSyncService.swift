//
//  FreedomFundSyncService.swift
//  Norma
//
//  Keeps the local (SwiftData) freedom-fund ledger and its Supabase mirror
//  in step. Local stays the read path — offline-first — while every write
//  pushes up fire-and-forget, and the first home-appear per login pulls the
//  account's ledger down. Logout wipes local (see LocalDataReset), so the
//  pull is what makes the ledger follow the account instead of the device.
//

import Foundation
import SwiftData

enum FreedomFundSync {
    /// User the ledger has already been pulled for this session — the pull
    /// runs once per login, not on every home appear.
    private static var pulledForUser: String?

    /// Two-way union merge by entry id: server rows missing locally are
    /// inserted (fresh login on this device); local rows the server has never
    /// seen are uploaded (history from before sync existed, or written while
    /// offline). Call from the main actor with the main-context.
    static func pullIfNeeded(context: ModelContext, userId: String) async {
        guard !userId.isEmpty, pulledForUser != userId else { return }
        pulledForUser = userId
        do {
            let remote = try await SupabaseService.shared.fetchFreedomFundEntries(userId: userId)
            let local = (try? context.fetch(FetchDescriptor<FreedomFundEntry>(
                predicate: #Predicate { $0.userId == userId }
            ))) ?? []
            let localIds = Set(local.map { $0.id.lowercased() })
            let remoteIds = Set(remote.map { $0.id.lowercased() })

            for record in remote where !localIds.contains(record.id.lowercased()) {
                context.insert(FreedomFundEntry(
                    id: record.id,
                    userId: record.userId,
                    createdAt: record.createdAt,
                    delta: record.delta,
                    balanceAfter: record.balanceAfter,
                    source: FreedomFundEntrySource(rawValue: record.source) ?? .manualEdit
                ))
            }
            try? context.save()

            let unsynced = local.filter { !remoteIds.contains($0.id.lowercased()) }
            try await SupabaseService.shared.upsertFreedomFundEntries(
                unsynced.map(FreedomFundEntryRecord.init)
            )
        } catch {
            // Retry on the next home appear rather than silently giving up.
            pulledForUser = nil
            print("FreedomFundSync: pull failed — \(error)")
        }
    }

    /// Mirror a just-written entry up. Fire-and-forget: local is already
    /// saved, and a lost push is recovered by the union merge next login.
    static func push(_ entry: FreedomFundEntry) {
        let record = FreedomFundEntryRecord(entry: entry)
        Task { try? await SupabaseService.shared.upsertFreedomFundEntries([record]) }
    }

    /// Mirror a local ledger deletion up.
    static func pushDelete(id: String) {
        Task { try? await SupabaseService.shared.deleteFreedomFundEntries(ids: [id]) }
    }

    /// Forget the per-session pull marker (logout) so the next login pulls.
    static func reset() {
        pulledForUser = nil
    }
}
