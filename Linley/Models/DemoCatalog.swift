import SwiftUI

struct DemoPost: Identifiable {
    let id: String
    let title: String
    let creator: String
    let kind: Creation.Kind
    let resource: String
    let height: CGFloat
}

enum DemoCatalog {
    static let creators = ["Color Studio", "Paper Planet", "Loop Lab"]
    static let posts: [DemoPost] = [
        .init(id: "sun", title: "Sunset shapes", creator: "Color Studio", kind: .picture, resource: "DemoSun", height: 220),
        .init(id: "blue", title: "Blue daydream", creator: "Paper Planet", kind: .picture, resource: "DemoBlue", height: 165),
        .init(id: "coral", title: "Coral collage", creator: "Loop Lab", kind: .picture, resource: "DemoCoral", height: 170),
        .init(id: "paper", title: "Paper playground", creator: "Paper Planet", kind: .picture, resource: "DemoPaper", height: 225),
        .init(id: "motion", title: "Shapes in motion", creator: "Loop Lab", kind: .video, resource: "DemoMotion", height: 260)
    ]
    static func search(_ query: String, kind: Creation.Kind, linked: Set<String>? = nil) -> [DemoPost] {
        posts.filter {
            $0.kind == kind && (linked == nil || linked!.contains($0.creator)) &&
            (query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
             "\($0.title) \($0.creator) \($0.kind.rawValue)".localizedCaseInsensitiveContains(query.trimmingCharacters(in: .whitespacesAndNewlines)))
        }
    }
}

