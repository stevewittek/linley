import XCTest
import UIKit
@testable import Linley

final class LinleyTests: XCTestCase {
    func testBrandCopyIsReadyForPrototype() {
        XCTAssertEqual(LinleyCopy.appName, "Linley")
        XCTAssertEqual(LinleyCopy.version, "Prototype 0.4")
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
