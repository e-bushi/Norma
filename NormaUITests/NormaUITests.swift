//
//  NormaUITests.swift
//  NormaUITests
//
//  End-to-end: onboard with an income, add a bill, and see what's left.
//

import XCTest

final class NormaUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testOnboardAddBillAndSeeWhatsLeft() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        app.buttons["begin"].tap()

        let amount = app.textFields.firstMatch
        XCTAssertTrue(amount.waitForExistence(timeout: 25), "rhythm screen should follow the intro")
        amount.tap()
        amount.typeText("2000")
        app.buttons["monthly"].tap()
        attachScreenshot(app, named: "rhythm")
        app.buttons["continue"].tap()

        let addBill = app.buttons["add bill"]
        XCTAssertTrue(addBill.waitForExistence(timeout: 15), "home should appear after the welcome")
        attachScreenshot(app, named: "home-empty")

        addBill.tap()
        let name = app.textFields.element(boundBy: 0)
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        XCTAssertTrue(
            app.keyboards.firstMatch.waitForExistence(timeout: 5),
            "bill name field should show the keyboard"
        )
        // Whole-screen shot so the keyboard is in the attachment. This is not
        // a snapshot baseline: SnapshotTesting cannot see the keyboard.
        let keyboard = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        keyboard.name = "keyboard-dark"
        keyboard.lifetime = .keepAlways
        add(keyboard)
        name.typeText("rent")
        let billAmount = app.textFields.element(boundBy: 1)
        billAmount.tap()
        billAmount.typeText("1500")
        attachScreenshot(app, named: "new-bill")
        app.buttons["add"].tap()

        let leftover = app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH '$500'")).firstMatch
        XCTAssertTrue(leftover.waitForExistence(timeout: 5), "$2,000 income − $1,500 rent should leave $500")
        attachScreenshot(app, named: "home-with-bill")
    }

    @MainActor
    func testStaysDarkWhenTheSystemIsLight() {
        XCUIDevice.shared.appearance = .light
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        let dark = app.descendants(matching: .any)["interface-style-dark"]
        XCTAssertTrue(
            dark.waitForExistence(timeout: 15),
            "UIUserInterfaceStyle Dark should keep the app dark when the system is light"
        )
        XCTAssertFalse(app.descendants(matching: .any)["interface-style-light"].exists)
    }

    private func attachScreenshot(_ app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
