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

    init(
        id: UUID = UUID(),
        type: InsightType,
        headline: String,
        detail: String,
        sourceNoteIds: [UUID] = [],
        createdAt: Date = Date(),
        isRead: Bool = false
    ) {
        self.id = id
        self.type = type
        self.headline = headline
        self.detail = detail
        self.sourceNoteIds = sourceNoteIds
        self.createdAt = createdAt
        self.isRead = isRead
    }
}
