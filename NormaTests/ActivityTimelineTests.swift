//
//  ActivityTimelineTests.swift
//  NormaTests
//
//  Row mapping, rail dots, pull states, and the activity card chrome.
//  Each acceptance check is tagged on the test that covers it.
//

import Foundation
import SwiftUI
import Testing

@testable import Norma

@MainActor
struct ActivityTimelineTests {
    @Test func modelRendersAllSixRowTypes() throws {
        // AC-1
        // AC-8
        let model = ActivityTimelineModel.sample
        let rows = model.rows

        #expect(model.summary == "3 days · $271.55 spent")
        #expect(model.days.count == 3)
        let firstDay: ActivityTimelineDay = try #require(model.days.first)
        let firstEntry: ActivityTimelineEntry = try #require(firstDay.entries.first)
        #expect(firstEntry.kind == .insightActive)
        #expect(Set(model.days.map(\.dot)) == Set(ActivityDayDot.allCases))
        #expect(entryKinds(in: rows) == Set(ActivityEntryKind.allCases))
        #expect(rows.contains(where: isDay))

        #expect(ActivityTimelineMetrics.headerTitleText == "Activity")
        #expect(
            ActivityTimelineMetrics.headerTitle
                == ActivityTextStyle(
                    postScriptName: "InstrumentSans-Medium",
                    weight: 600,
                    size: 15,
                    lineHeight: 20,
                    swatch: NormaTheme.ink,
                    textStyle: .subheadline
                ))
        #expect(
            ActivityTimelineMetrics.headerSummary
                == ActivityTextStyle(
                    postScriptName: "CommitMono-Regular",
                    weight: 400,
                    size: 11,
                    lineHeight: 14,
                    swatch: NormaTheme.mist,
                    textStyle: .caption2
                ))
        #expect(ActivityTimelineMetrics.headerTitle.lineSpacing == 5)
        #expect(ActivityTimelineMetrics.columnWidth == 343)
        #expect(ActivityTimelineMetrics.columnGap == 18)
        #expect(ActivityTimelineMetrics.listWidth == 343)
        #expect(ActivityTimelineMetrics.listHeight == 528)
        #expect(ActivityTimelineMetrics.rowSpacerHeight == 12)
        #expect(ActivityTimelineMetrics.baselineGap == 8)

        let today = try day(.today, in: rows)
        #expect(
            ActivityTimelineMetrics.presentation(for: today)
                == ActivityRowPresentation(
                    height: 36,
                    paddingTop: 0,
                    paddingLeading: 22,
                    spaceBetween: true,
                    title: ActivityTextStyle(
                        postScriptName: "InstrumentSans-Medium",
                        weight: 600,
                        size: 16,
                        lineHeight: 20,
                        swatch: NormaTheme.ink,
                        textStyle: .callout
                    ),
                    meta: ActivityTextStyle(
                        postScriptName: "CommitMono-Regular",
                        weight: 400,
                        size: 11,
                        lineHeight: 14,
                        swatch: NormaTheme.mist,
                        textStyle: .caption2
                    ),
                    amount: ActivityTextStyle(
                        postScriptName: "CommitMono-Regular",
                        weight: 400,
                        size: 13,
                        lineHeight: 16,
                        swatch: NormaTheme.ink,
                        textStyle: .footnote
                    ),
                    dot: ActivityTimelineMetrics.dayDotStyle(.today)
                ))

        let active = try entry(.insightActive, in: rows)
        #expect(ActivityTimelineMetrics.presentation(for: active).height == 44)
        #expect(ActivityTimelineMetrics.presentation(for: active).paddingTop == 4)
        #expect(ActivityTimelineMetrics.presentation(for: active).paddingLeading == 38)
        #expect(ActivityTimelineMetrics.presentation(for: active).spaceBetween == false)
        #expect(ActivityTimelineMetrics.presentation(for: active).title.swatch == NormaTheme.ink)
        #expect(ActivityTimelineMetrics.presentation(for: active).title.weight == 400)
        #expect(ActivityTimelineMetrics.presentation(for: active).title.size == 15)
        #expect(ActivityTimelineMetrics.presentation(for: active).title.lineHeight == 20)
        #expect(ActivityTimelineMetrics.presentation(for: active).title.postScriptName == "InstrumentSans-Regular")
        #expect(ActivityTimelineMetrics.presentation(for: active).meta.swatch == NormaTheme.coral)
        #expect(ActivityTimelineMetrics.presentation(for: active).meta.size == 11)
        #expect(ActivityTimelineMetrics.presentation(for: active).meta.lineHeight == 14)
        #expect(ActivityTimelineMetrics.presentation(for: active).amount == nil)

        let insight = try entry(.insight, in: rows)
        #expect(ActivityTimelineMetrics.presentation(for: insight).title.swatch == NormaTheme.graphite)
        #expect(ActivityTimelineMetrics.presentation(for: insight).meta.swatch == NormaTheme.mist)
        #expect(ActivityTimelineMetrics.presentation(for: insight).spaceBetween == false)
        #expect(ActivityTimelineMetrics.presentation(for: insight).height == 44)

        let expenses = try entry(.expenses, in: rows)
        let expensesStyle = ActivityTimelineMetrics.presentation(for: expenses)
        #expect(expensesStyle.spaceBetween)
        #expect(expensesStyle.title.swatch == NormaTheme.graphite)
        #expect(expensesStyle.meta.swatch == NormaTheme.mist)
        #expect(expensesStyle.amount?.size == 13)
        #expect(expensesStyle.amount?.lineHeight == 16)
        #expect(expensesStyle.amount?.swatch == NormaTheme.ink)
        #expect(expensesStyle.amount?.postScriptName == "CommitMono-Regular")

        let event = try entry(.event, in: rows)
        #expect(ActivityTimelineMetrics.presentation(for: event).spaceBetween == false)
        #expect(ActivityTimelineMetrics.presentation(for: event).title.swatch == NormaTheme.graphite)
        #expect(ActivityTimelineMetrics.presentation(for: event).meta.swatch == NormaTheme.mist)
        #expect(ActivityTimelineMetrics.presentation(for: event).amount == nil)

        let priced = try entry(.eventWithAmount, in: rows)
        let pricedStyle = ActivityTimelineMetrics.presentation(for: priced)
        #expect(pricedStyle.spaceBetween)
        #expect(pricedStyle.amount?.postScriptName == "CommitMono-Regular")
        #expect(pricedStyle.amount?.weight == 400)
        #expect(pricedStyle.amount?.size == 12)
        #expect(pricedStyle.amount?.lineHeight == 20)
        #expect(pricedStyle.amount?.swatch == NormaTheme.coral)
        #expect(pricedStyle.amount?.lineSpacing == 8)

        #expect(ActivityTimelineMetrics.showsMetaBesideTitle(spaceBetween: false, hasAmount: false))
        #expect(ActivityTimelineMetrics.showsMetaBesideTitle(spaceBetween: true, hasAmount: true))
        #expect(ActivityTimelineMetrics.showsMetaBesideTitle(spaceBetween: true, hasAmount: false) == false)

        let timeline = ActivityTimeline(model: model, pullState: .home)
        #expect(timeline.model == model)
        let view = try viewSource()
        #expect(view.contains("columnWidth"))
        #expect(view.contains("columnGap"))
        #expect(view.contains("listWidth"))
        #expect(view.contains("listHeight"))
        #expect(view.contains("rowSpacerHeight"))
        #expect(view.contains("baselineGap"))
        #expect(view.contains("firstTextBaseline"))
        #expect(view.contains("minHeight"))
        #expect(view.contains("headerTitle"))
    }

    @Test func componentHasNoHexLiterals() throws {
        // AC-2
        let view = strippingStringsAndComments(try viewSource())
        let model = strippingStringsAndComments(try modelSource())
        #expect(hexLiterals(in: view) == [])
        #expect(hexLiterals(in: model) == [])
        #expect(numericLiterals(in: view) == [])
        #expect(view.contains("Color.white") == false)
        #expect(view.contains("Color.black") == false)
        #expect(view.contains("UIColor") == false)
        #expect(model.contains("UIColor") == false)

        #expect(NormaTheme.paper.hex == 0xFFFFFF)
        #expect(NormaTheme.paperHighlight.hex == 0xFFFDF9)
        #expect(NormaTheme.paperMid.hex == 0xF7F2EA)
        #expect(NormaTheme.paperShade.hex == 0xECE3D5)
        #expect(NormaTheme.paperStroke.hex == 0xDED6CA)
        #expect(NormaTheme.paperRail.hex == 0xD6CEC1)
        #expect(NormaTheme.paperDot.hex == 0xB3AA9C)
        #expect(NormaTheme.paperRing.hex == 0xFCF9F3)
        #expect(NormaTheme.paperDay.hex == 0xF5EFE5)
        #expect(NormaTheme.paperDayAlt.hex == 0xF1E9DD)
        #expect(NormaTheme.graphite.hex == 0x4A5058)
        #expect(NormaTheme.mist.hex == 0x8A9199)
        #expect(NormaTheme.ink.hex == 0x111111)
        #expect(NormaTheme.coral.hex == 0xCC664D)
        #expect(NormaTheme.swatches.contains(NormaTheme.paper))
        #expect(NormaTheme.swatches.contains(NormaTheme.mist))
        #expect(ActivityTimelineMetrics.cardFill == NormaTheme.paper)
        #expect(ActivityTimelineMetrics.cardStroke == NormaTheme.paperStroke)
    }

    @Test func cardChromeMatchesSpec() throws {
        // AC-3
        let shape = ActivityTimelineMetrics.cardShape
        #expect(shape.style == .continuous)
        #expect(shape.cornerRadii.topLeading == 56)
        #expect(shape.cornerRadii.topTrailing == 56)
        #expect(shape.cornerRadii.bottomLeading == 0)
        #expect(shape.cornerRadii.bottomTrailing == 0)
        #expect(ActivityTimelineMetrics.cardTopRadius == 56)
        #expect(ActivityTimelineMetrics.cardBottomRadius == 0)
        #expect(ActivityTimelineMetrics.cardHeight == 780)
        #expect(ActivityTimelineMetrics.paddingTop == 32)
        #expect(ActivityTimelineMetrics.paddingBottom == 140)
        #expect(ActivityTimelineMetrics.paddingInline == 24)
        #expect(ActivityTimelineMetrics.cardGap == 24)
        #expect(ActivityTimelineMetrics.cardStrokeWidth == 1)
        let firstStop: ActivityGradientStop = try #require(ActivityTimelineMetrics.gradientStops.first)
        #expect(firstStop.location == 0)
        #expect(ActivityTimelineMetrics.gradientStops.map(\.location) == [0, 0.35, 1])
        #expect(
            ActivityTimelineMetrics.gradientStops.map(\.swatch) == [
                NormaTheme.paperHighlight,
                NormaTheme.paperMid,
                NormaTheme.paperShade,
            ])
        #expect(ActivityTimelineMetrics.shadowOpacity == 0.08)
        #expect(ActivityTimelineMetrics.shadowX == 0)
        #expect(ActivityTimelineMetrics.shadowY == 8)
        #expect(ActivityTimelineMetrics.shadowBlur == 28)

        let model = try modelSource()
        #expect(model.contains("NormaTheme.ink.color.opacity(shadowOpacity)"))
        let view = try viewSource()
        let fill = try #require(view.range(of: "cardFill"))
        let gradient = try #require(view.range(of: "cardGradient"))
        #expect(fill.lowerBound < gradient.lowerBound)
        #expect(view.contains("cardStroke"))
        #expect(view.contains("strokeBorder"))
        #expect(view.contains("shadowColor"))
        #expect(view.contains("shadowBlur"))
        #expect(view.contains("shadowY"))
        #expect(view.contains("shadowX"))
        #expect(view.contains("cardHeight"))
        #expect(view.contains("paddingTop"))
        #expect(view.contains("paddingBottom"))
        #expect(view.contains("paddingInline"))
        #expect(view.contains("cardGap"))
    }

    @Test func railDotsAndDashedTail() throws {
        // AC-4
        let rows = ActivityTimelineModel.sample.rows
        let layout = ActivityTimelineMetrics.railLayout(for: rows)

        #expect(ActivityTimelineMetrics.railWidth == 30)
        #expect(layout.centerX == 15)
        #expect(layout.lineWidth == 1.25)
        #expect(layout.dash == [2, 4])
        #expect(layout.roundCaps)
        #expect(layout.stroke == NormaTheme.paperRail)
        #expect(layout.contentHeight == 468)
        #expect(layout.height == 528)
        #expect(layout.drawsSolidLine)
        #expect(layout.solidFromY == 0)
        #expect(layout.solidToY == 446)
        #expect(layout.drawsDashedTail)
        #expect(layout.dashedFromY == 446)
        #expect(layout.dashedToY == 528)
        #expect(layout.dots.map(\.centerY) == [18, 70, 126, 182, 234, 286, 342, 394, 446])

        let entryDot: ActivityDotStyle = ActivityTimelineMetrics.entryDot
        #expect(entryDot.radius == 3)
        #expect(entryDot.fill == NormaTheme.paperDot)
        #expect(layout.dots[0].radius == 4)
        #expect(layout.dots[0].fill == NormaTheme.ink)
        #expect(layout.dots[0].stroke == nil)
        #expect(layout.dots[1].radius == 5)
        #expect(layout.dots[1].fill == NormaTheme.coral)
        #expect(layout.dots[1].stroke == NormaTheme.paperRing)
        #expect(layout.dots[1].strokeWidth == 2.5)
        #expect(layout.dots[1].diameter == 10)
        #expect(layout.dots[2].radius == 3)
        #expect(layout.dots[2].fill == NormaTheme.paperDot)
        #expect(layout.dots[2].stroke == nil)
        #expect(layout.dots[4].radius == 4)
        #expect(layout.dots[4].fill == NormaTheme.paperDay)
        #expect(layout.dots[4].stroke == NormaTheme.mist)
        #expect(layout.dots[4].strokeWidth == 1.5)
        #expect(layout.dots[7].fill == NormaTheme.paperDayAlt)
        #expect(layout.dots[7].stroke == NormaTheme.mist)
        #expect(layout.dots[7].strokeWidth == 1.5)

        let empty = ActivityTimelineMetrics.railLayout(for: [])
        #expect(empty.drawsSolidLine == false)
        #expect(empty.drawsDashedTail)
        #expect(empty.dashedFromY == 0)
        #expect(empty.dashedToY == 528)
        #expect(empty.dots.isEmpty)
        #expect(empty.height == 528)

        let view = try viewSource()
        #expect(view.contains("roundCaps"))
        #expect(view.contains(".round"))
        #expect(view.contains("layout.dash"))
        #expect(view.contains("railWidth"))
    }

    @Test func pullStatesApplyOffsetsAndHeader() throws {
        // AC-5
        // AC-8
        #expect(ActivityTimelinePullState.allCases == [.home, .pull1, .pull2, .pull3])

        #expect(ActivityTimelinePullState.home.absoluteTop == nil)
        let homePlacement: ActivityTimelinePlacement = ActivityTimelinePullState.home.placement
        #expect(homePlacement == .flow(paddingTop: 28, grows: true))
        #expect(ActivityTimelinePullState.home.grows)
        #expect(ActivityTimelinePullState.home.zIndex == 0)
        #expect(ActivityTimelinePullState.home.headerBlur == 0)
        #expect(ActivityTimelinePullState.home.headerOpacity == 1)
        #expect(ActivityTimelinePullState.home.hidesHeader == false)

        #expect(ActivityTimelinePullState.pull1.absoluteTop == 430)
        #expect(ActivityTimelinePullState.pull1.placement == .absolute(top: 430, zIndex: 5))
        #expect(ActivityTimelinePullState.pull1.zIndex == 5)
        #expect(ActivityTimelinePullState.pull1.headerBlur == 5)
        #expect(ActivityTimelinePullState.pull1.headerOpacity == 0.75)
        #expect(ActivityTimelinePullState.pull1.grows == false)
        #expect(ActivityTimelinePullState.pull1.paddingTop == 0)

        #expect(ActivityTimelinePullState.pull2.absoluteTop == 150)
        #expect(ActivityTimelinePullState.pull2.placement == .absolute(top: 150, zIndex: 5))
        #expect(ActivityTimelinePullState.pull2.headerBlur == 16)
        #expect(ActivityTimelinePullState.pull2.headerOpacity == 0.35)

        #expect(ActivityTimelinePullState.pull3.absoluteTop == 106)
        #expect(ActivityTimelinePullState.pull3.placement == .absolute(top: 106, zIndex: 5))
        #expect(ActivityTimelinePullState.pull3.headerBlur == 0)
        #expect(ActivityTimelinePullState.pull3.headerOpacity == 0)
        #expect(ActivityTimelinePullState.pull3.hidesHeader)

        let pulled = ActivityTimeline(model: .sample, pullState: .pull2)
        #expect(pulled.pullState == .pull2)
        let view = try viewSource()
        #expect(view.contains("pullState.placement"))
        #expect(view.contains("headerBlur"))
        #expect(view.contains("headerOpacity"))
        #expect(view.contains("hidesHeader"))
        #expect(view.contains(".offset"))
        #expect(view.contains(".zIndex"))
    }

    @Test func rowsStayReadableAtLargerType() throws {
        // AC-6
        let rows = ActivityTimelineModel.sample.rows
        let today = try day(.today, in: rows)
        let active = try entry(.insightActive, in: rows)
        let priced = try entry(.eventWithAmount, in: rows)
        let expenses = try entry(.expenses, in: rows)

        #expect(today.accessibilityLabel == "Today, Oct 26, $128.40")
        #expect(active.accessibilityLabel == "Dining is up, vs last week")
        #expect(priced.accessibilityLabel == "Groceries, Market, $44.20")
        #expect(expenses.accessibilityLabel == "Expenses, 3 charges, $84.20")
        #expect(ActivityTimelineMetrics.accessibilityLabel(title: "Paid rent", meta: "Due today", amount: "$44.20") == "Paid rent, Due today, $44.20")
        #expect(ActivityTimelineMetrics.accessibilityLabel(title: "Note", meta: "", amount: nil) == "Note")
        #expect(ActivityTimelineMetrics.accessibilityLabel(title: "Note", meta: "Later", amount: "") == "Note, Later")

        let view = try viewSource()
        #expect(view.contains(".accessibilityElement(children: .ignore)"))
        #expect(view.contains("accessibilityLabel"))
        #expect(view.contains("minHeight"))
        #expect(view.contains("fixedSize(horizontal: false, vertical: true)"))
        #expect(view.contains(".clipped(") == false)
        #expect(view.contains("lineLimit") == false)
        #expect(view.contains("ScrollView"))

        let model = try modelSource()
        #expect(model.contains("relativeTo: textStyle"))
        let styles = [
            ActivityTimelineMetrics.headerTitle,
            ActivityTimelineMetrics.headerSummary,
            ActivityTimelineMetrics.dayTitle,
            ActivityTimelineMetrics.dayTotal,
            ActivityTimelineMetrics.eventAmount,
        ]
        #expect(styles.allSatisfy { $0.lineHeight >= $0.size })
        #expect(ActivityTimelineMetrics.headerSummary.textStyle == .caption2)
        #expect(ActivityTimelineMetrics.eventAmount.textStyle == .caption)
        #expect(ActivityTimelineMetrics.dayTotal.textStyle == .footnote)
    }

    @Test func previewsShowEveryPullState() throws {
        // AC-7
        let view = try viewSource()
        let previewCount = view.components(separatedBy: "#Preview").count - 1
        #expect(previewCount == 4)
        #expect(view.contains("Activity home"))
        #expect(view.contains("Activity pull 1"))
        #expect(view.contains("Activity pull 2"))
        #expect(view.contains("Activity pull 3"))
        #expect(view.contains("pullState: .home"))
        #expect(view.contains("pullState: .pull1"))
        #expect(view.contains("pullState: .pull2"))
        #expect(view.contains("pullState: .pull3"))
        #expect(view.contains("model: .sample"))
        #expect(ActivityTimelineModel.sample.summary == "3 days · $271.55 spent")
        #expect(ActivityTimelinePullState.home.previewHeight == 844)
        #expect(ActivityTimelinePullState.pull1.previewHeight == 1246)
        #expect(ActivityTimelinePullState.pull2.previewHeight == 966)
        #expect(ActivityTimelinePullState.pull3.previewHeight == 922)

        let timeline = ActivityTimeline(model: .sample, pullState: .pull3)
        #expect(timeline.pullState == .pull3)
        #expect(timeline.model.days.count == 3)
    }

    @Test func rowMappingAndPullStatesAreSnapshotFree() throws {
        // AC-8
        let tests = try testSource()
        #expect(tests.contains("SnapshotTesting") == false)
        #expect(tests.contains("assertSnapshot") == false)
        #expect(tests.contains("ActivityEntryKind.allCases"))
        #expect(tests.contains("ActivityTimelinePullState.allCases"))
        #expect(entryKinds(in: ActivityTimelineModel.sample.rows) == Set(ActivityEntryKind.allCases))
        #expect(ActivityTimelinePullState.pull1.headerBlur == 5)
        #expect(ActivityTimelinePullState.pull2.absoluteTop == 150)
    }
}

