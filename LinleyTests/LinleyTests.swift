import SwiftUI
import XCTest
import UIKit
import AVFoundation
@testable import Linley

final class LinleyTests: XCTestCase {
    func testBrandCopyIsReadyForPrototype() {
        XCTAssertEqual(LinleyCopy.appName, "Linley")
        XCTAssertEqual(LinleyCopy.version, "Prototype 0.4.9")
        XCTAssertFalse(LinleyCopy.tagline.isEmpty)
    }

    func testSuggestionShareTextRequiresDadReview() {
        let suggestion = LinleySuggestion(
            title: "New idea",
            category: "Design change",
            details: "Make the button coral."
        )

        XCTAssertTrue(suggestion.shareText.contains("Dad to review"))
        XCTAssertTrue(suggestion.shareText.contains("does not change the app automatically"))
    }
}

@MainActor
final class PrivateLibraryTests: XCTestCase {
    private var root: URL!
    override func setUp() async throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    }
    override func tearDown() async throws { try? FileManager.default.removeItem(at: root) }

    func testPictureAndVideoPersistAcrossNewStoreAndDelete() throws {
        let store = MediaStore(root: root)
        let picture = Bundle.main.url(forResource: "DemoMotion", withExtension: "mp4")!
        // Real media fixture exercises durable copying rather than holding a temporary URL.
        let video = try store.save(source: picture, kind: .video)
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.url(for: video).path))
        let jpegURL = root.appendingPathComponent("input.jpg")
        let image = UIGraphicsImageRenderer(size: CGSize(width: 12, height: 12)).image { ctx in
            UIColor.orange.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: 12, height: 12))
        }
        try image.jpegData(compressionQuality: 0.8)!.write(to: jpegURL)
        let photo = try store.save(source: jpegURL, kind: .picture)
        try FileManager.default.removeItem(at: jpegURL)
        let reloaded = MediaStore(root: root)
        XCTAssertEqual(reloaded.creations, [photo, video])
        XCTAssertEqual(try Data(contentsOf: reloaded.url(for: video)), try Data(contentsOf: picture))
        try reloaded.delete(photo)
        XCTAssertFalse(FileManager.default.fileExists(atPath: reloaded.url(for: photo).path))
        XCTAssertEqual(MediaStore(root: root).creations, [video])
        try reloaded.delete(video)
        XCTAssertTrue(MediaStore(root: root).creations.isEmpty)
    }

    func testFailedSaveDoesNotCreateManifestEntry() throws {
        let store = MediaStore(root: root)
        XCTAssertThrowsError(try store.save(source: root.appendingPathComponent("missing.mov"), kind: .video))
        XCTAssertTrue(MediaStore(root: root).creations.isEmpty)
    }

    func testCorruptManifestFailsClosedAndIsNotOverwritten() throws {
        _ = MediaStore(root: root)
        let index = root.appendingPathComponent("index.json")
        let bad = Data("broken index".utf8)
        try bad.write(to: index)
        let store = MediaStore(root: root)
        XCTAssertNotNil(store.errorMessage)
        XCTAssertThrowsError(try store.toggleLink("Loop Lab"))
        XCTAssertEqual(try Data(contentsOf: index), bad)
    }

    func testPrivateDirectoryExcludedFromBackupAndPathValidation() throws {
        _ = MediaStore(root: root)
        XCTAssertEqual(try root.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
        for path in ["../photo.jpg", "/etc/passwd", "..", "nested/file", "nested\\file"] {
            XCTAssertFalse(MediaStore.safeFilename(path))
        }
        XCTAssertTrue(MediaStore.safeFilename("safe.jpg"))
    }

    func testProfileReplacementRemovalAndLinkedCreatorPersistence() throws {
        let store = MediaStore(root: root)
        try store.setProfile(Data([1, 2]))
        XCTAssertEqual(MediaStore(root: root).profileData, Data([1, 2]))
        try store.setProfile(Data([3]))
        XCTAssertEqual(MediaStore(root: root).profileData, Data([3]))
        try store.setProfile(nil)
        XCTAssertNil(MediaStore(root: root).profileData)
        try store.toggleLink("Loop Lab")
        XCTAssertEqual(MediaStore(root: root).linkedCreators, ["Loop Lab"])
        try store.toggleLink("Loop Lab")
        XCTAssertTrue(MediaStore(root: root).linkedCreators.isEmpty)
        XCTAssertThrowsError(try store.toggleLink("Unknown real person"))
    }

    func testNoConnectedPermissionsAndOnlyBundledSearchResults() {
        XCTAssertTrue(FeaturePolicy.localCreation)
        XCTAssertFalse(FeaturePolicy.cloudStorage)
        XCTAssertFalse(FeaturePolicy.publicPosting)
        XCTAssertFalse(FeaturePolicy.communication)
        XCTAssertEqual(DemoCatalog.search("blue", kind: .picture).map(\.id), ["blue"])
        XCTAssertEqual(DemoCatalog.search("LOOP", kind: .video).map(\.id), ["motion"])
        XCTAssertTrue(DemoCatalog.search("", kind: .picture, linked: []).isEmpty)
        XCTAssertEqual(DemoCatalog.search("", kind: .picture, linked: ["Paper Planet"]).count, 2)
    }
}

@MainActor
final class CreativeQuestTests: XCTestCase {
    private func withStore(_ body: (QuestStore, UserDefaults) throws -> Void) rethrows {
        let name = "LinleyQuestTests.\(UUID())"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        try body(QuestStore(defaults: defaults), defaults)
    }
    private func win(_ game: QuestStore) {
        for supply in QuestMap.supplies(for: game.progress.variant) {
            let route = QuestMap.route(from: game.progress.position, to: supply.cell, variant: game.progress.variant)
            for cell in route { game.move(to: cell) }
        }
    }
    func testEverySupplyReachableAndPathsAreAdjacent() {
        for supply in QuestMap.supplies {
            let path = QuestMap.route(from: QuestMap.start, to: supply.cell)
            XCTAssertEqual(path.last, supply.cell)
            var prior = QuestMap.start
            for step in path {
                XCTAssertTrue(QuestMap.canEnter(step))
                XCTAssertEqual(abs(prior.x - step.x) + abs(prior.y - step.y), 1)
                prior = step
            }
        }
        XCTAssertTrue(QuestMap.route(from: QuestMap.start, to: .init(x: 2, y: 1)).isEmpty)
    }
    func testWallsBoundsAndTeleportCannotMoveHero() {
        withStore { game, _ in
            game.move(to: .init(x: -1, y: 8))
            game.move(to: .init(x: 3, y: 7))
            game.move(to: .init(x: 1, y: 1))
            XCTAssertEqual(game.progress.position, QuestMap.start)
            game.nextAdventure()
            XCTAssertEqual(game.progress.round, 0)
        }
    }

