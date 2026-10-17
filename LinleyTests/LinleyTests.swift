import XCTest
import UIKit
@testable import Linley

final class LinleyTests: XCTestCase {
    func testBrandCopyIsReadyForPrototype() {
        XCTAssertEqual(LinleyCopy.appName, "Linley")
        XCTAssertEqual(LinleyCopy.version, "Prototype 0.4.1")
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
        for supply in QuestMap.supplies {
            let route = QuestMap.route(from: game.progress.position, to: supply.cell)
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
            for cell in QuestMap.route(from: game.progress.position, to: QuestMap.supplies[0].cell) { game.move(to: cell) }
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
