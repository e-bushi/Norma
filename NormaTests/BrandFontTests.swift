//
//  BrandFontTests.swift
//  NormaTests
//
//  The brand fonts bundled for APP-94. UIFont(name:size:) looks up the
//  PostScript name, which resolves after the app host loads UIAppFonts.
//

import Testing
import UIKit

@MainActor
struct BrandFontTests {
    @Test(arguments: [
        "InstrumentSans-Regular",
        "InstrumentSans-Medium",
        "InstrumentSans-SemiBold",
        "InstrumentSans-Bold",
        "CommitMono-Regular",
        "CommitMono-Bold",
    ])
    func postScriptNameLoads(_ postScriptName: String) {
        let font = UIFont(name: postScriptName, size: 16)
        #expect(font != nil)
        #expect(font?.fontName == postScriptName)
    }
}
