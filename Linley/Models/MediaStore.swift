import Foundation
import SwiftUI

struct Creation: Codable, Identifiable, Equatable {
    enum Kind: String, Codable { case picture, video }
    let id: UUID
    let filename: String
    let kind: Kind
    let createdAt: Date
}

/// No remote destinations exist in Phase 1. UI switches cannot authorize them.
enum FeaturePolicy {
    static let localCreation = true
    static let cloudStorage = false
    static let publicPosting = false
    static let communication = false
}

@MainActor
final class MediaStore: ObservableObject {
    @Published private(set) var creations: [Creation] = []
    @Published private(set) var linkedCreators: Set<String> = []
    @Published private(set) var profileRevision = UUID()
    @Published var errorMessage: String?
    private let root: URL
    private let fm = FileManager.default
    private var healthy = false
    private struct Index: Codable {
        var creations: [Creation]
        var linkedCreators: Set<String>
    }

    init(root: URL? = nil) {
        self.root = root ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PrivateCreations", isDirectory: true)
        do {
            try fm.createDirectory(at: self.root, withIntermediateDirectories: true,
                                   attributes: [.protectionKey: FileProtectionType.complete])
            var url = self.root
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try url.setResourceValues(values)
            let index = self.root.appendingPathComponent("index.json")
            if fm.fileExists(atPath: index.path) {
                let saved = try JSONDecoder().decode(Index.self, from: Data(contentsOf: index))
                guard saved.creations.allSatisfy({ Self.safeFilename($0.filename) }) else {
                    throw CocoaError(.fileReadCorruptFile)
                }
                creations = saved.creations
                linkedCreators = saved.linkedCreators
            }
            healthy = true
        } catch {
            errorMessage = "Your private library could not be opened. Your files have been kept. \(error.localizedDescription)"
        }
    }

    static func safeFilename(_ name: String) -> Bool {
        !name.isEmpty && name != "." && name != ".." && !name.contains("/") && !name.contains("\\")
    }

    func url(for creation: Creation) -> URL { root.appendingPathComponent(creation.filename) }
    var profileURL: URL { root.appendingPathComponent("profile.jpg") }
    var profileData: Data? { try? Data(contentsOf: profileURL) }

    @discardableResult
    func save(source: URL, kind: Creation.Kind) throws -> Creation {
        guard healthy else { throw CocoaError(.fileWriteUnknown) }
        let ext = kind == .picture ? "jpg" : source.pathExtension.lowercased()
        guard kind == .picture || ["mov", "mp4", "m4v"].contains(ext) else {
            throw CocoaError(.fileReadUnsupportedScheme)
        }
        let item = Creation(id: UUID(), filename: "\(UUID().uuidString).\(ext)", kind: kind, createdAt: Date())
        let destination = url(for: item)
        do {
            try fm.copyItem(at: source, to: destination)
            try fm.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: destination.path)
            let next = [item] + creations
            try persist(creations: next, links: linkedCreators)
            creations = next
            return item
        } catch {
            try? fm.removeItem(at: destination)
            throw error
        }
    }

    func delete(_ item: Creation) throws {
        guard healthy else { throw CocoaError(.fileWriteUnknown) }
        // Leave the manifest intact if removing the private file fails.
        let file = url(for: item)
        if fm.fileExists(atPath: file.path) { try fm.removeItem(at: file) }
        let next = creations.filter { $0.id != item.id }
        try persist(creations: next, links: linkedCreators)
        creations = next
    }

    func toggleLink(_ creator: String) throws {
        guard healthy, DemoCatalog.creators.contains(creator) else { throw CocoaError(.validationMissingMandatoryProperty) }
        var next = linkedCreators
        if next.contains(creator) { next.remove(creator) } else { next.insert(creator) }
        try persist(creations: creations, links: next)
        linkedCreators = next
    }

    func setProfile(_ data: Data?) throws {
        guard healthy else { throw CocoaError(.fileWriteUnknown) }
        if let data { try data.write(to: profileURL, options: [.atomic, .completeFileProtection]) }
        else if fm.fileExists(atPath: profileURL.path) { try fm.removeItem(at: profileURL) }
        profileRevision = UUID()
    }

    private func persist(creations: [Creation], links: Set<String>) throws {
        let data = try JSONEncoder().encode(Index(creations: creations, linkedCreators: links))
        try data.write(to: root.appendingPathComponent("index.json"), options: [.atomic, .completeFileProtection])
    }
}
