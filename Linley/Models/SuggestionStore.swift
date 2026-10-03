import Foundation

struct LinleySuggestion: Codable, Identifiable, Equatable {
    let id: UUID
    let createdAt: Date
    let title: String
    let category: String
    let details: String

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        title: String,
        category: String,
        details: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.title = title
        self.category = category
        self.details = details
    }

    var shareText: String {
        """
        Linley idea for Dad to review

        Title: \(title)
        Type: \(category)

        \(details)

        Status: Waiting for Dad's approval. This idea does not change the app automatically.
        """
    }
}

@MainActor
final class SuggestionStore: ObservableObject {
    @Published private(set) var suggestions: [LinleySuggestion] = []

    private let defaults: UserDefaults
    private let storageKey = "linley.pendingSuggestions"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func add(title: String, category: String, details: String) {
        let suggestion = LinleySuggestion(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            details: details.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        suggestions.insert(suggestion, at: 0)
        save()
    }

    func remove(_ suggestion: LinleySuggestion) {
        suggestions.removeAll { $0.id == suggestion.id }
        save()
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([LinleySuggestion].self, from: data) else {
            return
        }
        suggestions = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(suggestions) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
