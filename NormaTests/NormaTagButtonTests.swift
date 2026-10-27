//
//  NormaTagButtonTests.swift
//  NormaTests
//
//  Tag button variants and the press motion. Each test is tagged with its
//  acceptance check. AC-8: these cover variant colors and the press offset.
//

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
