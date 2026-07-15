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

    /// Persist and enqueue a sync without overwriting rawText. Used when the
    /// view has already set `note.rawText` immediately (for race protection)
    /// and the debounced save just needs to flush to disk + trigger extraction.
    func saveAndSync(_ note: Note) {
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
        // Deduplicate — the LLM occasionally emits the same entity twice
        // when prose is ambiguous, contains typos, or rephrases the same fact.
        var tokens: [NoteToken] = {
            var seen = Set<String>()
            return tokens.filter { seen.insert(deduplicationKey(for: $0)).inserted }
        }()

        // Sticky user-adjusted intentions/commitments: the user moved or
        // upgraded these directly on the token (the prose never changed), so a
        // re-extraction must keep them as-is rather than reverting to a fresh
        // LLM emission. Drop any newly-emitted intent/commit whose subject
        // matches one we're preserving, so we don't end up with a duplicate.
        let stickyUserTokens = note.tokens.filter {
            ($0.kind == .intent || $0.kind == .commit) && $0.userAdjustedAt != nil
        }
        let stickyUserSubjects = Set(stickyUserTokens.compactMap { normalizedSubject(for: $0) })
        if !stickyUserSubjects.isEmpty {
            tokens = tokens.filter { token in
                guard token.kind == .intent || token.kind == .commit,
                      let subject = normalizedSubject(for: token)
                else { return true }
                return !stickyUserSubjects.contains(subject)
            }
        }

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
        // Preserve both sticky reminder tokens and user-adjusted intent/commit
        // tokens; delete everything else and rebuild from the fresh emission.
        let preservedIds = stickyIds.union(stickyUserTokens.map { $0.id })
        let preservedTokens = note.tokens.filter { preservedIds.contains($0.id) }
        for old in note.tokens where !preservedIds.contains(old.id) {
            context.delete(old)
        }
        note.tokens = tokens + preservedTokens

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

    /// Why user-facing confirmation can fail. Surfaced so the canvas can
    /// explain the failure instead of silently leaving the chip dashed.
    enum ReminderConfirmFailure {
        case notificationsDenied
        case timeAlreadyPassed
        case schedulingFailed
    }

    /// User-driven confirmation: schedules the OS notification first, and only
    /// stamps confirmedAt once the OS accepts it — the chip must never read
    /// "confirmed" for a reminder that doesn't exist. Returns nil on success,
    /// or the failure reason so the caller can surface it. If the user has
    /// never answered the notification-permission prompt, asks now — at the
    /// moment the permission visibly matters. Idempotent — confirming again
    /// replaces any existing scheduled notification with the new time.
    ///
    /// Does NOT re-enqueue the LLM extractor: the note's prose hasn't changed,
    /// only the user's confirmation state on an existing token. Re-extracting
    /// would replace this token with a fresh one (new UUID) and drop the
    /// confirmation if the user picked a time different from what the LLM
    /// originally inferred — the chip would visibly flip back to dashed.
    @discardableResult
    func confirmReminder(_ token: NoteToken, remindAt: Date, on note: Note) async -> ReminderConfirmFailure? {
        guard token.kind == .reminder else { return nil }

        let service = NotificationService.shared
        await service.refreshPermissionStatus()
        if service.notificationPermissionStatus == .notDetermined {
            _ = await service.requestNotificationPermission()
        }

        let result = await Self.scheduleReminderRequest(token, fireDate: remindAt, on: note)
        if case .failure(let error) = result {
            switch error as? NotificationError {
            case .permissionDenied: return .notificationsDenied
            case .invalidDate: return .timeAlreadyPassed
            default: return .schedulingFailed
            }
        }

        token.remindAt = remindAt
        token.occurredAt = remindAt
        token.confirmedAt = Date()
        note.updatedAt = Date()
        save()
        return nil
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

    /// Fingerprint for deduplication within a single extraction batch.
    /// Reminders key on kind+subject; financial tokens key on kind+amount+currency+subject+recurrence.
    private static func deduplicationKey(for token: NoteToken) -> String {
        let subject = normalizedSubject(for: token) ?? ""
        if token.kind == .reminder {
            return "reminder|\(subject)"
        }
        let amt = String(format: "%.2f", token.amount)
        let rec = token.recurrence?.rawValue ?? ""
        return "\(token.kind.rawValue)|\(amt)|\(token.currency.uppercased())|\(subject)|\(rec)"
    }

    /// Fire-and-forget scheduling for the re-extraction path, where the
    /// confirmation being carried forward is already the source of truth and
    /// there is no user interaction to report a failure to.
    static func scheduleReminder(_ token: NoteToken, on note: Note) {
        guard let fireDate = token.remindAt else { return }
        Task { @MainActor in
            _ = await scheduleReminderRequest(token, fireDate: fireDate, on: note)
        }
    }

    /// Awaitable core — builds the notification and returns the OS's verdict
    /// so user-driven paths (confirmReminder) can react to a refusal.
    static func scheduleReminderRequest(
        _ token: NoteToken,
        fireDate: Date,
        on note: Note? = nil
    ) async -> Result<String, Error> {
        let subject = token.subject?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedSubject = (subject?.isEmpty == false ? subject! : "reminder")
        let noteTitle = note?.title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = (noteTitle?.isEmpty == false) ? "from your '\(noteTitle!)' note" : ""
        let identifier = reminderIdentifier(tokenId: token.id)
        let recurrence = mapRecurrence(token.recurrence)
        var userInfo: [String: Any] = [
            "subject": resolvedSubject,
            "tokenId": token.id.uuidString
        ]
        if let note { userInfo["noteId"] = note.id.uuidString }
        return await NotificationService.shared.scheduleAIReminder(
            title: resolvedSubject,
            message: body,
            remindAt: fireDate,
            reminderType: .general,
            recurrence: recurrence,
            identifier: identifier,
            userInfo: userInfo
        )
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
