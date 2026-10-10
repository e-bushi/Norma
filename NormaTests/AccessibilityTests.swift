//
//  AccessibilityTests.swift
//  NormaTests
//
//  Weekday chip order, payday subtitles, calendar day labels, contrast of
//  the muted text tokens, and Rubik's variable-font weight axis.
//

import CoreText
import Foundation
import Testing
import UIKit
@testable import Norma

private let enUS: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_US")
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

private func utcDay(_ year: Int, _ month: Int, _ day: Int) -> Date {
    enUS.date(from: DateComponents(year: year, month: month, day: day))!
}

struct WeekdayOrderTests {
    @Test func sundayFirstLocaleKeepsGregorianOrder() {
        #expect(WeekdayOrder.ordered(firstWeekday: 1) == [1, 2, 3, 4, 5, 6, 7])
    }

    @Test func mondayFirstLocaleStartsOnMondayAndKeepsStoredValues() {
        let ordered = WeekdayOrder.ordered(firstWeekday: 2)
        #expect(ordered == [2, 3, 4, 5, 6, 7, 1])
        #expect(Set(ordered) == Set(1...7))
    }

    @Test func saturdayFirstWrapsThroughTheWeek() {
        #expect(WeekdayOrder.ordered(firstWeekday: 7) == [7, 1, 2, 3, 4, 5, 6])
    }
}

struct PaydaySubtitleTests {
    @Test func threePaydaysShareOneMonthName() {
        let paydays = [utcDay(2026, 10, 2), utcDay(2026, 10, 16), utcDay(2026, 10, 30)]
        #expect(PaydaySubtitle.line(for: paydays, calendar: enUS) == "3 paydays · Oct 2, 16, 30")
    }

    @Test func onePaydayUsesTheSingular() {
        #expect(PaydaySubtitle.line(for: [utcDay(2026, 10, 2)], calendar: enUS) == "1 payday · Oct 2")
    }

    @Test func noPaydaysProducesNoSubtitle() {
        #expect(PaydaySubtitle.line(for: [], calendar: enUS) == nil)
    }

    @Test func aNewMonthRepeatsTheMonthName() {
        let paydays = [utcDay(2026, 10, 30), utcDay(2026, 11, 13)]
        #expect(PaydaySubtitle.line(for: paydays, calendar: enUS) == "2 paydays · Oct 30, Nov 13")
    }
}

struct CalendarDayLabelTests {
    @Test func paydayAndUnpaidBill() {
        let label = CalendarDayLabel.day(
            date: utcDay(2026, 10, 16),
            isPayday: true,
            bills: [CalendarDayLabel.Bill(name: "Rent", isPaid: false)],
            calendar: enUS
        )
        #expect(label == "October 16, payday, rent due")
    }

    @Test func paidBillOmitsPayday() {
        let label = CalendarDayLabel.spoken(
            monthDay: "October 16",
            isPayday: false,
            bills: [CalendarDayLabel.Bill(name: "Phone", isPaid: true)]
        )
        #expect(label == "October 16, phone paid")
    }

    @Test func severalBillsAreEachNamed() {
        let label = CalendarDayLabel.spoken(
            monthDay: "October 16",
            isPayday: true,
            bills: [
                CalendarDayLabel.Bill(name: "Rent", isPaid: false),
                CalendarDayLabel.Bill(name: "Phone", isPaid: false),
            ]
        )
        #expect(label == "October 16, payday, rent due, phone due")
    }
}

struct PaletteContrastTests {
    @Test func mutedAndSubtleClearBodyTextContrastOnCanvasAndSheets() {
        let minimum = 4.5
        for background in [NormaPalette.canvasSRGB, NormaPalette.sheetSRGB] {
            #expect(NormaPalette.inkMutedSRGB.contrastRatio(on: background) >= minimum)
            #expect(NormaPalette.inkSubtleSRGB.contrastRatio(on: background) >= minimum)
        }
    }

    @Test func subtleStaysLighterThanMuted() {
        #expect(NormaPalette.inkSubtleSRGB.relativeLuminance > NormaPalette.inkMutedSRGB.relativeLuminance)
    }
}

struct DynamicTypeScaleTests {
    @Test func bodyTextGrowsAtTheLargestAccessibilitySize() {
        let large = VariableFont.scaledSize(16, relativeTo: .body, dynamicTypeSize: .large)
        let ax = VariableFont.scaledSize(16, relativeTo: .body, dynamicTypeSize: .accessibility5)
        #expect(abs(large - 16) < 1)
        #expect(ax > large)
    }

    @Test func heroSizeGrowsInsteadOfShrinkingToHalf() {
        let large = VariableFont.scaledSize(64, relativeTo: .largeTitle, dynamicTypeSize: .large)
        let ax = VariableFont.scaledSize(64, relativeTo: .largeTitle, dynamicTypeSize: .accessibility5)
        #expect(ax >= large)
        #expect(ax > 32)
    }
}

struct RubikFontTests {
    @Test func everyFaceUsesTheVariableFontAndItsWeightAxis() {
        let expected: [(FontConvertible, CGFloat)] = [
            (FontFamily.Rubik.light, 300),
            (FontFamily.Rubik.regular, 400),
            (FontFamily.Rubik.medium, 500),
            (FontFamily.Rubik.semiBold, 600),
            (FontFamily.Rubik.bold, 700),
            (FontFamily.Rubik.extraBold, 800),
            (FontFamily.Rubik.black, 900),
        ]
        for (face, axis) in expected {
            #expect(face.path == "Rubik-Variable.ttf")
            #expect(VariableFont.postScriptName(for: face) == "Rubik-Light")
            #expect(VariableFont.weightAxis(for: face) == axis)
        }
    }

    @Test func registeredFacesAreRubikAndIncreaseInWeight() throws {
        let faces = [
            FontFamily.Rubik.light,
            FontFamily.Rubik.regular,
            FontFamily.Rubik.medium,
            FontFamily.Rubik.semiBold,
            FontFamily.Rubik.bold,
            FontFamily.Rubik.extraBold,
            FontFamily.Rubik.black,
        ]
        var previous = -2.0
        for face in faces {
            let font = try #require(VariableFont.uiFont(face, size: 18))
            let family = font.familyName.lowercased()
            let name = font.fontName.lowercased()
            #expect(family.contains("rubik") || name.contains("rubik"))
            let weight = weightTrait(font)
            #expect(weight > previous)
            previous = weight
        }
    }

    private func weightTrait(_ font: UIFont) -> Double {
        let traits = CTFontCopyTraits(font) as NSDictionary
        return (traits[kCTFontWeightTrait] as? NSNumber)?.doubleValue ?? -999
    }
}
