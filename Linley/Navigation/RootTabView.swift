import SwiftUI

struct RootTabView: View {
    @State private var selectedTab = 0
    @State private var lastContentTab = 0
    @State private var showingCreator = false

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)

            NavigationStack {
                IdeaLabView()
            }
            .tabItem {
                Label("Idea Lab", systemImage: "sparkles")
            }
            .tag(1)

            Color.clear
                .tabItem {
                    Label("Create", systemImage: "plus.circle.fill")
                }
                .tag(2)

            NavigationStack {
                BuilderView()
            }
            .tabItem {
                Label("Builder", systemImage: "hammer.fill")
            }
            .tag(3)

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle.fill")
            }
            .tag(4)
        }
        .onChange(of: selectedTab) { _, newValue in
            if newValue == 2 {
                showingCreator = true
                selectedTab = lastContentTab
            } else {
                lastContentTab = newValue
            }
        }
        .sheet(isPresented: $showingCreator) {
            VideoCreatorView()
        }
    }
}

#Preview("Responsive shell") {
    RootTabView()
        .environmentObject(SuggestionStore())
}
