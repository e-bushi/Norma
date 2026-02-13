//
//  ChallengeDifficulty.swift
//  Norma
//
//  Created by Claude on 12/30/25.
//

import Foundation
import SwiftUI

/// Represents the difficulty level for a spending challenge
/// Higher difficulty = tighter budget but more points on completion
enum ChallengeDifficulty: String, Codable, CaseIterable, Identifiable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"

    var id: String { rawValue }

    /// Points earned for completing a challenge at this difficulty
    var pointReward: Int {
        switch self {
        case .easy: return 1
        case .medium: return 2
        case .hard: return 3
        }
    }

    /// Budget multiplier applied to the calculated challenge amount
    /// Easy = 20% less budget (tight)
    /// Medium = 40% less budget (strict)
    /// Hard = 60% less budget (extreme)
    var budgetMultiplier: Double {
        switch self {
        case .easy: return 0.8
        case .medium: return 0.6
        case .hard: return 0.4
        }
    }

    /// Display name for the difficulty
    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }

    /// SF Symbol icon for the difficulty
    var icon: String {
        switch self {
        case .easy: return "leaf.fill"
        case .medium: return "flame.fill"
        case .hard: return "bolt.fill"
        }
    }

    /// Color associated with the difficulty
    var color: Color {
        switch self {
        case .easy: return Color("NormaPastelTeal")
        case .medium: return Color("NormaPastelPurple")
        case .hard: return Color("NormaPastelCoral")
        }
    }

    /// Short description of what this difficulty means
    var description: String {
        switch self {
        case .easy: return "Tight budget"
        case .medium: return "Strict budget"
        case .hard: return "Extreme budget"
        }
    }
}
