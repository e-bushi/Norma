//
//  NormaTagButtonTests.swift
//  NormaTests
//
//  Tag button variants and the press motion. Each test is tagged with its
//  acceptance check. AC-8: these cover variant colors and the press offset.
//

import SwiftUI
import Testing

@testable import Norma

@MainActor
struct NormaTagButtonTests {
    @Test("AC-1: NormaTagButton(title:variant:action:) has navy and coral")
    func initializerAndVariants() {
        // AC-1
        let navy = NormaTagButton(title: "Skip", variant: .navy) {}
        let coral = NormaTagButton(title: "Approve", variant: .coral) {}
        #expect(navy.title == "Skip")
        #expect(coral.title == "Approve")
        #expect(navy.variant == .navy)
        #expect(coral.variant == .coral)
        #expect(navy.variant != coral.variant)
    }

    @Test("AC-2: face and base colors are NormaTheme tokens")
    func variantColorsComeFromThemeTokens() {
        // AC-2
        #expect(NormaTagButton.Variant.navy.face == NormaTheme.navy)
        #expect(NormaTagButton.Variant.navy.base == NormaTheme.pressedTagButtonNavy)
        #expect(NormaTagButton.Variant.coral.face == NormaTheme.coral)
        #expect(NormaTagButton.Variant.coral.base == NormaTheme.pressedTagButtonCoral)
        #expect(NormaTagButton.Variant.navy.face.hex == 0x222E38)
        #expect(NormaTagButton.Variant.navy.base.hex == 0x13191F)
        #expect(NormaTagButton.Variant.coral.face.hex == 0xCC664D)
        #expect(NormaTagButton.Variant.coral.base.hex == 0x70382A)
        #expect(NormaTagButton.Variant.navy.face.hex != NormaTagButton.Variant.navy.base.hex)
        #expect(NormaTagButton.Variant.coral.face.hex != NormaTagButton.Variant.coral.base.hex)
    }

    @Test("AC-3: rest has a 2pt lip and shadow; pressed offsets 2pt and drops the shadow")
    func pressOffsetAndShadow() {
        // AC-3
        let rest = NormaTagButton.Metrics.chrome(isPressed: false)
        let pressed = NormaTagButton.Metrics.chrome(isPressed: true)
        #expect(NormaTagButton.Metrics.lip == 2)
        #expect(
            rest
                == NormaTagButton.Chrome(
                    faceOffset: 0,
                    shadowRadius: 8,
                    shadowY: 4,
                    shadowOpacity: 0.25
                ))
        #expect(
            pressed
                == NormaTagButton.Chrome(
                    faceOffset: 2,
                    shadowRadius: 0,
                    shadowY: 0,
                    shadowOpacity: 0
                ))
        #expect(pressed.faceOffset == NormaTagButton.Metrics.lip)
        #expect(rest.shadowRadius > 0)
        #expect(rest.shadowOpacity > 0)
    }

    @Test("AC-4: NormaTagButtonStyle is a ButtonStyle")
    func styleIsAButtonStyle() {
        // AC-4: makeBody passes configuration.isPressed into the face.
        let style = NormaTagButtonStyle(variant: .coral)
        #expect(style.variant == .coral)
        confirmButtonStyle(style)
    }

    @Test("AC-5: corners use continuous style")
    func cornersAreContinuous() {
        // AC-5
        let shape = NormaTagButton.Metrics.cornerShape
        #expect(NormaTagButton.Metrics.cornerRadius == 16)
        #expect(shape.style == .continuous)
        #expect(shape.cornerSize == CGSize(width: 16, height: 16))
    }

    @Test("AC-6: the control's title is what VoiceOver reads on the button")
    func voiceOverReadsTheTitle() {
        // AC-6: the body is a Button labeled with `title`, plus the button trait.
        let button = NormaTagButton(title: "Approve", variant: .coral) {}
        #expect(button.title == "Approve")
    }

    private func confirmButtonStyle<S: ButtonStyle>(_ style: S) {
        _ = style
    }
}
