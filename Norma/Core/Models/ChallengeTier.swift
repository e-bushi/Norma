//
//  ChallengeTier.swift
//  Norma
//
//  Created by Claude on 12/30/25.
//

import Foundation
import SwiftUI

/// Represents a challenge tier in the progression system
/// Users unlock higher-tier birds based on their total challenge points
enum ChallengeTier: Int, CaseIterable, Codable, Identifiable {
    case starter = 0
    case spark = 1
    case ember = 2
    case kindle = 3
    case flame = 4
    case blaze = 5
    case inferno = 6
    case firestorm = 7
    case supernova = 8
    case phoenix = 9

    var id: Int { rawValue }

    /// The USDZ file name (without extension)
    var fileName: String {
        switch self {
        case .starter: return "challenge-bird-starter"
        case .spark: return "challenge-bird-spark"
        case .ember: return "challenge-bird-ember"
        case .kindle: return "challenge-bird-kindle"
        case .flame: return "challenge-bird-flame"
        case .blaze: return "challenge-bird-blaze"
        case .inferno: return "challenge-bird-inferno"
        case .firestorm: return "challenge-bird-firestorm"
        case .supernova: return "challenge-bird-supernova"
        case .phoenix: return "challenge-bird-phoenix"
        }
    }

    /// Minimum points required to unlock this tier
    /// Updated for daily points system - users earn points daily, so thresholds are higher
    var requiredPoints: Int {
        switch self {
        case .starter: return 0
        case .spark: return 5
        case .ember: return 25
        case .kindle: return 60
        case .flame: return 120
        case .blaze: return 200
        case .inferno: return 300
        case .firestorm: return 450
        case .supernova: return 650
        case .phoenix: return 1000
        }
    }

    /// Display name for the tier
    var displayName: String {
        switch self {
        case .starter: return "Starter"
        case .spark: return "Spark"
        case .ember: return "Ember"
        case .kindle: return "Kindle"
        case .flame: return "Flame"
        case .blaze: return "Blaze"
        case .inferno: return "Inferno"
        case .firestorm: return "Firestorm"
        case .supernova: return "Supernova"
        case .phoenix: return "Phoenix"
        }
    }

    /// Glow color for the bird's halo effect
    var glowColor: Color {
        switch self {
        case .starter: return Color.gray
        case .spark: return Color(hex: "C4A777") ?? Color.gray           // Muted sand
        case .ember: return Color(hex: "D4886A") ?? Color.gray           // Terracotta
        case .kindle: return Color(hex: "E8705C") ?? Color.gray          // Burnt coral
        case .flame: return Color(hex: "FF6B6B") ?? Color("NormaPastelCoral")  // Coral
        case .blaze: return Color(hex: "4ECDC4") ?? Color("NormaPastelTeal")   // Teal
        case .inferno: return Color(hex: "5B8CDB") ?? Color.blue         // Sky blue
        case .firestorm: return Color(hex: "9B7ED9") ?? Color.purple     // Lavender purple
        case .supernova: return Color(hex: "E8A4B8") ?? Color.pink       // Rose gold
        case .phoenix: return Color(hex: "FFD700") ?? Color.yellow       // Radiant gold
        }
    }

    /// All tiers in progression order (lowest to highest)
    static var allTiersInOrder: [ChallengeTier] {
        [.starter, .spark, .ember, .kindle, .flame, .blaze, .inferno, .firestorm, .supernova, .phoenix]
    }

    /// The next tier after this one, if any
    var nextTier: ChallengeTier? {
        guard let currentIndex = ChallengeTier.allTiersInOrder.firstIndex(of: self),
              currentIndex < ChallengeTier.allTiersInOrder.count - 1 else {
            return nil
        }
        return ChallengeTier.allTiersInOrder[currentIndex + 1]
    }

    /// Points needed to reach the next tier from this tier
    var pointsToNextTier: Int? {
        guard let next = nextTier else { return nil }
        return next.requiredPoints - requiredPoints
    }
}
