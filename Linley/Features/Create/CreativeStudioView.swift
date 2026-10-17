import SwiftUI

struct CoinBalanceView: View {
    @EnvironmentObject private var game: QuestStore
    var body: some View {
        Label(game.loadError ? "Coins unavailable" : "\(game.progress.coins) Linley Coins", systemImage: "sparkles")
            .font(.headline).foregroundStyle(LinleyTheme.plum)
            .padding(12).background(LinleyTheme.gold.opacity(0.25), in: Capsule())
            .accessibilityIdentifier("coinBalance")
    }
}

struct CreativeShopView: View {
    @EnvironmentObject private var game: QuestStore
    @State private var pending: String?
    @State private var message: String?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                CoinBalanceView()
                Text("Play. Collect. Create.").font(.largeTitle.bold())
                Text("Finish an adventure for 100 coins. Unlock an art pack once, then use it as often as you like. Coins are earned here and have no money value.")
                NavigationLink { CreativeStudioView() } label: {
                    Label("Open image maker", systemImage: "paintpalette.fill")
                }.buttonStyle(.borderedProminent)
                if game.loadError {
                    Text("Saved rewards couldn't open. Your saved data has been kept; the shop is locked until game progress is recovered.")
                }
                ForEach(CreativePack.catalog) { pack in
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            ForEach(pack.symbols, id: \.self) { symbol in
                                Image(systemName: symbol).font(.title).foregroundStyle(LinleyTheme.coralDeep)
                            }
                        }
                        Text(pack.title).font(.title2.bold())
                        Text("Three art stamps • yours to reuse forever").font(.subheadline)
                        if game.progress.ownedPacks.contains(pack.id) {
                            Label("Unlocked", systemImage: "checkmark.circle.fill")
                                .accessibilityIdentifier("owned-\(pack.id)")
                        } else {
                            Button("Unlock for \(pack.cost) coins") { pending = pack.id }
                                .buttonStyle(.borderedProminent)
                                .accessibilityIdentifier("unlock-\(pack.id)")
                                .disabled(game.loadError || game.progress.coins < pack.cost)
                            if game.progress.coins < pack.cost {
                                Text("\(pack.cost - game.progress.coins) more coins to unlock").font(.caption)
                            }
                        }
                    }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white, in: RoundedRectangle(cornerRadius: 24))
                }
                Text("Basic art stamps, camera and local creation stay free. No ads, real-money purchases, random prizes, expiring coins or trading with other people.")
                    .font(.footnote).foregroundStyle(.secondary)
            }.padding(22).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.background(LinleyTheme.pageGradient).navigationTitle("Creative Shop")
            .confirmationDialog("Unlock this art pack?", isPresented: Binding(get: { pending != nil }, set: { if !$0 { pending = nil } }), titleVisibility: .visible) {
                if let id = pending, let pack = CreativePack.catalog.first(where: { $0.id == id }) {
                    Button("Use \(pack.cost) coins for \(pack.title)") {
                        message = game.unlockPack(id) ? "\(pack.title) is ready in your image maker." : "This pack could not unlock. Your balance has not changed."
                        pending = nil
                    }
                }
                Button("Cancel", role: .cancel) { pending = nil }
            } message: { Text("This uses earned Linley Coins, never money. The pack is yours to reuse.") }
            .alert("Creative Shop", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
                Button("OK") { message = nil }
            } message: { Text(message ?? "") }
    }
}

struct ArtStamp: Identifiable {
    let id = UUID()
    let symbol: String
    let x: CGFloat
    let y: CGFloat
    let color: Int
}

