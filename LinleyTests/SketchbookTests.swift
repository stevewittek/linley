import XCTest
import PencilKit
@testable import Linley

@MainActor final class SketchbookTests: XCTestCase {
    private var root: URL!
    override func setUp() async throws { root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString) }
    override func tearDown() async throws { try? FileManager.default.removeItem(at: root) }
    private func drawing() -> Data {
        let points = [CGPoint(x: 30, y: 40), CGPoint(x: 250, y: 300)].enumerated().map { index, point in
            PKStrokePoint(location: point, timeOffset: Double(index) * 0.1, size: CGSize(width: 5, height: 5), opacity: 1, force: 1, azimuth: 0, altitude: .pi / 2)
        }
        let path = PKStrokePath(controlPoints: points, creationDate: Date())
        return PKDrawing(strokes: [PKStroke(ink: PKInk(.pen, color: .blue), path: path)]).dataRepresentation()
    }
    private var preview: Data { UIGraphicsImageRenderer(size: CGSize(width: 20, height: 20)).image { $0.fill(CGRect(x: 0, y: 0, width: 20, height: 20)) }.jpegData(compressionQuality: 0.5)! }

    func testEditableDraftSurvivesRelaunchAndUpdateWithoutDuplicates() throws {
        let store = SketchStore(root: root), id = UUID()
        let first = try store.save(id: id, title: " Moon Garden ", paper: 2, drawing: drawing(), preview: preview)
        let reopened = SketchStore(root: root)
        XCTAssertEqual(reopened.projects.count, 1)
        let document = try reopened.load(id)
        XCTAssertEqual(document.summary.title, "Moon Garden")
        XCTAssertEqual(document.summary.paper, 2)
        XCTAssertEqual(try PKDrawing(data: document.drawing).strokes.count, 1)
        XCTAssertFalse(document.preview.isEmpty)
        let updated = try reopened.save(id: id, title: "New name", paper: 0, drawing: document.drawing, preview: document.preview)
        XCTAssertEqual(updated.createdAt, first.createdAt)
        XCTAssertEqual(reopened.projects.count, 1)
        XCTAssertEqual(SketchStore(root: root).projects.first?.title, "New name")
    }
    func testInvalidReplacementKeepsGoodDrawingAndMetadata() throws {
        let store = SketchStore(root: root), id = UUID()
        try store.save(id: id, title: "Keep me", paper: 1, drawing: drawing(), preview: preview)
        let before = try Data(contentsOf: store.fileURL(id))
        XCTAssertThrowsError(try store.save(id: id, title: "Bad", paper: 4, drawing: drawing(), preview: preview))
        XCTAssertThrowsError(try store.save(id: id, title: "Bad", paper: 0, drawing: Data([0, 1]), preview: preview))
        XCTAssertEqual(try Data(contentsOf: store.fileURL(id)), before)
        XCTAssertEqual(store.projects.first?.title, "Keep me")
    }
    func testCorruptDraftPreservedWhileOtherDrawingsRemainUsable() throws {
        let store = SketchStore(root: root), good = UUID(), bad = UUID()
        try store.save(id: good, title: "Good", paper: 0, drawing: drawing(), preview: preview)
        let bytes = Data("corrupt document".utf8)
        try bytes.write(to: store.fileURL(bad))
        let reopened = SketchStore(root: root)
        XCTAssertNotNil(reopened.errorMessage)
        XCTAssertEqual(reopened.projects.map(\.id), [good])
        XCTAssertThrowsError(try reopened.save(id: bad, title: "Overwrite", paper: 0, drawing: drawing(), preview: preview))
        XCTAssertEqual(try Data(contentsOf: store.fileURL(bad)), bytes)
        XCTAssertEqual(try reopened.load(good).summary.title, "Good")
    }
    func testDeleteDraftPreservesExportedPicture() throws {
        let store = SketchStore(root: root), id = UUID()
        try store.save(id: id, title: "Draft", paper: 0, drawing: drawing(), preview: preview)
        let mediaRoot = root.appendingPathComponent("Gallery")
        let media = MediaStore(root: mediaRoot)
        let source = root.appendingPathComponent("export.jpg"); try preview.write(to: source)
        _ = try media.save(source: source, kind: .picture)
        try store.delete(id)
        XCTAssertTrue(SketchStore(root: root).projects.isEmpty)
        XCTAssertEqual(MediaStore(root: mediaRoot).creations.count, 1)
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.fileURL(id).path))
    }
    func testPrivateStorageAndTitleBounds() throws {
        let store = SketchStore(root: root), id = UUID()
        let summary = try store.save(id: id, title: String(repeating: "a", count: 90), paper: 0, drawing: drawing(), preview: preview)
        XCTAssertEqual(summary.title.count, 48)
        XCTAssertEqual(try root.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
        let protection = try FileManager.default.attributesOfItem(atPath: store.fileURL(id).path)[.protectionKey] as? FileProtectionType
        XCTAssertEqual(protection, .complete)
        let empty = try store.save(id: id, title: "  ", paper: 0, drawing: drawing(), preview: preview)
        XCTAssertEqual(empty.title, "Untitled sketch")
    }
}
