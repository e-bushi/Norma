//
//  Category.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation
import SwiftUI

struct Category: Identifiable, Codable, Hashable {
    var id: String?
    let name: String
    let type: CategoryType
    let icon: String
    let colorHex: String
    let isSystem: Bool
    let isActive: Bool
    let sortOrder: Int
    var createdAt: String?
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case icon
        case colorHex = "color_hex"
        case isSystem = "is_system"
        case isActive = "is_active"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: String? = nil,
        name: String,
        type: CategoryType,
        icon: String,
        colorHex: String,
        isSystem: Bool = false,
        isActive: Bool = true,
        sortOrder: Int = 0,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.icon = icon
        self.colorHex = colorHex
        self.isSystem = isSystem
        self.isActive = isActive
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
    
    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(type)
        hasher.combine(icon)
        hasher.combine(colorHex)
        hasher.combine(isSystem)
        hasher.combine(isActive)
        hasher.combine(sortOrder)
    }

    static func == (lhs: Category, rhs: Category) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.type == rhs.type &&
               lhs.icon == rhs.icon &&
               lhs.colorHex == rhs.colorHex &&
               lhs.isSystem == rhs.isSystem &&
               lhs.isActive == rhs.isActive &&
               lhs.sortOrder == rhs.sortOrder
    }
}

enum CategoryType: String, Codable, CaseIterable {
    case income = "Income"
    case expense = "Expense"
    case both = "Both"
}

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let length = hexSanitized.count
        
        if length == 6 {
            let r = Double((rgb & 0xFF0000) >> 16) / 255.0
            let g = Double((rgb & 0x00FF00) >> 8) / 255.0
            let b = Double(rgb & 0x0000FF) / 255.0
            self.init(red: r, green: g, blue: b)
        } else if length == 8 {
            let r = Double((rgb & 0xFF000000) >> 24) / 255.0
            let g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            let b = Double((rgb & 0x0000FF00) >> 8) / 255.0
            let a = Double(rgb & 0x000000FF) / 255.0
            self.init(red: r, green: g, blue: b, opacity: a)
        } else {
            return nil
        }
    }
}