    func testAllGardenLayoutsAndOptionalStarsAreReachable() {
        for variant in 0..<4 {
            let start = QuestMap.transform(QuestMap.start, variant: variant)
            let targets = QuestMap.supplies(for: variant).map(\.cell) + QuestMap.stars(for: variant)
            for target in targets {
                let path = QuestMap.route(from: start, to: target, variant: variant)
                XCTAssertEqual(path.last, target)
                XCTAssertTrue(path.allSatisfy { QuestMap.canEnter($0, variant: variant) })
            }
        }
        XCTAssertNotEqual(QuestMap.supplies(for: 0).map(\.cell), QuestMap.supplies(for: 1).map(\.cell))
    }

    func testOptionalStarsEarnBadgeWithoutExtraCoinsAndPersist() {
        withStore { game, defaults in
            for star in QuestMap.stars(for: 0) {
                for cell in QuestMap.route(from: game.progress.position, to: star) { game.move(to: cell) }
            }
            XCTAssertEqual(game.progress.gardenStars, [0, 1, 2])
            XCTAssertEqual(game.progress.explorerBadges, [0])
            XCTAssertEqual(game.progress.coins, 0)
            let loaded = QuestStore(defaults: defaults)
            XCTAssertEqual(loaded.progress.explorerBadges, [0])
            win(loaded)
            XCTAssertEqual(loaded.progress.coins, 100)
            loaded.nextAdventure()
            XCTAssertEqual(loaded.progress.variant, 1)
            XCTAssertTrue(loaded.progress.gardenStars.isEmpty)
            XCTAssertEqual(loaded.progress.explorerBadges, [0])
            loaded.restartAdventure()
            XCTAssertEqual(loaded.progress.explorerBadges, [0])
        }
    }

    func testLegacyGardenLayoutSurvivesUntilNextAdventure() throws {
        try withStore { _, defaults in
            var progress = QuestProgress()
            progress.round = 2; progress.position = QuestMap.start
            progress.collected = Set(QuestMap.supplies.map(\.id))
            var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(progress)) as? [String: Any])
            for field in ["mapVersion", "gardenStars", "explorerBadges"] { object.removeValue(forKey: field) }
            defaults.set(try JSONSerialization.data(withJSONObject: object), forKey: "linley.creativeQuest.v1")
            let old = QuestStore(defaults: defaults)
            XCTAssertFalse(old.loadError)
            XCTAssertEqual(old.progress.variant, 0)
            XCTAssertEqual(old.progress.position, QuestMap.start)
            old.nextAdventure()
            XCTAssertEqual(old.progress.variant, 3)
            XCTAssertEqual(old.progress.position, QuestMap.transform(QuestMap.start, variant: 3))
            var invalid = old.progress; invalid.mapVersion = 99
            XCTAssertFalse(QuestStore.valid(invalid))
            invalid = old.progress; invalid.gardenStars = [3]
            XCTAssertFalse(QuestStore.valid(invalid))
        }
    }
    func testWinAwardsOneStickerAndPersistsAcrossReload() {
        withStore { game, defaults in
            win(game)
            XCTAssertTrue(game.progress.complete)
            XCTAssertEqual(game.progress.stickers, [0])
            let reloaded = QuestStore(defaults: defaults)
            XCTAssertEqual(reloaded.progress.collected.count, 5)
            XCTAssertEqual(reloaded.progress.stickers, [0])
            XCTAssertEqual(reloaded.progress.coins, 100)
            let position = game.progress.position
            game.move(to: position.offset(0, 1))
            XCTAssertEqual(game.progress.position, position)
            XCTAssertEqual(game.progress.stickers.count, 1)
            XCTAssertEqual(game.progress.coins, 100)
            game.nextAdventure()
            XCTAssertEqual(game.progress.round, 1)
            XCTAssertTrue(game.progress.collected.isEmpty)
            XCTAssertEqual(game.progress.stickers, [0])
        }
    }
    func testAllEightStickersAndReplayRemainBounded() {
        withStore { game, _ in
            for _ in 0..<10 { win(game); game.nextAdventure() }
            XCTAssertEqual(game.progress.stickers, Set(0..<8))
            XCTAssertEqual(game.progress.round, 10)
            XCTAssertEqual(game.progress.coins, 1000)
        }
    }
    func testHeroAndPartialAdventurePersistAndRestartKeepsRewards() {
        withStore { game, defaults in
            win(game); game.nextAdventure()
            var hero = QuestHero(); hero.skin = 3; hero.hair = 2; hero.outfit = 1; hero.longHair = false
            game.setHero(hero)
            for cell in QuestMap.route(from: game.progress.position, to: QuestMap.supplies(for: game.progress.variant)[0].cell, variant: game.progress.variant) { game.move(to: cell) }
            let reloaded = QuestStore(defaults: defaults)
            XCTAssertEqual(reloaded.progress.hero, hero)
            XCTAssertEqual(reloaded.progress.position, game.progress.position)
            XCTAssertTrue(reloaded.progress.collected.contains("brush"))
            XCTAssertEqual(reloaded.progress.collected, game.progress.collected)
            reloaded.restartAdventure()
            XCTAssertTrue(reloaded.progress.collected.isEmpty)
            XCTAssertEqual(reloaded.progress.stickers, [0])
            XCTAssertEqual(reloaded.progress.hero, hero)
        }
    }
    func testCorruptProgressFailsClosedAndGameOnlyResetRecovers() {
        withStore { _, defaults in
            defaults.set("keep", forKey: "linley.profile.nickname")
            let bad = Data("bad progress".utf8)
            defaults.set(bad, forKey: "linley.creativeQuest.v1")
            let game = QuestStore(defaults: defaults)
            XCTAssertTrue(game.loadError)
            game.move(to: .init(x: 2, y: 8))
            XCTAssertEqual(defaults.data(forKey: "linley.creativeQuest.v1"), bad)
            game.resetUnreadableGame()
            XCTAssertFalse(game.loadError)
            XCTAssertEqual(defaults.string(forKey: "linley.profile.nickname"), "keep")
        }
        var invalid = QuestProgress(); invalid.hero.skin = 99
        XCTAssertFalse(QuestStore.valid(invalid))
        invalid = QuestProgress(); invalid.stickers = [99]
        XCTAssertFalse(QuestStore.valid(invalid))
    }

    func testEarnSpendDuplicateAndInsufficientFundsAcrossReload() {
        withStore { game, defaults in
            XCTAssertFalse(game.unlockPack("garden"))
            win(game)
            XCTAssertTrue(game.unlockPack("garden"))
            XCTAssertEqual(game.progress.coins, 0)
            XCTAssertFalse(game.unlockPack("garden"))
            XCTAssertFalse(game.unlockPack("dream"))
            XCTAssertFalse(game.unlockPack("unknown"))
            let reloaded = QuestStore(defaults: defaults)
            XCTAssertEqual(reloaded.progress.coins, 0)
            XCTAssertEqual(reloaded.progress.ownedPacks, ["garden"])
            XCTAssertTrue(reloaded.progress.complete)
            reloaded.restartAdventure()
            XCTAssertEqual(reloaded.progress.coinsEarned, 100)
            reloaded.nextAdventure(); win(reloaded)
            XCTAssertEqual(reloaded.progress.coins, 100)
            XCTAssertEqual(reloaded.progress.ownedPacks, ["garden"])
        }
    }

    func testOldCompletedProgressMigratesWithoutDuplicateReward() throws {
        try withStore { game, defaults in
            win(game)
            var old = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(game.progress)) as? [String: Any])
            old.removeValue(forKey: "coins"); old.removeValue(forKey: "coinsEarned"); old.removeValue(forKey: "ownedPacks")
            defaults.set(try JSONSerialization.data(withJSONObject: old), forKey: "linley.creativeQuest.v1")
            let migrated = QuestStore(defaults: defaults)
            XCTAssertFalse(migrated.loadError)
            XCTAssertEqual(migrated.progress.coins, 0)
            XCTAssertEqual(migrated.progress.stickers, [0])
            migrated.move(to: migrated.progress.position.offset(1, 0))
            XCTAssertEqual(migrated.progress.coins, 0)
            migrated.nextAdventure(); win(migrated)
            XCTAssertEqual(migrated.progress.coins, 100)
        }
    }

    func testMalformedEconomyFailsClosedAndOverflowCannotAward() throws {
        try withStore { _, defaults in
            var invalid = QuestProgress(); invalid.coins = -1
            XCTAssertFalse(QuestStore.valid(invalid))
            invalid = QuestProgress(); invalid.ownedPacks = ["garden"]
            XCTAssertFalse(QuestStore.valid(invalid))
            invalid = QuestProgress(); invalid.coinsEarned = 100; invalid.coins = 99
            defaults.set(try JSONEncoder().encode(invalid), forKey: "linley.creativeQuest.v1")
            let broken = QuestStore(defaults: defaults)
            XCTAssertTrue(broken.loadError)
            XCTAssertFalse(broken.unlockPack("garden"))
            var high = QuestProgress()
            high.coins = Int.max - Int.max % 100; high.coinsEarned = high.coins
            defaults.set(try JSONEncoder().encode(high), forKey: "linley.creativeQuest.v1")
            let full = QuestStore(defaults: defaults)
            win(full)
            XCTAssertFalse(full.progress.complete)
            XCTAssertEqual(full.progress.coins, high.coins)
        }
    }
}

