import XCTest

final class CreativeQuestUITests: XCTestCase {
    func testExpandedMatchObjectivesAndBackgroundResume() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication(); app.launchArguments = ["--quest-ui-tests", "--challenge-ui-tests"]
        app.launch()
        XCTAssertTrue(app.buttons["openGames"].waitForExistence(timeout: 10)); app.buttons["openGames"].tap()
        app.buttons["playMatch3"].tap()
        let level = app.buttons["matchLevel-10"]
        for _ in 0..<8 { if level.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(level.isHittable); level.tap()
        XCTAssertTrue(app.staticTexts["matchFrostGoal"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["matchFrostGoal"].label, "24 frost layers left")
        XCTAssertTrue(app.staticTexts["matchCollectionGoal"].exists)
        XCTAssertTrue(app.frame.contains(app.buttons["matchCell-0"].frame),"Starting a later level must reset the menu scroll offset")
        XCTAssertTrue(app.frame.contains(app.buttons["matchCell-35"].frame))
        let board = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        board.name = "DEVICE expanded Match-3 frost and collection goals"; board.lifetime = .keepAlways; add(board)
        for (a,b) in [(23,29),(16,17),(1,7),(12,13)] {
            let first = app.buttons["matchCell-\(a)"]
            let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"),object:first)
            XCTAssertEqual(XCTWaiter.wait(for:[ready],timeout:10),.completed)
            first.tap(); app.buttons["matchCell-\(b)"].tap()
        }
        XCTAssertEqual(app.staticTexts["matchFrostGoal"].label,"2 frost layers left")
        XCTAssertEqual(app.staticTexts["matchMoves"].label,"28 moves left")
        let score = app.staticTexts["matchScore"].label
        XCUIDevice.shared.press(.home); app.activate()
        XCTAssertTrue(app.staticTexts["matchScore"].waitForExistence(timeout:5))
        XCTAssertEqual(app.staticTexts["matchScore"].label,score)
        XCTAssertEqual(app.staticTexts["matchMoves"].label,"28 moves left")
        XCTAssertTrue(app.staticTexts["0 Linley Coins"].exists)
        let progress = XCTAttachment(screenshot:XCUIScreen.main.screenshot())
        progress.name = "DEVICE expanded Match-3 frost cleared and saved pause"; progress.lifetime = .keepAlways; add(progress)
    }

    func testExpandedChaseFrostFailureRetryAndPracticeClear() {
        let app = XCUIApplication(); openPuzzle(app)
        let practice = app.switches["chasePractice"]
        practice.coordinate(withNormalizedOffset:CGVector(dx:0.94,dy:0.5)).tap()
        let on = XCTNSPredicateExpectation(predicate:NSPredicate(format:"value == '1'"),object:practice)
        XCTAssertEqual(XCTWaiter.wait(for:[on],timeout:5),.completed)
        let level = app.buttons["chaseLevel-10"]
        for _ in 0..<8 { if level.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(level.isHittable); level.tap()
        XCTAssertTrue(app.staticTexts["chaseHazardForecast"].waitForExistence(timeout:5))
        XCTAssertEqual(app.staticTexts["chaseHazardForecast"].label,"Next turn: frost safe")
        let board = XCTAttachment(screenshot:XCUIScreen.main.screenshot())
        board.name = "DEVICE Frost Archive new chapter and pulse forecast"; board.lifetime = .keepAlways; add(board)
        app.buttons["chase-Right"].tap(); app.buttons["chase-Right"].tap()
        XCTAssertTrue(app.staticTexts["Try a new plan"].waitForExistence(timeout:5))
        XCTAssertTrue(app.staticTexts["5/5 lives"].exists)
        app.buttons["Try again"].tap()
        let controls: [Character:String] = ["R":"Right","L":"Left","U":"Up","D":"Down"]
        for step in "RLRRRRDDDDDDLLLLRRRR" { app.buttons["chase-"+controls[step]!].tap() }
        XCTAssertTrue(app.staticTexts["Practice complete!"].waitForExistence(timeout:5))
        XCTAssertTrue(app.staticTexts["5/5 lives"].exists); XCTAssertTrue(app.staticTexts["0 Linley Coins"].exists)
        let win = XCTAttachment(screenshot:XCUIScreen.main.screenshot())
        win.name = "DEVICE Frost Archive solved after a free practice retry"; win.lifetime = .keepAlways; add(win)
        app.buttons["Next level"].tap()
        XCTAssertTrue(app.staticTexts["0/1 keys"].waitForExistence(timeout:5))
        for _ in 0..<3 { app.buttons["chase-Right"].tap() }
        XCTAssertTrue(app.staticTexts["1/1 keys"].waitForExistence(timeout:5))
        let key = XCTAttachment(screenshot:XCUIScreen.main.screenshot())
        key.name = "DEVICE Archive key collected and door unlocked"; key.lifetime = .keepAlways; add(key)
    }

    func testMatchThreeWinSharedWalletAndShopPurchase() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["--quest-ui-tests"]
        app.launch()
        XCTAssertTrue(app.buttons["openGames"].waitForExistence(timeout: 10))
        app.buttons["openGames"].tap()
        XCTAssertTrue(app.buttons["playMatch3"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["playPuzzleChase"].exists)
        app.buttons["playMatch3"].tap()
        app.buttons["matchLevel-0"].tap()
        XCTAssertTrue(app.buttons["matchCell-0"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.frame.contains(app.buttons["matchCell-0"].frame))
        XCTAssertTrue(app.frame.contains(app.buttons["matchCell-35"].frame))
        let board = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        board.name = "Match-3 working board"; board.lifetime = .keepAlways; add(board)
        // Seed 1 fixture uses normal matching and rewards, no injected win or coins.
        for pair in [(0,1),(0,6),(2,8),(2,8)] {
            let first = app.buttons["matchCell-\(pair.0)"]
            let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: first)
            XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 10), .completed)
            first.tap(); app.buttons["matchCell-\(pair.1)"].tap()
        }
        XCTAssertTrue(app.staticTexts["Garden cleared!"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["100 Linley Coins"].exists)
        let win = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        win.name = "Match-3 win and shared 100 coins"; win.lifetime = .keepAlways; add(win)
        let shop = app.buttons["matchShop"]
        if !shop.isHittable { app.swipeUp() }
        shop.tap()
        XCTAssertTrue(app.buttons["unlock-garden"].waitForExistence(timeout: 5))
        app.buttons["unlock-garden"].tap()
        app.buttons["Use 100 coins for Garden Party"].tap()
        XCTAssertTrue(app.alerts["Creative Shop"].waitForExistence(timeout: 5))
        app.alerts["Creative Shop"].buttons["OK"].tap()
        XCTAssertTrue(app.staticTexts["0 Linley Coins"].exists)
        XCTAssertTrue(app.staticTexts["owned-garden"].exists)
        let bought = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        bought.name = "Shared reward spent on Garden Party"; bought.lifetime = .keepAlways; add(bought)
    }

    private func openPuzzle(_ app: XCUIApplication) {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app.launchArguments = ["--quest-ui-tests"]
        app.launch()
        XCTAssertTrue(app.buttons["openGames"].waitForExistence(timeout: 10))
        app.buttons["openGames"].tap()
        XCTAssertTrue(app.buttons["playPuzzleChase"].waitForExistence(timeout: 8))
        app.buttons["playPuzzleChase"].tap()
        XCTAssertTrue(app.buttons["chaseLevel-0"].waitForExistence(timeout: 8))
    }

    func testPuzzleChaseClearLossAndConfirmedCoinLife() {
        let app = XCUIApplication(); openPuzzle(app)
        app.buttons["chaseLevel-0"].tap()
        XCTAssertTrue(app.buttons["chase-Right"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.frame.contains(app.buttons["chaseCell-0-0"].frame))
        XCTAssertTrue(app.frame.contains(app.buttons["chaseCell-6-8"].frame))
        XCTAssertLessThan(app.buttons["chaseCell-0-8"].frame.maxY, app.buttons["chase-Down"].frame.minY)
        let controls: [Character: String] = ["U":"Up", "R":"Right", "D":"Down", "L":"Left", "W":"Wait"]
        for char in "RRRRDDDDDDLLLLRRRR" { app.buttons["chase-" + controls[char]!].tap() }
        XCTAssertTrue(app.staticTexts["Level cleared!"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["100 Linley Coins"].exists)
        let win = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        win.name = "DEVICE VERIFIED — Puzzle Chase first clear and 100 coins"
        win.lifetime = .keepAlways; add(win)
        app.buttons["Next level"].tap()
        XCTAssertTrue(app.buttons["chase-Wait"].waitForExistence(timeout: 5))
        for _ in 0..<18 {
            if app.staticTexts["Try a new plan"].exists { break }
            app.buttons["chase-Wait"].tap()
        }
        XCTAssertTrue(app.staticTexts["Try a new plan"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["4/5 lives"].exists)
        let lost = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        lost.name = "DEVICE VERIFIED — creature capture costs one life with free refill timer"
        lost.lifetime = .keepAlways; add(lost)
        app.buttons["buyChaseLife"].tap()
        if app.buttons["Cancel"].exists { app.buttons["Cancel"].tap() }
        else { app.coordinate(withNormalizedOffset: CGVector(dx: 0.03, dy: 0.2)).tap() }
        XCTAssertTrue(app.staticTexts["100 Linley Coins"].exists)
        app.buttons["buyChaseLife"].tap()
        app.buttons["Use 100 coins for 1 life"].tap()
        XCTAssertTrue(app.staticTexts["5/5 lives"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["0 Linley Coins"].exists)
    }

    func testPuzzleChaseCrateGateAndFreePracticeLoss() {
        let app = XCUIApplication(); openPuzzle(app)
        let practice = app.switches["chasePractice"]
        practice.coordinate(withNormalizedOffset: CGVector(dx: 0.94, dy: 0.5)).tap()
        let on = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == '1'"), object: practice)
        XCTAssertEqual(XCTWaiter.wait(for: [on], timeout: 5), .completed)
        app.buttons["chaseLevel-2"].tap()
        XCTAssertTrue(app.buttons["chase-Down"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.frame.contains(app.buttons["chaseCell-0-0"].frame))
        XCTAssertTrue(app.frame.contains(app.buttons["chaseCell-6-8"].frame))
        app.buttons["chase-Down"].tap(); app.buttons["chase-Right"].tap()
        XCTAssertTrue(app.staticTexts["Gate open — collect every drop and reach the flag"].waitForExistence(timeout: 5))
        let crate = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        crate.name = "DEVICE VERIFIED — crate opens pressure gate in Practice"
        crate.lifetime = .keepAlways; add(crate)
        for _ in 0..<22 {
            if app.staticTexts["Try a new plan"].exists { break }
            app.buttons["chase-Wait"].tap()
        }
        XCTAssertTrue(app.staticTexts["Try a new plan"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["5/5 lives"].exists)
        XCTAssertTrue(app.staticTexts["0 Linley Coins"].exists)
    }

    func testSoundSettingsHintsAndOptionalExplorerBadge() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["--quest-ui-tests"]
        app.launch()
        XCTAssertTrue(app.buttons["openGames"].waitForExistence(timeout: 10))
        app.buttons["openGames"].tap()
        XCTAssertTrue(app.buttons["playCreativeQuest"].waitForExistence(timeout: 8))
        app.buttons["playCreativeQuest"].tap()
        app.buttons["questAudioSettings"].tap()
        let music = app.switches["questMusicToggle"]
        let effects = app.switches["questEffectsToggle"]
        XCTAssertTrue(music.waitForExistence(timeout: 5))
        func setSwitch(_ control: XCUIElement, to value: String) {
            if control.value as? String != value {
                control.coordinate(withNormalizedOffset: CGVector(dx: 0.94, dy: 0.5)).tap()
            }
            let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", value), object: control)
            XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 5), .completed)
        }
        setSwitch(music, to: "0"); setSwitch(music, to: "1")
        setSwitch(effects, to: "0"); setSwitch(effects, to: "1")
        app.buttons["Try a collection sound"].tap()
        let sound = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        sound.name = "DEVICE VERIFIED — game sound controls and CC0 credits"
        sound.lifetime = .keepAlways; add(sound)
        app.buttons["Done"].tap()
        app.buttons["Hint"].tap()
        XCTAssertTrue(app.staticTexts["Follow the golden path to the paintbrush."].waitForExistence(timeout: 5))
        for (index, x, y) in [(1, 0, 0), (2, 6, 4), (3, 0, 8)] {
            app.buttons["questCell-\(x)-\(y)"].tap()
            XCTAssertTrue(app.staticTexts["Stars \(index)/3"].waitForExistence(timeout: 12))
        }
        XCTAssertTrue(app.staticTexts["Badges 1/4"].exists)
        XCTAssertTrue(app.staticTexts["0 Linley Coins"].exists)
        let badge = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        badge.name = "DEVICE VERIFIED — optional garden stars and explorer badge"
        badge.lifetime = .keepAlways; add(badge)
    }

    func testEarnCoinsUnlockArtPackAndSavePicture() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["--quest-ui-tests"]
        app.launch()
        XCTAssertTrue(app.buttons["openGames"].waitForExistence(timeout: 10))
        app.buttons["openGames"].tap()
        XCTAssertTrue(app.buttons["playCreativeQuest"].waitForExistence(timeout: 8))
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
        for _ in 0..<3 {
            if leaf.exists && leaf.isHittable { break }
            app.swipeUp()
        }
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


final class StyleEditorUITests: XCTestCase {
    func testPhoneEditorCategoriesPreviewAndPlacementPersistence() {
        continueAfterFailure=false
        XCUIDevice.shared.orientation = .portrait
        let app=XCUIApplication()
        app.launchArguments=["--quest-ui-tests","--style-review-board"]
        app.launch()
        let faceTab=app.buttons["styleTab-2"]
        XCTAssertTrue(faceTab.waitForExistence(timeout:30))
        for i in 0..<8 {XCTAssertTrue(app.buttons["styleTab-\(i)"].isHittable,"Every editing category must be visible without scrolling")}
        faceTab.tap()
        app.buttons["styleSkin-3"].tap()
        app.segmentedControls["styleFaceShape"].buttons["Round"].tap()
        let preview=app.descendants(matching:.any)["stylePreview"].firstMatch
        XCTAssertTrue(preview.label.contains("skin tone 4"))
        XCTAssertTrue(preview.label.contains("face style 2"))
        let face=XCTAttachment(screenshot:XCUIScreen.main.screenshot());face.name="SIMULATOR phone face controls and connected avatar";face.lifetime = .keepAlways;add(face)
        app.buttons["styleTab-1"].tap()
        let buns=app.buttons["styleItem-buns"]
        for _ in 0..<4 {if buns.isHittable {break};app.swipeUp()}
        XCTAssertTrue(buns.isHittable);buns.tap()
        XCTAssertTrue(preview.label.contains("buns"))
        app.buttons["styleTab-3"].tap()
        app.segmentedControls["stylePalette-Lip color"].buttons["Rose"].tap()
        app.segmentedControls["stylePalette-Eye shadow"].buttons["Berry"].tap()
        XCTAssertTrue(preview.label.contains("lip color 2"));XCTAssertTrue(preview.label.contains("eye shadow 3"))
        let makeup=XCTAttachment(screenshot:XCUIScreen.main.screenshot());makeup.name="SIMULATOR phone makeup editor";makeup.lifetime = .keepAlways;add(makeup)
        app.buttons["styleMoveMode"].tap()
        let size=app.sliders["styleAdjust-Size"]
        XCTAssertTrue(size.waitForExistence(timeout:5));size.adjust(toNormalizedSliderPosition:0.7)
        app.buttons["styleMoveMode"].tap()
        app.terminate();app.launch()
        XCTAssertTrue(app.buttons["styleTab-2"].waitForExistence(timeout:20))
        XCTAssertTrue(preview.label.contains("buns"));XCTAssertTrue(preview.label.contains("skin tone 4"));XCTAssertTrue(preview.label.contains("lip color 2"))
        app.buttons["styleTab-7"].tap()
        let save=app.buttons["saveStyleLook"]
        for _ in 0..<3 {if save.exists {break};app.swipeUp()}
        XCTAssertFalse(save.isEnabled,"Trying on unpaid hair must not bypass wardrobe ownership")
    }
}
