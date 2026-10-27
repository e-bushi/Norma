//
//  AgentThreadTests.swift
//  NormaTests
//
//  Layout, tokens, rail, VoiceOver, and the board preview for AgentThread.
//  Each acceptance check is tagged on the test that covers it.
//

import SwiftUI
import Testing
import UIKit

@testable import Norma

@MainActor
struct AgentThreadModelTests {
    @Test func boardRendersEveryRowToTheMeasuredValues() {
        // AC-1
        let board = AgentThreadModel.board
        #expect(board.spacerHeights == [10, 20, 12, 16])
        #expect(board.spacerHeights == AgentThreadMetrics.groupSpacers)
        #expect(
            kindNames(board) == [
                "header",
                "spacer",
                "yesterday",
                "spacer",
                "day",
                "event",
                "event",
                "spacer",
                "reply",
                "reply",
                "reply",
                "spacer",
                "you",
            ])

        let header = header(in: board)
        #expect(header?.title == "Everyone")
        #expect(header?.agentCount == 5)
        #expect(header?.countText == "\u{00B7} 5 agents")
        #expect(AgentThreadMetrics.headerPaddingTop == 18)
        #expect(AgentThreadMetrics.headerPaddingHorizontal == 6)
        #expect(AgentThreadMetrics.headerPaddingBottom == 24)
        #expect(AgentThreadMetrics.headerGap == 8)
        #expect(AgentThreadMetrics.headerDotSize == 8)
        #expect(AgentThreadMetrics.headerDot == NormaTheme.ink)
        let everyone: AgentThreadText = AgentThreadMetrics.everyone
        #expect(everyone.size == 14)
        #expect(AgentThreadMetrics.everyone.lineHeight == 18)
        #expect(AgentThreadMetrics.everyone.weight == 600)
        #expect(AgentThreadMetrics.everyone.postScriptName == "InstrumentSans-Medium")
        #expect(AgentThreadMetrics.everyone.color == NormaTheme.ink)
        #expect(AgentThreadMetrics.agentCount.size == 11)
        #expect(AgentThreadMetrics.agentCount.lineHeight == 14)
        #expect(AgentThreadMetrics.agentCount.postScriptName == "CommitMono-Regular")
        #expect(AgentThreadMetrics.agentCount.color == NormaTheme.threadMuted)

        let yesterday = yesterday(in: board)
        #expect(yesterday?.title == "Yesterday")
        #expect(yesterday?.date == "Oct 26")
        #expect(yesterday?.amount == "$146.20")
        #expect(yesterday?.summary == "Rent cleared. Stash set $40 aside.")
        #expect(yesterday?.faces == [NormaTheme.threadFaceWarm, NormaTheme.threadFaceCool, NormaTheme.ink])
        #expect(AgentThreadMetrics.yesterdayHeight == 60)
        #expect(AgentThreadMetrics.yesterdayPaddingLeading == 22)
        #expect(AgentThreadMetrics.chipRadius == 14)
        #expect(AgentThreadMetrics.chipPaddingVertical == 8)
        #expect(AgentThreadMetrics.chipPaddingHorizontal == 14)
        #expect(AgentThreadMetrics.chipGap == 6)
        #expect(AgentThreadMetrics.chipFill == NormaTheme.threadChip)
        #expect(AgentThreadMetrics.faceSize == 18)
        #expect(AgentThreadMetrics.faceOverlap == 6)
        #expect(AgentThreadMetrics.faceStrokeWidth == 1.5)
        #expect(AgentThreadMetrics.faceRing == NormaTheme.threadFaceRing)
        #expect(AgentThreadMetrics.yesterdayTitle.size == 15)
        #expect(AgentThreadMetrics.yesterdayTitle.lineHeight == 20)
        #expect(AgentThreadMetrics.yesterdayTitle.weight == 600)
        #expect(AgentThreadMetrics.yesterdayTitle.postScriptName == AgentThreadMetrics.emphasisFace)
        #expect(AgentThreadMetrics.date.size == 11)
        #expect(AgentThreadMetrics.date.lineHeight == 14)
        #expect(AgentThreadMetrics.date.color == NormaTheme.threadMuted)
        #expect(AgentThreadMetrics.amount.size == 12)
        #expect(AgentThreadMetrics.amount.lineHeight == 16)
        #expect(AgentThreadMetrics.amount.color == NormaTheme.ink)
        #expect(AgentThreadMetrics.summary.size == 13)
        #expect(AgentThreadMetrics.summary.lineHeight == 18)
        #expect(AgentThreadMetrics.summary.weight == 400)
        #expect(AgentThreadMetrics.summary.postScriptName == "InstrumentSans-Regular")
        #expect(AgentThreadMetrics.summary.color == NormaTheme.threadSecondary)
        #expect(AgentThreadMetrics.chevron == ">")
        #expect(AgentThreadMetrics.chevronText.size == 12)
        #expect(AgentThreadMetrics.chevronText.lineHeight == 16)
        #expect(AgentThreadMetrics.chevronText.postScriptName == "CommitMono-Regular")
        #expect(AgentThreadMetrics.chevronText.color == NormaTheme.threadMuted)