@MainActor
final class QuestCharacterTests: XCTestCase {
    func testNewGamesStartWithLoreleiAndOldCustomHeroesMigrate() throws {
        XCTAssertEqual(QuestHero().character, .lorelei)
        let old = Data(#"{"skin":2,"hair":1,"outfit":3,"longHair":false}"#.utf8)
        let hero = try JSONDecoder().decode(QuestHero.self, from: old)
        XCTAssertEqual(hero.character, .custom)
        XCTAssertEqual(hero.skin, 2)
        XCTAssertFalse(hero.longHair)
        var hailey = QuestHero(); hailey.character = .hailey
        XCTAssertEqual(try JSONDecoder().decode(QuestHero.self, from: JSONEncoder().encode(hailey)), hailey)
    }
}

@MainActor
final class QuestAudioTests: XCTestCase {
    func testEveryBundledAudioFileDecodes() throws {
        for name in QuestAudio.resources {
            let url = try XCTUnwrap(QuestAudio.resourceURL(name))
            let player = try AVAudioPlayer(contentsOf: url)
            XCTAssertGreaterThan(player.duration, 0)
            XCTAssertGreaterThan(player.numberOfChannels, 0)
        }
    }

    func testAudioPreferencesPauseAndInterruptionResume() {
        let suite = "LinleyAudioTests.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let audio = QuestAudio(defaults: defaults)
        audio.musicEnabled = true
        audio.setVisible(true)
        XCTAssertTrue(audio.isPlaying)
        audio.setVisible(false)
        XCTAssertFalse(audio.isPlaying)
        audio.setVisible(true)
        audio.interrupt(Notification(name: AVAudioSession.interruptionNotification, userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue]))
        XCTAssertFalse(audio.isPlaying)
        audio.interrupt(Notification(name: AVAudioSession.interruptionNotification, userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue, AVAudioSessionInterruptionOptionKey: AVAudioSession.InterruptionOptions.shouldResume.rawValue]))
        XCTAssertTrue(audio.isPlaying)
        audio.musicEnabled = false; audio.effectsEnabled = false
        XCTAssertFalse(audio.isPlaying)
        let loaded = QuestAudio(defaults: defaults)
        XCTAssertFalse(loaded.musicEnabled); XCTAssertFalse(loaded.effectsEnabled)
        audio.setVisible(false)
    }
}