private func isDay(_ row: ActivityTimelineRow) -> Bool {
    if case .day = row {
        return true
    }
    return false
}

private func entryKinds(in rows: [ActivityTimelineRow]) -> Set<ActivityEntryKind> {
    Set(
        rows.compactMap { row in
            if case .entry(let entry) = row {
                return entry.kind
            }
            return nil
        })
}

private func day(_ dot: ActivityDayDot, in rows: [ActivityTimelineRow]) throws -> ActivityTimelineRow {
    let row = rows.first { row in
        if case .day(let day) = row {
            return day.dot == dot
        }
        return false
    }
    return try #require(row)
}

private func entry(_ kind: ActivityEntryKind, in rows: [ActivityTimelineRow]) throws -> ActivityTimelineRow {
    let row = rows.first { row in
        if case .entry(let entry) = row {
            return entry.kind == kind
        }
        return false
    }
    return try #require(row)
}

private func viewSource() throws -> String {
    try componentSource("ActivityTimeline.swift")
}

private func modelSource() throws -> String {
    try componentSource("ActivityTimelineModel.swift")
}

private func testSource() throws -> String {
    try String(contentsOf: URL(fileURLWithPath: #filePath), encoding: .utf8)
}

private func componentSource(_ name: String) throws -> String {
    let url =
        URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Norma", isDirectory: true)
        .appendingPathComponent("Views", isDirectory: true)
        .appendingPathComponent("Components", isDirectory: true)
        .appendingPathComponent(name)
    return try String(contentsOf: url, encoding: .utf8)
}

private func strippingStringsAndComments(_ source: String) -> String {
    var result = ""
    var index = source.startIndex
    while index < source.endIndex {
        let next = source.index(after: index)
        if source[index] == "/", next < source.endIndex, source[next] == "/" {
            index = source[index...].firstIndex(of: "\n") ?? source.endIndex
            continue
        }
        if source[index] == "/", next < source.endIndex, source[next] == "*" {
            let searchFrom = source.index(after: next)
            if let end = source[searchFrom...].range(of: "*/") {
                index = end.upperBound
            } else {
                index = source.endIndex
            }
            continue
        }
        if source[index] == "\"" {
            index = next
            while index < source.endIndex {
                if source[index] == "\\" {
                    index = source.index(after: index)
                    if index < source.endIndex {
                        index = source.index(after: index)
                    }
                    continue
                }
                if source[index] == "\"" {
                    index = source.index(after: index)
                    break
                }
                index = source.index(after: index)
            }
            result.append("\"\"")
            continue
        }
        result.append(source[index])
        index = next
    }
    return result
}

private func hexLiterals(in code: String) -> [String] {
    var literals: [String] = []
    var index = code.startIndex
    while index < code.endIndex {
        if code[index] == "0" {
            let marker = code.index(after: index)
            if marker < code.endIndex, code[marker] == "x" || code[marker] == "X" {
                var end = code.index(after: marker)
                while end < code.endIndex, isHexDigit(code[end]) {
                    end = code.index(after: end)
                }
                if end > code.index(after: marker) {
                    literals.append(String(code[index..<end]))
                    index = end
                    continue
                }
            }
        }
        if code[index] == "#" {
            var end = code.index(after: index)
            var count = 0
            while end < code.endIndex, count < 8, isHexDigit(code[end]) {
                end = code.index(after: end)
                count += 1
            }
            let stopped = end == code.endIndex || !isHexDigit(code[end])
            if stopped && (count == 3 || count == 4 || count == 6 || count == 8) {
                literals.append(String(code[index..<end]))
                index = end
                continue
            }
        }
        index = code.index(after: index)
    }
    return literals
}

private func numericLiterals(in code: String) -> [String] {
    var literals: [String] = []
    var index = code.startIndex
    while index < code.endIndex {
        let character = code[index]
        if isDecimalDigit(character), !continuesIdentifier(code, at: index) {
            let start = index
            index = code.index(after: index)
            while index < code.endIndex, isDecimalDigit(code[index]) || code[index] == "_" {
                index = code.index(after: index)
            }
            if index < code.endIndex, code[index] == "." {
                let fraction = code.index(after: index)
                if fraction < code.endIndex, isDecimalDigit(code[fraction]) {
                    index = fraction
                    while index < code.endIndex, isDecimalDigit(code[index]) {
                        index = code.index(after: index)
                    }
                }
            }
            literals.append(String(code[start..<index]))
            continue
        }
        if character == ".", !continuesIdentifier(code, at: index) {
            let fraction = code.index(after: index)
            if fraction < code.endIndex, isDecimalDigit(code[fraction]) {
                var end = fraction
                while end < code.endIndex, isDecimalDigit(code[end]) {
                    end = code.index(after: end)
                }
                literals.append(String(code[index..<end]))
                index = end
                continue
            }
        }
        index = code.index(after: index)
    }
    return literals
}

private func continuesIdentifier(_ code: String, at index: String.Index) -> Bool {
    guard index > code.startIndex else { return false }
    let previous = code[code.index(before: index)]
    return previous.isLetter || previous.isNumber || previous == "_"
}

private func isDecimalDigit(_ character: Character) -> Bool {
    character.isASCII && character.isNumber
}

private func isHexDigit(_ character: Character) -> Bool {
    guard let ascii = character.asciiValue else { return false }
    return (ascii >= 48 && ascii <= 57) || (ascii >= 65 && ascii <= 70) || (ascii >= 97 && ascii <= 102)
}