        let day = day(in: board)
        #expect(day?.title == "Today")
        #expect(day?.date == "Oct 27")
        #expect(day?.total == "$84.00")
        #expect(AgentThreadMetrics.dayHeight == 36)
        #expect(AgentThreadMetrics.dayPaddingLeading == 22)
        #expect(AgentThreadMetrics.dayTitle.size == 16)
        #expect(AgentThreadMetrics.dayTitle.lineHeight == 20)
        #expect(AgentThreadMetrics.dayTitle.weight == 600)
        #expect(AgentThreadMetrics.dayTitle.color == NormaTheme.ink)
        #expect(AgentThreadMetrics.dayTotal.size == 13)
        #expect(AgentThreadMetrics.dayTotal.lineHeight == 16)
        #expect(AgentThreadMetrics.dayTotal.color == NormaTheme.ink)
        #expect(AgentThreadMetrics.titleDateGap == 8)

        #expect(board.events.map(\.isActive) == [false, true])
        #expect(board.events.map(\.title) == ["Grocery run", "Paycheck landed"])
        #expect(board.events.map(\.time) == ["8:40 AM", "9:15 AM"])
        #expect(AgentThreadMetrics.eventHeight == 34)
        #expect(AgentThreadMetrics.eventPaddingLeading == 38)
        #expect(AgentThreadMetrics.eventTitle.size == 15)
        #expect(AgentThreadMetrics.eventTitle.lineHeight == 20)
        #expect(AgentThreadMetrics.eventTitle.postScriptName == "InstrumentSans-Regular")
        #expect(AgentThreadMetrics.eventTime.size == 11)
        #expect(AgentThreadMetrics.eventTime.lineHeight == 14)
        #expect(AgentThreadMetrics.eventTime.postScriptName == "CommitMono-Regular")
        let idle = AgentThreadEventStyle.resolve(false)
        let active = AgentThreadEventStyle.resolve(true)
        #expect(idle.title == NormaTheme.threadSecondary)
        #expect(idle.time == NormaTheme.threadMuted)
        #expect(active.title == NormaTheme.ink)
        #expect(active.time == NormaTheme.coral)

        #expect(board.replies.map(\.name) == ["Stash", "Ratio", "Norma"])
        #expect(board.replies.map(\.mark) == [.stash, .ratio, .norma])
        #expect(AgentThreadMetrics.replyPaddingLeading == 54)
        #expect(AgentThreadMetrics.replyGap == 2)
        #expect(AgentThreadMetrics.namePaddingLeading == 11)
        #expect(AgentThreadMetrics.name.size == 11)
        #expect(AgentThreadMetrics.name.lineHeight == 14)
        #expect(AgentThreadMetrics.name.color == NormaTheme.threadMuted)
        #expect(AgentThreadMetrics.name.postScriptName == "CommitMono-Regular")
        #expect(AgentThreadMetrics.agentBody.size == 14)
        #expect(AgentThreadMetrics.agentBody.lineHeight == 20)
        #expect(AgentThreadMetrics.agentBody.postScriptName == "InstrumentSans-Regular")
        #expect(AgentThreadMetrics.agentBody.color == NormaTheme.ink)