@MainActor
final class PuzzleChaseTests: XCTestCase {
    private let routes = [
        "RRRRDDDDDDLLLLRRRR",
        "DDRRDWDDDLLRRUULLUUUURRRRDD",
        "DRDDLRDDRRDUUUR",
        "DRDWDDLDDUUUUUURRRRDDD",
        "RRRRDUDULWLLLDDDDDDRRRR",
        "RRRRLRLRRDDLLRRRR",
        "RRRUDRLRRDDLLRRRRUU",
        "DRURRRRRLLLRDDD",
        "RRRDDUURDDDD",
        "DDURURRRLRDDDDLUURD",
        "RLRRRRDDDDDDLLLLRRRR", "RRRRDDDDDDLLLLRRUURR", "RLRRRUDRDULRRDDLLRRRRU",
        "DRDDDWLDDUUUUUURRRRDDD", "RLRRRRDWDDDLLLLDDUURRRR", "RRRRDDDDDDLLLLRRUURR",
        "RRRRLRLRRDDLLRRUURR", "DRDDDWLDDUUUUUURRRRDDD", "RRRDDUURDDDDLR", "DRDLRWDDRRUUUURLRDDD"
    ]
    private let epoch = Date(timeIntervalSince1970: 1_700_000_000)
    private func delta(_ char: Character) -> (Int, Int) {
        switch char { case "U": (0,-1); case "R": (1,0); case "D": (0,1); case "L": (-1,0); default: (0,0) }
    }
    private func withGame(_ body: (QuestStore, UserDefaults) throws -> Void) rethrows {
        let name = "LinleyChaseTests.\(UUID())"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        try body(QuestStore(defaults: defaults), defaults)
    }
    private func win(_ game: QuestStore, level: Int, practice: Bool = false) {
        XCTAssertTrue(game.startChase(level: level, practice: practice, at: epoch))
        for char in routes[level] {
            let (dx,dy) = delta(char); game.moveChase(dx: dx, dy: dy, at: epoch)
        }
        XCTAssertEqual(game.progress.chase.session?.status, .won)
    }
    func testAllTwentyAuthoredLevelsHaveWinningRoutesThroughRequiredPuzzles() {
        XCTAssertEqual(ChaseLevel.all.count, 20)
        for level in ChaseLevel.all.indices {
            var state = ChaseSession(level: level, practice: false)
            let board = ChaseLevel.all[level]
            XCTAssertEqual(board.rows.count, 9)
            XCTAssertTrue(board.rows.allSatisfy { $0.count == 7 })
            for char in routes[level] {
                XCTAssertEqual(state.status, .playing)
                let (dx,dy) = delta(char); state = ChaseEngine.step(state, dx: dx, dy: dy)
            }
            XCTAssertEqual(state.status, .won, "Level \(level + 1)")
            XCTAssertEqual(state.collected, board.required)
            if !board.positions("g").isEmpty { XCTAssertTrue(ChaseEngine.gatesOpen(state)) }
            XCTAssertLessThanOrEqual(state.turns, board.moveLimit)
        }
    }
    func testBlockedMovesEnemyTimingWaitAndCapture() {
        var state = ChaseSession(level: 0, practice: false)
        XCTAssertEqual(ChaseEngine.step(state, dx: -1, dy: 0), state)
        XCTAssertEqual(ChaseEngine.step(state, dx: Int.min, dy: 0), state)
        XCTAssertEqual(ChaseEngine.step(state, dx: 1, dy: 1), state)
        let enemies = state.enemies
        state = ChaseEngine.step(state, dx: 0, dy: 0)
        XCTAssertEqual(state.enemies, enemies)
        state = ChaseEngine.step(state, dx: 0, dy: 0)
        XCTAssertEqual(state.enemies, enemies)
        state = ChaseEngine.step(state, dx: 0, dy: 0)
        XCTAssertNotEqual(state.enemies, enemies)
        for _ in 0..<60 { state = ChaseEngine.step(state, dx: 0, dy: 0) }
        XCTAssertEqual(state.status, .lost)
        XCTAssertTrue(state.enemies.contains(state.player))
    }
    func testCratePressureGateSwitchAndPortalRules() {
        var crate = ChaseSession(level: 2, practice: false)
        crate = ChaseEngine.step(crate, dx: 0, dy: 1)
        crate = ChaseEngine.step(crate, dx: 1, dy: 0)
        XCTAssertTrue(crate.crates.contains(.init(x: 3, y: 2)))
        XCTAssertTrue(ChaseEngine.gatesOpen(crate))
        crate = ChaseEngine.step(crate, dx: 1, dy: 0)
        XCTAssertFalse(ChaseEngine.gatesOpen(crate))
        crate = ChaseEngine.step(crate, dx: 1, dy: 0)
        XCTAssertEqual(ChaseEngine.step(crate, dx: 1, dy: 0), crate)
        var flip = ChaseSession(level: 1, practice: false)
        flip = ChaseEngine.step(flip, dx: 1, dy: 0)
        flip = ChaseEngine.step(flip, dx: 1, dy: 0)
        XCTAssertTrue(flip.switchOn); XCTAssertTrue(ChaseEngine.gatesOpen(flip))
        var portal = ChaseSession(level: 5, practice: false)
        for _ in 0..<3 { portal = ChaseEngine.step(portal, dx: 1, dy: 0) }
        XCTAssertEqual(portal.player, QuestCell(x: 1, y: 5))
    }
    func testFiniteMovesCanLoseEvenWhenNotCaught() {
        var state = ChaseSession(level: 0, practice: true)
        state.turns = ChaseLevel.all[0].moveLimit - 1
        state.enemies = [QuestCell(x: 5, y: 7)]
        state = ChaseEngine.step(state, dx: 0, dy: 0)
        XCTAssertEqual(state.status, .lost)
        XCTAssertTrue(state.reason.contains("Out of moves"))
    }
    func testFirstClearProgressionChapterRewardsAndNoDoubleClaimsPersist() {
        withGame { game, defaults in
            XCTAssertFalse(game.startChase(level: 1, practice: false, at: epoch))
            win(game, level: 0)
            XCTAssertEqual(game.progress.coins, 100)
            game.moveChase(dx: 0, dy: 0, at: epoch)
            XCTAssertEqual(game.progress.coins, 100)
            win(game, level: 0)
            XCTAssertEqual(game.progress.coins, 200)
            for level in 1..<10 { win(game, level: level) }
            XCTAssertEqual(game.progress.coins, 1300)
            XCTAssertEqual(game.progress.chase.cleared, Set(0..<10))
            let saved = QuestStore(defaults: defaults)
            XCTAssertFalse(saved.loadError)
            XCTAssertEqual(saved.progress.coins, 1300)
            XCTAssertEqual(saved.progress.chase.lives, 5)
        }
    }
    func testLivesLossIsIdempotentAndRefillsEveryTwentyMinutesCappedAtFive() {
        withGame { game, defaults in
            for _ in 0..<5 {
                XCTAssertTrue(game.startChase(level: 0, practice: false, at: epoch))
                game.abandonChase(at: epoch)
                let lives = game.progress.chase.lives
                game.abandonChase(at: epoch); game.moveChase(dx: 1, dy: 0, at: epoch)
                XCTAssertEqual(game.progress.chase.lives, lives)
            }
            XCTAssertEqual(game.progress.chase.lives, 0)
            XCTAssertFalse(game.startChase(level: 0, practice: false, at: epoch))
            XCTAssertTrue(game.startChase(level: 0, practice: true, at: epoch))
            game.abandonChase(at: epoch)
            XCTAssertEqual(game.progress.chase.lives, 0)
            let loaded = QuestStore(defaults: defaults)
            loaded.refreshLives(at: epoch.addingTimeInterval(-100))
            loaded.refreshLives(at: epoch.addingTimeInterval(1199))
            XCTAssertEqual(loaded.progress.chase.lives, 0)
            loaded.refreshLives(at: epoch.addingTimeInterval(1200))
            XCTAssertEqual(loaded.progress.chase.lives, 1)
            XCTAssertEqual(loaded.progress.chase.nextLifeAt, epoch.addingTimeInterval(2400))
            loaded.refreshLives(at: epoch.addingTimeInterval(60_000_000))
            XCTAssertEqual(loaded.progress.chase.lives, 5)
            XCTAssertNil(loaded.progress.chase.nextLifeAt)
        }
    }
    func testEarnedCoinLifePurchaseAndRefillRaceCannotDoubleCharge() {
        withGame { game, defaults in
            win(game, level: 0)
            XCTAssertTrue(game.startChase(level: 1, practice: false, at: epoch))
            game.abandonChase(at: epoch)
            XCTAssertTrue(game.buyChaseLife(at: epoch))
            XCTAssertEqual(game.progress.coins, 0)
            XCTAssertEqual(game.progress.chase.spentOnLives, 100)
            XCTAssertEqual(game.progress.chase.lives, 5)
            XCTAssertFalse(game.buyChaseLife(at: epoch))
            XCTAssertEqual(QuestStore(defaults: defaults).progress.chase.spentOnLives, 100)
        }
        withGame { game, _ in
            win(game, level: 0)
            XCTAssertTrue(game.startChase(level: 1, practice: false, at: epoch))
            game.abandonChase(at: epoch)
            XCTAssertFalse(game.buyChaseLife(at: epoch.addingTimeInterval(1200)))
            XCTAssertEqual(game.progress.chase.lives, 5)
            XCTAssertEqual(game.progress.coins, 100)
        }
    }
    func testPracticeWinsDoNotAwardCoinsOrUnlockLevels() {
        withGame { game, _ in
            win(game, level: 9, practice: true)
            XCTAssertEqual(game.progress.coins, 0)
            XCTAssertTrue(game.progress.chase.cleared.isEmpty)
            XCTAssertEqual(game.progress.chase.lives, 5)
            win(game, level: 0)
            XCTAssertEqual(game.progress.coins, 100)
        }
    }
    func testPreCampaignSavesMigrateWithoutLosingStudioOrGameProgress() throws {
        try withGame { _, defaults in
            var old = QuestProgress(); old.coinsEarned = 100; old.coins = 0; old.ownedPacks = ["garden"]; old.stickers = [0]
            var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(old)) as? [String: Any])
            object.removeValue(forKey: "chase")
            defaults.set(try JSONSerialization.data(withJSONObject: object), forKey: "linley.creativeQuest.v1")
            let migrated = QuestStore(defaults: defaults)
            XCTAssertFalse(migrated.loadError)
            XCTAssertEqual(migrated.progress.ownedPacks, ["garden"])
            XCTAssertEqual(migrated.progress.stickers, [0])
            XCTAssertEqual(migrated.progress.chase.lives, 5)
            var bad = migrated.progress; bad.chase.lives = -1
            XCTAssertFalse(QuestStore.valid(bad))
            bad = migrated.progress; bad.chase.spentOnLives = 100
            XCTAssertFalse(QuestStore.valid(bad))
            bad = migrated.progress; bad.chase.cleared = [1]
            XCTAssertFalse(QuestStore.valid(bad))
        }
    }
}

