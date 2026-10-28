//
//  AgentThreadBoardTests.swift
//  NormaTests
//
//  Board-match checks for the measured Agents rail, markers, and sample order.
//  Each acceptance check is tagged on the test that covers it.
//

import Foundation
import SwiftUI
import Testing

@testable import Norma

@MainActor
struct AgentThreadBoardRailTests {
    @Test func railIsTheMeasuredSteppedPath() {
        // AC-9
        let solid = AgentThreadBoardRail.solid
        #expect(solid.map(\.x) != [CGFloat](repeating: solid[0].x, count: solid.count))
        #expect(AgentThreadBoardRail.hops.contains(.angleRight))
        #expect(AgentThreadBoardRail.hops.contains(.angleLeft))
        #expect(AgentThreadBoardRail.hops.contains(.straight))
        #expect(AgentThreadBoardRail.hop(from: CGPoint(x: 5, y: 126), to: CGPoint(x: 21, y: 138)) == .angleRight)
        #expect(AgentThreadBoardRail.hop(from: CGPoint(x: 21, y: 172), to: CGPoint(x: 37, y: 184)) == .angleRight)
        #expect(AgentThreadBoardRail.hop(from: CGPoint(x: 37, y: 234), to: CGPoint(x: 21, y: 250)) == .angleLeft)
        #expect(AgentThreadBoardRail.hop(from: CGPoint(x: 37, y: 398), to: CGPoint(x: 21, y: 414)) == .angleLeft)
        #expect(AgentThreadBoardRail.hop(from: CGPoint(x: 37, y: 296), to: CGPoint(x: 37, y: 398)) == .straight)
        #expect(
            solid == [
                CGPoint(x: 5, y: 28),
                CGPoint(x: 5, y: 126),
                CGPoint(x: 21, y: 138),
                CGPoint(x: 21, y: 172),
                CGPoint(x: 37, y: 184),
                CGPoint(x: 37, y: 234),
                CGPoint(x: 21, y: 250),
                CGPoint(x: 21, y: 284),
                CGPoint(x: 37, y: 296),
                CGPoint(x: 37, y: 398),
                CGPoint(x: 21, y: 414),
                CGPoint(x: 21, y: 446),
            ])
        #expect(AgentThreadMetrics.railStrokeWidth == 1.25)
        #expect(AgentThreadMetrics.railColor == NormaTheme.threadRail)
        #expect(AgentThreadMetrics.railLineCap == .round)
        #expect(AgentThreadMetrics.railLineJoin == .round)
    }

    @Test func onlyTheTopSegmentIsDashed() {
        // AC-10
        #expect(AgentThreadBoardRail.dashX == 5)
        #expect(AgentThreadBoardRail.dashStartY == 2)
        #expect(AgentThreadBoardRail.dashEndY == 28)
        #expect(AgentThreadBoardRail.dash == [2, 4])
        #expect(AgentThreadBoardRail.solid.first == CGPoint(x: 5, y: 28))
        #expect(AgentThreadMetrics.segmentIsDashed(isOpening: true))
        #expect(AgentThreadMetrics.segmentIsDashed(isOpening: false) == false)
        let drawn = AgentThreadBoardRail.translated(originY: AgentThreadMetrics.railOriginY)
        #expect(drawn.dash[0].y == AgentThreadMetrics.railOriginY + 2)
        #expect(drawn.dash[1].y == AgentThreadMetrics.railOriginY + 28)
        #expect(drawn.solid.allSatisfy { point in point.y >= drawn.dash[1].y })
    }

    @Test func dayMarkersAreTheRingAndTheInkDot() {
        // AC-11
        let ring = AgentThreadMetrics.railStyle(.yesterdayRing)
        #expect(ring.diameter == 8)
        #expect(ring.strokeWidth == 1.5)
        #expect(ring.stroke == NormaTheme.threadMuted)
        #expect(ring.fill == NormaTheme.threadRingFill)
        #expect(ring.fill.hex == 0xF5EFE5)
        #expect(AgentThreadMetrics.columnX(.yesterdayRing) == 5)

        let today = AgentThreadMetrics.railStyle(.todayDot)
        #expect(today.diameter == 8)
        #expect(today.fill == NormaTheme.ink)
        #expect(today.strokeWidth == 0)
        #expect(AgentThreadMetrics.columnX(.todayDot) == 5)
    }

    @Test func eventDotsAndReplyFacesKeepTheirColumns() {
        // AC-12
        let idle = AgentThreadMetrics.railStyle(.eventIdle)
        #expect(idle.diameter == 6)
        #expect(idle.fill == NormaTheme.threadIdleDot)
        #expect(idle.fill.hex == 0xB3AA9C)
        #expect(idle.strokeWidth == 0)
        #expect(AgentThreadMetrics.columnX(.eventIdle) == 21)

        let active = AgentThreadMetrics.railStyle(.eventActive)
        #expect(active.diameter == 10)
        #expect(active.fill == NormaTheme.coral)
        #expect(active.stroke == NormaTheme.threadCream)
        #expect(active.strokeWidth == 2.5)
        #expect(AgentThreadMetrics.columnX(.eventActive) == 21)

        let stash = AgentThreadMetrics.railStyle(.stash)
        #expect(stash.diameter == 20)
        #expect(stash.fill == NormaTheme.threadStash)
        #expect(stash.stroke == NormaTheme.threadCream)
        #expect(stash.strokeWidth == 2)
        #expect(AgentThreadMetrics.columnX(.stash) == 37)

        let ratio = AgentThreadMetrics.railStyle(.ratio)
        #expect(ratio.diameter == 20)
        #expect(ratio.fill == NormaTheme.threadFaceCool)
        #expect(ratio.strokeWidth == 2)
        #expect(AgentThreadMetrics.columnX(.ratio) == 37)

        let norma = AgentThreadMetrics.railStyle(.norma)
        #expect(norma.diameter == 20)
        #expect(norma.fill == NormaTheme.ink)
        #expect(norma.stroke == NormaTheme.threadMuted)
        #expect(norma.strokeWidth == 1.5)
        #expect(AgentThreadMetrics.columnX(.norma) == 37)

        let you = AgentThreadMetrics.railStyle(.you)
        #expect(you.diameter == 8)
        #expect(you.fill == NormaTheme.ink)
        #expect(you.stroke == NormaTheme.threadCream)
        #expect(you.strokeWidth == 2)
        #expect(AgentThreadMetrics.columnX(.you) == 21)

        let marks = AgentThreadModel.board.rows.compactMap(\.railMark)
        #expect(marks.contains(.eventIdle))
        #expect(marks.contains(.eventActive))
    }
}