        let you = you(in: board)
        #expect(you?.label == "You")
        #expect(you?.message == "Move another $20.")
        #expect(AgentThreadMetrics.youHeight == 48)
        #expect(AgentThreadMetrics.youPaddingLeading == 38)
        #expect(AgentThreadMetrics.youBody.size == 14)
        #expect(AgentThreadMetrics.youBody.lineHeight == 20)
        #expect(AgentThreadMetrics.youBody.color == NormaTheme.threadCream)
    }

    @Test func sheetFrameGradientStrokeAndShadowMatchTheBoard() {
        // AC-1
        #expect(AgentThreadMetrics.threadWidth == 391)
        #expect(AgentThreadMetrics.threadHeight == 512)
        #expect(AgentThreadMetrics.paddingTop == 14)
        #expect(AgentThreadMetrics.paddingInline == 20)
        #expect(AgentThreadMetrics.listWidth == 351)
        #expect(AgentThreadMetrics.listHeight == 496)
        #expect(AgentThreadMetrics.threadWidth - AgentThreadMetrics.paddingInline * 2 == AgentThreadMetrics.listWidth)
        #expect(
            AgentThreadMetrics.threadHeight - AgentThreadMetrics.paddingTop - AgentThreadMetrics.paddingBottom
                == AgentThreadMetrics.listHeight
        )
        #expect(AgentThreadMetrics.sheetRadius == 44)
        let shape = AgentThreadMetrics.sheetShape
        #expect(shape.style == .continuous)
        #expect(shape.cornerRadii.topLeading == 44)
        #expect(shape.cornerRadii.topTrailing == 44)
        #expect(shape.cornerRadii.bottomLeading == 0)
        #expect(shape.cornerRadii.bottomTrailing == 0)
        #expect(AgentThreadMetrics.gradientStart == NormaTheme.threadSheetStart)
        #expect(AgentThreadMetrics.gradientMid == NormaTheme.threadSheetMid)
        #expect(AgentThreadMetrics.gradientEnd == NormaTheme.threadSheetEnd)
        #expect(AgentThreadMetrics.gradientMidLocation == 0.45)
        #expect(AgentThreadMetrics.stroke == NormaTheme.threadStroke)
        #expect(AgentThreadMetrics.strokeWidth == 1)
        #expect(AgentThreadMetrics.shadowColor == NormaTheme.ink)
        #expect(AgentThreadMetrics.shadowOpacity == 0.08)
        #expect(AgentThreadMetrics.shadowX == 0)
        #expect(AgentThreadMetrics.shadowY == 8)
        #expect(AgentThreadMetrics.shadowBlur == 28)
        #expect(AgentThreadMetrics.railHeight == AgentThreadMetrics.listHeight)
    }
}

@MainActor
struct AgentThreadTokenTests {
    @Test func colorsAreNamedTokensWithNoHexInTheComponent() throws {
        // AC-2
        expectLocked(NormaTheme.threadSheetStart, hex: 0xFFFDF9, hexString: "#FFFDF9")
        expectLocked(NormaTheme.threadSheetMid, hex: 0xF7F2EA, hexString: "#F7F2EA")
        expectLocked(NormaTheme.threadSheetEnd, hex: 0xECE3D5, hexString: "#ECE3D5")
        expectLocked(NormaTheme.threadStroke, hex: 0xDED6CA, hexString: "#DED6CA")
        expectLocked(NormaTheme.threadMuted, hex: 0x8A9199, hexString: "#8A9199")
        expectLocked(NormaTheme.threadChip, hex: 0xF1EADF, hexString: "#F1EADF")
        expectLocked(NormaTheme.threadSecondary, hex: 0x4A5058, hexString: "#4A5058")
        expectLocked(NormaTheme.threadFaceRing, hex: 0xFAF6EF, hexString: "#FAF6EF")
        expectLocked(NormaTheme.threadFaceWarm, hex: 0xCDB3A6, hexString: "#CDB3A6")
        expectLocked(NormaTheme.threadFaceCool, hex: 0xB8C3D1, hexString: "#B8C3D1")
        expectLocked(NormaTheme.threadAgentBubble, hex: 0xEDE6DA, hexString: "#EDE6DA")
        expectLocked(NormaTheme.threadCream, hex: 0xFCF9F3, hexString: "#FCF9F3")
        expectLocked(NormaTheme.threadRail, hex: 0xD6CEC1, hexString: "#D6CEC1")
        expectLocked(NormaTheme.threadStash, hex: 0xB7C4AE, hexString: "#B7C4AE")
        #expect(NormaTheme.ink.hex == 0x111111)
        #expect(NormaTheme.coral.hex == 0xCC664D)
        #expect(
            Set(NormaTheme.threadSwatches.map(\.name)).isDisjoint(with: Set(NormaTheme.swatches.map(\.name)))
        )

