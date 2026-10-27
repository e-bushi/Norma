//
//  NormaCardTests.swift
//  NormaTests
//
//  Padding, radius, and hairline for NormaCard. Expected values are
//  literals, so a token change that drifts from the spec fails here.
//
//  AC-5: NormaCard.swift has no hex literals and no raw size literals.
//  Radius, padding, and the hairline all read from NormaTheme.
//  AC-6: the NormaCard preview shows text and a CommitMono number
//  (NormaTheme.number). The card draws a stroke and does not apply a shadow.
//

import SwiftUI
import Testing

@testable import Norma

@MainActor
struct NormaCardTests {
    @Test func acceptsAnyContent() {
        // AC-1
        let textCard = NormaCard { Text("hello") }
        let stackCard = NormaCard {
            VStack(alignment: .leading, spacing: NormaTheme.spacing8) {
                Text("Left this month")
                Text("1,234.50")
            }
        }
        let emptyCard = NormaCard { EmptyView() }

        #expect(textCard.padding == NormaTheme.spacing16)
        #expect(stackCard.padding == NormaTheme.spacing16)
        #expect(emptyCard.padding == NormaTheme.spacing16)
    }

    @Test func radiusIsTheCardRadiusWithContinuousCorners() {
        // AC-2
        let card = NormaCard { Text("rent") }
        let shape = card.shape

        #expect(shape.style == .continuous)
        #expect(shape.cornerSize == CGSize(width: NormaTheme.cardRadius, height: NormaTheme.cardRadius))
        #expect(NormaTheme.cardRadius == 36)
    }

    @Test func borderWidthIsTheHairlineToken() {
        // AC-3
        let card = NormaCard { Text("rent") }
        let scales: [CGFloat] = [1, 2, 3]

        for scale in scales {
            #expect(card.borderWidth(displayScale: scale) == NormaTheme.hairline(displayScale: scale))
        }
        #expect(card.borderWidth(displayScale: 1) == 1)
        #expect(card.borderWidth(displayScale: 2) == 0.5)
        #expect(card.borderWidth(displayScale: 3) == 1 / CGFloat(3))
    }

    @Test func defaultPaddingIsSpacing16() {
        // AC-4
        let card = NormaCard { Text("rent") }

        #expect(card.padding == NormaTheme.spacing16)
        #expect(card.padding == 16)
    }

    @Test func paddingCanBeOverriddenWithAnotherSpacingToken() {
        // AC-4
        let card = NormaCard(padding: NormaTheme.spacing24) { Text("rent") }

        #expect(card.padding == NormaTheme.spacing24)
        #expect(card.padding == 24)
        #expect(card.padding != NormaTheme.spacing16)
    }
}
