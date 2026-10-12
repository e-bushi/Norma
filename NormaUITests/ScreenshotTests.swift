//
//  ScreenshotTests.swift
//  NormaUITests
//
//  Norma is dark only. The PR gate runs dark / default Dynamic Type on
//  iPhone 17. The main and nightly workflow runs dark mode at default and
//  accessibility Dynamic Type, on a small phone and a large phone.
//  Accessibility screenshots scroll the rent row fully into view. The 16e
//  also snapshots $12,345.67 at accessibilityExtraExtraExtraLarge.
//

import UIKit
import XCTest

final class ScreenshotTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testHomeDarkDefault() throws {
        try assertHome(dynamicType: "default", name: "home-dark-default")
    }

    @MainActor
    func testHomeDarkAccessibility() throws {
        try assertHome(dynamicType: "accessibility", name: "home-dark-accessibility", scrollRentIntoView: true)
    }

    /// Longest realistic amount at accessibilityExtraExtraExtraLarge (`.accessibility5`) on iPhone 16e.
    @MainActor
    func testLongAmountStaysOneLineAtAccessibilitySize() throws {
        let device = try deviceSlug()
        guard device == "iphone-16e" else { return }
        try assertHome(
            dynamicType: "accessibility",
            name: "long-amount-accessibility",
            extraArguments: ["--bill-amount=12345.67"],
            scrollRentIntoView: true,
            requireSingleLineAmount: "$12,345.67"
        )
    }

    @MainActor
    private func assertHome(
        dynamicType: String,
        name: String,
        extraArguments: [String] = [],
        scrollRentIntoView: Bool = false,
        requireSingleLineAmount: String? = nil
    ) throws {
        let device = try deviceSlug()
        let record = shouldRecord

        XCUIDevice.shared.appearance = .dark

        var arguments = [
            "--ui-testing",
            "--screenshot",
            "--dynamic-type=\(dynamicType)",
            "--reference-date=2026-10-15",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
        ]
        arguments.append(contentsOf: extraArguments)
        let app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()

        let marker = app.descendants(matching: .any)["screenshot-home"]
        XCTAssertTrue(marker.waitForExistence(timeout: 20), "seeded home screen should appear")

        if scrollRentIntoView {
            let rent = app.staticTexts["rent"]
            let amount = app.staticTexts["bill-amount-rent"]
            XCTAssertTrue(rent.waitForExistence(timeout: 5), "rent row should exist")
            XCTAssertTrue(amount.waitForExistence(timeout: 5), "rent amount should exist")
            XCTAssertTrue(rentRowIsFullyVisible(rent, amount, in: app), "rent row is clipped")
        }

        if let expected = requireSingleLineAmount {
            let amount = app.staticTexts["bill-amount-rent"]
            XCTAssertEqual(amount.label, expected)
            let frame = amount.frame
            XCTAssertGreaterThan(
                frame.width,
                frame.height * 2,
                "amount wrapped onto more than one line: \(frame)"
            )
        }

        let settled = expectation(description: "layout settles")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { settled.fulfill() }
        wait(for: [settled], timeout: 3)

        let image = app.screenshot().image
        let url = baselineURL(device: device, name: name)
        let attachment = XCTAttachment(image: image)
        attachment.name = "\(device)-\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)

        if record {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            guard let data = image.pngData() else {
                XCTFail("Could not encode \(url.lastPathComponent)")
                return
            }
            try data.write(to: url)
            return
        }

        guard FileManager.default.fileExists(atPath: url.path),
            let baseline = UIImage(contentsOfFile: url.path)
        else {
            XCTFail("Missing baseline \(url.path). Record with: bash scripts/ci.sh record-screenshots")
            return
        }

        if let difference = pixelDifference(image, baseline) {
            XCTFail("\(device)/\(name): \(difference). Re-record only if the change is intended, and get Designer Dan's review.")
        }
    }

    /// The app scrolls the rent row to center for accessibility screenshots.
    private func rentRowIsFullyVisible(_ rent: XCUIElement, _ amount: XCUIElement, in app: XCUIApplication) -> Bool {
        let window = app.windows.firstMatch
        guard window.waitForExistence(timeout: 5) else { return false }
        for _ in 0..<12 {
            let minY = min(rent.frame.minY, amount.frame.minY)
            let maxY = max(rent.frame.maxY, amount.frame.maxY)
            let visible = window.frame.inset(by: UIEdgeInsets(top: 4, left: 0, bottom: 140, right: 0))
            if minY >= visible.minY && maxY <= visible.maxY { return true }
            let settled = expectation(description: "wait for the rent row to scroll into view")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { settled.fulfill() }
            wait(for: [settled], timeout: 1)
        }
        return false
    }

    private func deviceSlug() throws -> String {
        let supplied = ProcessInfo.processInfo.environment["SCREENSHOT_DEVICE"] ?? ""
        if !supplied.isEmpty && !supplied.hasPrefix("$(") {
            return supplied
        }
        let env = ProcessInfo.processInfo.environment
        let width = whole(env["SIMULATOR_MAINSCREEN_WIDTH"])
        let height = whole(env["SIMULATOR_MAINSCREEN_HEIGHT"])
        let key = "\(width)x\(height)"
        let known = [
            "1206x2622": "iphone-17",
            "1170x2532": "iphone-16e",
            "1320x2868": "iphone-17-pro-max",
        ]
        if let slug = known[key] { return slug }
        XCTFail("Unknown simulator screen \(key). Add it to the screenshot device map.")
        throw XCTSkip("unknown screen \(key)")
    }

    private func whole(_ raw: String?) -> String {
        guard let raw, let value = Double(raw) else { return raw ?? "" }
        return String(Int(value.rounded()))
    }

    private var shouldRecord: Bool {
        if ProcessInfo.processInfo.environment["RECORD_SCREENSHOTS"] == "1" { return true }
        return FileManager.default.fileExists(atPath: recordFlag.path)
    }

    private var recordFlag: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ScreenshotBaselines/.record")
    }

    private func baselineURL(device: String, name: String) -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ScreenshotBaselines", isDirectory: true)
            .appendingPathComponent(device, isDirectory: true)
            .appendingPathComponent("\(name).png")
    }

    /// Nil when the images match. A few anti-aliased pixels may differ.
    private func pixelDifference(_ actual: UIImage, _ expected: UIImage) -> String? {
        guard let actualPixels = pixels(of: actual), let expectedPixels = pixels(of: expected) else {
            return "could not read pixels"
        }
        guard actualPixels.width == expectedPixels.width, actualPixels.height == expectedPixels.height else {
            return "size \(actualPixels.width)x\(actualPixels.height) != baseline \(expectedPixels.width)x\(expectedPixels.height)"
        }

        var mismatched = 0
        let total = actualPixels.width * actualPixels.height
        for index in 0..<total {
            let offset = index * 4
            let red = abs(Int(actualPixels.bytes[offset]) - Int(expectedPixels.bytes[offset]))
            let green = abs(Int(actualPixels.bytes[offset + 1]) - Int(expectedPixels.bytes[offset + 1]))
            let blue = abs(Int(actualPixels.bytes[offset + 2]) - Int(expectedPixels.bytes[offset + 2]))
            if red > 12 || green > 12 || blue > 12 {
                mismatched += 1
            }
        }
        let fraction = Double(mismatched) / Double(max(total, 1))
        if fraction > 0.002 {
            return String(format: "%.3f%% of pixels differ (%d/%d)", fraction * 100, mismatched, total)
        }
        return nil
    }

    private func pixels(of image: UIImage) -> (width: Int, height: Int, bytes: [UInt8])? {
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        let byteCount = width * height * 4
        var data = Data(count: byteCount)
        let drew = data.withUnsafeMutableBytes { raw -> Bool in
            guard
                let context = CGContext(
                    data: raw.baseAddress,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: width * 4,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                )
            else { return false }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drew else { return nil }
        return (width, height, [UInt8](data))
    }
}
