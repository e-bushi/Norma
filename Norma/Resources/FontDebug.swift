//
//  FontDebug.swift
//  Norma
//
//  Temporary file to debug font names
//

import UIKit

func printAvailableFonts() {
    print("\n=== AVAILABLE FONTS ===")

    // Print all font families
    UIFont.familyNames.sorted().forEach { family in
        print("\nFamily: \(family)")
        UIFont.fontNames(forFamilyName: family).forEach { font in
            print("  Font: \(font)")
        }
    }

    // Specifically check for our fonts
    print("\n=== CHECKING CUSTOM FONTS ===")

    let customFonts = ["Rubik", "Nunito", "DM Sans", "Lexend Deca"]
    customFonts.forEach { fontFamily in
        let fonts = UIFont.fontNames(forFamilyName: fontFamily)
        if fonts.isEmpty {
            print("❌ \(fontFamily) - NOT FOUND")
        } else {
            print("✅ \(fontFamily) - Found:")
            fonts.forEach { print("   \($0)") }
        }
    }
}
