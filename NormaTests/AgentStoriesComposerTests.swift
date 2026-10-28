//
//  AgentStoriesComposerTests.swift
//  NormaTests
//
//  Tokens, layout numbers, send state, and VoiceOver labels for the
//  stories row and the composer. Each test is tagged with its AC id.
//

import SwiftUI
import Testing
import UIKit

@testable import Norma

@MainActor
struct AgentStoriesRowTests {
    @Test func activeAndIdleRingsFacesAndLabels() {
        // AC-1
        let active = AgentStory(name: "Stash", face: NormaTheme.stash, isActive: true)
        let idle = AgentStory(name: "Bills", face: NormaTheme.bills, isActive: false)
        let activeStyle = AgentStoryStyle.resolve(active)
        let idleStyle = AgentStoryStyle.resolve(idle)

        #expect(activeStyle.ring == NormaTheme.coral)
        #expect(activeStyle.ringWidth == 2.5)
        #expect(activeStyle.ringPadding == 3)
        #expect(activeStyle.label == NormaTheme.ink)
        #expect(idleStyle.ring == NormaTheme.idleRing)
        #expect(idleStyle.ringWidth == 1.5)
        #expect(idleStyle.ringPadding == 4)
        #expect(idleStyle.label == NormaTheme.slate)
        #expect(active.face == NormaTheme.stash)
        #expect(idle.face == NormaTheme.bills)

        #expect(AgentStoriesMetrics.ringSize == 62)
        #expect(AgentStoriesMetrics.faceSize == 51)
        #expect(AgentStoriesMetrics.faceRadius == 26)
        #expect(AgentStoriesMetrics.well == NormaTheme.storyWell)
        #expect(AgentStoriesMetrics.columnWidth == 62)
        #expect(AgentStoriesMetrics.labelGap == 6)
        #expect(AgentStoriesMetrics.paddingTop == 14)
        #expect(AgentStoriesMetrics.paddingBottom == 18)
        #expect(AgentStoriesMetrics.paddingInline == 22)
        #expect(AgentStoriesMetrics.columnGap == 14)
        #expect(AgentStoriesMetrics.labelStyle == NormaTheme.caption)
        #expect(AgentStoriesMetrics.labelStyle.size == 12)
        #expect(AgentStoriesMetrics.labelStyle.postScriptName == "InstrumentSans-Regular")
        #expect(AgentStoriesMetrics.labelLineHeight == 16)

        #expect(activeStyle.ringWidth + activeStyle.ringPadding == (AgentStoriesMetrics.ringSize - AgentStoriesMetrics.faceSize) / 2)
        #expect(idleStyle.ringWidth + idleStyle.ringPadding == (AgentStoriesMetrics.ringSize - AgentStoriesMetrics.faceSize) / 2)
    }

    @Test func normaEntryUsesTheExistingMark() throws {
        // AC-1
        let norma = AgentStory(name: "Norma", face: NormaTheme.ink, isActive: true)
        #expect(norma.showsMark)
        #expect(norma.face == NormaTheme.ink)
        #expect(!AgentStory(name: "Stash", face: NormaTheme.stash, isActive: true).showsMark)
        #expect(!AgentStory(name: "norman", face: NormaTheme.ink, isActive: true).showsMark)
        #expect(AgentStoriesMetrics.markWidth == 30)
        #expect(AgentStoriesMetrics.markHeight == 28)
        #expect(AgentStoriesMetrics.markAssetName == "NormaMark")

        let root = repoRoot()
        let mark = root.appendingPathComponent("Norma/Assets.xcassets/NormaMark.imageset/norma-logo.png")
        let existing = root.appendingPathComponent("Norma/nms.icon/Assets/norma-logo.png")
        let markData = try Data(contentsOf: mark)
        let existingData = try Data(contentsOf: existing)
        #expect(markData == existingData)

        let bundle = Bundle(identifier: "com.myndfruit.Norma") ?? Bundle.main
        let image = UIImage(named: AgentStoriesMetrics.markAssetName, in: bundle, compatibleWith: nil)
        #expect(image != nil)
    }

