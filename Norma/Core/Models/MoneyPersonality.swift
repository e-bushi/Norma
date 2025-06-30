//
//  MoneyPersonality.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation

struct MoneyPersonality: Identifiable, Codable {
    var id: String?
    let userId: String
    let category: String
    let primaryTrait: String
    let subconscious: String
    let patterns: [String]
    let strengths: [String]
    let growthAreas: [String]
    let psychologicalBarriers: [String]
    var createdAt: String?
    var updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case category
        case primaryTrait = "primary_trait"
        case subconscious
        case patterns
        case strengths
        case growthAreas = "growth_areas"
        case psychologicalBarriers = "psychological_barriers"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}