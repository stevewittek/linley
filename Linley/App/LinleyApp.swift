import SwiftUI

@main
struct LinleyApp: App {
    @AppStorage("linley.profile.nickname") private var nickname = ""
    @StateObject private var suggestionStore = SuggestionStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if nickname.isEmpty {
                    ProfileSetupView(canCancel: false)
                } else {
                    RootTabView()
                }
            }
            .environmentObject(suggestionStore)
            .tint(LinleyTheme.coralDeep)
        }
    }
}
