//
//  NormaPalette.swift
//  Norma
//
//  The app's color tokens. Every screen reads from here, so the dark
//  editorial look stays consistent and the user-picked accent (AppTheme)
//  reaches every view without extra wiring.
//

import SwiftUI

/// sRGB triple stored as 0...1 channels, so contrast checks read the same
/// numbers the colors are built from.
struct SRGB: Equatable {
    let red: Double
    let green: Double
    let blue: Double

    init(_ red: Double, _ green: Double, _ blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    init(hex: UInt32) {
        red = Double((hex >> 16) & 0xFF) / 255
        green = Double((hex >> 8) & 0xFF) / 255
        blue = Double(hex & 0xFF) / 255
    }

    var color: Color { Color(red: red, green: green, blue: blue) }

    /// WCAG 2 relative luminance.
    var relativeLuminance: Double {
        func channel(_ value: Double) -> Double {
            value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(red) + 0.7152 * channel(green) + 0.0722 * channel(blue)
    }

    /// WCAG 2 contrast ratio of this color drawn on `background`.
    func contrastRatio(on background: SRGB) -> Double {
        let lighter = max(relativeLuminance, background.relativeLuminance)
        let darker = min(relativeLuminance, background.relativeLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }
}

enum NormaPalette {
    /// User-selectable accent — reads the persisted `AppTheme` choice.
    static var lavender: Color { AppTheme.current.color }

    /// Full-bleed canvas behind onboarding and the home screen (#0E0E10).
    static let canvasSRGB = SRGB(hex: 0x0E0E10)
    static let canvas = canvasSRGB.color
    /// Sheet background (#16161A).
    static let sheetSRGB = SRGB(hex: 0x16161A)
    static let sheet = sheetSRGB.color

    /// Warm off-white primary text (#F2EDE2). Use instead of pure white.
    static let ink = Color(red: 0.949, green: 0.929, blue: 0.886)
    /// Secondary labels (#96928C). At least 4.5:1 on the canvas and on sheets.
    static let inkSubtleSRGB = SRGB(hex: 0x96928C)
    static let inkSubtle = inkSubtleSRGB.color
    /// Meta text (#86827C). Quieter than `inkSubtle`, still at least 4.5:1 on both backgrounds.
    static let inkMutedSRGB = SRGB(hex: 0x86827C)
    static let inkMuted = inkMutedSRGB.color
    /// Near-black text drawn on top of the accent fill.
    static let onAccent = Color(red: 0x0E/255, green: 0x0E/255, blue: 0x10/255)

    /// Paydays and money coming in.
    static let income = Color(red: 0.45, green: 0.80, blue: 0.55)
    /// Overspent months and overdue bills.
    static let warning = Color(red: 0.93, green: 0.58, blue: 0.35)
    /// Destructive actions.
    static let danger = Color(red: 0xE0/255, green: 0x7B/255, blue: 0x6F/255)
}
