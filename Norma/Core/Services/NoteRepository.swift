//
//  NoteRepository.swift
//  Norma
//
//  Created by Claude on 4/26/26.
//
//  Local-first write API for notes. Wraps SwiftData ModelContext.
//
//  Read path is intentionally not centralized here — views should use @Query
//  to bind directly to the local store. The repository owns the *write* path
//  so that every mutation can stamp updatedAt and enqueue background sync
//  in one place.

import Foundation
import SwiftData

@MainActor
final class NoteRepository {
    private let context: ModelContext
    private let syncQueue: NoteSyncQueue

    init(context: ModelContext, syncQueue: NoteSyncQueue = .shared) {
        self.context = context
        self.syncQueue = syncQueue
    }

    // MARK: - Reads (one-shot)

    /// The note for the current local day. Convenience wrapper around `note(forDate:)`.
    func today(calendar: Calendar = .current) -> Note {
        note(forDate: Date(), calendar: calendar)
    }

    /// The earliest note created on the day of `date`. If none exists, a fresh
    /// note is inserted with `createdAt` pinned to start-of-day for that date.
    /// "Earliest" means the daily note auto-created on first launch — confirmed
    /// transactions land there, not in whichever thematic note happens to be newest.
    func note(forDate date: Date, calendar: Calendar = .current) -> Note {
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

        let descriptor = FetchDescriptor<Note>(
            predicate: #Predicate { $0.createdAt >= startOfDay && $0.createdAt < endOfDay },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )

        if let existing = try? context.fetch(descriptor).first {
            return existing
        }

        let fresh = Note()
        fresh.createdAt = startOfDay
        fresh.updatedAt = startOfDay
        context.insert(fresh)
        save()
        syncQueue.enqueueUpsert(noteId: fresh.id)
        return fresh
    }

    // MARK: - Writes

    /// Updates the raw text on a note. Tokens are produced by the server-side
    /// LLM extractor and arrive asynchronously via the sync queue — existing
    /// chips remain visible while new text is in flight.
    func updateText(_ text: String, on note: Note) {
        note.rawText = text
        touch(note)
    }

    /// Updates the user-editable hero title.
    func updateTitle(_ title: String?, on note: Note) {
        note.title = title
        touch(note)
    }

    /// Replaces the token list on a note. User-facing entry point — also
    /// stamps updatedAt and re-enqueues a sync. The actual swap and reminder
    /// reconciliation live in `applyExtractedTokens` so the background queue
    /// can share the same path without re-triggering its own sync.
    func replaceTokens(_ tokens: [NoteToken], on note: Note) {
        Self.applyExtractedTokens(tokens, to: note, in: context)
        touch(note)
    }

    /// Pure token-swap + reminder reconciliation. Called by both the repo's
    /// `replaceTokens` (user-driven) and `NoteSyncQueue.processOne` (extractor
    /// background flow), so confirmation preservation runs on every path that
    /// can rewrite a note's tokens. Caller is responsible for `context.save()`
    /// and any sync bookkeeping.
    ///
    /// Reminder reconciliation:
    /// - The user's confirmation (`confirmedAt`) is preserved across re-extractions
    ///   by matching old vs new reminder tokens on (subject, remindAt). When the
    ///   LLM re-emits the same reminder, the carry-over keeps the chip in its
    ///   confirmed state and re-arms the OS notification under the new token id.
    /// - All old reminder notifications are cancelled first to keep a clean slate;
    ///   only new reminders that carry confirmation forward get re-scheduled.
    static func applyExtractedTokens(
        _ tokens: [NoteToken],
        to note: Note,
        in context: ModelContext
    ) {
        let outgoingReminders = note.tokens.filter { $0.kind == .reminder }
        let confirmedLookup: [ReminderKey: Date] = Dictionary(
            uniqueKeysWithValues: outgoingReminders.compactMap { token -> (ReminderKey, Date)? in
                guard let confirmedAt = token.confirmedAt,
                      let key = reminderKey(for: token)
                else { return nil }
                return (key, confirmedAt)
            }
        )

        for id in outgoingReminders.map(\.id) {
            NotificationService.shared.cancelAIReminder(identifier: reminderIdentifier(tokenId: id))
        }
        for old in note.tokens { context.delete(old) }
        note.tokens = tokens

        for token in tokens where token.kind == .reminder {
            if let key = reminderKey(for: token), let prior = confirmedLookup[key] {
                token.confirmedAt = prior
                scheduleReminder(token, on: note)
            }
        }

        // Promote recurring bill tokens into canonical Bill records so they
        // surface in BillsView/ForecastSheet. Dedupes against existing bills,
        // so re-extractions of the same note don't create duplicates.
        BillTokenBridge.shared.reconcile(extractedTokens: tokens)
    }

    /// User-driven confirmation: stamps confirmedAt, persists the chosen time
    /// (if the chip was in "needs info" state and the user just picked one),
    /// and schedules the OS notification. Idempotent — calling again replaces
    /// any existing scheduled notification with the new time.
    func confirmReminder(_ token: NoteToken, remindAt: Date, on note: Note) {
        guard token.kind == .reminder else { return }
        token.remindAt = remindAt
        token.occurredAt = remindAt
        token.confirmedAt = Date()
        Self.scheduleReminder(token, on: note)
        touch(note)
    }

    /// Inverse of confirmReminder — used when the user dismisses a reminder
    /// from RemindersSheet. Clears the local confirmation stamp so the chip
    /// flips back to its dashed/unconfirmed state, and so the next LLM
    /// re-extraction's preservation logic finds no entry to carry forward
    /// (preventing zombie OS notifications). The OS notification itself is
    /// expected to be cancelled by the caller — this method only touches
    /// the local model.
    func unconfirmReminder(tokenId: UUID) {
        let descriptor = FetchDescriptor<NoteToken>(
            predicate: #Predicate { $0.id == tokenId }
        )
        guard let token = try? context.fetch(descriptor).first else { return }
        token.confirmedAt = nil
        if let parent = token.note {
            touch(parent)
        } else {
            save()
        }
    }

    /// Deletes a note. Cascade rule on the relationship cleans up its tokens;
    /// we still need to cancel any OS notifications scheduled for reminder tokens.
    func delete(_ note: Note) {
        let id = note.id
        let reminderIds = note.tokens.filter { $0.kind == .reminder }.map(\.id)
        context.delete(note)
        save()
        syncQueue.enqueueDeletion(noteId: id)
        for tokenId in reminderIds {
            NotificationService.shared.cancelAIReminder(identifier: Self.reminderIdentifier(tokenId: tokenId))
        }
    }

    // MARK: - Reminder scheduling

    static func reminderIdentifier(tokenId: UUID) -> String {
        // Prefix must stay "ai_reminder_" so the existing RemindersSheet
        // (which filters NotificationService.getPendingAIReminders by that
        // prefix) picks up note-token reminders alongside chat-created ones.
        "\(reminderIdentifierPrefix)\(tokenId.uuidString)"
    }

    /// Inverse of reminderIdentifier — returns nil for identifiers that
    /// belong to other reminder sources (chat, bills) rather than note
    /// tokens. Used by RemindersSheet to route a sheet-side cancel back
    /// to the originating NoteToken.
    static func parseReminderTokenId(from identifier: String) -> UUID? {
        guard identifier.hasPrefix(reminderIdentifierPrefix) else { return nil }
        let suffix = identifier.dropFirst(reminderIdentifierPrefix.count)
        return UUID(uuidString: String(suffix))
    }

    static let reminderIdentifierPrefix = "ai_reminder_note_"

    /// Identity for matching reminders across re-extractions. Subject is
    /// normalized (trimmed + lowercased) and paired with the fire time so a
    /// "pay rent at 9am may 5" stays matched even if surrounding prose changes.
    /// Returns nil for reminders that don't have enough info to identify
    /// stably — those start fresh as unconfirmed each extraction.
    struct ReminderKey: Hashable {
        let subject: String
        let remindAt: Date
    }

    static func reminderKey(for token: NoteToken) -> ReminderKey? {
        guard let subject = token.subject?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              !subject.isEmpty,
              let remindAt = token.remindAt
        else { return nil }
        return ReminderKey(subject: subject, remindAt: remindAt)
    }

    static func scheduleReminder(_ token: NoteToken, on note: Note) {
        guard let fireDate = token.remindAt else { return }
        let title = (note.title?.isEmpty == false ? note.title : nil) ?? "reminder"
        let body = token.subject ?? "reminder"
        let identifier = reminderIdentifier(tokenId: token.id)
        let recurrence = mapRecurrence(token.recurrence)
        Task { @MainActor in
            _ = await NotificationService.shared.scheduleAIReminder(
                title: title,
                message: body,
                remindAt: fireDate,
                reminderType: .general,
                recurrence: recurrence,
                identifier: identifier
            )
        }
    }

    /// Maps the richer NoteToken.Recurrence enum onto NotificationService.Recurrence.
    /// Biweekly/quarterly/yearly fall back to one-time scheduling — the OS
    /// scheduler doesn't support those cadences directly.
    private static func mapRecurrence(_ r: NoteToken.Recurrence?) -> NotificationService.Recurrence {
        switch r {
        case .daily: return .daily
        case .weekly: return .weekly
        case .monthly: return .monthly
        default: return .none
        }
    }

    // MARK: - Internals

    /// Stamp updatedAt, persist, enqueue sync.
    private func touch(_ note: Note) {
        note.updatedAt = Date()
        save()
        syncQueue.enqueueUpsert(noteId: note.id)
    }

    private func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            // Local saves shouldn't fail; if they do it's a programming error.
            assertionFailure("NoteRepository save failed: \(error)")
        }
    }
}
