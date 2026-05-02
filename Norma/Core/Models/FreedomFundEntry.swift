//
//  FreedomFundEntry.swift
//  Norma
//
//  Local-first ledger of changes to the user's freedom fund balance. Each
//  entry represents a single observed delta — either a manual edit through
//  FreedomFundEditSheet or a refresh of a Plaid-linked account balance.
//
//  Entries are write-only: we only insert when the new balance differs from
//  the most recent entry's balanceAfter. The Recent Activity list on
//  ArcCountView reads these in reverse-chronological order.
//

import Foundation
import SwiftData

/// What triggered the entry. Drives both the activity-row label and the
/// visual variant (positive/negative delta determines lavender vs muted).
enum FreedomFundEntrySource: String, Codable {
    case manualEdit
    case linkedAccountSync
}

@Model
final class FreedomFundEntry {
    @Attribute(.unique) var id: String
    var userId: String
    var createdAt: Date
    /// Signed change relative to the previous entry's balanceAfter.
    /// Positive = inflow (added/synced higher), negative = outflow.
    var delta: Double
    /// The new balance recorded by this event. Used as the comparison
    /// reference for the next observation.
    var balanceAfter: Double
    /// Raw value of FreedomFundEntrySource — SwiftData persists the string.
    var sourceRaw: String

    var source: FreedomFundEntrySource {
        FreedomFundEntrySource(rawValue: sourceRaw) ?? .manualEdit
    }

    init(
        id: String = UUID().uuidString,
        userId: String,
        createdAt: Date = Date(),
        delta: Double,
        balanceAfter: Double,
        source: FreedomFundEntrySource
    ) {
        self.id = id
        self.userId = userId
        self.createdAt = createdAt
        self.delta = delta
        self.balanceAfter = balanceAfter
        self.sourceRaw = source.rawValue
    }
}
