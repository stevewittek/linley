import Foundation
import SwiftUI

struct QuestCell: Codable, Hashable {
    let x: Int
    let y: Int
    func offset(_ dx: Int, _ dy: Int) -> QuestCell { .init(x: x + dx, y: y + dy) }
}

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

    static func canEnter(_ cell: QuestCell) -> Bool {
        (0..<columns).contains(cell.x) && (0..<rows).contains(cell.y) && !obstacles.contains(cell)
    }

    /// Breadth-first pathfinding makes every reachable tile usable with a single tap.
    static func route(from start: QuestCell, to target: QuestCell) -> [QuestCell] {
        guard canEnter(start), canEnter(target), start != target else { return [] }
        var queue = [start]
        var visited: Set<QuestCell> = [start]
        var previous: [QuestCell: QuestCell] = [:]
        var cursor = 0
        while cursor < queue.count {
            let current = queue[cursor]; cursor += 1
            for next in [current.offset(0, -1), current.offset(1, 0), current.offset(0, 1), current.offset(-1, 0)] {
                guard canEnter(next), visited.insert(next).inserted else { continue }
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
    var complete: Bool { collected.count == QuestMap.supplies.count }

    init() { }
    enum CodingKeys: String, CodingKey { case round, position, collected, stickers, hero, coins, coinsEarned, ownedPacks }
    init(from decoder: Decoder) throws {
        let data = try decoder.container(keyedBy: CodingKeys.self)
        round = try data.decode(Int.self, forKey: .round)
        position = try data.decode(QuestCell.self, forKey: .position)
        collected = try data.decode(Set<String>.self, forKey: .collected)
        stickers = try data.decode(Set<Int>.self, forKey: .stickers)
        hero = try data.decode(QuestHero.self, forKey: .hero)
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
            if let saved = try? JSONDecoder().decode(QuestProgress.self, from: data), Self.valid(saved) {
                progress = saved
            } else { loadError = true }
        }
    }

    static func valid(_ saved: QuestProgress) -> Bool {
        let owned = CreativePack.catalog.filter { saved.ownedPacks.contains($0.id) }
        let spent = owned.reduce(0) { $0 + $1.cost }
        let economyValid = saved.coins >= 0 && saved.coinsEarned >= spent &&
            saved.coinsEarned % 100 == 0 && saved.coins == saved.coinsEarned - spent &&
            saved.ownedPacks.isSubset(of: Set(CreativePack.catalog.map(\.id)))
        return economyValid && saved.round >= 0 && saved.round < Int.max && QuestMap.canEnter(saved.position) &&
        saved.collected.isSubset(of: Set(QuestMap.supplies.map(\.id))) &&
        saved.stickers.allSatisfy { QuestMap.stickerSymbols.indices.contains($0) } &&
        (0..<4).contains(saved.hero.skin) && (0..<4).contains(saved.hero.hair) && (0..<4).contains(saved.hero.outfit)
    }

    func move(to cell: QuestCell) {
        guard !loadError, !progress.complete, QuestMap.canEnter(cell),
              abs(cell.x - progress.position.x) + abs(cell.y - progress.position.y) == 1 else { return }
        var next = progress
        next.position = cell
        if let supply = QuestMap.supplies.first(where: { $0.cell == cell }) { next.collected.insert(supply.id) }
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
        next.round += 1; next.position = QuestMap.start; next.collected = []
        save(next)
    }

    func restartAdventure() {
        guard !loadError, !progress.complete else { return }
        var next = progress
        next.position = QuestMap.start; next.collected = []
        save(next)
    }

    func setHero(_ hero: QuestHero) {
        var next = progress; next.hero = hero
        guard !loadError, Self.valid(next) else { return }
        save(next)
    }

    func resetUnreadableGame() {
        guard loadError else { return }
        defaults.removeObject(forKey: key)
        progress = QuestProgress(); loadError = false
    }

    private func save(_ next: QuestProgress) {
        guard Self.valid(next), let data = try? JSONEncoder().encode(next) else { return }
        defaults.set(data, forKey: key)
        progress = next
    }
}
