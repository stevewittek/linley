import Foundation
import SwiftUI

struct QuestSupply: Identifiable {
    let id: String
    let name: String
    let symbol: String
    let cell: QuestCell
}

enum QuestMap {
    static let columns = 7
    static let rows = 9
    static let start = QuestCell(x: 3, y: 8)
    static let obstacles: Set<QuestCell> = [
        .init(x: 2, y: 1), .init(x: 2, y: 2), .init(x: 4, y: 3),
        .init(x: 1, y: 4), .init(x: 2, y: 4), .init(x: 4, y: 5),
        .init(x: 5, y: 5), .init(x: 3, y: 7)
    ]
    static let supplies: [QuestSupply] = [
        .init(id: "brush", name: "Paintbrush", symbol: "paintbrush.pointed.fill", cell: .init(x: 1, y: 1)),
        .init(id: "palette", name: "Palette", symbol: "paintpalette.fill", cell: .init(x: 5, y: 1)),
        .init(id: "pencil", name: "Pencil", symbol: "pencil", cell: .init(x: 3, y: 3)),
        .init(id: "scissors", name: "Scissors", symbol: "scissors", cell: .init(x: 1, y: 6)),
        .init(id: "star", name: "Paper star", symbol: "star.fill", cell: .init(x: 5, y: 7))
    ]
    static let stickerSymbols = ["rainbow", "sparkles", "heart.fill", "camera.macro", "moon.stars.fill", "paperplane.fill", "sun.max.fill", "paintpalette.fill"]
    static let stickerNames = ["Rainbow maker", "Spark collector", "Made with heart", "Flower power", "Dream big", "Paper explorer", "Sunshine artist", "Color superstar"]

    static func transform(_ cell: QuestCell, variant: Int) -> QuestCell {
        .init(x: variant % 2 == 1 ? columns - 1 - cell.x : cell.x,
              y: variant >= 2 ? rows - 1 - cell.y : cell.y)
    }
    static func obstacles(for variant: Int) -> Set<QuestCell> {
        Set(obstacles.map { transform($0, variant: variant) })
    }
    static func supplies(for variant: Int) -> [QuestSupply] {
        supplies.map { .init(id: $0.id, name: $0.name, symbol: $0.symbol, cell: transform($0.cell, variant: variant)) }
    }
    static func stars(for variant: Int) -> [QuestCell] {
        [QuestCell(x: 0, y: 0), .init(x: 6, y: 4), .init(x: 0, y: 8)].map { transform($0, variant: variant) }
    }

    static func canEnter(_ cell: QuestCell, variant: Int = 0) -> Bool {
        (0..<columns).contains(cell.x) && (0..<rows).contains(cell.y) && !obstacles(for: variant).contains(cell)
    }

    /// Breadth-first pathfinding makes every reachable tile usable with a single tap.
    static func route(from start: QuestCell, to target: QuestCell, variant: Int = 0) -> [QuestCell] {
        guard canEnter(start, variant: variant), canEnter(target, variant: variant), start != target else { return [] }
        var queue = [start]
        var visited: Set<QuestCell> = [start]
        var previous: [QuestCell: QuestCell] = [:]
        var cursor = 0
        while cursor < queue.count {
            let current = queue[cursor]; cursor += 1
            for next in [current.offset(0, -1), current.offset(1, 0), current.offset(0, 1), current.offset(-1, 0)] {
                guard canEnter(next, variant: variant), visited.insert(next).inserted else { continue }
                previous[next] = current
                if next == target {
                    var path = [target]
                    var step = target
                    while let parent = previous[step], parent != start { path.append(parent); step = parent }
                    return path.reversed()
                }
                queue.append(next)
            }
        }
        return []
    }
}

enum QuestCharacter: String, Codable, CaseIterable {
    case lorelei, hailey, custom
    var title: String { switch self { case .lorelei: "Lorelei"; case .hailey: "Hailey"; case .custom: "Make my own" } }
}

struct QuestHero: Codable, Equatable {
    var skin = 1
    var hair = 1
    var outfit = 0
    var longHair = true
    var character = QuestCharacter.lorelei
    init() { }
    enum CodingKeys: String, CodingKey { case skin, hair, outfit, longHair, character }
    init(from decoder: Decoder) throws {
        let data = try decoder.container(keyedBy: CodingKeys.self)
        skin = try data.decode(Int.self, forKey: .skin)
        hair = try data.decode(Int.self, forKey: .hair)
        outfit = try data.decode(Int.self, forKey: .outfit)
        longHair = try data.decode(Bool.self, forKey: .longHair)
        // Earlier local prototype avatars had no character field; preserve that custom look.
        character = try data.decodeIfPresent(QuestCharacter.self, forKey: .character) ?? .custom
    }
}