        let source = try agentThreadSource()
        #expect(source.contains("struct AgentThread"))
        #expect(hexLiterals(in: source) == [])
        #expect(source.contains("Color(red:") == false)
        #expect(source.contains("UIColor(") == false)
        #expect(source.contains(".sRGB") == false)
        #expect(source.contains("NormaTheme.threadAgentBubble"))
        #expect(source.contains("NormaTheme.threadCream"))
        #expect(source.contains("NormaTheme.ink"))
        #expect(source.contains("NormaTheme.coral"))
        #expect(source.contains("NormaTheme.threadSheetStart"))
        #expect(source.contains("NormaTheme.shape"))
    }
}

@MainActor
struct AgentThreadBubbleTests {
    @Test func bubblesUseContinuousRadiusAndTheTwoFills() {
        // AC-3
        let shape = AgentThreadMetrics.bubbleShape
        #expect(AgentThreadMetrics.bubbleRadius == 16)
        #expect(shape.style == .continuous)
        #expect(shape.cornerSize == CGSize(width: 16, height: 16))
        #expect(AgentThreadMetrics.bubblePaddingVertical == 6)
        #expect(AgentThreadMetrics.bubblePaddingHorizontal == 11)
        #expect(AgentThreadMetrics.agentBubbleFill == NormaTheme.threadAgentBubble)
        #expect(AgentThreadMetrics.agentBubbleFill.hex == 0xEDE6DA)
        #expect(AgentThreadMetrics.agentBody.color == NormaTheme.ink)
        #expect(AgentThreadMetrics.youBubbleFill == NormaTheme.ink)
        #expect(AgentThreadMetrics.youBubbleFill.hex == 0x111111)
        #expect(AgentThreadMetrics.youBody.color == NormaTheme.threadCream)
        #expect(AgentThreadMetrics.youBody.color.hex == 0xFCF9F3)
    }
}

@MainActor
struct AgentThreadRailTests {
    @Test func railUsesTheFaceOrDotForEachMarkedRow() {
        // AC-4
        let board = AgentThreadModel.board
        let marks: [AgentThreadRailMark] = board.rows.compactMap(\.railMark)
        #expect(marks == [.stash, .ratio, .norma, .you])
        #expect(board.rows.filter { $0.railMark == nil }.count == board.rows.count - 4)

        let stash: AgentThreadRailStyle = AgentThreadMetrics.railStyle(.stash)
        #expect(stash.fill == NormaTheme.threadStash)
        #expect(stash.stroke == NormaTheme.threadCream)
        #expect(stash.strokeWidth == 2)
        #expect(stash.radius == 10)
        #expect(stash.diameter == 20)

        let ratio = AgentThreadMetrics.railStyle(.ratio)
        #expect(ratio.fill == NormaTheme.threadFaceCool)
        #expect(ratio.stroke == NormaTheme.threadCream)
        #expect(ratio.strokeWidth == 2)
        #expect(ratio.radius == 10)

        let norma = AgentThreadMetrics.railStyle(.norma)
        #expect(norma.fill == NormaTheme.ink)
        #expect(norma.stroke == NormaTheme.threadMuted)
        #expect(norma.strokeWidth == 1.5)
        #expect(norma.radius == 10)

        let you = AgentThreadMetrics.railStyle(.you)
        #expect(you.fill == NormaTheme.ink)
        #expect(you.stroke == NormaTheme.threadCream)
        #expect(you.strokeWidth == 2)
        #expect(you.radius == 4)
        #expect(you.diameter == 8)

        #expect(AgentThreadMetrics.railWidth == 60)
        #expect(AgentThreadMetrics.railHeight == 496)
        #expect(AgentThreadMetrics.railColor == NormaTheme.threadRail)
        #expect(AgentThreadMetrics.railStrokeWidth == 1.25)
        #expect(AgentThreadMetrics.railLineCap == .round)
        #expect(AgentThreadMetrics.openingSegmentDashed)
        #expect(AgentThreadMetrics.railDash == [2, 4])
        #expect(AgentThreadMetrics.segmentIsDashed(isOpening: true))
        #expect(AgentThreadMetrics.segmentIsDashed(isOpening: false) == false)
        #expect(AgentThreadMetrics.railLineX == 18)
    }
}

