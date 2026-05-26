//
//  NoteSyncQueue.swift
//  Norma
//
//  Created by Claude on 4/26/26.
//
//  Background queue that drives note extraction and tracks per-note processing
//  state so the canvas can show a status capsule ("thinking", "queued · offline",
//  "synced", etc.).
//
//  Local writes always succeed regardless of connectivity. When offline, notes
//  sit in `.queued` until the network returns; when online, they cycle through
//  `.pending → .syncing → .synced` (or `.error` on failure).
//

import Foundation
import Network
import Observation
import SwiftData

@MainActor
@Observable
final class NoteSyncQueue {
    static let shared = NoteSyncQueue()

    enum SyncState: Equatable {
        case pending
        case syncing
        case queued
        case synced
        case error
    }

    private(set) var pendingUpserts: Set<UUID> = []
    private(set) var pendingDeletions: Set<UUID> = []
    private(set) var noteStates: [UUID: SyncState] = [:]
    private(set) var isOnline: Bool = false

    @ObservationIgnored private let monitor = NWPathMonitor()
    @ObservationIgnored private let monitorQueue = DispatchQueue(label: "com.myndfruit.Norma.NoteSyncQueue")
    @ObservationIgnored private var modelContainer: ModelContainer?
    @ObservationIgnored private var extractor: NoteExtractionService = .shared
    @ObservationIgnored private var inFlight: Set<UUID> = []

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            Task { @MainActor in
                self?.handleConnectivityChange(online: online)
            }
        }
        monitor.start(queue: monitorQueue)
    }

    /// Wires the queue to a SwiftData container so it can look up notes by id
    /// and persist extracted tokens. Call once at app launch.
    func attach(modelContainer: ModelContainer, extractor: NoteExtractionService = .shared) {
        self.modelContainer = modelContainer
        self.extractor = extractor
    }

    func enqueueUpsert(noteId: UUID) {
        pendingDeletions.remove(noteId)
        pendingUpserts.insert(noteId)
        // Don't overwrite .syncing — an in-flight call's race-protection branch
        // will re-queue if the text changed under it.
        if noteStates[noteId] != .syncing {
            noteStates[noteId] = isOnline ? .pending : .queued
        }
        Task { await flush() }
    }

    func enqueueDeletion(noteId: UUID) {
        pendingUpserts.remove(noteId)
        pendingDeletions.insert(noteId)
        noteStates.removeValue(forKey: noteId)
        Task { await flush() }
    }

    func state(for noteId: UUID) -> SyncState? {
        noteStates[noteId]
    }

    func retry(noteId: UUID) {
        guard pendingUpserts.contains(noteId) || noteStates[noteId] == .error else { return }
        pendingUpserts.insert(noteId)
        noteStates[noteId] = isOnline ? .pending : .queued
        Task { await flush() }
    }

    /// Best-effort drain. No-ops when offline so callers never block on network.
    func flush() async {
        guard isOnline, let modelContainer else { return }

        let context = modelContainer.mainContext
        let snapshot = pendingUpserts.subtracting(inFlight)
        for noteId in snapshot {
            inFlight.insert(noteId)
            await processOne(noteId: noteId, context: context)
            inFlight.remove(noteId)
        }
    }

    private func processOne(noteId: UUID, context: ModelContext) async {
        let descriptor = FetchDescriptor<Note>(predicate: #Predicate { $0.id == noteId })
        guard let note = try? context.fetch(descriptor).first else {
            pendingUpserts.remove(noteId)
            noteStates.removeValue(forKey: noteId)
            return
        }

        let textAtSend = note.rawText
        noteStates[noteId] = .syncing

        do {
            let tokens = try await extractor.extract(text: textAtSend)

            // Race protection: if the user kept typing while we were extracting,
            // skip applying these tokens — the next flush has fresher text.
            // Trigger a fresh flush so the re-queued note gets picked up.
            guard note.rawText == textAtSend else {
                noteStates[noteId] = isOnline ? .pending : .queued
                Task { await flush() }
                return
            }

            // Route through the repo helper so reminder confirmation
            // (and any other future cross-extraction state) is preserved
            // when the LLM re-emits a token the user has already acted on.
            NoteRepository.applyExtractedTokens(tokens, to: note, in: context)
            try context.save()

            pendingUpserts.remove(noteId)
            noteStates[noteId] = .synced
            scheduleSyncedFade(noteId: noteId)

            let hasNotifiable = tokens.contains { $0.kind == .bill || $0.kind == .reminder }
            if hasNotifiable {
                requestNotificationPermissionIfNeeded()
            }
        } catch {
            print("NoteSyncQueue extract failed id=\(noteId) error=\(error)")
            noteStates[noteId] = .error
        }
    }

    private func requestNotificationPermissionIfNeeded() {
        let service = NotificationService.shared
        guard !service.isNotificationsEnabled else { return }
        guard service.notificationPermissionStatus == .notDetermined else { return }
        Task {
            _ = await service.requestNotificationPermission()
        }
    }

    private func scheduleSyncedFade(noteId: UUID) {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            if noteStates[noteId] == .synced {
                noteStates.removeValue(forKey: noteId)
            }
        }
    }

    private func handleConnectivityChange(online: Bool) {
        let wasOnline = isOnline
        isOnline = online

        if online && !wasOnline {
            for (id, state) in noteStates where state == .queued {
                noteStates[id] = .pending
            }
            Task { await flush() }
        } else if !online {
            for (id, state) in noteStates where state == .pending || state == .syncing {
                noteStates[id] = .queued
            }
        }
    }
}