struct QuestProgress: Codable {
    var round = 0
    var position = QuestMap.start
    var collected: Set<String> = []
    var stickers: Set<Int> = []
    var hero = QuestHero()
    var coins = 0
    var coinsEarned = 0
    var ownedPacks: Set<String> = []
    var mapVersion = 1
    var gardenStars: Set<Int> = []
    var explorerBadges: Set<Int> = []
    var chase = ChaseProgress()
    var match = MatchProgress()
    var wardrobe: Set<String> = []
    var styleBriefs: Set<Int> = []
    var variant: Int { mapVersion == 0 ? 0 : round % 4 }
    var complete: Bool { collected.count == QuestMap.supplies.count }

    init() { }
    enum CodingKeys: String, CodingKey { case round, position, collected, stickers, hero, coins, coinsEarned, ownedPacks, mapVersion, gardenStars, explorerBadges, chase, match, wardrobe, styleBriefs }
    init(from decoder: Decoder) throws {
        let data = try decoder.container(keyedBy: CodingKeys.self)
        round = try data.decode(Int.self, forKey: .round)
        position = try data.decode(QuestCell.self, forKey: .position)
        collected = try data.decode(Set<String>.self, forKey: .collected)
        stickers = try data.decode(Set<Int>.self, forKey: .stickers)
        hero = try data.decode(QuestHero.self, forKey: .hero)
        // Preserve the old layout for an adventure already in progress.
        mapVersion = try data.decodeIfPresent(Int.self, forKey: .mapVersion) ?? 0
        gardenStars = try data.decodeIfPresent(Set<Int>.self, forKey: .gardenStars) ?? []
        explorerBadges = try data.decodeIfPresent(Set<Int>.self, forKey: .explorerBadges) ?? []
        chase = try data.decodeIfPresent(ChaseProgress.self, forKey: .chase) ?? ChaseProgress()
        match = try data.decodeIfPresent(MatchProgress.self, forKey: .match) ?? MatchProgress()
        wardrobe = try data.decodeIfPresent(Set<String>.self, forKey: .wardrobe) ?? []
        styleBriefs = try data.decodeIfPresent(Set<Int>.self, forKey: .styleBriefs) ?? []
        // Old adventures retain their hero/stickers without claiming a new completion reward.
        if data.contains(.coins) || data.contains(.coinsEarned) || data.contains(.ownedPacks) {
            coins = try data.decode(Int.self, forKey: .coins)
            coinsEarned = try data.decode(Int.self, forKey: .coinsEarned)
            ownedPacks = try data.decode(Set<String>.self, forKey: .ownedPacks)
        }
    }
}

struct CreativePack: Identifiable {
    let id: String
    let title: String
    let cost: Int
    let symbols: [String]
    static let catalog = [
        CreativePack(id: "garden", title: "Garden Party", cost: 100, symbols: ["leaf.fill", "camera.macro", "sun.max.fill"]),
        CreativePack(id: "dream", title: "Dream Studio", cost: 200, symbols: ["moon.stars.fill", "cloud.fill", "sparkles"]),
        CreativePack(id: "maker", title: "Maker Magic", cost: 300, symbols: ["paintpalette.fill", "paintbrush.pointed.fill", "scissors"])
    ]
}

@MainActor
final class QuestStore: ObservableObject {
    @Published private(set) var progress = QuestProgress()
    @Published private(set) var loadError = false
    @Published private(set) var recoveryNotice: String?
    private let defaults: UserDefaults
    private let key = "linley.creativeQuest.v1"

    init(defaults: UserDefaults = .standard) {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--quest-ui-tests"),
           let isolated = UserDefaults(suiteName: "linley.quest.ui-tests") {
            isolated.removePersistentDomain(forName: "linley.quest.ui-tests")
            self.defaults = isolated
        } else { self.defaults = defaults }
        #else
        self.defaults = defaults
        #endif
        if let data = self.defaults.data(forKey: key) {
            if let saved = try? JSONDecoder().decode(QuestProgress.self, from: data) {
                if Self.valid(saved) { progress = saved }
                else {
                    var recovered = saved
                    if !saved.match.valid { recovered.match.session = nil }
                    if !saved.chase.valid { recovered.chase.session = nil }
                    if Self.valid(recovered), let repaired = try? JSONEncoder().encode(recovered) {
                        // Preserve the damaged record for diagnosis, and keep the healthy wallet/other game.
                        self.defaults.set(data, forKey: key + ".board-recovery-backup")
                        self.defaults.set(repaired, forKey: key)
                        progress = recovered
                        recoveryNotice = "A damaged board was safely closed. Your coins, purchases and cleared levels were kept."
                    } else { loadError = true }
                }
            } else { loadError = true }
        }
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--quest-ui-tests") &&
            ProcessInfo.processInfo.arguments.contains("--challenge-ui-tests") {
            // Navigation fixture only: unlock chapter three without injecting a win or any coins.
            progress.match.cleared = Set(0..<10)
        }
        #endif
    }

