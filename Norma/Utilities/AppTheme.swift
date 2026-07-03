//
//  AppTheme.swift
//  Norma
//
//  User-selectable accent theme — the app's main UI accent. The dark
//  background/canvas colors in NormaPalette stay static; only this hue is
//  user-changeable. Selection persists via UserDefaults, and
//  NormaPalette.lavender reads it directly so every existing call site
//  (including the Metal dither "thinking" animation) picks up the choice
//  without further wiring.
//
//  Presets are the original brand lavender plus four other color families.
//  They're chosen to stay clear of the app's existing semantic pastel
//  colors (teal = success/timezone, coral = danger/reminders — see
//  NormaPastelTeal / NormaPastelCoral in Assets.xcassets) so picking a
//  non-purple accent doesn't get visually confused with those meanings.
//

import SwiftUI

struct AccentTheme: Identifiable, Equatable {
    let id: String
    let name: String
    let color: Color
}

enum AppTheme {
    static let storageKey = "selectedAccentThemeID"
    static let defaultID = "lavender"

    static let presets: [AccentTheme] = [
        AccentTheme(id: "lavender", name: "lavender", color: Color(red: 0.588, green: 0.463, blue: 0.851)),
        AccentTheme(id: "ocean", name: "ocean", color: Color(red: 0.380, green: 0.541, blue: 0.780)),
        AccentTheme(id: "sage", name: "sage", color: Color(red: 0.573, green: 0.663, blue: 0.494)),
        AccentTheme(id: "amber", name: "amber", color: Color(red: 0.827, green: 0.639, blue: 0.361)),
        AccentTheme(id: "berry", name: "berry", color: Color(red: 0.780, green: 0.412, blue: 0.573)),
    ]

    /// Falls back to the default (current brand lavender) if nothing has
    /// been picked yet or the stored id no longer matches a preset.
    static var current: AccentTheme {
        let id = UserDefaults.standard.string(forKey: storageKey) ?? defaultID
        return presets.first(where: { $0.id == id }) ?? presets[0]
    }
}