@MainActor
struct AgentThreadBoardRowTests {
    @Test func eventTimeSitsUnderTheTitle() throws {
        // AC-13
        #expect(AgentThreadMetrics.eventTimeBelowTitle)
        #expect(AgentThreadMetrics.eventTimeGap == 0)
        #expect(AgentThreadMetrics.eventPaddingLeading == 38)
        #expect(AgentThreadMetrics.eventTitle.size == 15)
        #expect(AgentThreadMetrics.eventTitle.lineHeight == 20)
        #expect(AgentThreadMetrics.eventTime.size == 11)
        #expect(AgentThreadMetrics.eventTime.lineHeight == 14)
        #expect(AgentThreadMetrics.eventTime.postScriptName == "CommitMono-Regular")
        #expect(AgentThreadEventStyle.resolve(false).title == NormaTheme.threadSecondary)
        #expect(AgentThreadEventStyle.resolve(false).time == NormaTheme.threadMuted)
        let source = try agentThreadAndRailSource()
        #expect(source.contains("VStack(alignment: .leading, spacing: AgentThreadMetrics.eventTimeGap)"))
        #expect(source.contains("Text(event.time)"))
    }

    @Test func activeTimeIsInkAndCoralIsOnlyTheRailDot() throws {
        // AC-14
        #expect(AgentThreadEventStyle.resolve(true).time == NormaTheme.ink)
        #expect(AgentThreadEventStyle.resolve(true).time.hex == 0x111111)
        #expect(AgentThreadEventStyle.resolve(true).title == NormaTheme.ink)
        let source = try agentThreadAndRailSource()
        let coralLines = source.split(separator: "\n").filter { $0.contains("NormaTheme.coral") }
        #expect(coralLines.count == 1)
        #expect(coralLines[0].contains("fill: NormaTheme.coral"))
        #expect(coralLines[0].contains("foregroundStyle") == false)
        #expect(coralLines[0].contains("Text") == false)
    }

