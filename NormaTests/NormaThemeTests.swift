//
//  NormaThemeTests.swift
//  NormaTests
//
//  The rebuild tokens. Expected hex and spacing values are literals, so
//  editing a token without editing the literal fails the test.
//

import SwiftUI
import Testing
import UIKit

@testable import Norma

@MainActor
struct NormaThemeTests {
    @Test func colorHexesAreLocked() {
        expectLocked(NormaTheme.silver, hex: 0xE4E6E8, hexString: "#E4E6E8")
        expectLocked(NormaTheme.ink, hex: 0x111111, hexString: "#111111")
        expectLocked(NormaTheme.navy, hex: 0x222E38, hexString: "#222E38")
        expectLocked(NormaTheme.slate, hex: 0x667387, hexString: "#667387")
        expectLocked(NormaTheme.plum, hex: 0x51474F, hexString: "#51474F")
        expectLocked(NormaTheme.coral, hex: 0xCC664D, hexString: "#CC664D")
        expectLocked(NormaTheme.pressedTagButtonNavy, hex: 0x13191F, hexString: "#13191F")
        expectLocked(NormaTheme.pressedTagButtonCoral, hex: 0x70382A, hexString: "#70382A")
        #expect(
            NormaTheme.swatches.map(\.name) == [
                "silver",
                "ink",
                "navy",
                "slate",
                "plum",
                "coral",
                "pressed tag-button navy",
                "pressed tag-button coral",
            ])
        #expect(
            NormaTheme.swatches.map(\.hex) == [
                NormaTheme.silver.hex,
                NormaTheme.ink.hex,
                NormaTheme.navy.hex,
                NormaTheme.slate.hex,
                NormaTheme.plum.hex,
                NormaTheme.coral.hex,
                NormaTheme.pressedTagButtonNavy.hex,
                NormaTheme.pressedTagButtonCoral.hex,
            ])
    }

    @Test func textStylesUseInstrumentSansFaces() {
        #expect(
            Set(NormaTheme.textStyles.map(\.postScriptName)) == [
                "InstrumentSans-Regular",
                "InstrumentSans-Medium",
                "InstrumentSans-Bold",
            ])
        #expect(NormaTheme.textStyles.allSatisfy { $0.kind == .text })
    }

    @Test func numberStylesUseCommitMono() {
        #expect(NormaTheme.numberStyles.isEmpty == false)
        #expect(
            NormaTheme.numberStyles.allSatisfy { style in
                style.kind == .number && style.postScriptName == "CommitMono-Regular"
            })
    }

    @Test func realBalanceUsesCommitMonoBold() {
        #expect(NormaTheme.realBalance.kind == .realBalance)
        #expect(NormaTheme.realBalance.postScriptName == "CommitMono-Bold")
        #expect(NormaTheme.realBalance.size == 48)
        #expect(NormaTheme.typeStyles == NormaTheme.textStyles + NormaTheme.numberStyles + [NormaTheme.realBalance])
    }

    @Test func typeRampSizesAreLocked() {
        #expect(NormaTheme.title.size == 28)
        #expect(NormaTheme.title.postScriptName == "InstrumentSans-Bold")
        #expect(NormaTheme.body.size == 17)
        #expect(NormaTheme.body.postScriptName == "InstrumentSans-Regular")
        #expect(NormaTheme.label.size == 13)
        #expect(NormaTheme.label.postScriptName == "InstrumentSans-Medium")
        #expect(NormaTheme.caption.size == 12)
        #expect(NormaTheme.caption.kind == .text)
        #expect(NormaTheme.caption.postScriptName == "InstrumentSans-Regular")
        #expect(NormaTheme.number.size == 17)
        #expect(NormaTheme.number.postScriptName == "CommitMono-Regular")
        #expect(NormaTheme.numberLarge.size == 28)
        #expect(NormaTheme.numberLarge.postScriptName == "CommitMono-Regular")
        #expect(NormaTheme.textStyles == [NormaTheme.title, NormaTheme.body, NormaTheme.label, NormaTheme.caption])
    }

    @Test func radiiAreCard36AndPanel28() {
        #expect(NormaTheme.cardRadius == 36)
        #expect(NormaTheme.panelRadius == 28)
        #expect(NormaTheme.radii.map(\.name) == ["card", "panel"])
        #expect(NormaTheme.radii.map(\.value) == [NormaTheme.cardRadius, NormaTheme.panelRadius])
    }

    @Test func shapeAlwaysUsesContinuousCorners() {
        let radii: [CGFloat] = [0, 7, 28, 36, 100]
        for radius in radii {
            let shape = NormaTheme.shape(radius)
            #expect(shape == RoundedRectangle(cornerRadius: radius, style: .continuous))
            #expect(shape.style == .continuous)
            #expect(shape.cornerSize == CGSize(width: radius, height: radius))
        }
    }

    @Test func spacingTokensAreTheFourPointGrid() {
        #expect(NormaTheme.spacing4 == 4)
        #expect(NormaTheme.spacing8 == 8)
        #expect(NormaTheme.spacing12 == 12)
        #expect(NormaTheme.spacing16 == 16)
        #expect(NormaTheme.spacing24 == 24)
        #expect(NormaTheme.spacing32 == 32)
        #expect(NormaTheme.spacing == [4, 8, 12, 16, 24, 32])
    }

    @Test func hairlineIsOnePixel() {
        #expect(NormaTheme.hairline(displayScale: 1) == 1)
        #expect(NormaTheme.hairline(displayScale: 2) == 0.5)
        #expect(NormaTheme.hairline(displayScale: 3) == 1 / CGFloat(3))
    }

    private func expectLocked(_ swatch: NormaTheme.Swatch, hex: UInt32, hexString: String) {
        #expect(swatch.hex == hex)
        #expect(swatch.hexString == hexString)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        let uiColor = UIColor(swatch.color)
        #expect(uiColor.getRed(&red, &green, &blue, &alpha))
        #expect(byte(red) == Int((hex >> 16) & 0xFF))
        #expect(byte(green) == Int((hex >> 8) & 0xFF))
        #expect(byte(blue) == Int(hex & 0xFF))
        #expect(byte(alpha) == 255)
    }

    private func byte(_ component: CGFloat) -> Int {
        Int((component * 255).rounded())
    }
}