    @Test func voiceOverSaysNameAndActive() {
        // AC-5
        #expect(AgentStory(name: "Norma", face: NormaTheme.ink, isActive: true).voiceOverLabel == "Norma, active")
        #expect(AgentStory(name: "Stash", face: NormaTheme.stash, isActive: true).voiceOverLabel == "Stash, active")
        #expect(AgentStory(name: "Bills", face: NormaTheme.bills, isActive: false).voiceOverLabel == "Bills")
        #expect(AgentStory(name: "Oakline", face: NormaTheme.oakline, isActive: false).voiceOverLabel == "Oakline")
    }

    @Test func rowScrollsHorizontally() {
        // AC-6
        #expect(AgentStoriesMetrics.scrollAxis == .horizontal)
    }

    @Test func boardPreviewListsTheFiveAgents() throws {
        // AC-7
        #expect(AgentStory.board.map(\.name) == ["Norma", "Stash", "Ratio", "Bills", "Oakline"])
        #expect(AgentStory.board.map(\.isActive) == [true, true, true, false, false])
        #expect(
            AgentStory.board.map(\.face) == [
                NormaTheme.ink,
                NormaTheme.stash,
                NormaTheme.ratio,
                NormaTheme.bills,
                NormaTheme.oakline,
            ])
        #expect(AgentStory.board.filter(\.showsMark).map(\.name) == ["Norma"])

        let source = try componentSource("AgentStoriesRow.swift")
        let rendersBoard = previewBlocks(in: source).contains { block in
            block.contains("AgentStoriesRow(") && block.contains("AgentStory.board")
        }
        #expect(rendersBoard)
    }
}

@MainActor
struct AgentComposerTests {
    @Test func addFieldAndSendMatchTheBoard() {
        // AC-2
        #expect(AgentComposerMetrics.paddingTop == 10)
        #expect(AgentComposerMetrics.paddingBottom == 34)
        #expect(AgentComposerMetrics.paddingInline == 16)
        #expect(AgentComposerMetrics.rowGap == 10)

        #expect(AgentComposerMetrics.addButtonSize == 36)
        #expect(AgentComposerMetrics.addButtonRadius == 18)
        #expect(AgentComposerMetrics.addFill == NormaTheme.addFill)
        #expect(AgentComposerMetrics.plusSize == 18)
        #expect(AgentComposerMetrics.plusStroke == 2)
        #expect(AgentComposerMetrics.plusColor == NormaTheme.slate)

        #expect(AgentComposerMetrics.fieldHeight == 38)
        #expect(AgentComposerMetrics.fieldRadius == 19)
        #expect(AgentComposerMetrics.fieldFill == NormaTheme.fieldFill)
        #expect(AgentComposerMetrics.fieldStroke == NormaTheme.fieldStroke)
        #expect(AgentComposerMetrics.fieldStrokeWidth == 1)
        #expect(AgentComposerMetrics.fieldPaddingLeading == 14)
        #expect(AgentComposerMetrics.fieldPaddingTrailing == 4)
        #expect(AgentComposer.placeholder == "Message everyone, or @ one")
        #expect(AgentComposerMetrics.placeholderColor == NormaTheme.placeholder)
        #expect(AgentComposerMetrics.textStyle == NormaTheme.message)
        #expect(AgentComposerMetrics.textStyle.size == 16)
        #expect(AgentComposerMetrics.textStyle.postScriptName == "InstrumentSans-Regular")
        #expect(AgentComposerMetrics.textLineHeight == 20)
        #expect(AgentComposerMetrics.typedText == NormaTheme.ink)

        #expect(AgentComposerMetrics.sendButtonSize == 30)
        #expect(AgentComposerMetrics.sendButtonRadius == 15)
        #expect(AgentComposerMetrics.sendFill == NormaTheme.coral)
        #expect(AgentComposerMetrics.arrowSize == 16)
        #expect(AgentComposerMetrics.arrowStroke == 2.4)
        #expect(AgentComposerMetrics.arrowColor == NormaTheme.white)
    }

