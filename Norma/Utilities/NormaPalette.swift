//
//  NormaPalette.swift
//  Norma
//
//  The app's color tokens. Every screen reads from here, so the dark
//  editorial look stays consistent and the user-picked accent (AppTheme)
//  reaches every view without extra wiring.
//

import SwiftUI

enum NormaPalette {
    /// User-selectable accent — reads the persisted `AppTheme` choice.
    static var lavender: Color { AppTheme.current.color }

    /// Full-bleed canvas behind onboarding and the home screen (#0E0E10).
    static let canvas = Color(red: 0.055, green: 0.055, blue: 0.063)
    /// Sheet background (#16161A).
    static let sheet = Color(red: 0x16 / 255, green: 0x16 / 255, blue: 0x1A / 255)

    /// Warm off-white primary text (#F2EDE2). Use instead of pure white.
    static let ink = Color(red: 0.949, green: 0.929, blue: 0.886)
    /// Mid-warm gray for secondary labels (#7A7670).
    static let inkSubtle = Color(red: 0.478, green: 0.463, blue: 0.439)
    /// Dark gray for meta text and dividers (#5C5852).
    static let inkMuted = Color(red: 0.361, green: 0.345, blue: 0.322)
    /// Near-black text drawn on top of the accent fill.
    static let onAccent = Color(red: 0x0E / 255, green: 0x0E / 255, blue: 0x10 / 255)

    /// Paydays and money coming in.
    static let income = Color(red: 0.45, green: 0.80, blue: 0.55)
    /// Overspent months and overdue bills.
    static let warning = Color(red: 0.93, green: 0.58, blue: 0.35)
    /// Destructive actions.
    static let danger = Color(red: 0xE0 / 255, green: 0x7B / 255, blue: 0x6F / 255)
}
