import XCTest

final class CreativeQuestUITests: XCTestCase {
    func testEarnCoinsUnlockArtPackAndSavePicture() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["--quest-ui-tests"]
        app.launch()
        XCTAssertTrue(app.buttons["openGames"].waitForExistence(timeout: 10))
        app.buttons["openGames"].tap()
        app.buttons["playCreativeQuest"].tap()
        for (name, x, y) in [("Paintbrush", 1, 1), ("Palette", 5, 1), ("Pencil", 3, 3), ("Scissors", 1, 6), ("Paper star", 5, 7)] {
            let supply = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", name + ", row")).firstMatch
            if supply.exists {
                app.buttons["questCell-\(x)-\(y)"].tap()
                let collected = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: supply)
                XCTAssertEqual(XCTWaiter.wait(for: [collected], timeout: 12), .completed)
            }
        }
        XCTAssertTrue(app.buttons["Next adventure"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["100 Linley Coins"].exists)
        let earned = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        earned.name = "DEVICE VERIFIED — 100 coins earned"
        earned.lifetime = .keepAlways; add(earned)
        app.buttons["Use coins in the Creative Shop"].tap()
        XCTAssertTrue(app.buttons["unlock-garden"].waitForExistence(timeout: 5))
        app.buttons["unlock-garden"].tap()
        app.buttons["Use 100 coins for Garden Party"].tap()
        XCTAssertTrue(app.alerts["Creative Shop"].waitForExistence(timeout: 5))
        app.alerts["Creative Shop"].buttons["OK"].tap()
        XCTAssertTrue(app.staticTexts["0 Linley Coins"].exists)
        XCTAssertTrue(app.staticTexts["owned-garden"].exists)
        let shop = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shop.name = "DEVICE VERIFIED — earned coins spent on Garden Party"
        shop.lifetime = .keepAlways; add(shop)
        app.buttons["Open image maker"].tap()
        let leaf = app.buttons["stamp-leaf.fill"]
        XCTAssertTrue(leaf.waitForExistence(timeout: 5))
        if !leaf.isHittable { app.swipeUp() }
        leaf.tap()
        let paper = app.buttons["artPaper"]
        XCTAssertTrue(paper.waitForExistence(timeout: 5))
        paper.tap()
        let save = app.buttons["saveStudioPicture"]
        if !save.isHittable { app.swipeUp() }
        XCTAssertTrue(save.isEnabled)
        save.tap()
        XCTAssertTrue(app.alerts["Image Maker"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.alerts.staticTexts["Saved privately to My Stuff. Your coins and supplies stay yours."].exists)
        app.alerts["Image Maker"].buttons["OK"].tap()
        let art = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        art.name = "DEVICE VERIFIED — unlocked garden stamp image maker"
        art.lifetime = .keepAlways; add(art)
    }

    func testFreeImageMakerSavesToPrivateGallery() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["--quest-ui-tests"]
        app.launch()
        XCTAssertTrue(app.buttons["Image Maker"].waitForExistence(timeout: 10))
        app.buttons["Image Maker"].tap()
        let paper = app.buttons["artPaper"]
        XCTAssertTrue(paper.waitForExistence(timeout: 5))
        paper.tap()
        let save = app.buttons["saveStudioPicture"]
        if !save.isHittable { app.swipeUp() }
        save.tap()
        XCTAssertTrue(app.alerts["Image Maker"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.alerts.staticTexts["Saved privately to My Stuff. Your coins and supplies stay yours."].exists)
        app.alerts["Image Maker"].buttons["OK"].tap()
        let gallery = app.buttons["See My Stuff"]
        if !gallery.isHittable { app.swipeUp() }
        gallery.tap()
        XCTAssertTrue(app.staticTexts["Picture"].waitForExistence(timeout: 5))
        let saved = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        saved.name = "DEVICE VERIFIED — free art saved in private gallery"
        saved.lifetime = .keepAlways; add(saved)
    }

    func testPlayExploreCustomizeAndStickerBoard() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["--quest-ui-tests"]
        app.launch()
        XCTAssertTrue(app.buttons["openGames"].waitForExistence(timeout: 10))
        app.buttons["openGames"].tap()
        XCTAssertTrue(app.buttons["playCreativeQuest"].waitForExistence(timeout: 5))
        app.buttons["playCreativeQuest"].tap()
        XCTAssertTrue(app.buttons["My Hero"].waitForExistence(timeout: 5))
        let initial = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        initial.name = "Creative Quest — device verified initial screen"
        initial.lifetime = .keepAlways; add(initial)
        for (name, x, y) in [("Paintbrush", 1, 1), ("Palette", 5, 1), ("Pencil", 3, 3), ("Scissors", 1, 6), ("Paper star", 5, 7)] {
            let supply = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", name + ", row")).firstMatch
            if supply.exists {
                app.buttons["questCell-\(x)-\(y)"].tap()
                let collected = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: supply)
                XCTAssertEqual(XCTWaiter.wait(for: [collected], timeout: 12), .completed)
            }
        }
        XCTAssertTrue(app.buttons["Next adventure"].waitForExistence(timeout: 8))
        let won = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        won.name = "Creative Quest — device verified completed adventure"
        won.lifetime = .keepAlways; add(won)
        app.buttons["Sticker Board"].tap()
        XCTAssertTrue(app.staticTexts["1 of 8 stickers collected"].waitForExistence(timeout: 5))
        let stickers = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        stickers.name = "Creative Quest — device verified sticker board"
        stickers.lifetime = .keepAlways; add(stickers)
        app.buttons["Done"].tap()
        app.buttons["My Hero"].tap()
        XCTAssertTrue(app.buttons["questCharacterPicker"].waitForExistence(timeout: 5))
        app.buttons["questCharacterPicker"].tap()
        app.buttons["Hailey"].tap()
        let hailey = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        hailey.name = "Creative Quest — Hailey character on device"
        hailey.lifetime = .keepAlways; add(hailey)
        app.buttons["questCharacterPicker"].tap()
        app.buttons["Lorelei"].tap()
        for _ in 0..<3 {
            if app.switches["Long hair"].exists && app.switches["Long hair"].isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(app.switches["Long hair"].waitForExistence(timeout: 5))
        app.switches["Long hair"].tap()
        app.buttons["Done"].tap()
        app.buttons["Next adventure"].tap()
        XCTAssertTrue(app.staticTexts["Adventure 2"].waitForExistence(timeout: 5))
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.buttons["My Hero"].waitForExistence(timeout: 5))
        let visibleControls = expectation(for: NSPredicate(format: "hittable == YES"), evaluatedWith: app.buttons["Move right"])
        wait(for: [visibleControls], timeout: 8)
        let landscape = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        landscape.name = "Creative Quest — landscape device layout"
        landscape.lifetime = .keepAlways; add(landscape)
        XCUIDevice.shared.orientation = .portrait
    }
}
