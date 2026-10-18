import SwiftUI
import AVFoundation

struct ChaseLivesView: View {
    @EnvironmentObject private var game: QuestStore
    @State private var buy = false
    @State private var error = false
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label("\(game.progress.chase.lives)/5 lives", systemImage: "heart.fill")
                    .foregroundStyle(LinleyTheme.coralDeep).accessibilityIdentifier("chaseLives")
                Spacer()
                CoinBalanceView()
            }
            TimelineView(.periodic(from: .now, by: 1)) { context in
                HStack {
                    if let deadline = game.progress.chase.nextLifeAt {
                        Text("Next life in")
                        Text(deadline, style: .timer).monospacedDigit()
                    } else { Text("Lives are full") }
                    Spacer()
                    Button("1 life · 100 coins") { buy = true }
                        .accessibilityIdentifier("buyChaseLife")
                        .disabled(game.loadError || game.progress.chase.lives >= 5 || game.progress.coins < 100)
                }.font(.caption)
                    .onChange(of: context.date) { _, date in game.refreshLives(at: date) }
            }
        }.onAppear { game.refreshLives() }
            .confirmationDialog("Use 100 earned coins for one life?", isPresented: $buy, titleVisibility: .visible) {
                Button("Use 100 coins for 1 life") { error = !game.buyChaseLife() }
                Button("Cancel", role: .cancel) { }
            } message: { Text("No real money. One life also returns free every 20 minutes, up to five. Practice is always available.") }
            .alert("Life refill", isPresented: $error) { Button("OK") { } } message: { Text("Your balance or lives changed. No coins were spent.") }
    }
}

struct ChaseHubView: View {
    @EnvironmentObject private var game: QuestStore
    @State private var practice = false
    @State private var openGame = false
    @State private var abandon = false
    private var active: Bool { game.progress.chase.session?.status == .playing }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Puzzle Chase").font(.largeTitle.bold())
                Text("Plan your moves. Outsmart the ink creatures. Push crates, open gates and escape with every paint drop.")
                ChaseLivesView()
                DisclosureGroup("How to play") {
                    Text("Move one square with the arrows or tap a neighboring square. Wait takes a turn without moving. Creatures move when their turn counter reaches zero. Purple blots chase you; workshop cog creatures can patrol. Push orange crates onto ring plates and step on lightning switches to open gates. Blue portals jump to their partner. Collect all paint drops, open the gate and reach the flag before your moves run out. Getting caught or running out of moves loses one life in Challenge. Frost tiles are safe on turns 0–1 of each four-turn cycle and hot on turns 2–3; check the next-turn forecast and wait on safe ground. Collect every gold key to open key doors. Relay switches flip the gate on each entry, so plan your return route. Practice never uses lives.")
                        .font(.footnote).padding(.vertical, 8)
                }
                if game.loadError {
                    Text("Saved progress couldn't open. Your saved data has been kept; recover it in Creative Quest before starting a challenge.")
                } else if active {
                    Button("Resume level \((game.progress.chase.session?.level ?? 0) + 1)") { openGame = true }
                        .buttonStyle(LinleyPrimaryButtonStyle()).accessibilityIdentifier("resumeChase")
                    Button("End this attempt", role: .destructive) { abandon = true }
                    Text("Leaving the game pauses it. Ending a challenge attempt uses one life; Practice uses none.").font(.caption)
                } else {
                    Toggle("Practice · no lives, coins or level unlocks", isOn: $practice).accessibilityIdentifier("chasePractice")
                    if game.progress.chase.lives == 0 {
                        Text("Out of lives? Turn on Practice, visit Creative Quest, use earned coins, or wait for a free refill.").font(.subheadline)
                    }
                    ForEach(0..<4, id: \.self) { world in
                        Text(["1 · Ink Garden", "2 · Clockwork Workshop", "3 · Frost Archive", "4 · Relay Observatory"][world]).font(.title2.bold())
                        Text(["Chasing creatures, switches and crate gates", "Portals and a patrolling cog creature", "Timed frost pulses and keys to find", "Toggle relays, key doors and mixed puzzles"][world]).font(.caption)
                        ForEach((world * 5)..<(world * 5 + 5), id: \.self) { index in
                            let cleared = game.progress.chase.cleared.contains(index)
                            let allowed = practice || index <= game.progress.chase.unlocked
                            Button {
                                if game.startChase(level: index, practice: practice) { openGame = true }
                            } label: {
                                HStack {
                                    Image(systemName: cleared ? "checkmark.seal.fill" : allowed ? "flag.fill" : "lock.fill")
                                    Text("\(index + 1). \(ChaseLevel.all[index].name)")
                                    Spacer()
                                    Text(practice ? "Practice" : cleared ? "Replay +100" : index % 5 == 4 ? "+200" : "+100")
                                }.font(.subheadline.bold()).padding(16)
                                    .background(.white, in: RoundedRectangle(cornerRadius: 18))
                            }.disabled(game.loadError || !allowed || (!practice && game.progress.chase.lives == 0))
                                .accessibilityIdentifier("chaseLevel-\(index)")
                        }
                    }
                }
                Text("Challenge wins earn 100 coins. First clears of every fifth level earn 200. Practice has no lives or rewards. Coins stay shared with your creative studio.")
                    .font(.footnote).foregroundStyle(.secondary)
            }.padding(22).frame(maxWidth: 850).frame(maxWidth: .infinity)
        }.background(LinleyTheme.pageGradient).navigationTitle("Puzzle Chase")
            .navigationDestination(isPresented: $openGame) { ChaseGameView() }
            .confirmationDialog("End this attempt?", isPresented: $abandon, titleVisibility: .visible) {
                Button("End attempt", role: .destructive) { game.abandonChase() }
                Button("Keep playing", role: .cancel) { }
            } message: { Text("A challenge loses one life. Practice costs no lives. Your coins and cleared levels stay.") }
    }
}

