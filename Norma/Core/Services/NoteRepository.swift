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

    /// The note for the current local day, if one exists. Convenience wrapper
    /// around `note(forDate:)`. Returns nil when the user has not yet created
    /// a note today — notes are only created through explicit user action.
    func today(calendar: Calendar = .current) -> Note? {
        note(forDate: Date(), calendar: calendar)
    }

    /// The earliest note created on the day of `date`, or nil if none exists.
    /// "Earliest" means the first note the user wrote that day — confirmed
    /// transactions and bill-payment chips land there, not in whichever
    /// thematic note happens to be newest.
    func note(forDate date: Date, calendar: Calendar = .current) -> Note? {
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

        let descriptor = FetchDescriptor<Note>(
            predicate: #Predicate { $0.createdAt >= startOfDay && $0.createdAt < endOfDay },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )

        return try? context.fetch(descriptor).first
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
    /// Reminder reconciliation across re-extractions:
    ///
    /// - When the LLM re-emits a reminder (subject matches an old one), we
    ///   carry forward the user's `confirmedAt` and chosen `remindAt`/
    ///   `occurredAt` onto the freshly-emitted token, then re-schedule the
    ///   OS notification under the new token id. The user-picked time wins
    ///   over whatever the LLM re-infers from the prose.
    ///
    /// - When the LLM drops a previously-confirmed reminder (subject no
    ///   longer present in new emission), we treat the user's confirmation
    ///   as sticky: the old token survives the swap, its OS notification is
    ///   left alone, and it remains attached to the note. The LLM's
    ///   extraction can drift across edits (rephrasing, dropped phrases,
    ///   ambiguous prose) — confirmation is the source of truth, and the
    ///   only way to remove a confirmed reminder is the explicit cancel
    ///   button on the reminders sheet.
    static func applyExtractedTokens(
        _ tokens: [NoteToken],
        to note: Note,
        in context: ModelContext
    ) {
        struct Carry { let confirmedAt: Date; let remindAt: Date }
        let outgoingReminders = note.tokens.filter { $0.kind == .reminder }

        let confirmedLookup: [String: Carry] = Dictionary(
            outgoingReminders.compactMap { token -> (String, Carry)? in
                guard let confirmedAt = token.confirmedAt,
                      let remindAt = token.remindAt,
                      let subject = normalizedSubject(for: token)
                else { return nil }
                return (subject, Carry(confirmedAt: confirmedAt, remindAt: remindAt))
            },
            uniquingKeysWith: { first, _ in first }
        )

        let newReminderSubjects: Set<String> = Set(
            tokens.compactMap { $0.kind == .reminder ? normalizedSubject(for: $0) : nil }
        )

        // Sticky old reminders: confirmed by the user and not represented in the
        // new emission. Keep these tokens, leave their OS notifications alone.
        let stickyIds: Set<UUID> = Set(
            outgoingReminders.compactMap { token -> UUID? in
                guard token.confirmedAt != nil,
                      let subject = normalizedSubject(for: token),
                      !newReminderSubjects.contains(subject)
                else { return nil }
                return token.id
            }
        )

        // Cancel only the outgoing reminders we won't preserve as-is.
        for old in outgoingReminders where !stickyIds.contains(old.id) {
            NotificationService.shared.cancelAIReminder(identifier: reminderIdentifier(tokenId: old.id))
        }
        // Delete only non-sticky tokens. Sticky reminder tokens stay attached.
        let stickyTokens = note.tokens.filter { stickyIds.contains($0.id) }
        for old in note.tokens where !stickyIds.contains(old.id) {
            context.delete(old)
        }
        note.tokens = tokens + stickyTokens

        for token in tokens where token.kind == .reminder {
            if let subject = normalizedSubject(for: token), let prior = confirmedLookup[subject] {
                token.confirmedAt = prior.confirmedAt
                token.remindAt = prior.remindAt
                token.occurredAt = prior.remindAt
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
    ///
    /// Does NOT re-enqueue the LLM extractor: the note's prose hasn't changed,
    /// only the user's confirmation state on an existing token. Re-extracting
    /// would replace this token with a fresh one (new UUID) and drop the
    /// confirmation if the user picked a time different from what the LLM
    /// originally inferred — the chip would visibly flip back to dashed.
    func confirmReminder(_ token: NoteToken, remindAt: Date, on note: Note) {
        guard token.kind == .reminder else { return }
        token.remindAt = remindAt
        token.occurredAt = remindAt
        token.confirmedAt = Date()
        note.updatedAt = Date()
        Self.scheduleReminder(token, on: note)
        save()
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

    /// Normalized subject used as the identity key for matching reminders
    /// across re-extractions. Returns nil when the subject is missing or
    /// blank — those tokens start fresh as unconfirmed each extraction.
    static func normalizedSubject(for token: NoteToken) -> String? {
        guard let subject = token.subject?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              !subject.isEmpty
        else { return nil }
        return subject
    }

    static func scheduleReminder(_ token: NoteToken, on note: Note) {
        guard let fireDate = token.remindAt else { return }
        let subject = token.subject?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedSubject = (subject?.isEmpty == false ? subject! : "reminder")
        let noteTitle = note.title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = (noteTitle?.isEmpty == false) ? "from your '\(noteTitle!)' note" : ""
        let identifier = reminderIdentifier(tokenId: token.id)
        let recurrence = mapRecurrence(token.recurrence)
        let userInfo: [String: Any] = [
            "subject": resolvedSubject,
            "noteId": note.id.uuidString,
            "tokenId": token.id.uuidString
        ]
        Task { @MainActor in
            _ = await NotificationService.shared.scheduleAIReminder(
                title: resolvedSubject,
                message: body,
                remindAt: fireDate,
                reminderType: .general,
                recurrence: recurrence,
                identifier: identifier,
                userInfo: userInfo
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