    static func valid(_ saved: QuestProgress) -> Bool {
        let owned = CreativePack.catalog.filter { saved.ownedPacks.contains($0.id) }
        let spent = owned.reduce(0) { $0 + $1.cost } + (WardrobeItem.all + WardrobeItem.bags).filter { saved.wardrobe.contains($0.id) }.reduce(0) { $0 + $1.cost }
        let economyValid = saved.wardrobe.isSubset(of: Set((WardrobeItem.all + WardrobeItem.bags).filter { $0.cost > 0 }.map(\.id))) && saved.styleBriefs.isSubset(of: Set(StyleBrief.all.map(\.id))) && saved.match.valid && saved.chase.valid && saved.coins >= 0 && saved.coinsEarned >= spent &&
            saved.chase.spentOnLives <= saved.coinsEarned - spent &&
            saved.coinsEarned % 100 == 0 && saved.coins == saved.coinsEarned - spent - saved.chase.spentOnLives &&
            saved.ownedPacks.isSubset(of: Set(CreativePack.catalog.map(\.id)))
        return economyValid && (0...1).contains(saved.mapVersion) &&
        saved.gardenStars.isSubset(of: Set(0..<3)) && saved.explorerBadges.isSubset(of: Set(0..<4)) &&
        saved.round >= 0 && saved.round < Int.max && QuestMap.canEnter(saved.position, variant: saved.variant) &&
        saved.collected.isSubset(of: Set(QuestMap.supplies.map(\.id))) &&
        saved.stickers.allSatisfy { QuestMap.stickerSymbols.indices.contains($0) } &&
        (0..<4).contains(saved.hero.skin) && (0..<4).contains(saved.hero.hair) && (0..<4).contains(saved.hero.outfit)
    }

    func move(to cell: QuestCell) {
        guard !loadError, !progress.complete, QuestMap.canEnter(cell, variant: progress.variant),
              abs(cell.x - progress.position.x) + abs(cell.y - progress.position.y) == 1 else { return }
        var next = progress
        next.position = cell
        if let supply = QuestMap.supplies(for: progress.variant).first(where: { $0.cell == cell }) { next.collected.insert(supply.id) }
        if let star = QuestMap.stars(for: progress.variant).firstIndex(of: cell) {
            next.gardenStars.insert(star)
            if next.gardenStars.count == 3 { next.explorerBadges.insert(next.variant) }
        }
        if next.complete {
            guard next.coinsEarned <= Int.max - 100 else { return }
            next.stickers.insert(next.round % QuestMap.stickerSymbols.count)
            // Reward and completion are persisted together; reopening cannot claim again.
            next.coins += 100
            next.coinsEarned += 100
        }
        save(next)
    }

    @discardableResult
    func unlockPack(_ id: String) -> Bool {
        guard !loadError, let pack = CreativePack.catalog.first(where: { $0.id == id }),
              !progress.ownedPacks.contains(id), progress.coins >= pack.cost else { return false }
        var next = progress
        next.coins -= pack.cost
        next.ownedPacks.insert(id)
        save(next)
        return true
    }

    func nextAdventure() {
        guard !loadError, progress.complete, progress.round < Int.max - 1 else { return }
        var next = progress
        next.round += 1; next.mapVersion = 1
        next.position = QuestMap.transform(QuestMap.start, variant: next.variant)
        next.collected = []; next.gardenStars = []
        save(next)
    }

    func restartAdventure() {
        guard !loadError, !progress.complete else { return }
        var next = progress
        next.position = QuestMap.transform(QuestMap.start, variant: next.variant)
        next.collected = []; next.gardenStars = []
        save(next)
    }

    func setHero(_ hero: QuestHero) {
        var next = progress; next.hero = hero
        guard !loadError, Self.valid(next) else { return }
        save(next)
    }

    func refreshLives(at now: Date = Date()) {
        guard !loadError else { return }
        var next = progress; next.chase.refresh(at: now)
        if next.chase.lives != progress.chase.lives { save(next) }
    }

    @discardableResult
    func startChase(level: Int, practice: Bool, at now: Date = Date()) -> Bool {
        guard !loadError, ChaseLevel.all.indices.contains(level) else { return false }
        var next = progress; next.chase.refresh(at: now)
        if let session = next.chase.session, session.status == .playing {
            return session.level == level && session.practice == practice
        }
        guard practice || (level <= next.chase.unlocked && next.chase.lives > 0) else { return false }
        next.chase.session = ChaseSession(level: level, practice: practice)
        return save(next)
    }