    @Test func sendIsDisabledWhenTextIsEmpty() {
        // AC-3
        #expect(!AgentComposer.canSend(""))
        #expect(AgentComposer.canSend("On my way"))
        #expect(AgentComposer.sendOpacity(for: "") == AgentComposer.disabledOpacity)
        #expect(AgentComposer.sendOpacity(for: "On my way") == 1)
        #expect(AgentComposer.disabledOpacity < 1)
        #expect(AgentComposerMetrics.sendFill == NormaTheme.coral)
    }

    @Test func addAndSendButtonsAreLabeled() {
        // AC-5
        #expect(AgentComposer.addAccessibilityLabel == "Add")
        #expect(AgentComposer.sendAccessibilityLabel == "Send")
    }

    @Test func composerPreviewsCoverEmptyAndTyped() throws {
        // AC-7
        let source = try componentSource("AgentComposer.swift")
        let texts = composerPreviewTexts(in: source)
        #expect(texts.contains(""))
        #expect(texts.contains { !$0.isEmpty })
    }
}

@MainActor
struct AgentBuildSurfaceTests {
    @Test func projectBuildsAndExistingTestsPass() {
        // AC-8
        let stories = AgentStoriesRow(agents: AgentStory.board)
        let composer = AgentComposer(text: .constant(""), onAdd: {}, onSend: {})
        #expect(stories.agents.map(\.name) == AgentStory.board.map(\.name))
        #expect(composer.text.isEmpty)
        #expect(!AgentComposer.canSend(composer.text))
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
    }
}

@MainActor
struct AgentComponentTokenTests {
    @Test func componentColorsAreNamedTokens() {
        // AC-4
        expectLocked(NormaTheme.storyWell, hex: 0xE8EAEC, hexString: "#E8EAEC")
        expectLocked(NormaTheme.idleRing, hex: 0xC2C8CE, hexString: "#C2C8CE")
        expectLocked(NormaTheme.stash, hex: 0xAFC3A9, hexString: "#AFC3A9")
        expectLocked(NormaTheme.ratio, hex: 0xAEBCCA, hexString: "#AEBCCA")
        expectLocked(NormaTheme.bills, hex: 0xCBAE9F, hexString: "#CBAE9F")
        expectLocked(NormaTheme.oakline, hex: 0xC0AEC7, hexString: "#C0AEC7")
        expectLocked(NormaTheme.addFill, hex: 0xECE4D7, hexString: "#ECE4D7")
        expectLocked(NormaTheme.fieldFill, hex: 0xFFFDF9, hexString: "#FFFDF9")
        expectLocked(NormaTheme.fieldStroke, hex: 0xD9D0C2, hexString: "#D9D0C2")
        expectLocked(NormaTheme.placeholder, hex: 0x9AA0A6, hexString: "#9AA0A6")
        expectLocked(NormaTheme.white, hex: 0xFFFFFF, hexString: "#FFFFFF")
        #expect(
            NormaTheme.componentSwatches.map(\.name) == [
                "story well",
                "idle ring",
                "stash",
                "ratio",
                "bills",
                "oakline",
                "add fill",
                "field fill",
                "field stroke",
                "placeholder",
                "white",
            ])
        #expect(NormaTheme.message.size == 16)
        #expect(NormaTheme.message.postScriptName == "InstrumentSans-Regular")
        #expect(NormaTheme.message.kind == .text)
    }

    @Test func radiiUseContinuousCorners() {
        // AC-4
        let radii: [CGFloat] = [
            AgentStoriesMetrics.ringRadius,
            AgentStoriesMetrics.faceRadius,
            AgentComposerMetrics.addButtonRadius,
            AgentComposerMetrics.fieldRadius,
            AgentComposerMetrics.sendButtonRadius,
        ]
        for radius in radii {
            let shape = NormaTheme.shape(radius)
            #expect(shape.style == .continuous)
            #expect(shape.cornerSize == CGSize(width: radius, height: radius))
        }
    }

    @Test func componentSourcesHaveNoHexLiterals() throws {
        // AC-4
        let pattern = try NSRegularExpression(
            pattern: "#[0-9A-Fa-f]{3,8}\\b|0x[0-9A-Fa-f]+|Color\\.white|UIColor\\(|RoundedRectangle|Circle\\("
        )
        for name in ["AgentStoriesRow.swift", "AgentComposer.swift"] {
            let source = try componentSource(name)
            let range = NSRange(source.startIndex..., in: source)
            let match = pattern.firstMatch(in: source, range: range)
            #expect(match == nil)
            #expect(source.contains("NormaTheme.shape"))
        }
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
}

