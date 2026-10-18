import SwiftUI
import AVFoundation

struct GamesView: View {
    @EnvironmentObject private var game: QuestStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Choose your game").font(.largeTitle.bold())
                AvatarLibraryCard()
                Text("Play your favorites. Earn Linley Coins. Unlock art supplies in the Creative Shop.").foregroundStyle(.secondary)
                NavigationLink { DressUpView() } label: {
                    VStack(alignment:.leading,spacing:12) {
                        Label("Style Studio",systemImage:"tshirt.fill").font(.title.bold())
                        Text("Dress up • Try hair • Private photo avatar • Your Lookbook")
                        Text("Style missions earn coins. Unlock your next favorite look.").font(.headline)
                    }.foregroundStyle(.white).padding(24).frame(maxWidth:.infinity,alignment:.leading)
                        .background(LinearGradient(colors:[LinleyTheme.plum,LinleyTheme.coralDeep],startPoint:.topLeading,endPoint:.bottomTrailing),in:RoundedRectangle(cornerRadius:28))
                }.accessibilityIdentifier("playDressUp")
                NavigationLink { MatchGameView() } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Gem Garden · Match-3", systemImage: "diamond.fill").font(.title.bold())
                        Text("20 levels • Clear frost • Collect gems • Earn rockets")
                        Text("Win boards. Earn coins for your creations.").font(.headline)
                    }.foregroundStyle(.white).padding(24).frame(maxWidth: .infinity, alignment: .leading)
                        .background(LinearGradient(colors: [Color(red: 0.13, green: 0.49, blue: 0.47), LinleyTheme.plum], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 28))
                }.accessibilityIdentifier("playMatch3")
                NavigationLink { ChaseHubView() } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Puzzle Chase", systemImage: "puzzlepiece.extension.fill").font(.title.bold())
                        Text("20 levels • Frost pulses • Keys • Crates • Relay gates")
                        Text("Play the challenge").font(.headline)
                    }.foregroundStyle(.white).padding(24).frame(maxWidth: .infinity, alignment: .leading)
                        .background(LinleyTheme.plum, in: RoundedRectangle(cornerRadius: 28))
                }.accessibilityIdentifier("playPuzzleChase")
                NavigationLink { CreativeQuestView() } label: {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            QuestHeroView(hero: QuestHero()).frame(width: 95, height: 120)
                            Spacer()
                            Image(systemName: "paintpalette.fill").font(.system(size: 55)).rotationEffect(.degrees(14))
                            Image(systemName: "sparkles").font(.title)
                        }
                        Text("Creative Quest").font(.largeTitle.bold())
                        Text("Find art supplies. Finish an adventure to earn 100 Linley Coins and a sticker.").font(.title3)
                        Label("Let's play", systemImage: "play.fill").font(.headline)
                    }
                    .foregroundStyle(.white).padding(26)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(LinleyTheme.heroGradient, in: RoundedRectangle(cornerRadius: 28))
                }.buttonStyle(.plain).accessibilityIdentifier("playCreativeQuest")
                CoinBalanceView()
                if let notice = game.recoveryNotice { Text(notice).font(.footnote).foregroundStyle(.secondary) }
                NavigationLink("Visit the Creative Shop") { CreativeShopView() }
                Label("Free to play • No ads or real money", systemImage: "heart.fill").font(.subheadline)
            }.padding(24).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.background(LinleyTheme.pageGradient).navigationTitle("Games")
    }
}

