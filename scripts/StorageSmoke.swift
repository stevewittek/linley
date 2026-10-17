import Foundation

@main
struct StorageSmoke {
    @MainActor static func main() throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("LinleySmoke-\(UUID())")
        defer { try? fm.removeItem(at: root) }
        let source = fm.temporaryDirectory.appendingPathComponent("LinleyFixture-\(UUID()).mov")
        defer { try? fm.removeItem(at: source) }
        let bytes = Data("local media fixture".utf8)
        try bytes.write(to: source)
        let store = MediaStore(root: root)
        precondition(store.errorMessage == nil, store.errorMessage ?? "")
        let video = try store.save(source: source, kind: .video)
        let picture = try store.save(source: source, kind: .picture)
        let reload = MediaStore(root: root)
        precondition(reload.creations == [picture, video])
        let savedBytes = try Data(contentsOf: reload.url(for: video)); precondition(savedBytes == bytes)
        try reload.delete(picture)
        precondition(!fm.fileExists(atPath: reload.url(for: picture).path))
        precondition(MediaStore(root: root).creations == [video])
        print("PASS: save, copied bytes, reload and deletion")
        do { _ = try store.save(source: root.appendingPathComponent("missing.mov"), kind: .video); fatalError("missing source accepted") } catch { }
        precondition(MediaStore(root: root).creations == [video])
        print("PASS: failed copy does not change manifest")
        let backup = try root.resourceValues(forKeys: [.isExcludedFromBackupKey]); precondition(backup.isExcludedFromBackup == true)
        for name in ["../secret", "..", "/absolute", "nested/file", "nested\\file"] { precondition(!MediaStore.safeFilename(name)) }
        print("PASS: backup exclusion and path validation")
        try reload.setProfile(Data([1, 2])); precondition(MediaStore(root: root).profileData == Data([1, 2]))
        try reload.setProfile(Data([3])); precondition(MediaStore(root: root).profileData == Data([3]))
        try reload.setProfile(nil); precondition(MediaStore(root: root).profileData == nil)
        try reload.toggleLink("Loop Lab"); precondition(MediaStore(root: root).linkedCreators == ["Loop Lab"])
        try reload.toggleLink("Loop Lab"); precondition(MediaStore(root: root).linkedCreators.isEmpty)
        do { try reload.toggleLink("Stranger"); fatalError("unknown creator accepted") } catch { }
        print("PASS: profile replacement/removal and persisted sample links")
        precondition(FeaturePolicy.localCreation && !FeaturePolicy.cloudStorage && !FeaturePolicy.publicPosting && !FeaturePolicy.communication)
        precondition(DemoCatalog.search("BLUE", kind: .picture).map(\.id) == ["blue"])
        precondition(DemoCatalog.search("loop", kind: .video).map(\.id) == ["motion"])
        precondition(DemoCatalog.search("", kind: .picture, linked: []).isEmpty)
        precondition(DemoCatalog.search("", kind: .picture, linked: ["Paper Planet"]).count == 2)
        print("PASS: connected features denied, media search and linked-only filtering")
        let index = root.appendingPathComponent("index.json")
        let corrupt = Data("corrupt".utf8); try corrupt.write(to: index)
        let broken = MediaStore(root: root); precondition(broken.errorMessage != nil)
        do { try broken.toggleLink("Loop Lab"); fatalError("corrupt index overwritten") } catch { }
        let preserved = try Data(contentsOf: index); precondition(preserved == corrupt)
        print("PASS: corrupt index preserved and writes denied")
    }
}
