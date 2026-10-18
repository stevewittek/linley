import SwiftUI
import AVFoundation

struct MatchTileView: View {
    let kind: Int
    static let names = ["Purple gem", "Garden patch", "Silver cog", "Sun gem", "Heart gem"]
    private var filename: String { kind == 1 ? "tile-grass" : kind == 2 ? "tile-spikes" : "tile-gem" }
    // Decode each bundled sprite once, rather than reading disk for every animated cell.
    private static let sprites: [String: UIImage] = {
        var images: [String: UIImage] = [:]
        for name in ["tile-grass", "tile-spikes", "tile-gem"] {
            if let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "MatchTiles"),
               let image = UIImage(contentsOfFile: url.path) { images[name] = image }
        }
        return images
    }()
    private var sprite: UIImage? { Self.sprites[filename] }
    var body: some View {
        ZStack {
            if let sprite {
                Image(uiImage: sprite).resizable().interpolation(.none).scaledToFit()
                    .hueRotation(.degrees(kind == 3 ? 120 : kind == 4 ? 70 : 0))
                if kind == 3 || kind == 4 {
                    Image(systemName: kind == 3 ? "sun.max.fill" : "heart.fill")
                        .font(.system(size: 17, weight: .bold)).foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 1)
                }
            }
        }.padding(4).opacity(kind < 0 ? 0 : 1)
    }
}

struct MatchGameView: View {
    @EnvironmentObject private var game: QuestStore
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var audio = QuestAudio()
    @State private var selected: Int?
    @State private var hint: Set<Int> = []
    @State private var frames: [Int]?
    @State private var animating = false
    @State private var animation: Task<Void, Never>?
    @State private var message = "Tap a gem, then a neighbor. Match 3 or more in a row."
    @State private var showAudio = false
    @State private var restart = false
    private var session: MatchSession? { game.progress.match.session }