struct CreativeStudioView: View {
    @EnvironmentObject private var game: QuestStore
    @EnvironmentObject private var media: MediaStore
    @State private var stamps: [ArtStamp] = []
    @State private var symbol = "star.fill"
    @State private var ink = 0
    @State private var paper = 0
    @State private var message: String?
    private let inks = [LinleyTheme.coralDeep, LinleyTheme.sky, LinleyTheme.orange, LinleyTheme.plum]
    private let papers = [Color.white, LinleyTheme.cream, LinleyTheme.sky.opacity(0.15)]
    private var symbols: [String] {
        ["star.fill", "heart.fill", "circle.fill"] + CreativePack.catalog
            .filter { !game.loadError && game.progress.ownedPacks.contains($0.id) }.flatMap(\.symbols)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                CoinBalanceView()
                NavigationLink { SketchbookView() } label: {
                    Label("Draw in My Sketchbook", systemImage: "pencil.and.outline")
                }.buttonStyle(.bordered).accessibilityIdentifier("studioSketchbook")
                Text("Make a little masterpiece").font(.title2.bold())
                Text("Choose a stamp and color, then tap the paper. Saving and reusing your art supplies is always free.")
                artPaper
                    .aspectRatio(1, contentMode: .fit)
                    .overlay {
                        GeometryReader { geo in
                            Color.clear.contentShape(Rectangle())
                                .onTapGesture { point in
                                    guard stamps.count < 40 else { message = "Your paper has 40 stamps. Undo one or save this picture and start another."; return }
                                    stamps.append(ArtStamp(symbol: symbol, x: min(0.9, max(0.1, point.x / geo.size.width)), y: min(0.9, max(0.1, point.y / geo.size.height)), color: ink))
                                }
                        }.accessibilityLabel("Art paper. Tap to add your selected stamp.")
                            .accessibilityIdentifier("artPaper")
                            .accessibilityAddTraits(.isButton)
                            .accessibilityAction {
                                if stamps.count < 40 { stamps.append(ArtStamp(symbol: symbol, x: 0.5, y: 0.5, color: ink)) }
                            }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 52))]) {
                    ForEach(symbols, id: \.self) { item in
                        Button { symbol = item } label: {
                            Image(systemName: item).font(.title2).frame(width: 48, height: 48)
                                .background(symbol == item ? LinleyTheme.gold.opacity(0.4) : .white, in: RoundedRectangle(cornerRadius: 12))
                        }.accessibilityLabel("Stamp \(item)").accessibilityIdentifier("stamp-\(item)")
                    }
                }
                Picker("Ink", selection: $ink) {
                    Text("Coral").tag(0); Text("Blue").tag(1); Text("Orange").tag(2); Text("Plum").tag(3)
                }.pickerStyle(.segmented)
                Picker("Paper", selection: $paper) {
                    Text("White").tag(0); Text("Blush").tag(1); Text("Sky").tag(2)
                }.pickerStyle(.segmented)
                HStack {
                    Button("Undo stamp") { if !stamps.isEmpty { stamps.removeLast() } }.disabled(stamps.isEmpty)
                    Spacer()
                    Button("Save to My Stuff") { savePicture() }
                        .buttonStyle(.borderedProminent).disabled(stamps.isEmpty)
                        .accessibilityIdentifier("saveStudioPicture")
                }
                NavigationLink("See My Stuff") { GalleryView() }
                NavigationLink("More art packs in the Creative Shop") { CreativeShopView() }
            }.padding(22).frame(maxWidth: 600).frame(maxWidth: .infinity)
        }.background(LinleyTheme.pageGradient).navigationTitle("Image Maker")
            .alert("Image Maker", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
                Button("OK") { message = nil }
            } message: { Text(message ?? "") }
    }

    private var artPaper: some View {
        GeometryReader { geo in
            ZStack {
                papers[paper]
                ForEach(stamps) { stamp in
                    Image(systemName: stamp.symbol).resizable().scaledToFit()
                        .foregroundStyle(inks[stamp.color])
                        .frame(width: geo.size.width * 0.16, height: geo.size.height * 0.16)
                        .position(x: geo.size.width * stamp.x, y: geo.size.height * stamp.y)
                }
            }
        }
    }

    @MainActor private func savePicture() {
        let renderer = ImageRenderer(content: artPaper.frame(width: 768, height: 768))
        renderer.scale = 1
        guard let data = renderer.uiImage?.jpegData(compressionQuality: 0.92) else { message = "Your picture couldn't render. Try saving again."; return }
        let temporary = FileManager.default.temporaryDirectory.appendingPathComponent("linley-art-\(UUID()).jpg")
        defer { try? FileManager.default.removeItem(at: temporary) }
        do {
            try data.write(to: temporary, options: [.atomic, .completeFileProtection])
            _ = try media.save(source: temporary, kind: .picture)
            message = "Saved privately to My Stuff. Your coins and supplies stay yours."
        } catch { message = "Your picture couldn't save. Your coins have not changed. \(error.localizedDescription)" }
    }
}
