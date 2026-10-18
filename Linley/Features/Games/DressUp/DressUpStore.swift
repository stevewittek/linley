import Foundation
import SwiftUI
import UniformTypeIdentifiers
import ImageIO

struct SavedStyle: Identifiable, Codable {
    let id: UUID
    let date: Date
    let title: String
    let look: DressUpLook
}

/// A protected, backup-excluded private studio. Contains only explicit cropped face copies.
@MainActor final class DressUpStore: ObservableObject {
    @Published private(set) var draft = DressUpLook()
    @Published private(set) var looks: [SavedStyle] = []
    @Published private(set) var selectedAvatarID: UUID?
    var selectedAvatar: SavedStyle? { looks.first { $0.id == selectedAvatarID } }
    @Published var message: String?
    @Published private(set) var healthy = false
    @Published private(set) var isLoading = false
    private var pendingLoad = false
    private let root: URL
    private let fm = FileManager.default
    nonisolated static let maximumLooks = 24
    struct Document: Codable { var draft: DressUpLook; var looks: [SavedStyle]; var selectedAvatarID: UUID? = nil }

    init(root: URL? = nil, deferredLoad: Bool = false) {
        self.root = root ?? Self.defaultRoot()
        pendingLoad = deferredLoad
        isLoading = deferredLoad
        guard !deferredLoad else { return }
        do { apply(try Self.readDocument(root:self.root)) }
        catch { message = "Your style studio couldn't open. Existing photos and looks have been kept." }
    }
    /// The app can show its first screen before decoding a full private library.
    /// A second caller cannot start another load or overwrite edits with an older snapshot.
    func loadIfNeeded() async {
        guard pendingLoad else { return }
        pendingLoad = false
        let directory = root
        do {
            let document = try await Task.detached(priority:.utility) {
                try Self.readDocument(root:directory)
            }.value
            apply(document)
        } catch { message = "Your style studio couldn't open. Existing photos and looks have been kept." }
        isLoading = false
    }
    private func apply(_ document: Document) {
        draft=document.draft; looks=document.looks; selectedAvatarID=document.selectedAvatarID
        message=nil; healthy=true
    }
    nonisolated private static func prepareRoot(_ root: URL) throws {
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true,attributes:[.protectionKey:FileProtectionType.complete])
        var folder=root; var flags=URLResourceValues(); flags.isExcludedFromBackup=true
        try folder.setResourceValues(flags)
    }
    nonisolated private static func readDocument(root: URL) throws -> Document {
        try prepareRoot(root)
        // This directory belongs solely to the crop flow; never sweep the general temp directory.
        purgeCropFiles()
        let file=root.appendingPathComponent("studio.json")
        guard FileManager.default.fileExists(atPath:file.path) else {return Document(draft:DressUpLook(),looks:[])}
        guard (try file.resourceValues(forKeys:[.fileSizeKey]).fileSize ?? Int.max) <= 35_000_000 else {throw CocoaError(.fileReadCorruptFile)}
        let saved=try JSONDecoder().decode(Document.self,from:Data(contentsOf:file))
        guard valid(saved) else {throw CocoaError(.fileReadCorruptFile)}
        return saved
    }
    /// Call only after the user explicitly confirms deleting this unreadable private library.
    /// A failed removal leaves the unreadable file and all in-memory state untouched.
    func resetUnreadable() throws {
        guard !healthy && !isLoading else {throw CocoaError(.fileWriteNoPermission)}
        try Self.prepareRoot(root)
        let file=root.appendingPathComponent("studio.json")
        if fm.fileExists(atPath:file.path) {try fm.removeItem(at:file)}
        apply(Document(draft:DressUpLook(),looks:[]))
    }
    private static func defaultRoot() -> URL {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--quest-ui-tests") {
            return fmTemporary.appendingPathComponent("linley-style-ui-tests",isDirectory:true)
        }
        #endif
        return FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("PrivateStyleStudio",isDirectory:true)
    }
    private static var fmTemporary: URL { FileManager.default.temporaryDirectory }
    nonisolated static func valid(_ document: Document) -> Bool {
        document.draft.valid && safeFace(document.draft.face) && document.looks.count <= maximumLooks &&
        (document.selectedAvatarID == nil || document.looks.contains { $0.id == document.selectedAvatarID }) &&
        Set(document.looks.map(\.id)).count == document.looks.count &&
        document.looks.allSatisfy { $0.look.valid && safeFace($0.look.face) && !$0.title.isEmpty && $0.title.count <= 40 && $0.date.timeIntervalSince1970.isFinite }
    }
    nonisolated private static func safeFace(_ data: Data?) -> Bool {
        guard let data else {return true}
        guard let source = CGImageSourceCreateWithData(data as CFData,nil),
              let info = CGImageSourceCopyPropertiesAtIndex(source,0,nil) as? [CFString:Any],
              let width = info[kCGImagePropertyPixelWidth] as? Int,
              let height = info[kCGImagePropertyPixelHeight] as? Int else {return false}
        return (1...512).contains(width) && (1...512).contains(height)
    }
    private func persist(draft: DressUpLook, looks: [SavedStyle], selectedAvatarID: UUID?) throws {
        guard healthy, !isLoading, Self.valid(Document(draft:draft,looks:looks,selectedAvatarID:selectedAvatarID)) else { throw CocoaError(.fileWriteUnknown) }
        let data = try JSONEncoder().encode(Document(draft:draft,looks:looks,selectedAvatarID:selectedAvatarID))
        try data.write(to:root.appendingPathComponent("studio.json"),options:[.atomic,.completeFileProtection])
        self.draft = draft; self.looks = looks; self.selectedAvatarID = selectedAvatarID
    }
    func update(_ look: DressUpLook) throws { try persist(draft:look,looks:looks,selectedAvatarID:selectedAvatarID) }
    @discardableResult func save(_ look: DressUpLook, title: String, makeActive: Bool = false) throws -> UUID {
        guard looks.count < Self.maximumLooks else { throw CocoaError(.fileWriteOutOfSpace) }
        let clean = String(title.trimmingCharacters(in:.whitespacesAndNewlines).prefix(40))
        let item = SavedStyle(id:UUID(),date:Date(),title:clean.isEmpty ? "My style" : clean,look:look)
        try persist(draft:look,looks:[item]+looks,selectedAvatarID:makeActive ? item.id : selectedAvatarID); return item.id
    }
    func selectAvatar(_ id: UUID?) throws {
        guard id == nil || looks.contains(where: { $0.id == id }) else { throw CocoaError(.fileReadNoSuchFile) }
        try persist(draft:draft,looks:looks,selectedAvatarID:id)
    }
    /// Ownership can be reset separately from private artwork. Never equip a paid item after a wallet reset.
    func gameLook(ownsStyle: (String) -> Bool) -> DressUpLook? {
        guard var look = selectedAvatar?.look else { return nil }
        if !ownsStyle(look.outfit) { look.outfit = "lavender" }
        if !ownsStyle(look.hair) { look.hair = "bob" }
        if !ownsStyle(look.bag) { look.bag = "simple" }
        return look
    }
    func delete(_ id: UUID) throws {
        try persist(draft:draft,looks:looks.filter { $0.id != id },selectedAvatarID:selectedAvatarID == id ? nil : selectedAvatarID)
    }
    func removeEveryFace() throws {
        var clean = draft; clean.face = nil
        let safe = looks.map { item in
            var look = item.look; look.face = nil
            return SavedStyle(id:item.id,date:item.date,title:item.title,look:look)
        }
        try persist(draft:clean,looks:safe,selectedAvatarID:selectedAvatarID)
    }
    nonisolated private static func normalized(_ source: CGImageSource, maximum: Int) throws -> Data {
        guard let image = CGImageSourceCreateThumbnailAtIndex(source,0,[kCGImageSourceCreateThumbnailFromImageAlways:true,kCGImageSourceCreateThumbnailWithTransform:true,kCGImageSourceThumbnailMaxPixelSize:maximum] as CFDictionary) else { throw CocoaError(.fileReadCorruptFile) }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output,UTType.jpeg.identifier as CFString,1,nil) else { throw CocoaError(.fileWriteUnknown) }
        CGImageDestinationAddImage(destination,image,[kCGImageDestinationLossyCompressionQuality:0.86] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw CocoaError(.fileWriteUnknown) }
        return output as Data
    }
    /// Downsample/re-encode strips source metadata and bounds decoded photo memory.
    nonisolated static func normalizedFace(_ data: Data) throws -> Data {
        guard data.count <= 20_000_000, let source = CGImageSourceCreateWithData(data as CFData,nil) else { throw CocoaError(.fileReadCorruptFile) }
        let jpeg = try normalized(source,maximum:512)
        guard jpeg.count <= 1_000_000 else { throw CocoaError(.fileReadCorruptFile) }
        return jpeg
    }
    nonisolated static func prepareCrop(_ sourceURL: URL) throws -> URL {
        guard (try sourceURL.resourceValues(forKeys:[.fileSizeKey]).fileSize ?? Int.max) <= 30_000_000,
              let source = CGImageSourceCreateWithURL(sourceURL as CFURL,nil) else { throw CocoaError(.fileReadCorruptFile) }
        let data = try normalized(source,maximum:1600)
        let directory=cropDirectory
        try prepareRoot(directory)
        let url=directory.appendingPathComponent(UUID().uuidString+".jpg")
        try data.write(to:url,options:[.atomic,.completeFileProtection]); return url
    }
    nonisolated private static var cropDirectory: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("linley-style-crops",isDirectory:true)
    }
    nonisolated private static func ownsCrop(_ url: URL) -> Bool {
        url.standardizedFileURL.deletingLastPathComponent() == cropDirectory.standardizedFileURL &&
        url.pathExtension.lowercased() == "jpg" && UUID(uuidString:url.deletingPathExtension().lastPathComponent) != nil
    }
    nonisolated static func cleanupCrop(_ url: URL) {
        guard ownsCrop(url) else {return}
        try? FileManager.default.removeItem(at:url)
    }
    nonisolated private static func purgeCropFiles() {
        guard let files=try? FileManager.default.contentsOfDirectory(at:cropDirectory,includingPropertiesForKeys:nil) else {return}
        for file in files where ownsCrop(file) {cleanupCrop(file)}
    }
}
