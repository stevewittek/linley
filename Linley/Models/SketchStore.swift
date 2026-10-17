import Foundation
import SwiftUI
import PencilKit

struct SketchSummary: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var title: String
    var paper: Int
    let createdAt: Date
    var updatedAt: Date
}

struct SketchDocument: Codable, Sendable {
    var summary: SketchSummary
    let drawing: Data
    let preview: Data
}

/// Each editable sketch is one atomic, protected, backup-excluded file.
@MainActor
final class SketchStore: ObservableObject {
    @Published private(set) var projects: [SketchSummary] = []
    @Published var errorMessage: String?
    private let root: URL
    private let fm = FileManager.default
    private var ready = false
    static let maximumProjects = 100
    nonisolated static let maximumDrawingBytes = 25_000_000

    init(root: URL? = nil) {
        self.root = root ?? Self.defaultRoot()
        do {
            try fm.createDirectory(at: self.root, withIntermediateDirectories: true,
                                   attributes: [.protectionKey: FileProtectionType.complete])
            var folder = self.root
            var values = URLResourceValues(); values.isExcludedFromBackup = true
            try folder.setResourceValues(values)
            ready = true
            reload()
        } catch { errorMessage = "Your sketchbook couldn't open. Existing drawings were kept. \(error.localizedDescription)" }
    }

    private static func defaultRoot() -> URL {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--quest-ui-tests") {
            let session = ProcessInfo.processInfo.environment["LINLEY_SKETCH_TEST_SESSION"]
                .flatMap(UUID.init(uuidString:))?.uuidString ?? "default"
            return FileManager.default.temporaryDirectory.appendingPathComponent("linley-sketch-ui-tests/\(session)", isDirectory: true)
        }
        #endif
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PrivateSketchbook", isDirectory: true)
    }

    func fileURL(_ id: UUID) -> URL { root.appendingPathComponent(id.uuidString + ".sketch") }

    nonisolated static func read(_ url: URL) throws -> SketchDocument {
        let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard size > 0, size <= 40_100_000 else { throw CocoaError(.fileReadCorruptFile) }
        let document = try JSONDecoder().decode(SketchDocument.self, from: Data(contentsOf: url))
        guard (0..<3).contains(document.summary.paper), !document.summary.title.isEmpty,
              document.summary.title.count <= 48, document.drawing.count <= maximumDrawingBytes,
              document.preview.count <= 5_000_000 else { throw CocoaError(.fileReadCorruptFile) }
        return document
    }

    func load(_ id: UUID) throws -> SketchDocument {
        let document = try Self.read(fileURL(id))
        guard document.summary.id == id else { throw CocoaError(.fileReadCorruptFile) }
        _ = try PKDrawing(data: document.drawing)
        return document
    }

    @discardableResult
    func save(id: UUID, title: String, paper: Int, drawing: Data, preview: Data) throws -> SketchSummary {
        guard ready else { throw CocoaError(.fileWriteUnknown) }
        guard (0..<3).contains(paper), drawing.count <= Self.maximumDrawingBytes,
              preview.count <= 5_000_000, !preview.isEmpty else { throw CocoaError(.fileWriteInvalidFileName) }
        _ = try PKDrawing(data: drawing)
        let old = projects.first { $0.id == id }
        guard old != nil || projects.count < Self.maximumProjects else { throw SketchError.full }
        // Never silently replace an existing file that failed to load into the project list.
        if old == nil, fm.fileExists(atPath: fileURL(id).path) { throw CocoaError(.fileReadCorruptFile) }
        let clean = String(title.trimmingCharacters(in: .whitespacesAndNewlines).prefix(48))
        let summary = SketchSummary(id: id, title: clean.isEmpty ? "Untitled sketch" : clean, paper: paper,
                                    createdAt: old?.createdAt ?? Date(), updatedAt: Date())
        let document = SketchDocument(summary: summary, drawing: drawing, preview: preview)
        let data = try JSONEncoder().encode(document)
        try data.write(to: fileURL(id), options: [.atomic, .completeFileProtection])
        projects.removeAll { $0.id == id }; projects.insert(summary, at: 0)
        return summary
    }

    func delete(_ id: UUID) throws {
        guard ready else { throw CocoaError(.fileWriteUnknown) }
        try fm.removeItem(at: fileURL(id))
        projects.removeAll { $0.id == id }
    }

    private func reload() {
        do {
            var loaded: [SketchSummary] = []
            var unreadable = false
            for url in try fm.contentsOfDirectory(at: root, includingPropertiesForKeys: [.fileSizeKey]) where url.pathExtension == "sketch" {
                guard let id = UUID(uuidString: url.deletingPathExtension().lastPathComponent) else { unreadable = true; continue }
                do {
                    let document = try Self.read(url)
                    guard document.summary.id == id else { throw CocoaError(.fileReadCorruptFile) }
                    loaded.append(document.summary)
                } catch { unreadable = true }
            }
            projects = loaded.sorted { $0.updatedAt > $1.updatedAt }
            if unreadable { errorMessage = "Some sketches couldn't open and were kept untouched. Your other sketches are still available." }
        } catch { ready = false; errorMessage = "Your saved sketches couldn't be listed. Files were kept. \(error.localizedDescription)" }
    }
}

private enum SketchError: LocalizedError {
    case full
    var errorDescription: String? { "Your sketchbook has 100 drafts. Delete a draft you no longer need before starting another." }
}
