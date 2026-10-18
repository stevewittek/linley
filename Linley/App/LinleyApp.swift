import SwiftUI

@main
struct LinleyApp: App {
    @StateObject private var suggestionStore = SuggestionStore()
    @StateObject private var mediaStore = LinleyApp.makeMediaStore()
    @StateObject private var questStore = QuestStore()
    @StateObject private var styleStore = LinleyApp.makeStyleStore()

    @MainActor private static func makeStyleStore() -> DressUpStore {
        let store=DressUpStore(deferredLoad:!ProcessInfo.processInfo.arguments.contains("--quest-ui-tests"))
        #if DEBUG
        let args=ProcessInfo.processInfo.arguments
        if args.contains("--quest-ui-tests") && args.contains(where: {$0.hasPrefix("--avatar-")}) {
            // Fictional, free wardrobe only. This never changes the wallet or a real user's library.
            if store.looks.isEmpty {
                var look=DressUpLook(skin:2)
                look.lipColor=2;look.blush=1;look.eyeShadow=1
                _ = try? store.save(look,title:"Starlight",makeActive:true)
                var second=DressUpLook(skin:3,accessory:1)
                second.hairColor=3;second.glasses=1
                _ = try? store.save(second,title:"Berry sparkle")
            }
            if store.selectedAvatarID == nil {try? store.selectAvatar(store.looks.first?.id)}
        }
        #endif
        return store
    }

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

    @ViewBuilder private var appContent: some View {
        #if DEBUG
        // Headless simulator visual review; always uses the existing isolated UI-test stores.
        if ProcessInfo.processInfo.arguments.contains("--quest-ui-tests") &&
            ProcessInfo.processInfo.arguments.contains("--avatar-review") {
            NavigationStack {AvatarLibraryView()}
        } else if ProcessInfo.processInfo.arguments.contains("--quest-ui-tests") &&
            ProcessInfo.processInfo.arguments.contains("--avatar-games-review") {
            NavigationStack {GamesView()}
        } else if ProcessInfo.processInfo.arguments.contains("--quest-ui-tests") &&
            ProcessInfo.processInfo.arguments.contains("--avatar-chase-review") {
            NavigationStack {ChaseGameView().task {_ = questStore.startChase(level:0,practice:true)}}
        } else if ProcessInfo.processInfo.arguments.contains("--quest-ui-tests") &&
            ProcessInfo.processInfo.arguments.contains("--style-review-gallery") {
            NavigationStack { StyleArtReviewGallery() }
        } else if ProcessInfo.processInfo.arguments.contains("--quest-ui-tests") &&
            ProcessInfo.processInfo.arguments.contains("--style-review-board") {
            NavigationStack { DressUpView() }
        } else if ProcessInfo.processInfo.arguments.contains("--quest-ui-tests") &&
            ProcessInfo.processInfo.arguments.contains("--match-review-board") {
            NavigationStack {
                MatchGameView().task {
                    if questStore.progress.match.session == nil { _ = questStore.startMatch(level: 0, seed: 1) }
                }
            }
        } else { RootTabView() }
        #else
        RootTabView()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            appContent
                .environmentObject(suggestionStore)
                .environmentObject(mediaStore)
                .environmentObject(questStore)
                .environmentObject(styleStore)
                .task {await styleStore.loadIfNeeded()}
                .tint(LinleyTheme.coralDeep)
                .alert("Private library", isPresented: Binding(
                    get: { mediaStore.errorMessage != nil },
                    set: { if !$0 { mediaStore.errorMessage = nil } }
                )) { Button("OK") { mediaStore.errorMessage = nil } }
                message: { Text(mediaStore.errorMessage ?? "") }
        }
    }
}

#if DEBUG
/// Art/layout review fixture, not a purchase bypass in the shipped game.
private struct StyleArtReviewGallery: View {
    private let samples = [
        DressUpLook(outfit:"lavender",hair:"bob",skin:1,backdrop:0,accessory:3,bag:"kitty",glasses:1,makeup:2,animalEars:true),
        DressUpLook(outfit:"mint",hair:"waves",skin:0,backdrop:1,accessory:2,bag:"dumpling",makeup:1),
        DressUpLook(outfit:"pinkcloud",hair:"buns",skin:2,backdrop:3,accessory:1,bag:"bunny",glasses:2,makeup:3),
        DressUpLook(outfit:"emerald",hair:"braids",skin:3,backdrop:2,accessory:1,bag:"bear",makeup:2)
    ]
    var body: some View {
        ScrollView {
            VStack(spacing:12) {
                Text("Wardrobe preview").font(.largeTitle.bold()).foregroundStyle(LinleyTheme.plum)
                Text("SIMULATOR · Original avatar art · Sample styling").font(.caption)
                LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:14) {
                    ForEach(samples.indices,id:\.self) { i in
                        DressUpCanvas(look:samples[i],title:WardrobeItem.item(samples[i].outfit)!.title)
                            .clipShape(RoundedRectangle(cornerRadius:20))
                    }
                }.frame(maxWidth:620)
            }.padding(20).frame(maxWidth:.infinity)
        }.background(LinleyTheme.pageGradient)
    }
}
#endif