    func moveChase(dx: Int, dy: Int, at now: Date = Date()) {
        guard !loadError, let session = progress.chase.session, session.status == .playing else { return }
        var next = progress; next.chase.refresh(at: now)
        var result = ChaseEngine.step(session, dx: dx, dy: dy)
        guard result != session else { return }
        next.chase.session = result
        if !result.practice {
            if result.status == .lost { next.chase.loseLife(at: now) }
            if result.status == .won {
                let firstClear = !next.chase.cleared.contains(result.level)
                let reward = firstClear && result.level % 5 == 4 ? 200 : 100
                guard next.coinsEarned <= Int.max - reward else { return }
                next.chase.cleared.insert(result.level)
                next.coins += reward; next.coinsEarned += reward
                result.reason = "You escaped with every paint drop! +\(reward) Linley Coins."
                next.chase.session = result
            }
        }
        save(next)
    }

    func abandonChase(at now: Date = Date()) {
        guard !loadError, var session = progress.chase.session, session.status == .playing else { return }
        var next = progress
        session.status = .lost; session.reason = "Attempt ended. A new route is waiting."
        next.chase.session = session
        if !session.practice { next.chase.loseLife(at: now) }
        save(next)
    }

    @discardableResult
    func buyChaseLife(at now: Date = Date()) -> Bool {
        guard !loadError else { return false }
        var next = progress; next.chase.refresh(at: now)
        guard next.chase.lives < 5, next.coins >= 100 else {
            if next.chase.lives != progress.chase.lives { save(next) }
            return false
        }
        next.coins -= 100; next.chase.spentOnLives += 100; next.chase.lives += 1
        if next.chase.lives == 5 { next.chase.nextLifeAt = nil }
        return save(next)
    }

    @discardableResult
    func startMatch(level: Int, seed: UInt64 = UInt64.random(in: 0...UInt64.max)) -> Bool {
        guard !loadError, MatchLevel.all.indices.contains(level), level <= progress.match.unlocked else { return false }
        // Starting another board requires an explicit end/retry action in the UI.
        guard progress.match.session?.status != .playing else { return false }
        var next = progress
        next.match.session = MatchSession(level: level, seed: seed)
        return save(next)
    }

    @discardableResult
    func swapMatch(_ a: Int, _ b: Int) -> MatchTurn? {
        guard !loadError, let old = progress.match.session,
              let turn = (a == b ? MatchEngine.activate(old, at: a) : MatchEngine.step(old, a: a, b: b)) else { return nil }
        var next = progress
        next.match.session = turn.session
        if turn.session.status == .won {
            let first = !next.match.cleared.contains(old.level)
            let reward = first && old.level % 5 == 4 ? 200 : 100
            guard next.coinsEarned <= Int.max - reward else { return nil }
            next.coins += reward; next.coinsEarned += reward
            next.match.cleared.insert(old.level)
        }
        // Completed attempt and shared reward are persisted in one record.
        return save(next) ? turn : nil
    }

    func endMatch() {
        guard !loadError else { return }
        var next = progress; next.match.session = nil
        save(next)
    }

    func ownsStyle(_ id: String) -> Bool {
        guard !loadError, let item = WardrobeItem.item(id) else { return false }
        return item.cost == 0 || progress.wardrobe.contains(id)
    }
    func ownsLook(_ look: DressUpLook) -> Bool { look.valid && look.styleIDs.allSatisfy { ownsStyle($0) } }
    @discardableResult func unlockStyle(_ id: String) -> Bool {
        guard !loadError, let item = WardrobeItem.item(id), item.cost > 0,
              !ownsStyle(id), progress.coins >= item.cost else { return false }
        var next = progress; next.coins -= item.cost; next.wardrobe.insert(id)
        return save(next)
    }
    @discardableResult func completeStyleBrief(_ id: Int, look: DressUpLook) -> Bool {
        guard !loadError, let brief = StyleBrief.all.first(where: { $0.id == id }), brief.met(by:look),
              ownsLook(look), !progress.styleBriefs.contains(id),
              progress.coinsEarned <= Int.max - 100 else { return false }
        var next = progress; next.styleBriefs.insert(id); next.coins += 100; next.coinsEarned += 100
        return save(next)
    }

    func resetUnreadableGame() {
        guard loadError else { return }
        defaults.removeObject(forKey: key)
        progress = QuestProgress(); loadError = false
    }

    @discardableResult private func save(_ next: QuestProgress) -> Bool {
        guard Self.valid(next), let data = try? JSONEncoder().encode(next) else { return false }
        defaults.set(data, forKey: key)
        progress = next
        return true
    }
}