    @Test func repliesSitUnderTheEventTheyAnswer() {
        // AC-15
        #expect(
            kindNames(AgentThreadModel.board) == [
                "header",
                "yesterday",
                "day",
                "event",
                "reply",
                "event",
                "reply",
                "reply",
                "you",
            ])
        #expect(
            AgentThreadModel.board.events.map(\.title) == [
                "Stash moved $42.10 to savings",
                "Food spend is down 30%.",
            ])
        #expect(AgentThreadModel.board.replies.map(\.name) == ["Stash", "Ratio", "Norma"])
        #expect(AgentThreadMetrics.gapTimeToSender == 12)
        #expect(AgentThreadMetrics.replyGap == 2)
        #expect(AgentThreadMetrics.gapBubbleToEvent == 18)
        #expect(AgentThreadMetrics.gapBubbleToSender == 4)
        #expect(AgentThreadMetrics.rowGap(from: .event(stashEvent), to: .reply(stashReply)) == 12)
        #expect(AgentThreadMetrics.rowGap(from: .reply(stashReply), to: .event(foodEvent)) == 18)
        #expect(AgentThreadMetrics.rowGap(from: .reply(ratioReply), to: .reply(normaReply)) == 4)
    }

    @Test func youLabelIncludesTheTimeAndAlignsWithTheBubble() throws {
        // AC-16
        let you = youMessage(in: AgentThreadModel.board)
        #expect(you?.label == "You · 9:52 AM")
        #expect(you?.message == "Can I do a $90 dinner Friday?")
        #expect(AgentThreadMetrics.name.size == 11)
        #expect(AgentThreadMetrics.name.lineHeight == 14)
        #expect(AgentThreadMetrics.name.color == NormaTheme.threadMuted)
        let source = try threadSource()
        let youView = slice(in: source, from: "struct AgentThreadYouView", until: "struct AgentThreadBubble")
        #expect(youView.contains("Text(you.label)"))
        #expect(youView.contains("namePaddingLeading") == false)
    }

    @Test func yesterdayCardPutsFacesOnTheSecondLine() throws {
        // AC-17
        let yesterday = yesterdayCard(in: AgentThreadModel.board)
        #expect(yesterday?.title == "Yesterday")
        #expect(yesterday?.date == "Tue, Oct 20")
        #expect(yesterday?.amount == "-$124.15")
        #expect(yesterday?.summary == "Phone bill paid · 3 messages")
        #expect(yesterday?.faces.map(\.hex) == [0xCDB3A6, 0xB8C3D1, 0x111111])
        #expect(AgentThreadMetrics.yesterdayFacesOnSecondLine)
        #expect(AgentThreadMetrics.chipFill.hex == 0xF1EADF)
        #expect(AgentThreadMetrics.chipPaddingVertical == 8)
        #expect(AgentThreadMetrics.chipPaddingHorizontal == 14)
        #expect(AgentThreadMetrics.chipRadius == 14)
        #expect(AgentThreadMetrics.yesterdayPaddingLeading == 22)
        #expect(AgentThreadMetrics.yesterdayLineGap == 8)
        #expect(AgentThreadMetrics.yesterdayLine2Height == 18)
        #expect(AgentThreadMetrics.faceSize == 18)
        #expect(AgentThreadMetrics.faceCenterSpacing == 12)
        #expect(AgentThreadMetrics.faceStrokeWidth == 1.5)
        #expect(AgentThreadMetrics.faceRing.hex == 0xFAF6EF)
        #expect(AgentThreadMetrics.summary.size == 13)
        #expect(AgentThreadMetrics.summary.lineHeight == 18)
        let source = try threadSource()
        let view = slice(in: source, from: "struct AgentThreadYesterdayView", until: "struct AgentThreadFaces")
        let title = view.range(of: "yesterday.title")
        let faces = view.range(of: "AgentThreadFaces")
        let summary = view.range(of: "yesterday.summary")
        #expect(title != nil && faces != nil && summary != nil)
        if let title, let faces, let summary {
            #expect(title.lowerBound < faces.lowerBound)
            #expect(faces.lowerBound < summary.lowerBound)
        }
    }

    @Test func yesterdayChevronIsTheSymbolTwelvePointsAfterTheSummary() throws {
        // AC-18
        #expect(AgentThreadMetrics.chevronSymbol == "chevron.right")
        #expect(AgentThreadMetrics.chevronSize == 12)
        #expect(AgentThreadMetrics.chevronColor == NormaTheme.threadMuted)
        #expect(AgentThreadMetrics.chevronColor.hex == 0x8A9199)
        #expect(AgentThreadMetrics.chevronGapAfterSummary == 8)
        let source = try threadSource()
        #expect(source.contains("Image(systemName: AgentThreadMetrics.chevronSymbol)"))
        #expect(source.contains("Spacer(minLength: AgentThreadMetrics.chevronGapAfterSummary)"))
        #expect(source.contains("Text(\">\")") == false)
    }

    @Test func todayHeaderMatchesTheBoardRow() {
        // AC-19
        let day = todayRow(in: AgentThreadModel.board)
        #expect(day?.title == "Today")
        #expect(day?.date == "Wed, Oct 21")
        #expect(day?.total == "-$86.40")
        #expect(AgentThreadMetrics.dayHeight == 36)
        #expect(AgentThreadMetrics.dayPaddingLeading == 22)
        #expect(AgentThreadMetrics.dayTitle.size == 16)
        #expect(AgentThreadMetrics.dayTitle.lineHeight == 20)
        #expect(AgentThreadMetrics.dayTitle.weight == 600)
        #expect(AgentThreadMetrics.dayTitle.color == NormaTheme.ink)
        #expect(AgentThreadMetrics.titleDateGap == 8)
        #expect(AgentThreadMetrics.date.size == 11)
        #expect(AgentThreadMetrics.date.lineHeight == 14)
        #expect(AgentThreadMetrics.date.color == NormaTheme.threadMuted)
        #expect(AgentThreadMetrics.dayTotal.size == 13)
        #expect(AgentThreadMetrics.dayTotal.lineHeight == 16)
        #expect(AgentThreadMetrics.dayTotal.color == NormaTheme.ink)
        #expect(AgentThreadModel.board.rows.first { $0.id == "today" }?.railMark == .todayDot)
    }

    @Test func previewSitsBesideTheBoardImage() throws {
        // AC-20
        let source = try threadSource()
        let preview = previewSource(in: source)
        #expect(preview.contains("#Preview(\"Agent thread\")"))
        #expect(preview.contains("Image(\"AgentsBoard\")"))
        #expect(preview.contains("AgentThread(model: .board)"))
        #expect(preview.contains("width: AgentThreadMetrics.threadWidth"))
        #expect(AgentThreadMetrics.threadWidth == 391)
        #expect(kindNames(AgentThreadModel.board).count == 9)
        let thread = AgentThread(model: .board)
        #expect(thread.model.rows.count == 9)
        #expect(thread.model.events.count == 2)
        #expect(thread.model.replies.count == 3)
    }
}