final class MatchThreeTests: XCTestCase {
    @MainActor private func withStore(_ body: (QuestStore, UserDefaults) throws -> Void) rethrows {
        let name = "LinleyMatchTests.\(UUID())"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        try body(QuestStore(defaults: defaults), defaults)
    }

    func testGeneratedBoardsAreStablePlayableAndDeterministic() {
        for seed in 0..<200 {
            for level in MatchLevel.all.indices {
                let board = MatchSession(level: level, seed: UInt64(seed))
                XCTAssertTrue(board.valid)
                XCTAssertTrue(MatchEngine.matches(board.board).isEmpty)
                XCTAssertNotNil(MatchEngine.hint(board.board))
                XCTAssertEqual(board, MatchSession(level: level, seed: UInt64(seed)))
            }
        }
    }

    func testMatchingCrossCountsEachTileOnceAndIgnoresBlanks() {
        var board = (0..<36).map { ($0 / 6 + $0 % 6) % 5 }
        for i in [8,13,14,15,20] { board[i] = 4 }
        XCTAssertTrue(MatchEngine.matches(board).isSuperset(of: [8,13,14,15,20]))
        XCTAssertEqual(MatchEngine.matches(Array(repeating: -1, count: 36)), [])
        XCTAssertFalse(MatchEngine.adjacent(5,6)); XCTAssertFalse(MatchEngine.adjacent(-1,0))
        XCTAssertFalse(MatchEngine.adjacent(Int.max,0))
    }