struct CreativeQuestView: View {
    @EnvironmentObject private var game: QuestStore
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var audio = QuestAudio()
    @State private var showAudio = false
    @State private var hint: Set<QuestCell> = []
    @State private var walking: Task<Void, Never>?
    @State private var showHero = false
    @State private var showStickers = false
    @State private var restart = false
    @State private var lastSupply = "Find five supplies. Collect three stars first for an optional badge."
    private let gardens = ["Coral Garden", "Blue Daydream", "Sunshine Studio", "Mint Meadow"]
    private var garden: String { gardens[game.progress.round % gardens.count] }
    private var accent: Color { QuestHeroView.outfits[game.progress.round % 4] }
    var body: some View {
        VStack(spacing: 12) {
            if game.loadError {
                ContentUnavailableView("Game progress couldn't open", systemImage: "exclamationmark.triangle", description: Text("Your saved game has been kept. You can reset just this game; your photos and videos stay safe."))
                Button("Reset game progress", role: .destructive) { restart = true }
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(garden).font(.title3.bold())
                        Text("Adventure \(game.progress.round + 1)").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Label("\(game.progress.collected.count)/5", systemImage: "paintbrush.pointed.fill")
                        .font(.title3.bold()).accessibilityLabel("\(game.progress.collected.count) of 5 supplies collected").accessibilityIdentifier("questSupplyCount")
                }.padding(.horizontal, 20)
                HStack {
                    CoinBalanceView()
                    Button { stopWalking(); showAudio = true } label: { Image(systemName: "speaker.wave.2.fill").padding(12) }
                        .accessibilityLabel("Game Sound").accessibilityIdentifier("questAudioSettings")
                }
                HStack {
                    Label("Stars \(game.progress.gardenStars.count)/3", systemImage: "star.fill")
                    Spacer()
                    Label("Badges \(game.progress.explorerBadges.count)/4", systemImage: "rosette")
                    Button("Hint") { showHint() }.disabled(game.progress.complete)
                }.font(.caption.bold()).padding(.horizontal, 20)
                Text(game.progress.complete ? "You made it! +100 Linley Coins and a sticker for your board." : lastSupply)
                    .font(.subheadline).multilineTextAlignment(.center).frame(minHeight: 36)
                    .accessibilityAddTraits(.updatesFrequently)
                    .padding(.horizontal, 16)
                board
                    .overlay(alignment: .top) {
                        if game.progress.complete {
                            VStack { AvatarVictoryView(); Label("Adventure complete!", systemImage: "sparkles") }
                                .font(.headline).padding(14).background(.regularMaterial, in: Capsule())
                                .allowsHitTesting(false).transition(.scale.combined(with: .opacity))
                        }
                    }
                HStack(spacing: 20) {
                    VStack(spacing: 12) {
                        Button { stopWalking(); showHero = true } label: { Label("My Hero", systemImage: "person.crop.circle.fill") }
                        Button { stopWalking(); showStickers = true } label: { Label("Sticker Board", systemImage: "square.grid.2x2.fill") }
                    }.font(.subheadline.bold())
                    Spacer(minLength: 0)
                    VStack(spacing: 4) {
                        direction("arrow.up", label: "Move up", dx: 0, dy: -1)
                        HStack(spacing: 4) {
                            direction("arrow.left", label: "Move left", dx: -1, dy: 0)
                            direction("arrow.down", label: "Move down", dx: 0, dy: 1)
                            direction("arrow.right", label: "Move right", dx: 1, dy: 0)
                        }
                    }
                }.padding(.horizontal, 20)
                if game.progress.complete {
                    NavigationLink("Use coins in the Creative Shop") { CreativeShopView() }
                    Button("Next adventure") { hint = []; game.nextAdventure(); lastSupply = "A new color, another creative adventure." }
                        .buttonStyle(LinleyPrimaryButtonStyle())
                } else {
                    Button("Restart this adventure") { stopWalking(); restart = true }.font(.caption)
                }
            }
        }
        .padding(.vertical, 8).frame(maxWidth: 800).frame(maxWidth: .infinity)
        .background(LinleyTheme.pageGradient)
        .navigationTitle("Creative Quest").navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAudio) { QuestAudioSettings(audio: audio) }
        .sheet(isPresented: $showHero) { QuestHeroEditor(game: game) }
        .sheet(isPresented: $showStickers) { QuestStickerBoard(game: game) }
        .confirmationDialog(game.loadError ? "Reset this game's progress, coins and art packs?" : "Restart this adventure? Your coins, art packs and stickers stay.", isPresented: $restart, titleVisibility: .visible) {
            Button(game.loadError ? "Reset game" : "Restart", role: .destructive) {
                hint = []
                if game.loadError { game.resetUnreadableGame() } else { game.restartAdventure() }
                lastSupply = "Find five supplies. Collect three stars first for an optional badge."
            }
        }
        .onAppear { audio.setVisible(phase == .active && !game.loadError) }
        .onDisappear { stopWalking(); audio.setVisible(false) }
        .onChange(of: phase) { _, next in
            if next != .active { stopWalking() }
            audio.setVisible(next == .active && !game.loadError)
        }
        .onChange(of: game.loadError) { _, failed in audio.setVisible(!failed && phase == .active) }
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { audio.interrupt($0) }
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)) { audio.routeChanged($0) }
        .sensoryFeedback(.success, trigger: game.progress.complete)
        .sensoryFeedback(.selection, trigger: game.progress.gardenStars.count)
    }

    private var board: some View {
        GeometryReader { geometry in
            let tile = max(4, min((geometry.size.width - 24) / 7, geometry.size.height / 9))
            ZStack(alignment: .topLeading) {
                ForEach(0..<63, id: \.self) { index in
                    let cell = QuestCell(x: index % 7, y: index / 7)
                    let obstacle = QuestMap.obstacles(for: game.progress.variant).contains(cell)
                    let supply = QuestMap.supplies(for: game.progress.variant).first { $0.cell == cell && !game.progress.collected.contains($0.id) }
                    let star = QuestMap.stars(for: game.progress.variant).firstIndex(of: cell)
                    let hiddenStar = star.map { !game.progress.gardenStars.contains($0) } ?? false
                    Button { walk(to: cell) } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: tile * 0.15)
                                .fill(obstacle ? LinleyTheme.mint.opacity(0.65) : ((cell.x + cell.y) % 2 == 0 ? Color.white : accent.opacity(0.15)))
                            RoundedRectangle(cornerRadius: tile * 0.15)
                                .stroke(accent.opacity(0.18), lineWidth: 1)
                            if obstacle {
                                Image(systemName: "leaf.fill").foregroundStyle(Color(red: 0.17, green: 0.44, blue: 0.36))
                            } else if let supply {
                                Image(systemName: supply.symbol).font(.system(size: tile * 0.43, weight: .bold))
                                    .foregroundStyle(accent)
                            } else if hiddenStar {
                                Image(systemName: "star.circle.fill").font(.system(size: tile * 0.5)).foregroundStyle(LinleyTheme.gold)
                            } else if (cell.x * 3 + cell.y) % 9 == 0 {
                                Image(systemName: "sparkle").font(.caption).foregroundStyle(LinleyTheme.orange.opacity(0.5))
                            }
                            if hint.contains(cell) {
                                RoundedRectangle(cornerRadius: tile * 0.15).stroke(LinleyTheme.gold, lineWidth: 3)
                            }
                        }.frame(width: tile - 3, height: tile - 3)
                    }
                    .buttonStyle(.plain).disabled(obstacle || game.progress.complete)
                    .accessibilityIdentifier("questCell-\(cell.x)-\(cell.y)")
                    .accessibilityLabel(supply.map { "\($0.name), row \(cell.y + 1), column \(cell.x + 1)" } ?? "\(obstacle ? "Plant" : hiddenStar ? "Garden star" : "Garden path"), row \(cell.y + 1), column \(cell.x + 1)")
                    .offset(x: CGFloat(cell.x) * tile, y: CGFloat(cell.y) * tile)
                }
                GameAvatarHero()
                    .frame(width: tile * 0.86, height: tile * 1.13)
                    .offset(x: CGFloat(game.progress.position.x) * tile + tile * 0.04, y: CGFloat(game.progress.position.y) * tile - tile * 0.22)
                    .scaleEffect(game.progress.complete && !reduceMotion ? 1.12 : 1)
                    .animation(reduceMotion ? nil : .spring(duration: 0.4), value: game.progress.complete)
                    .allowsHitTesting(false)
                    .accessibilityLabel("Your hero, row \(game.progress.position.y + 1), column \(game.progress.position.x + 1)")
            }
            .frame(width: tile * 7, height: tile * 9, alignment: .topLeading)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }.padding(.horizontal, 12)
    }

    private func direction(_ symbol: String, label: String, dx: Int, dy: Int) -> some View {
        Button { stopWalking(); step(game.progress.position.offset(dx, dy)) } label: {
            Image(systemName: symbol).font(.headline.bold()).frame(width: 44, height: 44)
                .background(LinleyTheme.sky.opacity(0.22), in: RoundedRectangle(cornerRadius: 14))
        }.accessibilityLabel(label).disabled(game.progress.complete || game.loadError)
    }
    private func step(_ cell: QuestCell) {
        let before = game.progress.collected
        let starsBefore = game.progress.gardenStars
        let positionBefore = game.progress.position
        hint = []
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.14)) { game.move(to: cell) }
        if game.progress.collected != before, let item = QuestMap.supplies(for: game.progress.variant).first(where: { $0.cell == cell }) {
            lastSupply = "Found \(item.name.lowercased())! Keep exploring."
            audio.play(game.progress.complete ? "quest-win.wav" : "quest-collect.wav")
        } else if game.progress.gardenStars != starsBefore {
            lastSupply = game.progress.gardenStars.count == 3 ? "Explorer badge earned! Finish finding your art supplies." : "A garden star! Find three before your last supply for an explorer badge."
            audio.play("quest-star.wav")
        } else if game.progress.position != positionBefore { audio.play("quest-step.wav") }

    }
    private func walk(to target: QuestCell) {
        stopWalking()
        let path = QuestMap.route(from: game.progress.position, to: target, variant: game.progress.variant)
        walking = Task { @MainActor in
            for cell in path {
                guard !Task.isCancelled, !game.progress.complete else { return }
                step(cell)
                do { try await Task.sleep(for: .milliseconds(reduceMotion ? 30 : 165)) } catch { return }
            }
        }
    }
    private func showHint() {
        stopWalking()
        guard let next = QuestMap.supplies(for: game.progress.variant).first(where: { !game.progress.collected.contains($0.id) }) else { return }
        hint = Set(QuestMap.route(from: game.progress.position, to: next.cell, variant: game.progress.variant))
        lastSupply = "Follow the golden path to the \(next.name.lowercased())."
    }
    private func stopWalking() { walking?.cancel(); walking = nil }
}

