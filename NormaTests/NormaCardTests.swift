//
//  NormaCardTests.swift
//  NormaTests
//
//  Padding, radius, hairline, literals, and the preview for NormaCard.
//  Each acceptance check is tagged on the test that covers it.
//

import Foundation
import SwiftUI
import Testing

@testable import Norma

@MainActor
struct NormaCardTests {
    @Test func acceptsAnyContent() {
        // AC-1
        // AC-7
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

    @Test func borderWidthIsTheHairlineToken() throws {
        // AC-3
        let card = NormaCard { Text("rent") }
        let scales: [CGFloat] = [1, 2, 3]

        for scale in scales {
            #expect(card.borderWidth(displayScale: scale) == NormaTheme.hairline(displayScale: scale))
        }
        #expect(card.borderWidth(displayScale: 1) == 1)
        #expect(card.borderWidth(displayScale: 2) == 0.5)
        #expect(card.borderWidth(displayScale: 3) == 1 / CGFloat(3))

        let body = viewBody(in: strippingStringsAndComments(try normaCardSource()))
        #expect(body.hasPrefix("{"))
        #expect(body.contains(".shadow") == false)
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

    @Test("AC-5: no hex or size literals in NormaCard")
    func componentHasNoHexOrSizeLiterals() throws {
        // AC-5
        let source = try normaCardSource()
        let code = strippingStringsAndComments(source)
        #expect(source.contains("struct NormaCard"))
        #expect(hexLiterals(in: code) == [])
        #expect(numericLiterals(in: code) == [])
    }

    @Test("AC-6: preview shows text and a CommitMono number")
    func previewShowsTextAndCommitMonoNumber() throws {
        // AC-6
        let source = try normaCardSource()
        let preview = previewSource(in: source)
        #expect(preview.contains("#Preview"))
        #expect(preview.contains("Text(\"Left this month\")"))
        #expect(preview.contains("Text(\"1,234.50\")"))
        #expect(preview.contains("NormaTheme.number"))
        #expect(NormaTheme.number.postScriptName == "CommitMono-Regular")
        #expect(NormaTheme.number.kind == .number)

        let card = NormaCard {
            VStack(alignment: .leading, spacing: NormaTheme.spacing8) {
                Text("Left this month")
                    .font(NormaTheme.body.font)
                    .foregroundStyle(NormaTheme.ink.color)
                Text("1,234.50")
                    .font(NormaTheme.number.font)
                    .foregroundStyle(NormaTheme.ink.color)
            }
        }
        #expect(card.padding == NormaTheme.spacing16)
    }
}

private func normaCardSource() throws -> String {
    let url =
        URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Norma", isDirectory: true)
        .appendingPathComponent("Views", isDirectory: true)
        .appendingPathComponent("Components", isDirectory: true)
        .appendingPathComponent("NormaCard.swift")
    return try String(contentsOf: url, encoding: .utf8)
}

private func previewSource(in source: String) -> String {
    guard let range = source.range(of: "#Preview") else { return "" }
    return String(source[range.lowerBound...])
}

/// The `body` of `NormaCard`, including its braces. Comments must already be stripped.
private func viewBody(in code: String) -> String {
    guard let declaration = code.range(of: "var body") else { return "" }
    guard let open = code[declaration.upperBound...].firstIndex(of: "{") else { return "" }
    var depth = 0
    var index = open
    while index < code.endIndex {
        let character = code[index]
        if character == "{" {
            depth += 1
        } else if character == "}" {
            depth -= 1
            if depth == 0 {
                return String(code[open...index])
            }
        }
        index = code.index(after: index)
    }
    return ""
}

/// Code with comments and string literals removed, so token names such as
/// `spacing16` stay and quoted sample numbers do not.
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
