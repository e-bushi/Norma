//
//  CoinTier.swift
//  Norma
//
//  Created by Claude on 12/29/25.
//

import Foundation
import SwiftUI

/// Represents a coin tier in the progression system
/// Users unlock higher-tier coins based on their arc count (months of bills covered)
enum CoinTier: String, CaseIterable, Identifiable {
    case starter = "norma-coin-starter"
    case basic = "norma-coin"
    case silver = "norma-coin-silver"
    case tealSteel = "norma-coin-teal-steel"
    case gold = "norma-coin-gold"
    case skyBeige = "norma-coin-sky-beige"
    case pinkPanther = "norma-coin-pink-panther"
    case opal = "norma-coin-opal"
    case royalty = "norma-coin-royalty"

    var id: String { rawValue }

    /// The USDZ file name (without extension)
    var fileName: String { rawValue }

    /// Minimum arc count required to unlock this coin
    var requiredArcs: Int {
        switch self {
        case .starter: return 0
        case .basic: return 1
        case .silver: return 2
        case .tealSteel: return 3
        case .gold: return 4
        case .skyBeige: return 6
        case .pinkPanther: return 8
        case .opal: return 10
        case .royalty: return 12
        }
    }

    /// Display name for the coin
    var displayName: String {
        switch self {
        case .starter: return "Starter"
        case .basic: return "Basic"
        case .silver: return "Silver"
        case .tealSteel: return "Teal Steel"
        case .gold: return "Gold"
        case .skyBeige: return "Sky Beige"
        case .pinkPanther: return "Pink Panther"
        case .opal: return "Opal"
        case .royalty: return "Royalty"
        }
    }

    /// Glow color for the coin's halo effect
    var glowColor: Color {
        switch self {
        case .starter: return Color.gray
        case .basic: return Color(red: 0.72, green: 0.52, blue: 0.30)
        case .silver: return Color(red: 0.75, green: 0.75, blue: 0.8)
        case .tealSteel: return Color(red: 0.4, green: 0.7, blue: 0.7)
        case .gold: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .skyBeige: return Color(red: 0.96, green: 0.87, blue: 0.70)
        case .pinkPanther: return Color("NormaPastelPink")
        case .opal: return Color(red: 0.68, green: 0.85, blue: 0.90)
        case .royalty: return Color(red: 0.6, green: 0.4, blue: 0.8)
        }
    }

    /// All tiers in progression order (lowest to highest)
    static var allTiersInOrder: [CoinTier] {
        [.starter, .basic, .silver, .tealSteel, .gold, .skyBeige, .pinkPanther, .opal, .royalty]
    }
}