    func testInvalidSwapsDoNotUseMovesAndCascadesSettle() throws {
        let state = MatchSession(level: 0, seed: 6)
        XCTAssertNil(MatchEngine.step(state, a: 5, b: 6))
        XCTAssertNil(MatchEngine.step(state, a: 0, b: 35))
        var sawCascade = false
        for seed in 0..<50 {
            let game = MatchSession(level: 0, seed: UInt64(seed))
            let move = try XCTUnwrap(MatchEngine.hint(game.board))
            let turn = try XCTUnwrap(MatchEngine.step(game, a: move[0], b: move[1]))
            XCTAssertTrue(turn.session.valid)
            XCTAssertEqual(turn.session.moves, game.moves - 1)
            XCTAssertGreaterThanOrEqual(turn.session.score, 30)
            XCTAssertTrue(turn.frames.contains(where: { $0.contains(-1) }))
            sawCascade = sawCascade || turn.cascades > 1
        }
        XCTAssertTrue(sawCascade)
        var invalidFound = false
        for a in 0..<35 where MatchEngine.adjacent(a,a+1) {
            if MatchEngine.step(state, a:a, b:a+1) == nil { invalidFound = true }
        }
        XCTAssertTrue(invalidFound)
    }

    @MainActor func testWinSharedShopPersistenceAndNoDuplicateReward() throws {
        try withStore { store, defaults in
            XCTAssertFalse(store.startMatch(level: 1))
            XCTAssertTrue(store.startMatch(level: 0, seed: 1))
            XCTAssertFalse(store.startMatch(level: 0))
            while let state = store.progress.match.session, state.status == .playing {
                let move = try XCTUnwrap(MatchEngine.hint(state.board))
                XCTAssertNotNil(store.swapMatch(move[0],move[1]))
            }
            XCTAssertEqual(store.progress.match.session?.status, .won)
            XCTAssertEqual(store.progress.coins, 100)
            let old = store.progress.match.session!
            XCTAssertNil(store.swapMatch(0,1))
            let reopened = QuestStore(defaults: defaults)
            XCTAssertEqual(reopened.progress.match.session, old)
            XCTAssertEqual(reopened.progress.coins, 100)
            XCTAssertTrue(reopened.unlockPack("garden"))
            XCTAssertEqual(reopened.progress.coins, 0)
            XCTAssertFalse(reopened.unlockPack("garden"))
            XCTAssertTrue(QuestStore.valid(reopened.progress))
            XCTAssertTrue(reopened.startMatch(level: 0, seed: 1))
            while let state = reopened.progress.match.session, state.status == .playing {
                let move = try XCTUnwrap(MatchEngine.hint(state.board)); reopened.swapMatch(move[0],move[1])
            }
            XCTAssertEqual(reopened.progress.coins, 100)
            XCTAssertEqual(reopened.progress.coinsEarned, 200)
            XCTAssertTrue(reopened.progress.ownedPacks.contains("garden"))
        }
    }

    @MainActor func testResumeRestartAndOldSaveMigrationPreserveWallet() throws {
        try withStore { store, defaults in
            XCTAssertTrue(store.startMatch(level: 0, seed: 13))
            let old = store.progress.match.session!
            let restored = QuestStore(defaults: defaults)
            XCTAssertEqual(restored.progress.match.session, old)
            restored.endMatch()
            XCTAssertTrue(restored.startMatch(level: 0, seed: 42))
            XCTAssertEqual(restored.progress.coins,0)
            XCTAssertEqual(restored.progress.chase.lives,5)
            var save = QuestProgress(); save.coins = 100; save.coinsEarned = 200; save.ownedPacks = ["garden"]
            let data = try JSONEncoder().encode(save)
            var object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
            object.removeValue(forKey: "match")
            defaults.set(try JSONSerialization.data(withJSONObject: object),forKey: "linley.creativeQuest.v1")
            let migrated = QuestStore(defaults: defaults)
            XCTAssertFalse(migrated.loadError); XCTAssertEqual(migrated.progress.coins,100)
            XCTAssertTrue(migrated.progress.ownedPacks.contains("garden"))
            XCTAssertNil(migrated.progress.match.session)
            XCTAssertTrue(migrated.startMatch(level: 0, seed: 42))
            XCTAssertEqual(QuestStore(defaults: defaults).progress.coins, 100)
        }
    }

    func testLastMoveWinPrecedesLossAndFinishedBoardCannotMove() throws {
        var game = MatchSession(level: 0, seed: 1)
        game.moves = 1; game.score = 110
        let move = try XCTUnwrap(MatchEngine.hint(game.board))
        let won = try XCTUnwrap(MatchEngine.step(game,a:move[0],b:move[1])).session
        XCTAssertEqual(won.status,.won); XCTAssertEqual(won.moves,0)
        XCTAssertNil(MatchEngine.step(won,a:move[0],b:move[1]))
        var hard = MatchSession(level: 9, seed: 1); hard.moves = 1
        let loss = try XCTUnwrap(MatchEngine.step(hard,a:move[0],b:move[1])).session
        XCTAssertEqual(loss.status,.lost)
        XCTAssertTrue(loss.valid)
    }

    @MainActor func testCampaignUnlocksChapterBonusAndValidatesCorruptSaves() throws {
        try withStore { store, _ in
            let seeds: [UInt64] = [1,1,1,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2]
            for level in MatchLevel.all.indices {
                XCTAssertTrue(store.startMatch(level: level, seed: seeds[level]))
                // Greedy highest-scoring legal swaps exercise the real engine at every goal.
                while let state = store.progress.match.session, state.status == .playing {
                    let best = try XCTUnwrap(MatchEngine.suggestedMove(state))
                    XCTAssertNotNil(store.swapMatch(best.0,best.1))
                }
                XCTAssertEqual(store.progress.match.session?.status,.won,"Level \(level+1)")
            }
            XCTAssertEqual(store.progress.coins,2400)
            XCTAssertEqual(store.progress.match.cleared.count,20)
            var bad = store.progress; bad.match.session?.board[0] = 99
            XCTAssertFalse(QuestStore.valid(bad))
            bad = store.progress; bad.match.cleared = [9]
            XCTAssertFalse(QuestStore.valid(bad))
        }
    }
}