/// Bodies of `#Preview` blocks. Removing a preview drops it from this list.
private func previewBlocks(in source: String) -> [String] {
    var blocks: [String] = []
    var search = source.startIndex
    while let marker = source.range(of: "#Preview", range: search..<source.endIndex) {
        guard let open = source[marker.upperBound...].firstIndex(of: "{") else { break }
        guard let close = closingBrace(in: source, open: open) else { break }
        let bodyStart = source.index(after: open)
        blocks.append(String(source[bodyStart..<close]))
        search = source.index(after: close)
    }
    return blocks
}

/// Text values shown by previews that actually render `AgentComposer`.
/// A struct that is not referenced from a `#Preview` does not count.
private func composerPreviewTexts(in source: String) -> [String] {
    previewBlocks(in: source).flatMap { block in
        textsForComposerPreview(block, source: source)
    }
}

private func textsForComposerPreview(_ block: String, source: String) -> [String] {
    var texts: [String] = []
    if block.contains("AgentComposer(") {
        texts += textLiterals(in: block)
    }
    for name in calledTypeNames(in: block) {
        guard let body = typeBody(named: name, source: source) else { continue }
        guard body.contains("AgentComposer(") else { continue }
        texts += textLiterals(in: body)
    }
    return texts
}

private func calledTypeNames(in source: String) -> [String] {
    guard let regex = try? NSRegularExpression(pattern: #"\b([A-Z][A-Za-z0-9_]*)\s*\("#) else {
        return []
    }
    let range = NSRange(source.startIndex..., in: source)
    return regex.matches(in: source, range: range).compactMap { match in
        guard let swiftRange = Range(match.range(at: 1), in: source) else { return nil }
        return String(source[swiftRange])
    }
}

private func typeBody(named name: String, source: String) -> String? {
    guard let regex = try? NSRegularExpression(pattern: #"\bstruct\s+\#(name)\b"#) else { return nil }
    let range = NSRange(source.startIndex..., in: source)
    guard let match = regex.firstMatch(in: source, range: range),
        let matchEnd = Range(match.range, in: source)?.upperBound,
        let open = source[matchEnd...].firstIndex(of: "{"),
        let close = closingBrace(in: source, open: open)
    else { return nil }
    let bodyStart = source.index(after: open)
    return String(source[bodyStart..<close])
}

private func textLiterals(in source: String) -> [String] {
    let patterns = [
        #"text\s*=\s*"((?:\\.|[^"\\])*)""#,
        #"\.constant\(\s*"((?:\\.|[^"\\])*)"\s*\)"#,
    ]
    var found: [String] = []
    for pattern in patterns {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
        let range = NSRange(source.startIndex..., in: source)
        for match in regex.matches(in: source, range: range) {
            guard let swiftRange = Range(match.range(at: 1), in: source) else { continue }
            found.append(String(source[swiftRange]))
        }
    }
    return found
}

private func closingBrace(in source: String, open: String.Index) -> String.Index? {
    var depth = 0
    var index = open
    while index < source.endIndex {
        let character = source[index]
        if character == "{" { depth += 1 }
        if character == "}" {
            depth -= 1
            if depth == 0 { return index }
        }
        index = source.index(after: index)
    }
    return nil
}

private func repoRoot() -> URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
}

private func componentSource(_ name: String) throws -> String {
    let url = repoRoot()
        .appendingPathComponent("Norma/Views/Components")
        .appendingPathComponent(name)
    return try String(contentsOf: url, encoding: .utf8)
}