    var body: some View {
        ScrollViewReader { proxy in
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Color.clear.frame(height: 0).id("matchTop")
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Gem Garden").font(.largeTitle.bold())
                        Text("MATCH-3").font(.caption.bold()).tracking(3).foregroundStyle(LinleyTheme.plum)
                    }
                    Spacer()
                    Button { showAudio = true } label: { Image(systemName: "speaker.wave.2.fill").font(.title2) }
                        .accessibilityLabel("Game Sound").accessibilityIdentifier("matchAudio")
                }
                CoinBalanceView()
                AvatarPlayerCard()
                if game.loadError {
                    Text("Saved progress couldn't open. Your saved data is kept. Recover it in Creative Quest before playing.")
                } else if let current = session {
                    boardContent(current)
                } else {
                    Text("Swap colorful gems, garden patches and cogs. Make cascades before your moves run out. Every win earns 100 coins for the same Creative Shop used by all your games. First clears of every fifth level earn 200! Match four to earn a line rocket; match five to earn a starburst. Tap an earned power to fire it for one move.")
                    Text("Free retries • No life cost • No real money").font(.subheadline.bold()).foregroundStyle(LinleyTheme.plum)
                    ForEach(MatchLevel.all.indices, id: \.self) { level in
                        let item = MatchLevel.all[level]
                        Button {
                            begin(level)
                        } label: {
                            HStack {
                                Text("\(level + 1)").font(.title.bold()).frame(width: 40)
                                VStack(alignment: .leading) {
                                    Text(item.title).font(.headline)
                                    Text("\(item.target) points · \(item.moves) moves").font(.subheadline)
                                    Text(levelGoal(item)).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: game.progress.match.cleared.contains(level) ? "checkmark.seal.fill" : level > game.progress.match.unlocked ? "lock.fill" : "play.circle.fill")
                            }.padding(16).background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 20))
                        }.buttonStyle(.plain).disabled(level > game.progress.match.unlocked)
                            .accessibilityIdentifier("matchLevel-\(level)")
                    }
                }
                NavigationLink("Spend coins in the Creative Shop") { CreativeShopView() }
                    .accessibilityIdentifier("matchShop")
                DisclosureGroup("Rules & credits") {
                    Text("Tap two neighboring tiles or swipe a tile one space. Only swaps that make a match use a move. Three or more matching tiles clear; tiles above fall and new ones arrive. Each cleared tile scores 10 points; cascades multiply points up to 5×. Meet every goal before moves run out. Some boards ask for a specific tile collection and frost clearing as well as score. Match on a snowflake to remove one frost layer. A four-tile run earns a row/column rocket; five earns a 3×3 starburst. Tap a powered tile to fire it for one move; matching it also triggers it. Powers can chain. Frost stays on its board cell as gems fall. If no swaps remain, the board refreshes free. Leaving pauses your board. Winning it again earns another 100 coins; reopening a completed board never repeats its reward. Points measure a board's score; Linley Coins are your shared app rewards.")
                    Text("Native adaptation of Kenney Starter Kit Match-3 (MIT). Tile artwork by Kenney (CC0). Music: Flowerbed Fields by Zane Little (CC0). Linley adds levels, goals and shared rewards. No Godot runtime.")
                        .padding(.top, 8)
                }.font(.footnote)
            }.padding(24).frame(maxWidth: 650).frame(maxWidth: .infinity)
        }.onChange(of: session?.level) { _, _ in proxy.scrollTo("matchTop", anchor: .top) }
            .onChange(of: session?.status) { _, status in
                if status == .playing { proxy.scrollTo("matchTop", anchor: .top) }
            }
        }.background(LinleyTheme.pageGradient).navigationTitle("Match-3")
            .sheet(isPresented: $showAudio) { QuestAudioSettings(audio: audio) }
            .confirmationDialog("Start this level again?", isPresented: $restart, titleVisibility: .visible) {
                Button("Restart free") {
                    guard let level = session?.level else { return }
                    cancelAnimation(); game.endMatch(); begin(level)
                }
                Button("Cancel", role: .cancel) { }
            } message: { Text("This board's score will reset. Your coins and unlocked levels stay saved.") }
            .onAppear { audio.setVisible(phase == .active) }
            .onDisappear { cancelAnimation(); audio.setVisible(false) }
            .onChange(of: phase) { _, value in
                audio.setVisible(value == .active)
                if value != .active { cancelAnimation() }
            }
            .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { audio.interrupt($0) }
            .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)) { audio.routeChanged($0) }
    }

    @ViewBuilder private func boardContent(_ current: MatchSession) -> some View {
        let level = current.rules
        Text("Level \(current.level + 1) · \(level.title)").font(.title2.bold())
        HStack {
            Text("\(current.score) / \(level.target) points").accessibilityIdentifier("matchScore")
            Spacer()
            Text("\(current.moves) moves left").accessibilityIdentifier("matchMoves")
        }.font(.headline).monospacedDigit()
        ProgressView(value: Double(min(current.score, level.target)), total: Double(level.target)).tint(LinleyTheme.plum)
        HStack(spacing: 14) {
            if let kind = level.collectKind {
                Label("\(min(current.collected,level.collectGoal))/\(level.collectGoal) \(MatchTileView.names[kind])", systemImage: "tray.and.arrow.down.fill")
                    .accessibilityIdentifier("matchCollectionGoal")
            }
            if !level.frost.isEmpty {
                Label("\(current.frost.values.reduce(0,+)) frost layers left", systemImage: "snowflake")
                    .accessibilityIdentifier("matchFrostGoal")
            }
        }.font(.caption.bold()).foregroundStyle(LinleyTheme.plum)
        Text(current.rulesVersion == 1 ? "Saved classic board: original rules preserved. Restart free to try the new challenges." : "Match 4 → line rocket · Match 5 → starburst · Tap a power to fire").font(.caption).foregroundStyle(.secondary)
        let tiles = frames ?? current.board
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 6), spacing: 4) {
            ForEach(0..<36, id: \.self) { index in
                Button { tap(index) } label: {
                    MatchTileView(kind: tiles[index])
                        .overlay(alignment: .topLeading) {
                            if let layers = current.frost[index] {
                                Label("\(layers)", systemImage: "snowflake").font(.caption2.bold()).foregroundStyle(.white)
                                    .padding(4).background(Color.blue.opacity(0.85), in: Capsule())
                            }
                        }
                        .overlay(alignment: .bottomTrailing) {
                            if let power = current.powers[index] {
                                Image(systemName: power == 2 ? "sparkles" : power == 1 ? "arrow.left.and.right" : "arrow.up.and.down")
                                    .font(.caption.bold()).foregroundStyle(.white).padding(5).background(LinleyTheme.coralDeep, in: Circle())
                            }
                        }.aspectRatio(1, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected == index ? LinleyTheme.plum : hint.contains(index) ? Color.orange : .clear, lineWidth: 4))
                        .scaleEffect(selected == index ? 0.92 : 1)
                }.buttonStyle(.plain)
                    .disabled(animating || current.status != .playing)
                    .accessibilityElement(children: .ignore)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel("Row \(index / 6 + 1), column \(index % 6 + 1), \(MatchTileView.names[current.board[index]])")
                    .accessibilityIdentifier("matchCell-\(index)")
                    .accessibilityValue([selected == index ? "Selected" : hint.contains(index) ? "Hint" : "", current.frost[index].map { "\($0) frost layers" } ?? "", current.powers[index] != nil ? "Power ready: tap to activate" : ""].filter { !$0.isEmpty }.joined(separator: ", "))
                    .gesture(DragGesture(minimumDistance: 20).onEnded { value in
                        guard !animating, current.status == .playing else { return }
                        let dx = value.translation.width, dy = value.translation.height
                        let other = abs(dx) > abs(dy) ? index + (dx > 0 ? 1 : -1) : index + (dy > 0 ? 6 : -6)
                        swap(index, other)
                    })
            }
        }.padding(10).background(Color(red: 0.17, green: 0.34, blue: 0.38), in: RoundedRectangle(cornerRadius: 22))
        if !animating && current.status != .playing {
            if current.status == .won { AvatarVictoryView() }
            Text(current.status == .won ? "Garden cleared!" : "Try a fresh board").font(.title.bold()).accessibilityIdentifier("matchResult")
            Text(current.status == .won ? "Your Linley Coins are saved. Spend them on art packs or keep playing!" : "Out of moves. Retry free, or choose another game. Your coins are safe.")
            if current.status == .won && current.level + 1 < MatchLevel.all.count {
                Button("Next level") {
                    begin(current.level + 1)
                }.buttonStyle(LinleyPrimaryButtonStyle()).accessibilityIdentifier("matchNext")
            }
            Button("Play level again") { begin(current.level) }
                .accessibilityIdentifier("matchReplay")
            Button("Choose a level") { game.endMatch(); resetPresentation() }
        } else {
            Text(message).font(.subheadline).accessibilityIdentifier("matchMessage")
            HStack {
                Button("Show a match") { hint = current.powers.keys.sorted().first.map { Set([$0]) } ?? Set(MatchEngine.hint(current.board) ?? []); selected = nil }
                    .accessibilityIdentifier("matchHint")
                Spacer()
                Button("Restart level") { restart = true }.accessibilityIdentifier("matchRestart")
            }.disabled(animating)
            Text("Leaving saves this board. Retries are always free.").font(.caption).foregroundStyle(.secondary)
        }
    }

    private func levelGoal(_ level: MatchLevel) -> String {
        var goals: [String] = []
        if let kind = level.collectKind { goals.append("Collect \(level.collectGoal) \(MatchTileView.names[kind])") }
        if !level.frost.isEmpty { goals.append("Clear \(level.frost.values.reduce(0,+)) frost layers") }
        return goals.isEmpty ? "Score challenge" : goals.joined(separator: " · ")
    }
    private func begin(_ level: Int) {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--quest-ui-tests") {
            if game.startMatch(level: level, seed: 1) { resetPresentation() }
            return
        }
        #endif
        if game.startMatch(level: level) { resetPresentation() }
    }
    private func resetPresentation() {
        selected = nil; hint = []; frames = nil
        message = "Tap a gem, then a neighbor. Match 3 or more in a row."
    }
    private func cancelAnimation() {
        animation?.cancel(); animation = nil; animating = false; frames = nil; selected = nil; hint = []
    }
    private func tap(_ index: Int) {
        guard !animating, session?.status == .playing else { return }
        if session?.powers[index] != nil { swap(index,index); return }
        if let first = selected, MatchEngine.adjacent(first, index) { swap(first, index) }
        else { selected = selected == index ? nil : index; hint = [] }
    }
    private func swap(_ a: Int, _ b: Int) {
        guard !animating, session?.status == .playing else { return }
        selected = nil; hint = []
        guard let turn = game.swapMatch(a,b) else {
            message = "Try a neighboring swap that makes three in a row. No move used."
            audio.play("quest-step.wav"); return
        }
        message = turn.reshuffled ? "No swaps left — a fresh board, free!" : turn.cascades > 1 ? "\(turn.cascades)× cascade! Keep the colors flowing." : "Lovely match!"
        audio.play(turn.session.status == .won ? "quest-win.wav" : "quest-collect.wav")
        guard !reduceMotion else { return }
        animating = true; frames = turn.frames.first
        animation = Task { @MainActor in
            // Keep interaction pauses short even when the engine resolves a long chain.
            let visibleFrames = Array(turn.frames.dropFirst().prefix(5)) + [turn.session.board]
            for frame in visibleFrames {
                do { try await Task.sleep(for: .milliseconds(110)) } catch { return }
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.10)) { frames = frame }
            }
            do { try await Task.sleep(for: .milliseconds(110)) } catch { return }
            frames = nil; animating = false; animation = nil
        }
    }
}