struct QuestHeroView: View {
    let hero: QuestHero
    static let skin: [Color] = [Color(red: 0.99, green: 0.83, blue: 0.70), Color(red: 0.85, green: 0.62, blue: 0.43), Color(red: 0.62, green: 0.38, blue: 0.25), Color(red: 0.38, green: 0.23, blue: 0.17)]
    static let hair: [Color] = [Color(red: 0.96, green: 0.77, blue: 0.36), Color(red: 0.29, green: 0.16, blue: 0.13), Color(red: 0.10, green: 0.09, blue: 0.15), Color(red: 0.65, green: 0.28, blue: 0.17)]
    static let outfits = [LinleyTheme.coralDeep, LinleyTheme.sky, LinleyTheme.orange, LinleyTheme.mint]
    var body: some View {
        Group {
            if hero.character == .custom {
                drawnHero
            } else {
                Image(hero.character == .lorelei ? "QuestLorelei" : "QuestHailey")
                    .resizable().scaledToFit()
                    .accessibilityLabel("\(hero.character.title) illustrated game character")
            }
        }
    }
    private var drawnHero: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Ellipse().fill(.black.opacity(0.12)).frame(width: w * 0.75, height: h * 0.08).offset(y: h * 0.43)
                RoundedRectangle(cornerRadius: w * 0.23).fill(Self.hair[hero.hair])
                    .frame(width: w * 0.83, height: h * (hero.longHair ? 0.63 : 0.40)).offset(y: -h * 0.12)
                Capsule().fill(LinleyTheme.plum).frame(width: w * 0.21, height: h * 0.27).offset(x: -w * 0.16, y: h * 0.30)
                Capsule().fill(LinleyTheme.plum).frame(width: w * 0.21, height: h * 0.27).offset(x: w * 0.16, y: h * 0.30)
                RoundedRectangle(cornerRadius: w * 0.16).fill(Self.outfits[hero.outfit]).frame(width: w * 0.70, height: h * 0.35).offset(y: h * 0.11)
                Circle().fill(Self.skin[hero.skin]).frame(width: w * 0.64).offset(y: -h * 0.19)
                Capsule().fill(Self.hair[hero.hair]).frame(width: w * 0.68, height: h * 0.12).rotationEffect(.degrees(-12)).offset(y: -h * 0.35)
                HStack(spacing: w * 0.18) {
                    Circle().frame(width: w * 0.055)
                    Circle().frame(width: w * 0.055)
                }.foregroundStyle(LinleyTheme.plum).offset(y: -h * 0.18)
                Image(systemName: "heart.fill").font(.system(size: w * 0.18)).foregroundStyle(.white).offset(y: h * 0.10)
            }.frame(width: w, height: h)
        }
        .accessibilityElement(children: .ignore).accessibilityLabel("Customizable creative hero")
    }
}

