import XCTest

final class SketchbookUITests: XCTestCase {
    private func scrollTools(_ app: XCUIApplication) {
        let scroll = app.scrollViews["sketchEditorScroll"]
        scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.85)).press(forDuration: 0.05, thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.2)))
    }
    func testDrawUndoReopenAndExportPrivately() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["--quest-ui-tests"]
        app.launchEnvironment["LINLEY_SKETCH_TEST_SESSION"] = UUID().uuidString
        app.launch()
        XCTAssertTrue(app.buttons["openSketchbook"].waitForExistence(timeout: 12))
        app.buttons["openSketchbook"].tap()
        app.buttons["newSketch"].tap()
        let canvas = app.otherElements["sketchCanvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 8))
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.3)).press(forDuration: 0.1, thenDragTo: canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.65)))
        let name = app.textFields["sketchName"]
        name.tap(); name.typeText("Moon Garden\n")
        scrollTools(app)
        let undo = app.buttons["undoSketch"]
        XCTAssertTrue(undo.waitForExistence(timeout: 5)); XCTAssertTrue(undo.isEnabled)
        undo.tap()
        XCTAssertTrue(app.buttons["redoSketch"].isEnabled)
        XCTAssertFalse(app.buttons["exportSketch"].isEnabled)
        app.buttons["redoSketch"].tap()
        XCTAssertTrue(app.buttons["exportSketch"].isEnabled)
        app.buttons["finishSketch"].tap()
        XCTAssertTrue(app.buttons["sketch-Moon Garden"].waitForExistence(timeout: 5))
        app.terminate(); app.launch()
        app.buttons["openSketchbook"].tap()
        XCTAssertTrue(app.buttons["sketch-Moon Garden"].waitForExistence(timeout: 8))
        app.buttons["sketch-Moon Garden"].tap()
        XCTAssertTrue(canvas.waitForExistence(timeout: 8))
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "DEVICE VERIFIED — editable sketch restored after relaunch"
        attachment.lifetime = .keepAlways; add(attachment)
        scrollTools(app)
        let export = app.buttons["exportSketch"]
        XCTAssertTrue(export.isEnabled); export.tap()
        XCTAssertTrue(app.staticTexts["Picture saved privately to My Stuff. Your editable draft is kept in My Sketchbook."].waitForExistence(timeout: 8))
        app.alerts.buttons["OK"].tap()
        app.buttons["finishSketch"].tap()
        let library = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        library.name = "DEVICE VERIFIED — My Sketchbook saved draft"
        library.lifetime = .keepAlways; add(library)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["My Stuff"].tap()
        XCTAssertTrue(app.staticTexts["Picture"].waitForExistence(timeout: 8))
    }
}