@MainActor final class ExpandedChallengeTests: XCTestCase {
    func testFrostPulseForecastKeyDoorsAndToggleRelays() {
        XCTAssertFalse(ChaseEngine.hazardActive(turn: 0)); XCTAssertFalse(ChaseEngine.hazardActive(turn: 1))
        XCTAssertTrue(ChaseEngine.hazardActive(turn: 2)); XCTAssertTrue(ChaseEngine.hazardActive(turn: 3))
        XCTAssertFalse(ChaseEngine.hazardActive(turn: 4))
        var frost = ChaseSession(level: 10, practice: true)
        frost = ChaseEngine.step(frost, dx: 1, dy: 0)
        frost = ChaseEngine.step(frost, dx: 1, dy: 0)
        XCTAssertEqual(frost.status, .lost); XCTAssertTrue(frost.reason.contains("frost pulse"))
        var door = ChaseSession(level: 11, practice: true)
        door.player = QuestCell(x: 5, y: 3)
        XCTAssertEqual(ChaseEngine.step(door, dx: 0, dy: 1), door)
        door.collected.formUnion(ChaseLevel.all[11].positions("q"))
        XCTAssertTrue(ChaseEngine.doorsOpen(door))
        XCTAssertEqual(ChaseEngine.step(door, dx: 0, dy: 1).player, QuestCell(x: 5,y: 4))
        var relay = ChaseSession(level: 15, practice: true)
        relay = ChaseEngine.step(relay, dx: 1, dy: 0); relay = ChaseEngine.step(relay, dx: 1, dy: 0)
        XCTAssertTrue(ChaseEngine.gatesOpen(relay))
        relay = ChaseEngine.step(relay, dx: -1, dy: 0); relay = ChaseEngine.step(relay, dx: 1, dy: 0)
        XCTAssertFalse(ChaseEngine.gatesOpen(relay))
        var invalid = relay; invalid.level = Int.max
        XCTAssertEqual(ChaseEngine.step(invalid, dx: 1, dy: 0),invalid)
        invalid = relay; invalid.player = QuestCell(x: Int.max,y: Int.max)
        XCTAssertEqual(ChaseEngine.step(invalid, dx: 1, dy: 0),invalid)
    }

    func testFrostAndCollectionCannotBeSkippedByScoreAndPowersConsumeOneMove() throws {
        var session = MatchSession(level: 10, seed: 1)
        session.score = session.rules.target; session.moves = 1
        XCTAssertTrue(session.valid)
        let pair = try XCTUnwrap(MatchEngine.hint(session.board))
        let result = try XCTUnwrap(MatchEngine.step(session,a:pair[0],b:pair[1])).session
        XCTAssertEqual(result.status,.lost,"Score alone must not bypass frost and collection goals")
        var powered = MatchSession(level: 10, seed: 1)
        powered.powers[8] = 2
        let before = powered.frost.values.reduce(0,+)
        let fired = try XCTUnwrap(MatchEngine.activate(powered,at:8)).session
        XCTAssertEqual(fired.moves, powered.moves-1)
        XCTAssertLessThan(fired.frost.values.reduce(0,+), before)
        XCTAssertTrue(fired.valid)
        XCTAssertNil(MatchEngine.activate(powered,at:0))
        XCTAssertEqual(try JSONDecoder().decode(MatchSession.self,from:JSONEncoder().encode(fired)), fired)
    }

    func testFourAndFiveRunsEarnPowersAndChainsSettle() throws {
        var observed: Set<Int> = []
        for seed in 0..<80 {
            var s = MatchSession(level: 19,seed:UInt64(seed))
            // Normal generated, match-free board; no powers are injected here.
            for a in 0..<36 { for b in [a+1,a+6] where MatchEngine.adjacent(a,b) {
                if let turn = MatchEngine.step(s,a:a,b:b) { observed.formUnion(turn.session.powers.values) }
            } }
            let pair = try XCTUnwrap(MatchEngine.suggestedMove(s))
            s = try XCTUnwrap(MatchEngine.step(s,a:pair.0,b:pair.1)).session
            XCTAssertTrue(s.valid)
        }
        XCTAssertTrue(observed.contains(1)); XCTAssertTrue(observed.contains(2)); XCTAssertTrue(observed.contains(3))
    }

    func testOldScoreOnlyBoardMigratesWithoutNewGoalsOrDuplicateCoins() throws {
        let suite = "LinleyLegacyMatch.\(UUID())", key = "linley.creativeQuest.v1"
        let defaults = UserDefaults(suiteName:suite)!
        defer { defaults.removePersistentDomain(forName:suite) }
        var progress = QuestProgress()
        var board = MatchSession(level:9,seed:1)
        board.rulesVersion = 1; board.frost = [:]; board.powers = [:]; board.collected = 0
        board.moves = MatchLevel.legacy[9].moves; board.score = 2800; board.status = .won
        progress.match.cleared = Set(0..<10); progress.match.session = board
        progress.coins = 1200; progress.coinsEarned = 1200
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with:JSONEncoder().encode(progress)) as? [String:Any])
        var match = object["match"] as! [String:Any], old = match["session"] as! [String:Any]
        for field in ["rulesVersion","collected","frost","powers"] { old.removeValue(forKey:field) }
        match["session"] = old; object["match"] = match
        defaults.set(try JSONSerialization.data(withJSONObject:object),forKey:key)
        let loaded = QuestStore(defaults:defaults)
        XCTAssertFalse(loaded.loadError); XCTAssertEqual(loaded.progress.match.session?.rulesVersion,1)
        XCTAssertEqual(loaded.progress.coins,1200); XCTAssertEqual(loaded.progress.match.unlocked,10)
        XCTAssertNil(loaded.swapMatch(0,1)); XCTAssertEqual(loaded.progress.coins,1200)
        XCTAssertTrue(loaded.startMatch(level:10,seed:1)); XCTAssertEqual(loaded.progress.match.session?.rulesVersion,2)
    }

    func testDamagedBoardRecoveryPreservesWalletPurchasesAndHealthyOtherGame() throws {
        let suite = "LinleyBoardRecovery.\(UUID())", key = "linley.creativeQuest.v1"
        let defaults = UserDefaults(suiteName:suite)!
        defer { defaults.removePersistentDomain(forName:suite) }
        var saved = QuestProgress(); saved.coins = 100; saved.coinsEarned = 200; saved.ownedPacks = ["garden"]
        saved.chase.session = ChaseSession(level:0,practice:true)
        saved.match.session = MatchSession(level:0,seed:1); saved.match.session?.board[0] = 99
        let corrupt = try JSONEncoder().encode(saved); defaults.set(corrupt,forKey:key)
        let game = QuestStore(defaults:defaults)
        XCTAssertFalse(game.loadError); XCTAssertNotNil(game.recoveryNotice)
        XCTAssertNil(game.progress.match.session); XCTAssertEqual(game.progress.chase.session,saved.chase.session)
        XCTAssertEqual(game.progress.coins,100); XCTAssertEqual(game.progress.ownedPacks,["garden"])
        XCTAssertEqual(defaults.data(forKey:key + ".board-recovery-backup"),corrupt)
        XCTAssertTrue(game.startMatch(level:0,seed:1))
        XCTAssertFalse(QuestStore(defaults:defaults).loadError)
        saved.coins = 101
        defaults.set(try JSONEncoder().encode(saved),forKey:key)
        XCTAssertTrue(QuestStore(defaults:defaults).loadError,"Never repair untrusted wallet accounting by dropping a board")
    }
}

