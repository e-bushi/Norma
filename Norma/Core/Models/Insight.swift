//
//  Insight.swift
//  Norma
//
//  Created by Claude on 5/26/26.
//

import Foundation
import SwiftData

enum InsightType: String, Codable {
    case pattern
    case nudge
    case milestone
    case anomaly
}

@Model
final class Insight {
    @Attribute(.unique) var id: UUID
    var type: InsightType
    var headline: String
    var detail: String
    var sourceNoteIds: [UUID]
    var createdAt: Date
    var isRead: Bool
    /// Soft-delete stamp. Dismissed insights disappear from InsightsView but
    /// stay persisted as tombstones: the engine's dedup works by showing the
    /// LLM what already exists, so a hard delete would let the same insight
    /// regenerate from the same notes on the next run. Defaulted so existing
    /// rows migrate cleanly.
    var dismissedAt: Date? = nil

    /// Stable identity for a generated insight, independent of the dynamic
    /// numbers in its headline. The rule-based RunwayInsightEngine dedupes on
    /// this so the same collision/spike/tier event isn't re-surfaced every run
    /// (live match = skip; dismissed match = never resurface). Defaulted nil so
    /// existing rows migrate cleanly. Legacy note-era insights have no key.
    var ruleKey: String? = nil

    init(
        id: UUID = UUID(),
        type: InsightType,
        headline: String,
        detail: String,
        sourceNoteIds: [UUID] = [],
        createdAt: Date = Date(),
        isRead: Bool = false,
        dismissedAt: Date? = nil,
        ruleKey: String? = nil
    ) {
        self.id = id
        self.type = type
        self.headline = headline
        self.detail = detail
        self.sourceNoteIds = sourceNoteIds
        self.createdAt = createdAt
        self.isRead = isRead
        self.dismissedAt = dismissedAt
        self.ruleKey = ruleKey
    }
}
