//
//  CachedCategory.swift
//  Norma
//
//  Created by Claude on 7/20/25.
//

import Foundation
import SwiftData

@Model
final class CachedCategory {
    @Attribute(.unique) var id: String
    var userId: String
    var name: String
    var type: String
    var icon: String
    var colorHex: String
    var parentCategoryId: String?
    var isSystem: Bool
    var isActive: Bool
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date
    
    // Sync metadata
    var lastSyncedAt: Date
    var isFromCache: Bool = true
    
    init(
        id: String,
        userId: String,
        name: String,
        type: String,
        icon: String,
        colorHex: String,
        parentCategoryId: String? = nil,
        isSystem: Bool = false,
        isActive: Bool = true,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastSyncedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.type = type
        self.icon = icon
        self.colorHex = colorHex
        self.parentCategoryId = parentCategoryId
        self.isSystem = isSystem
        self.isActive = isActive
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastSyncedAt = lastSyncedAt
    }
    
    // Convert from Supabase Category model
    convenience init(from category: Category) {
        let formatter = ISO8601DateFormatter()
        let createdDate = category.createdAt.flatMap { formatter.date(from: $0) } ?? Date()
        let updatedDate = category.updatedAt.flatMap { formatter.date(from: $0) } ?? Date()
        
        self.init(
            id: category.id ?? UUID().uuidString,
            userId: category.userId,
            name: category.name,
            type: category.type.rawValue,
            icon: category.icon,
            colorHex: category.colorHex,
            parentCategoryId: category.parentCategoryId,
            isSystem: category.isSystem,
            isActive: category.isActive,
            sortOrder: category.sortOrder,
            createdAt: createdDate,
            updatedAt: updatedDate,
            lastSyncedAt: Date()
        )
    }
    
    // Convert to Supabase Category model
    func toCategory() -> Category {
        let formatter = ISO8601DateFormatter()
        
        return Category(
            id: id,
            userId: userId,
            name: name,
            type: CategoryType(rawValue: type) ?? .expense,
            icon: icon,
            colorHex: colorHex,
            parentCategoryId: parentCategoryId,
            isSystem: isSystem,
            isActive: isActive,
            sortOrder: sortOrder,
            createdAt: formatter.string(from: createdAt),
            updatedAt: formatter.string(from: updatedAt)
        )
    }
}