@MainActor
struct AgentThreadAccessibilityTests {
    @Test func voiceOverReadsNameThenMessageAndTitleThenTime() throws {
        // AC-5
        let stash = AgentThreadReply(name: "Stash", message: "Set $40 aside from yesterday's rent.", mark: .stash)
        let ratio = AgentThreadReply(name: "Ratio", message: "That leaves 12 days at this pace.", mark: .ratio)
        let norma = AgentThreadReply(
            name: "Norma",
            message: "Grocery is still open. Paycheck landed, so today is covered.",
            mark: .norma
        )
        let you = AgentThreadYou(label: "You", message: "Move another $20.")
        let idle = AgentThreadEvent(title: "Grocery run", time: "8:40 AM", isActive: false)
        let active = AgentThreadEvent(title: "Paycheck landed", time: "9:15 AM", isActive: true)

        #expect(stash.voiceOverLabel == "Stash, Set $40 aside from yesterday's rent.")
        #expect(ratio.voiceOverLabel == "Ratio, That leaves 12 days at this pace.")
        #expect(norma.voiceOverLabel == "Norma, Grocery is still open. Paycheck landed, so today is covered.")
        #expect(you.voiceOverLabel == "You, Move another $20.")
        #expect(idle.voiceOverLabel == "Grocery run, 8:40 AM")
        #expect(active.voiceOverLabel == "Paycheck landed, 9:15 AM")

        let rows = AgentThreadModel.board.rows
        #expect(rows.first { $0.id == "reply-stash" }?.voiceOverLabel == stash.voiceOverLabel)
        #expect(rows.first { $0.id == "event-idle" }?.voiceOverLabel == idle.voiceOverLabel)
        #expect(rows.first { $0.id == "event-active" }?.voiceOverLabel == active.voiceOverLabel)
        #expect(rows.first { $0.id == "you" }?.voiceOverLabel == you.voiceOverLabel)

        let source = try agentThreadSource()
        #expect(source.contains("accessibilityElement(children: .ignore)"))
        #expect(source.contains("accessibilityLabel(row.voiceOverLabel)"))
    }
}

@MainActor
struct AgentThreadGrowthTests {
    @Test func longMessagesWrapAndDynamicTypeDoesNotClip() throws {
        // AC-6
        let message = AgentThreadModel.longReply.message
        #expect(message.count > 140)
        let model = AgentThreadModel(rows: [
            AgentThreadRow(id: "long", kind: .reply(AgentThreadModel.longReply))
        ])
        let thread = AgentThread(model: model)
        #expect(thread.model.replies.first?.message == message)
        #expect(thread.model.replies.first?.message.count == message.count)

        let source = try agentThreadSource()
        #expect(source.contains("relativeTo: .body"))
        #expect(source.contains("fixedSize(horizontal: false, vertical: true)"))
        #expect(source.contains("minHeight: style.lineHeight"))
        #expect(source.contains("minHeight: AgentThreadMetrics.dayHeight"))
        #expect(source.contains("minHeight: AgentThreadMetrics.eventHeight"))
        #expect(source.contains("minHeight: AgentThreadMetrics.yesterdayHeight"))
        #expect(source.contains("minHeight: AgentThreadMetrics.youHeight"))
        #expect(source.contains("ScrollView"))
        #expect(source.contains("lineLimit") == false)
        #expect(source.contains("minimumScaleFactor") == false)
        #expect(source.contains("truncationMode") == false)
        #expect(AgentThreadMetrics.agentBody.extraLineSpacing >= 0)
        #expect(AgentThreadMetrics.everyone.extraLineSpacing >= 0)
        #expect(AgentThreadMetrics.youBody.lineHeight >= AgentThreadMetrics.youBody.size)
    }
}