struct QuestHeroEditor: View {
    @ObservedObject var game: QuestStore
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Section { QuestHeroView(hero: game.progress.hero).frame(width: 140, height: 180).frame(maxWidth: .infinity) }
                Section("Choose your hero") {
                    Picker("Character", selection: Binding(get: { game.progress.hero.character }, set: { selected in
                        var hero = game.progress.hero; hero.character = selected; game.setHero(hero)
                    })) {
                        ForEach(QuestCharacter.allCases, id: \.self) { Text($0.title).tag($0) }
                    }.accessibilityIdentifier("questCharacterPicker")
                }
                Section("Make your own") {
                    Text("These style controls switch to a custom hero. Choose Lorelei or Hailey above to use their illustrated character.").font(.caption)
                    choice("Skin tone", value: game.progress.hero.skin, names: ["Light", "Warm", "Brown", "Deep"]) { hero, value in hero.skin = value }
                    choice("Hair color", value: game.progress.hero.hair, names: ["Golden", "Brown", "Black", "Auburn"]) { hero, value in hero.hair = value }
                    choice("Outfit", value: game.progress.hero.outfit, names: ["Coral", "Blue", "Orange", "Mint"]) { hero, value in hero.outfit = value }
                    Toggle("Long hair", isOn: Binding(get: { game.progress.hero.longHair }, set: { value in
                        var hero = game.progress.hero; hero.character = .custom; hero.longHair = value; game.setHero(hero)
                    }))
                }
                Section { Text("Make a character that feels like you. Your hero and game progress stay on this device.").font(.footnote) }
            }.navigationTitle("My Hero").toolbar { Button("Done") { dismiss() } }
        }
    }
    private func choice(_ title: String, value: Int, names: [String], change: @escaping (inout QuestHero, Int) -> Void) -> some View {
        Picker(title, selection: Binding(get: { value }, set: { value in
            var hero = game.progress.hero; hero.character = .custom; change(&hero, value); game.setHero(hero)
        })) {
            ForEach(names.indices, id: \.self) { Text(names[$0]).tag($0) }
        }
    }
}

