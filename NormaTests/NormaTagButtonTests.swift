//
//  NormaTagButtonTests.swift
//  NormaTests
//
//  Tag button variants and the press motion. Each test is tagged with its
//  acceptance check. AC-8: these cover variant colors and the press offset.
//

import Foundation
import SwiftUI
import Testing
import UIKit

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
    func variantColorsComeFromThemeTokens() throws {
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

        let source = try normaTagButtonSource()
        #expect(source.contains("struct NormaTagButton"))
        #expect(hexLiterals(in: strippingStringsAndComments(source)) == [])
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

    @Test("AC-4: makeBody passes configuration.isPressed into the face")
    func styleIsAButtonStyle() throws {
        // AC-4
        let style = NormaTagButtonStyle(variant: .coral)
        #expect(style.variant == .coral)
        confirmButtonStyle(style)

        let code = strippingStringsAndComments(try normaTagButtonSource())
        let arguments = firstCallArguments(
            callee: "NormaTagButtonFace",
            in: functionBody(startingAt: "func makeBody", in: code)
        )
        let pressed = argument(named: "isPressed", in: arguments ?? "")
        #expect(pressed == "configuration.isPressed")
    }

    @Test("AC-5: corners use continuous style")
    func cornersAreContinuous() {
        // AC-5
        let shape = NormaTagButton.Metrics.cornerShape
        #expect(NormaTagButton.Metrics.cornerRadius == 16)
        #expect(shape.style == .continuous)
        #expect(shape.cornerSize == CGSize(width: 16, height: 16))
    }

    @Test("AC-7: the preview shows navy and coral at rest and pressed")
    func previewShowsBothVariantsAtRestAndPressed() {
        // AC-7
        let samples = NormaTagButton.previewSamples
        #expect(samples.filter { $0.variant == .navy && $0.isPressed == false }.count == 1)
        #expect(samples.filter { $0.variant == .coral && $0.isPressed == false }.count == 1)
        #expect(samples.filter { $0.variant == .navy && $0.isPressed }.count == 1)
        #expect(samples.filter { $0.variant == .coral && $0.isPressed }.count == 1)
    }

    @Test("AC-6: a hosted NormaTagButton exposes its title and the button trait")
    func voiceOverReadsTheTitle() {
        // AC-6
        expectHostedButton(title: "Approve", variant: .coral)
        expectHostedButton(title: "Skip", variant: .navy)
    }

    private func confirmButtonStyle<S: ButtonStyle>(_ style: S) {
        _ = style
    }

    /// Fails unless a window-hosted button exposes `title` and the button trait.
    private func expectHostedButton(title: String, variant: NormaTagButton.Variant) {
        let buttonLabels = hostedAccessibility(of: NormaTagButton(title: title, variant: variant) {})
            .filter { $0.traits.contains(.button) }
            .compactMap(\.label)
        #expect(buttonLabels.contains(title))
    }

    private struct HostedAccessibility {
        var label: String?
        var traits: UIAccessibilityTraits
    }

    private func hostedAccessibility<V: View>(of view: V) -> [HostedAccessibility] {
        let frame = CGRect(x: 0, y: 0, width: 320, height: 180)
        let controller = UIHostingController(rootView: view)
        let window = hostingWindow(frame: frame)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.frame = frame
        controller.view.layoutIfNeeded()

        var visited: Set<ObjectIdentifier> = []
        let nodes = accessibilityNodes(of: controller.view, visited: &visited)
        window.isHidden = true
        window.rootViewController = nil
        return nodes
    }

    private func hostingWindow(frame: CGRect) -> UIWindow {
        if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
            let window = UIWindow(windowScene: scene)
            window.frame = frame
            return window
        }
        return UIWindow(frame: frame)
    }

    private func accessibilityNodes(of object: NSObject, visited: inout Set<ObjectIdentifier>) -> [HostedAccessibility] {
        guard visited.insert(ObjectIdentifier(object)).inserted else { return [] }

        var nodes: [HostedAccessibility] = []
        if object.isAccessibilityElement || object.accessibilityLabel != nil {
            nodes.append(HostedAccessibility(label: object.accessibilityLabel, traits: object.accessibilityTraits))
        }

        let children = accessibilityChildren(of: object).filter { visited.contains(ObjectIdentifier($0)) == false }
        if children.isEmpty, let view = object as? UIView {
            for subview in view.subviews {
                nodes.append(contentsOf: accessibilityNodes(of: subview, visited: &visited))
            }
        } else {
            for child in children {
                nodes.append(contentsOf: accessibilityNodes(of: child, visited: &visited))
            }
        }
        return nodes
    }

    /// User-testing children when UIKit exposes them, otherwise the public container children.
    private func accessibilityChildren(of object: NSObject) -> [NSObject] {
        let testingChildren = userTestingChildren(of: object)
        if !testingChildren.isEmpty { return testingChildren }

        let count = min(object.accessibilityElementCount(), 64)
        guard count > 0 else { return [] }
        var children: [NSObject] = []
        for index in 0..<count {
            guard let child = object.accessibilityElement(at: index) as? NSObject, child !== object else { continue }
            children.append(child)
        }
        return children
    }

    private func userTestingChildren(of object: NSObject) -> [NSObject] {
        let selector = NSSelectorFromString("_accessibilityUserTestingChildren")
        guard object.responds(to: selector) else { return [] }
        guard let array = object.perform(selector)?.takeUnretainedValue() as? NSArray else { return [] }
        return array.compactMap { $0 as? NSObject }.filter { $0 !== object }
    }
}

private func normaTagButtonSource() throws -> String {
    let url =
        URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Norma", isDirectory: true)
        .appendingPathComponent("Views", isDirectory: true)
        .appendingPathComponent("Components", isDirectory: true)
        .appendingPathComponent("NormaTagButton.swift")
    return try String(contentsOf: url, encoding: .utf8)
}

/// Code with comments and string literals removed, so a hex color in either does not count.
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

private func isHexDigit(_ character: Character) -> Bool {
    guard let ascii = character.asciiValue else { return false }
    return (ascii >= 48 && ascii <= 57) || (ascii >= 65 && ascii <= 70) || (ascii >= 97 && ascii <= 102)
}

private func functionBody(startingAt needle: String, in code: String) -> String {
    guard let declaration = code.range(of: needle) else { return "" }
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

private func firstCallArguments(callee: String, in code: String) -> String? {
    let marker = callee + "("
    guard let start = code.range(of: marker) else { return nil }
    var depth = 1
    var index = start.upperBound
    while index < code.endIndex {
        let character = code[index]
        if character == "(" {
            depth += 1
        } else if character == ")" {
            depth -= 1
            if depth == 0 {
                return String(code[start.upperBound..<index])
            }
        }
        index = code.index(after: index)
    }
    return nil
}

private func argument(named name: String, in arguments: String) -> String? {
    var depth = 0
    var parts: [String] = []
    var current = ""
    for character in arguments {
        if character == "(" || character == "[" || character == "{" {
            depth += 1
        } else if character == ")" || character == "]" || character == "}" {
            depth -= 1
        }
        if character == ",", depth == 0 {
            parts.append(current)
            current = ""
            continue
        }
        current.append(character)
    }
    parts.append(current)

    let prefix = name + ":"
    for part in parts {
        let trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix(prefix) else { continue }
        return String(trimmed.dropFirst(prefix.count)).filter { !$0.isWhitespace }
    }
    return nil
}