@MainActor
struct AgentThreadPreviewTests {
    @Test func previewShowsTheFullBoardThread() throws {
        // AC-7
        let source = try agentThreadSource()
        let preview = previewSource(in: source)
        #expect(preview.contains("#Preview(\"Agent thread\")"))
        #expect(preview.contains("AgentThread(model: .board)"))
        #expect(preview.contains("AgentThreadMetrics.threadWidth"))
        #expect(preview.contains("AgentThreadMetrics.threadHeight"))

        let board = AgentThreadModel.board
        #expect(header(in: board)?.countText == "\u{00B7} 5 agents")
        #expect(yesterday(in: board)?.title == "Yesterday")
        #expect(day(in: board)?.title == "Today")
        #expect(board.events.map(\.isActive) == [false, true])
        #expect(board.replies.map(\.name) == ["Stash", "Ratio", "Norma"])
        #expect(you(in: board)?.label == "You")
        #expect(board.spacerHeights == [10, 20, 12, 16])
        let rendered = [
            "Everyone",
            "\u{00B7} 5 agents",
            "Yesterday",
            "Oct 26",
            "$146.20",
            "Rent cleared. Stash set $40 aside.",
            "Today",
            "Oct 27",
            "$84.00",
            "Grocery run",
            "8:40 AM",
            "Paycheck landed",
            "9:15 AM",
            "Stash",
            "Set $40 aside from yesterday's rent.",
            "Ratio",
            "That leaves 12 days at this pace.",
            "Norma",
            "Grocery is still open. Paycheck landed, so today is covered.",
            "You",
            "Move another $20.",
        ]
        for line in rendered {
            #expect(source.contains(line))
        }
    }
}

@MainActor
struct AgentThreadBuildTests {
    @Test func projectBuildsAndExistingTestsPass() {
        // AC-8
        let thread = AgentThread(model: .board)
        #expect(thread.model.rows.count == AgentThreadModel.board.rows.count)
        #expect(thread.model.replies.count == 3)
        #expect(thread.model.events.count == 2)
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
        #expect(NormaTheme.textStyles.map(\.name) == ["title", "body", "label", "caption"])
        #expect(NormaTheme.typeStyles == NormaTheme.textStyles + NormaTheme.numberStyles + [NormaTheme.realBalance])
        #expect(NormaTheme.cardRadius == 36)
        #expect(NormaTheme.spacing == [4, 8, 12, 16, 24, 32])
    }
}

private func kindNames(_ model: AgentThreadModel) -> [String] {
    model.rows.map { row in
        switch row.kind {
        case .header: return "header"
        case .yesterday: return "yesterday"
        case .day: return "day"
        case .event: return "event"
        case .reply: return "reply"
        case .you: return "you"
        case .spacer: return "spacer"
        }
    }
}

private func header(in model: AgentThreadModel) -> AgentThreadHeader? {
    for row in model.rows {
        if case .header(let header) = row.kind { return header }
    }
    return nil
}

private func yesterday(in model: AgentThreadModel) -> AgentThreadYesterday? {
    for row in model.rows {
        if case .yesterday(let yesterday) = row.kind { return yesterday }
    }
    return nil
}

private func day(in model: AgentThreadModel) -> AgentThreadDay? {
    for row in model.rows {
        if case .day(let day) = row.kind { return day }
    }
    return nil
}

private func you(in model: AgentThreadModel) -> AgentThreadYou? {
    for row in model.rows {
        if case .you(let you) = row.kind { return you }
    }
    return nil
}

private func agentThreadSource() throws -> String {
    let url =
        URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Norma", isDirectory: true)
        .appendingPathComponent("Views", isDirectory: true)
        .appendingPathComponent("Components", isDirectory: true)
        .appendingPathComponent("AgentThread.swift")
    return try String(contentsOf: url, encoding: .utf8)
}

private func previewSource(in source: String) -> String {
    guard let range = source.range(of: "#Preview") else { return "" }
    return String(source[range.lowerBound...])
}

private func expectLocked(_ swatch: NormaTheme.Swatch, hex: UInt32, hexString: String) {
    #expect(swatch.hex == hex)
    #expect(swatch.hexString == hexString)
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    let uiColor = UIColor(swatch.color)
    #expect(uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
    #expect(byte(red) == Int((hex >> 16) & 0xFF))
    #expect(byte(green) == Int((hex >> 8) & 0xFF))
    #expect(byte(blue) == Int(hex & 0xFF))
    #expect(byte(alpha) == 255)
}

private func byte(_ component: CGFloat) -> Int {
    Int((component * 255).rounded())
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

private func isHexDigit(_ character: Character) -> Bool {
    guard let ascii = character.asciiValue else { return false }
    return (ascii >= 48 && ascii <= 57) || (ascii >= 65 && ascii <= 70) || (ascii >= 97 && ascii <= 102)
}
