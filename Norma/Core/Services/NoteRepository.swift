//
//  NoteRepository.swift
//  Norma
//
//  Created by Claude on 4/26/26.
//
//  Reminder scheduling + reconciliation utilities for NoteToken-backed
//  reminders. Notes (prose + extraction) were removed in the runway-first
//  pivot; what survives here is the reminder plumbing the chat, forecast,
//  and reminders/calendar sheets still rely on.
//

import Foundation
import SwiftData

@MainActor
final class NoteRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Reminder confirmation state

    /// Clears a reminder token's confirmation stamp — used when the user
    /// dismisses a reminder from RemindersSheet/CalendarSheet. The OS
    /// notification itself is cancelled by the caller; this only touches the
    /// local model so the token no longer reads as confirmed.
    func unconfirmReminder(tokenId: UUID) {
        let descriptor = FetchDescriptor<NoteToken>(
            predicate: #Predicate { $0.id == tokenId }
        )
        guard let token = try? context.fetch(descriptor).first else { return }
        token.confirmedAt = nil
        save()
    }

    // MARK: - Reminder scheduling

    static func reminderIdentifier(tokenId: UUID) -> String {
        // Prefix must stay "ai_reminder_" so RemindersSheet/CalendarSheet
        // (which filter pending notifications by that prefix) pick up
        // token reminders alongside chat- and bill-created ones.
        "\(reminderIdentifierPrefix)\(tokenId.uuidString)"
    }

    /// Inverse of reminderIdentifier — returns nil for identifiers that
    /// belong to other reminder sources (bills) rather than token reminders.
    /// Used by the reminders/calendar sheets to route a sheet-side cancel
    /// back to the originating NoteToken.
    static func parseReminderTokenId(from identifier: String) -> UUID? {
        guard identifier.hasPrefix(reminderIdentifierPrefix) else { return nil }
        let suffix = identifier.dropFirst(reminderIdentifierPrefix.count)
        return UUID(uuidString: String(suffix))
    }

    static let reminderIdentifierPrefix = "ai_reminder_note_"

    /// Awaitable core — builds the notification and returns the OS's verdict
    /// so callers can react to a refusal. Standalone (no note): the chat
    /// creates reminders directly on a NoteToken.
    static func scheduleReminderRequest(
        _ token: NoteToken,
        fireDate: Date
    ) async -> Result<String, Error> {
        let subject = token.subject?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedSubject = (subject?.isEmpty == false ? subject! : "reminder")
        let identifier = reminderIdentifier(tokenId: token.id)
        let recurrence = mapRecurrence(token.recurrence)
        let userInfo: [String: Any] = [
            "subject": resolvedSubject,
            "tokenId": token.id.uuidString
        ]
        return await NotificationService.shared.scheduleAIReminder(
            title: resolvedSubject,
            message: "",
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

    private func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            assertionFailure("NoteRepository save failed: \(error)")
        }
    }
}
