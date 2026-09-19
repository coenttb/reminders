import Foundation
import XCTest

@MainActor final class RemindersUITests: XCTestCase {
    func testDomainFirstViewsEndToEnd() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["Add List"].waitForExistence(timeout: 15))
        capture("01-root", app)

        // Cancel is dismissal, not a submitted blank request.
        app.buttons["Add List"].tap()
        XCTAssertTrue(app.textFields["List Name"].waitForExistence(timeout: 5))
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.textFields["List Name"].waitForNonExistence(timeout: 5))

        let list = "UI Validation \(UUID().uuidString.prefix(6))"
        app.buttons["Add List"].tap()
        let name = app.textFields["List Name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText(list)
        app.buttons["Done"].tap()
        let listRow = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", list)).firstMatch
        XCTAssertTrue(listRow.waitForExistence(timeout: 10))
        listRow.tap()
        XCTAssertTrue(app.navigationBars[list].waitForExistence(timeout: 5))

        app.buttons["New Reminder"].tap()
        let field = app.textFields["New Reminder"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5), "The presented editor should own keyboard focus")
        field.typeText("Buy tea")
        capture("02-new-draft", app)
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["Buy tea"].waitForExistence(timeout: 10))
        XCTAssertTrue(field.waitForNonExistence(timeout: 5))

        let complete = app.buttons.matching(NSPredicate(format: "label == %@ AND value == %@", "Mark complete", "Buy tea")).firstMatch
        XCTAssertTrue(complete.waitForExistence(timeout: 5))
        complete.tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label == %@ AND value == %@", "Mark incomplete", "Buy tea")).firstMatch.waitForExistence(timeout: 10))
        capture("03-completed", app)

        app.buttons["Buy tea"].tap()
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: "Buy tea".count))
        field.typeText("Buy tea today\n")
        XCTAssertTrue(app.buttons["Buy tea today"].waitForExistence(timeout: 10))
        XCTAssertTrue(field.waitForNonExistence(timeout: 5))
        capture("04-edited", app)

        // A blank draft is discarded when Done ends its editing lifetime.
        app.buttons["New Reminder"].tap()
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        XCTAssertTrue(field.waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Buy tea today"].exists)

        // Switching between row identities must move one editor, not duplicate it.
        app.buttons["New Reminder"].tap()
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText("Second row")
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["Second row"].waitForExistence(timeout: 10))
        app.buttons["Buy tea today"].tap()
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        app.buttons["Second row"].tap()
        XCTAssertEqual(app.textFields.matching(identifier: "New Reminder").count, 1)
        XCTAssertEqual(field.value as? String, "Second row")
        XCTAssertTrue(app.buttons["Buy tea today"].exists)
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        capture("04b-switched-editor", app)
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["Second row"].waitForExistence(timeout: 5))
        app.buttons["Second row"].swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssertTrue(app.buttons["Second row"].waitForNonExistence(timeout: 10))

        // Relaunch demonstrates persistence, not merely an in-memory row overlay.
        app.terminate()
        app.launch()
        XCTAssertTrue(listRow.waitForExistence(timeout: 15))
        listRow.tap()
        let saved = app.buttons["Buy tea today"]
        XCTAssertTrue(saved.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label == %@ AND value == %@", "Mark incomplete", "Buy tea today")).firstMatch.exists)
        capture("05-persisted", app)
        saved.swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssertTrue(saved.waitForNonExistence(timeout: 10))
        capture("06-deleted-reminder", app)

        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(listRow.waitForExistence(timeout: 5))
        listRow.swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssertTrue(listRow.waitForNonExistence(timeout: 10))
        capture("07-cleaned-up", app)
    }

    private func capture(_ name: String, _ app: XCUIApplication) {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = name
        screenshot.lifetime = .keepAlways
        add(screenshot)
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "\(name)-hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
    }
}