struct ChaseGameView: View {
    @EnvironmentObject private var game: QuestStore
    @Environment(\.scenePhase) private var phase
    @Environment(\.dismiss) private var dismiss
    @StateObject private var audio = QuestAudio()
    @State private var showAudio = false
    @State private var restart = false
    var body: some View {
        VStack(spacing: 12) {
            AvatarPlayerCard()
            if let session = game.progress.chase.session {
                let board = ChaseLevel.all[session.level]
                HStack {
                    VStack(alignment: .leading) {
                        Text("Level \(session.level + 1) · \(board.name)").font(.headline)
                        Text(session.practice ? "Practice · no lives or rewards" : board.chapter).font(.caption)
                    }
                    Spacer()
                    Button { showAudio = true } label: { Image(systemName: "speaker.wave.2.fill").padding(12) }.accessibilityLabel("Game Sound")
                }
                HStack {
                    Label("\(session.collected.intersection(board.positions("k")).count)/\(board.positions("k").count) drops", systemImage: "drop.fill")
                    Spacer()
                    Label("\(game.progress.chase.lives)", systemImage: "heart.fill")
                    Text("\(max(0, board.moveLimit - session.turns)) moves left").monospacedDigit()
                }.font(.subheadline.bold())
                Text(session.reason).font(.caption).frame(minHeight: 34).accessibilityIdentifier("chaseMessage")
                if !board.positions("g").isEmpty {
                    Text(ChaseEngine.gatesOpen(session) ? "Gate open — collect every drop and reach the flag" : (!board.positions("r").isEmpty ? false : board.positions("t").isEmpty) ? "Push a crate onto each ring plate to open the gate" : board.positions("o").isEmpty ? (!board.positions("r").isEmpty ? "Relay switches flip the gate each time you enter" : "Step on the lightning switch to open the gate") : "Use the switch AND keep a crate on each ring plate")
                        .font(.caption.bold())
                }
                if !board.positions("h").isEmpty || !board.positions("q").isEmpty {
                    HStack {
                        if !board.positions("h").isEmpty {
                            Label(ChaseEngine.hazardActive(turn: session.turns + 1) ? "Next turn: frost HOT" : "Next turn: frost safe", systemImage: "snowflake")
                                .accessibilityIdentifier("chaseHazardForecast")
                        }
                        Spacer()
                        if !board.positions("q").isEmpty {
                            Label("\(session.collected.intersection(board.positions("q")).count)/\(board.positions("q").count) keys", systemImage: "key.fill")
                        }
                    }.font(.caption.bold())
                }
                chaseBoard(session, board)
                if session.status == .playing {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Creatures move every \(board.enemyPeriod) turns").font(.caption)
                            Text("Next move: \(board.enemyPeriod - session.turns % board.enemyPeriod)").font(.caption.bold())
                            Button("Restart attempt") { restart = true }.font(.caption)
                        }
                        Spacer()
                        VStack(spacing: 4) {
                            move("arrow.up", "Up", 0, -1)
                            HStack(spacing: 4) { move("arrow.left", "Left", -1, 0); move("hourglass", "Wait", 0, 0); move("arrow.right", "Right", 1, 0) }
                            move("arrow.down", "Down", 0, 1)
                        }
                    }
                } else {
                    Text(session.status == .won ? (session.practice ? "Practice complete!" : "Level cleared!") : "Try a new plan")
                        .font(.title2.bold()).accessibilityIdentifier("chaseResult")
                    if session.status == .won { AvatarVictoryView() }
                    if session.status == .won, !session.practice {
                        Text("Your reward is saved to the shared coin balance.").font(.caption)
                    }
                    ChaseLivesView()
                    HStack {
                        Button("Try again") {
                            _ = game.startChase(level: session.level, practice: session.practice)
                        }.disabled(!session.practice && session.status == .lost && game.progress.chase.lives == 0)
                        if !session.practice && session.status == .lost {
                            Button("Practice this level") { _ = game.startChase(level: session.level, practice: true) }
                        }
                        if session.status == .won, session.level + 1 < ChaseLevel.all.count {
                            Button("Next level") { _ = game.startChase(level: session.level + 1, practice: session.practice) }
                                .disabled(!session.practice && game.progress.chase.lives == 0)
                        }
                        Button("Levels") { dismiss() }
                    }.buttonStyle(.bordered)
                }
            } else { Text("Choose a level from Puzzle Chase.") }
        }.padding(16).frame(maxWidth: 900).frame(maxWidth: .infinity)
            .background(LinleyTheme.pageGradient).navigationTitle("Puzzle Chase").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAudio) { QuestAudioSettings(audio: audio) }
            .confirmationDialog("Restart this attempt?", isPresented: $restart, titleVisibility: .visible) {
                Button("Restart", role: .destructive) {
                    guard let session = game.progress.chase.session else { return }
                    game.abandonChase(); _ = game.startChase(level: session.level, practice: session.practice)
                }
                Button("Keep playing", role: .cancel) { }
            } message: { Text("A challenge uses one life when restarted. Practice is free.") }
            .onAppear { audio.setVisible(phase == .active) }
            .onDisappear { audio.setVisible(false) }
            .onChange(of: phase) { _, phase in audio.setVisible(phase == .active); game.refreshLives() }
            .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { audio.interrupt($0) }
            .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)) { audio.routeChanged($0) }
    }

    private func move(_ symbol: String, _ label: String, _ dx: Int, _ dy: Int) -> some View {
        Button { step(dx, dy) } label: {
            Image(systemName: symbol).frame(width: 44, height: 44)
                .background(LinleyTheme.sky.opacity(0.25), in: RoundedRectangle(cornerRadius: 12))
        }.accessibilityLabel(label).accessibilityIdentifier("chase-\(label)")
    }
    private func step(_ dx: Int, _ dy: Int) {
        let prior = game.progress.chase.session
        game.moveChase(dx: dx, dy: dy)
        guard let next = game.progress.chase.session, prior != next else { return }
        audio.play(next.status == .won ? "quest-win.wav" : next.collected != prior?.collected ? "quest-collect.wav" : "quest-step.wav")
    }
    private func chaseBoard(_ session: ChaseSession, _ board: ChaseLevel) -> some View {
        GeometryReader { geo in
            let tile = max(1, min(geo.size.width / 7, geo.size.height / 9))
            ZStack(alignment: .topLeading) {
                ForEach(0..<63, id: \.self) { index in
                    let cell = QuestCell(x: index % 7, y: index / 7)
                    let wall = !board.floor.contains(cell)
                    Button { step(cell.x - session.player.x, cell.y - session.player.y) } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: tile * 0.12)
                                .fill(wall ? LinleyTheme.plum.opacity(0.55) : (session.level < 5 ? LinleyTheme.mint.opacity(0.2) : LinleyTheme.sky.opacity(0.2)))
                            if board.positions("g").contains(cell) { icon(ChaseEngine.gatesOpen(session) ? "lock.open.fill" : "lock.fill", tile, LinleyTheme.orange) }
                            if board.positions("o").contains(cell) { icon("circle.inset.filled", tile, LinleyTheme.orange) }
                            if board.positions("t").contains(cell) { icon(session.switchOn ? "bolt.circle.fill" : "bolt.circle", tile, LinleyTheme.gold) }
                            if board.positions("h").contains(cell) { icon("snowflake", tile, ChaseEngine.hazardActive(turn: session.turns) ? LinleyTheme.coralDeep : LinleyTheme.sky) }
                            if board.positions("q").contains(cell), !session.collected.contains(cell) { icon("key.fill", tile, LinleyTheme.gold) }
                            if board.positions("d").contains(cell) { icon(ChaseEngine.doorsOpen(session) ? "door.left.hand.open" : "lock.rectangle.fill", tile, LinleyTheme.orange) }
                            if board.positions("r").contains(cell) { icon(session.switchOn ? "arrow.triangle.2.circlepath.circle.fill" : "arrow.triangle.2.circlepath.circle", tile, LinleyTheme.gold) }
                            if board.positions("@").contains(cell) { icon("circle.hexagongrid.fill", tile, LinleyTheme.sky) }
                            if board.positions("E").contains(cell) { icon("flag.checkered", tile, LinleyTheme.plum) }
                            if board.positions("k").contains(cell), !session.collected.contains(cell) { icon("drop.fill", tile, LinleyTheme.coralDeep) }
                            if session.crates.contains(cell) { icon("shippingbox.fill", tile, LinleyTheme.orange) }
                            if let enemy = session.enemies.firstIndex(of: cell) {
                                ZStack {
                                    if session.level >= 5 {
                                        Image(systemName: "gearshape.fill").resizable().scaledToFit().foregroundStyle(enemy == 0 ? LinleyTheme.sky : LinleyTheme.orange)
                                    } else {
                                        RoundedRectangle(cornerRadius: tile * 0.2).fill(enemy == 0 ? LinleyTheme.plum : LinleyTheme.sky)
                                    }
                                    HStack(spacing: tile * 0.1) { Circle().fill(.white); Circle().fill(.white) }.frame(width: tile * 0.4, height: tile * 0.1)
                                }.frame(width: tile * 0.7, height: tile * 0.65)
                            }
                        }.frame(width: max(1, tile - 3), height: max(1, tile - 3))
                    }.buttonStyle(.plain).disabled(wall || session.status != .playing)
                        .accessibilityIdentifier("chaseCell-\(cell.x)-\(cell.y)")
                        .accessibilityLabel(cellLabel(cell, session, board))
                        .offset(x: CGFloat(cell.x) * tile, y: CGFloat(cell.y) * tile)
                }
                GameAvatarHero().frame(width: tile * 0.8, height: tile * 0.8)
                    .offset(x: CGFloat(session.player.x) * tile, y: CGFloat(session.player.y) * tile - tile * 0.15)
                    .allowsHitTesting(false)
            }.frame(width: tile * 7, height: tile * 9, alignment: .topLeading).frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    private func icon(_ symbol: String, _ tile: CGFloat, _ color: Color) -> some View {
        Image(systemName: symbol).font(.system(size: tile * 0.45)).foregroundStyle(color)
    }
    private func cellLabel(_ cell: QuestCell, _ session: ChaseSession, _ board: ChaseLevel) -> String {
        var names: [String] = board.floor.contains(cell) ? [] : ["Wall"]
        if session.player == cell { names.append("Hero") }
        if session.enemies.contains(cell) { names.append("Ink creature") }
        if session.crates.contains(cell) { names.append("Pushable crate") }
        let legend: [(Character, String)] = [("g", "Gate"), ("o", "Pressure plate"), ("t", "Switch"), ("@", "Portal"), ("E", "Exit"), ("k", "Paint drop"), ("h", "Frost pulse: two cool then two hot turns"), ("q", "Collectible key"), ("d", "Key door"), ("r", "Toggle relay")]
        for (symbol, name) in legend {
            if board.positions(symbol).contains(cell) { names.append(symbol == "g" ? (ChaseEngine.gatesOpen(session) ? "Open gate" : "Closed gate") : name) }
        }
        return "\(names.isEmpty ? "Path" : names.joined(separator: ", ")), row \(cell.y + 1), column \(cell.x + 1)"
    }
}
