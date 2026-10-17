import SwiftUI

@main
struct LinleyApp: App {
    @StateObject private var suggestionStore = SuggestionStore()
    @StateObject private var mediaStore = MediaStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(suggestionStore)
                .environmentObject(mediaStore)
                .tint(LinleyTheme.coralDeep)
                .alert("Private library", isPresented: Binding(
                    get: { mediaStore.errorMessage != nil },
                    set: { if !$0 { mediaStore.errorMessage = nil } }
                )) { Button("OK") { mediaStore.errorMessage = nil } }
                message: { Text(mediaStore.errorMessage ?? "") }
        }
    }
}
