import SwiftUI

@main
struct LinleyApp: App {
    @StateObject private var suggestionStore = SuggestionStore()
    @StateObject private var mediaStore = LinleyApp.makeMediaStore()
    @StateObject private var questStore = QuestStore()

    @MainActor private static func makeMediaStore() -> MediaStore {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--quest-ui-tests") {
            let root = FileManager.default.temporaryDirectory.appendingPathComponent("linley-quest-ui-library", isDirectory: true)
            try? FileManager.default.removeItem(at: root)
            return MediaStore(root: root)
        }
        #endif
        return MediaStore()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(suggestionStore)
                .environmentObject(mediaStore)
                .environmentObject(questStore)
                .tint(LinleyTheme.coralDeep)
                .alert("Private library", isPresented: Binding(
                    get: { mediaStore.errorMessage != nil },
                    set: { if !$0 { mediaStore.errorMessage = nil } }
                )) { Button("OK") { mediaStore.errorMessage = nil } }
                message: { Text(mediaStore.errorMessage ?? "") }
        }
    }
}
