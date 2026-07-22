//
//  NoteToken.swift
//  Norma
//
//  Created by Claude on 4/26/26.
//

import Foundation
import SwiftData

@Model
final class NoteToken {
    @Attribute(.unique) var id: UUID
    var kindRaw: String
    var amount: Double
    var currency: String
    var usdEquivalent: Double?
    var categoryRaw: String?
    var subject: String?
    var counterparty: String?
    var recurrenceRaw: String?
    var occurredAt: Date
    var sourceStart: Int
    var sourceEnd: Int
    /// Local-first flag: true when produced by the on-device regex pass and not yet
    /// confirmed by the server-side LLM extractor. Visually identical either way.
    var isProvisional: Bool

    /// Canonical reminder fire time. Nil = the user hasn't set a time yet, so
    /// the chip renders in a "needs info" state. Ignored for non-reminder kinds.
    var remindAt: Date?

    /// When the user explicitly confirmed an extracted reminder by tapping the
    /// chip. Nil = unconfirmed and no OS notification has been scheduled.
    /// Only meaningful for `.reminder` kind.
    var confirmedAt: Date?

    /// Source bill ID for `.billPayment` tokens. Nil for all other kinds.
    var billId: String?

    /// Stamp set when the user directly mutates an `.intent`/`.commit` token
    /// (upgrading an intention to a commitment, or advancing it to a later
    /// month). Nil = machine-owned. Retained from the notes era; still set by
    /// direct token edits in the forecast.
    var userAdjustedAt: Date? = nil

    enum Kind: String, Codable, CaseIterable {
        case bill
        case income
        case transfer
        /// Non-financial: a scheduled notification extracted from prose like
        /// "remind me to call mom friday." `occurredAt` doubles as the fire time;
        /// `subject` carries the message body. `amount`/`currency` are unused.
        case reminder
        /// Tentative future spend extracted from intent prose like "thinking about
        /// a $200 Bali stay." `occurredAt` is the creation date; the token is
        /// scoped to the month it was created in and swept at month-end.
        case intent
        /// Firm one-shot obligation, upgraded from an `.intent` token by the user.
        /// `occurredAt` is the due date; auto-removed after that date passes.
        case commit
        /// Created when the user marks a bill paid in BillsView. Lives in today's
        /// note as a chip (the audit trail) but is excluded from spending pace
        /// totals — the bill is already pre-deducted from breathing room. Carries
        /// `billId` linking back to the source bill.
        case billPayment
    }

    /// Fixed taxonomy enforced at extraction time. Anything that doesn't fit
    /// a specific bucket falls back to `.other`. Aggregation/filtering reads
    /// off this enum, while the chip's `subject` carries the descriptive text.
    enum Category: String, Codable, CaseIterable {
        case takeout
        case groceries
        case transport
        case lodging
        case leisure
        case shopping
        case services
        case gifts
        case health
        case utilities
        case subscriptions
        case work
        case other

        var displayName: String { rawValue }
    }

    enum Recurrence: String, Codable, CaseIterable {
        case daily
        case weekly
        case biweekly
        case monthly
        case quarterly
        case yearly
    }

    var kind: Kind {
        // Fallback is `.bill` so any legacy tokens persisted with the
        // removed `.expense` kindRaw remain readable as the most generic
        // financial chip rather than crashing on a missing case.
        get { Kind(rawValue: kindRaw) ?? .bill }
        set { kindRaw = newValue.rawValue }
    }

    var category: Category? {
        get { categoryRaw.flatMap(Category.init(rawValue:)) }
        set { categoryRaw = newValue?.rawValue }
    }

    var recurrence: Recurrence? {
        get { recurrenceRaw.flatMap(Recurrence.init(rawValue:)) }
        set { recurrenceRaw = newValue?.rawValue }
    }

    init(
        id: UUID = UUID(),
        kind: Kind,
        amount: Double,
        currency: String,
        usdEquivalent: Double? = nil,
        category: Category? = nil,
        subject: String? = nil,
        counterparty: String? = nil,
        recurrence: Recurrence? = nil,
        occurredAt: Date = Date(),
        sourceStart: Int = 0,
        sourceEnd: Int = 0,
        isProvisional: Bool = false,
        remindAt: Date? = nil,
        confirmedAt: Date? = nil,
        billId: String? = nil,
        userAdjustedAt: Date? = nil
    ) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.amount = amount
        self.currency = currency
        self.usdEquivalent = usdEquivalent
        self.categoryRaw = category?.rawValue
        self.subject = subject
        self.counterparty = counterparty
        self.recurrenceRaw = recurrence?.rawValue
        self.occurredAt = occurredAt
        self.sourceStart = sourceStart
        self.sourceEnd = sourceEnd
        self.isProvisional = isProvisional
        self.remindAt = remindAt
        self.confirmedAt = confirmedAt
        self.billId = billId
        self.userAdjustedAt = userAdjustedAt
    }
}

// MARK: - Recurrence projection

extension NoteToken.Recurrence {
    /// Approximate occurrences-per-year, used to convert any recurrence to a monthly equivalent.
    var occurrencesPerYear: Double {
        switch self {
        case .daily: return 365
        case .weekly: return 52
        case .biweekly: return 26
        case .monthly: return 12
        case .quarterly: return 4
        case .yearly: return 1
        }
    }

    /// DateComponents used to step from one occurrence to the next.
    var stepComponents: DateComponents {
        switch self {
        case .daily: return DateComponents(day: 1)
        case .weekly: return DateComponents(day: 7)
        case .biweekly: return DateComponents(day: 14)
        case .monthly: return DateComponents(month: 1)
        case .quarterly: return DateComponents(month: 3)
        case .yearly: return DateComponents(year: 1)
        }
    }

    var displayLabel: String {
        switch self {
        case .daily: return "DAILY"
        case .weekly: return "WEEKLY"
        case .biweekly: return "BIWEEKLY"
        case .monthly: return "MONTHLY"
        case .quarterly: return "QUARTERLY"
        case .yearly: return "YEARLY"
        }
    }
}

extension NoteToken {
    /// The next occurrence at or after `now` for a recurring token.
    /// Returns nil for one-shot tokens.
    func nextOccurrence(after now: Date = Date(), calendar: Calendar = .current) -> Date? {
        guard let recurrence else { return nil }
        var date = occurredAt
        while date <= now {
            guard let next = calendar.date(byAdding: recurrence.stepComponents, to: date) else { return nil }
            date = next
        }
        return date
    }

    /// Monthly-equivalent amount for recurring tokens (in the token's currency).
    var monthlyEquivalent: Double? {
        guard let recurrence else { return nil }
        return amount * recurrence.occurrencesPerYear / 12.0
    }

    /// USD monthly equivalent if a USD conversion is known.
    var monthlyUsdEquivalent: Double? {
        guard let recurrence, let usd = usdEquivalent else { return nil }
        return usd * recurrence.occurrencesPerYear / 12.0
    }
}