struct QuestStickerBoard: View {
    @ObservedObject var game: QuestStore
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Little wins. Big creativity.").font(.title.bold())
                    Text("Find all five supplies in each adventure to earn a sticker. Collect all eight!").foregroundStyle(.secondary)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 130))], spacing: 18) {
                        ForEach(QuestMap.stickerSymbols.indices, id: \.self) { index in
                            let earned = game.progress.stickers.contains(index)
                            VStack(spacing: 14) {
                                Image(systemName: earned ? QuestMap.stickerSymbols[index] : "lock.fill")
                                    .font(.system(size: 44)).foregroundStyle(earned ? QuestHeroView.outfits[index % 4] : .gray)
                                Text(earned ? QuestMap.stickerNames[index] : "Keep exploring")
                                    .font(.subheadline.bold()).multilineTextAlignment(.center)
                            }.padding(20).frame(maxWidth: .infinity, minHeight: 150)
                                .background(.white, in: RoundedRectangle(cornerRadius: 24))
                                .rotationEffect(.degrees(earned ? (index % 2 == 0 ? -3 : 3) : 0))
                        }
                    }
                    Text("\(game.progress.stickers.count) of 8 stickers collected").font(.headline)
                }.padding(24).frame(maxWidth: 760).frame(maxWidth: .infinity)
            }.background(LinleyTheme.pageGradient).navigationTitle("Sticker Board")
                .toolbar { Button("Done") { dismiss() } }
        }
    }
}