private let stashEvent = AgentThreadEvent(title: "Stash moved $42.10 to savings", time: "9:12 AM", isActive: false)
private let foodEvent = AgentThreadEvent(title: "Food spend is down 30%.", time: "9:40 AM", isActive: true)
private let stashReply = AgentThreadReply(name: "Stash", message: "Round-ups from this week.", mark: .stash)
private let ratioReply = AgentThreadReply(name: "Ratio", message: "Mostly fewer delivery nights.", mark: .ratio)
private let normaReply = AgentThreadReply(name: "Norma", message: "That covers your phone bill.", mark: .norma)

private func kindNames(_ model: AgentThreadModel) -> [String] {
    model.rows.map { row in
        switch row.kind {
        case .header: return "header"
        case .yesterday: return "yesterday"
        case .day: return "day"
        case .event: return "event"
        case .reply: return "reply"
        case .you: return "you"
        }
    }
}

private func yesterdayCard(in model: AgentThreadModel) -> AgentThreadYesterday? {
    for row in model.rows {
        if case .yesterday(let yesterday) = row.kind { return yesterday }
    }
    return nil
}

private func todayRow(in model: AgentThreadModel) -> AgentThreadDay? {
    for row in model.rows {
        if case .day(let day) = row.kind { return day }
    }
    return nil
}

private func youMessage(in model: AgentThreadModel) -> AgentThreadYou? {
    for row in model.rows {
        if case .you(let you) = row.kind { return you }
    }
    return nil
}

private func threadSource() throws -> String {
    try String(contentsOf: componentURL("AgentThread.swift"), encoding: .utf8)
}

private func agentThreadAndRailSource() throws -> String {
    let thread = try threadSource()
    let rail = try String(contentsOf: componentURL("AgentThreadRail.swift"), encoding: .utf8)
    return thread + "\n" + rail
}

private func componentURL(_ name: String) -> URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Norma", isDirectory: true)
        .appendingPathComponent("Views", isDirectory: true)
        .appendingPathComponent("Components", isDirectory: true)
        .appendingPathComponent(name)
}

private func previewSource(in source: String) -> String {
    guard let range = source.range(of: "#Preview") else { return "" }
    return String(source[range.lowerBound...])
}

private func slice(in source: String, from start: String, until end: String) -> String {
    guard let startRange = source.range(of: start) else { return "" }
    let rest = source[startRange.lowerBound...]
    guard let endRange = rest.range(of: end) else { return String(rest) }
    return String(rest[..<endRange.lowerBound])
}