@MainActor final class StyleStudioTests: XCTestCase {
    private func wallet(_ body:(QuestStore,UserDefaults)throws->Void) rethrows {
        let name="LinleyStyleTests.\(UUID())"
        let defaults=UserDefaults(suiteName:name)!
        defer {defaults.removePersistentDomain(forName:name)}
        try body(QuestStore(defaults:defaults),defaults)
    }
    func testMissionCoinsBuyOutfitAndHairstyleExactlyOnce() throws {
        try wallet {game,defaults in
            XCTAssertTrue(game.ownsStyle("lavender"));XCTAssertTrue(game.ownsStyle("bob"))
            XCTAssertFalse(game.unlockStyle("mint"));XCTAssertEqual(game.progress.coins,0)
            for brief in StyleBrief.all.prefix(3) {
                var look=DressUpLook();look.backdrop=brief.backdrop;look.accessory=brief.accessory
                XCTAssertTrue(game.completeStyleBrief(brief.id,look:look));XCTAssertFalse(game.completeStyleBrief(brief.id,look:look))
            }
            XCTAssertEqual(game.progress.coins,300)
            XCTAssertTrue(game.unlockStyle("mint"));XCTAssertTrue(game.unlockStyle("buns"))
            XCTAssertEqual(game.progress.coins,0);XCTAssertFalse(game.unlockStyle("mint"))
            let loaded=QuestStore(defaults:defaults)
            XCTAssertTrue(loaded.ownsStyle("mint"));XCTAssertTrue(loaded.ownsStyle("buns"))
            XCTAssertEqual(loaded.progress.styleBriefs.count,3);XCTAssertTrue(QuestStore.valid(loaded.progress))
        }
    }
    func testBadLookUnownedItemsAndWrongBriefCannotEarn() {
        wallet {game,_ in
            var look=DressUpLook()
            XCTAssertFalse(game.completeStyleBrief(0,look:look))
            look.accessory=1;look.outfit="moonlight"
            XCTAssertFalse(game.completeStyleBrief(0,look:look))
            look.outfit="lavender";look.hair="unknown"
            XCTAssertFalse(game.completeStyleBrief(0,look:look))
            XCTAssertFalse(game.unlockStyle("../escape"));XCTAssertFalse(game.unlockStyle("lavender"))
            XCTAssertEqual(game.progress.coins,0)
        }
    }
    func testLegacyWalletGetsFreeStarterWithoutLosingArtPurchase() throws {
        try wallet {_,defaults in
            var old=QuestProgress();old.coins=100;old.coinsEarned=200;old.ownedPacks=["garden"]
            var json=try XCTUnwrap(JSONSerialization.jsonObject(with:JSONEncoder().encode(old)) as? [String:Any])
            json.removeValue(forKey:"wardrobe");json.removeValue(forKey:"styleBriefs")
            defaults.set(try JSONSerialization.data(withJSONObject:json),forKey:"linley.creativeQuest.v1")
            let game=QuestStore(defaults:defaults)
            XCTAssertFalse(game.loadError);XCTAssertEqual(game.progress.coins,100);XCTAssertTrue(game.progress.ownedPacks.contains("garden"))
            XCTAssertTrue(game.ownsStyle("bob"));XCTAssertTrue(game.unlockStyle("waves"))
            XCTAssertTrue(QuestStore.valid(game.progress))
        }
    }
    func testPrivateLookbookPhotoRemovalAndCorruptDataPreservation() throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {try? FileManager.default.removeItem(at:root)}
        let studio=DressUpStore(root:root)
        let image=UIGraphicsImageRenderer(size:CGSize(width:800,height:800)).image {c in
            UIColor.systemTeal.setFill();c.fill(CGRect(x:0,y:0,width:800,height:800))
        }
        var look=DressUpLook();look.face=try DressUpStore.normalizedFace(XCTUnwrap(image.jpegData(compressionQuality:0.9)))
        XCTAssertLessThanOrEqual(try XCTUnwrap(UIImage(data:look.face!)).size.width,512)
        try studio.update(look);let id=try studio.save(look,title:" Fan look ")
        let loaded=DressUpStore(root:root)
        XCTAssertEqual(loaded.draft,look);XCTAssertEqual(loaded.looks.first?.title,"Fan look")
        try loaded.removeEveryFace();XCTAssertNil(loaded.draft.face);XCTAssertNil(loaded.looks.first?.look.face)
        try loaded.delete(id);XCTAssertTrue(loaded.looks.isEmpty)
        let file=root.appendingPathComponent("studio.json"),bad=Data([0,1,2])
        try bad.write(to:file)
        XCTAssertFalse(DressUpStore(root:root).healthy);XCTAssertEqual(try Data(contentsOf:file),bad)
    }
    func testInvalidFaceAndSelectionCannotReplaceDraft() throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {try? FileManager.default.removeItem(at:root)}
        let studio=DressUpStore(root:root)
        var bad=DressUpLook();bad.face=Data([0,1,2])
        XCTAssertThrowsError(try studio.update(bad));XCTAssertEqual(studio.draft,DressUpLook())
        bad=DressUpLook();bad.backdrop=99
        XCTAssertThrowsError(try studio.update(bad));XCTAssertThrowsError(try DressUpStore.normalizedFace(Data([1,2])))
    }
    func testDressUpArtDecodesAndAvatarRenders() throws {
        for name in ["outfit-pop","outfit-mint","outfit-fantasy","outfit-dress","hair-waves","hair-bob","hair-buns","hair-braids","faces"] {
            let url=try XCTUnwrap(Bundle.main.url(forResource:name,withExtension:"png",subdirectory:"DressUp"))
            XCTAssertNotNil(UIImage(contentsOfFile:url.path))
        }
        let renderer=ImageRenderer(content:DressUpCanvas(look:DressUpLook(),title:"Test look").frame(width:360,height:540))
        XCTAssertNotNil(renderer.uiImage)
    }
}
