import Foundation

struct QuestCell: Codable, Hashable {
    let x: Int
    let y: Int
    func offset(_ dx: Int, _ dy: Int) -> QuestCell { .init(x: x + dx, y: y + dy) }
}


struct ChaseLevel {
    let name: String
    let rows: [String]
    let moveLimit: Int
    let enemyPeriod: Int
    private let tiles: [Character: Set<QuestCell>]
    let floor: Set<QuestCell>
    init(name: String, rows: [String], moveLimit: Int, enemyPeriod: Int) {
        self.name = name; self.rows = rows; self.moveLimit = moveLimit; self.enemyPeriod = enemyPeriod
        var tiles: [Character: Set<QuestCell>] = [:]
        var floor: Set<QuestCell> = []
        for (y, row) in rows.enumerated() {
            for (x, char) in row.enumerated() {
                let cell = QuestCell(x: x, y: y)
                tiles[char, default: []].insert(cell)
                if char != "#" { floor.insert(cell) }
            }
        }
        self.tiles = tiles; self.floor = floor
    }
    func positions(_ symbol: Character) -> Set<QuestCell> {
        tiles[symbol] ?? []
    }
    var chapter: String { ["Ink Garden", "Clockwork Workshop", "Frost Archive", "Relay Observatory"][min(3, (Self.all.firstIndex(where: { $0.name == name }) ?? 0) / 5)] }
    var required: Set<QuestCell> { positions("k").union(positions("q")) }
    var start: QuestCell { positions("S").first! }
    var enemyStarts: [QuestCell] { positions("B").sorted { $0.y == $1.y ? $0.x < $1.x : $0.y < $1.y } }
    static let all: [ChaseLevel] = [
        .init(name: "The Ink Blot", rows: ["#######", "#S...k#", "#.###.#", "#.....#", "#.#.#.#", "#B..#.#", "###.#.#", "#k...E#", "#######"], moveLimit: 55, enemyPeriod: 3),
        .init(name: "Flip the Switch", rows: ["#######", "#S.t..#", "#.###.#", "#k..gE#", "#.#.###", "#B....#", "###.#.#", "#k....#", "#######"], moveLimit: 60, enemyPeriod: 3),
        .init(name: "Push to Open", rows: ["#######", "#S....#", "#.co..#", "#..#..#", "#k.#gE#", "#..#..#", "#B....#", "#...k.#", "#######"], moveLimit: 65, enemyPeriod: 3),
        .init(name: "A Clever Detour", rows: ["#######", "#S...k#", "#.co..#", "#..#..#", "#..#gE#", "#B....#", "#.###.#", "#k....#", "#######"], moveLimit: 65, enemyPeriod: 2),
        .init(name: "Garden Showdown", rows: ["#######", "#S.t.k#", "#.###.#", "#B....#", "#.###.#", "#....B#", "#.###g#", "#k...E#", "#######"], moveLimit: 65, enemyPeriod: 5),
        .init(name: "Portal Workshop", rows: ["#######", "#S..@k#", "#.###.#", "#B....#", "#.###.#", "#@....#", "###.#.#", "#k...E#", "#######"], moveLimit: 60, enemyPeriod: 3),
        .init(name: "The Long Way Round", rows: ["#######", "#S.t@k#", "#.###.#", "#B....#", "#.###g#", "#@...E#", "###.#.#", "#k....#", "#######"], moveLimit: 65, enemyPeriod: 2),
        .init(name: "Crates and Portals", rows: ["#######", "#S..@k#", "#.co..#", "#..#..#", "#..#gE#", "#B....#", "#.###.#", "#@..k.#", "#######"], moveLimit: 70, enemyPeriod: 3),
        .init(name: "Workshop Patrol", rows: ["#######", "#S.t@k#", "#.###.#", "#B....#", "#.###g#", "#@...E#", "#.#.#.#", "#k..B.#", "#######"], moveLimit: 70, enemyPeriod: 3),
        .init(name: "The Grand Escape", rows: ["#######", "#S..@k#", "#.co..#", "#k.#k.#", "#..#gE#", "#B..t.#", "#.###.#", "#@k..B#", "#######"], moveLimit: 55, enemyPeriod: 3),
        .init(name: "Frost Footsteps", rows: ["#######", "#S.h.k#", "#.###.#", "#B....#", "#.###.#", "#..h..#", "###.#.#", "#k...E#", "#######"], moveLimit: 55, enemyPeriod: 3),
        .init(name: "Key to the Archive", rows: ["#######", "#S..qk#", "#.###.#", "#B....#", "#.###d#", "#....E#", "###.#.#", "#k.h..#", "#######"], moveLimit: 60, enemyPeriod: 3),
        .init(name: "Thaw and Travel", rows: ["#######", "#S.h@k#", "#.###.#", "#B....#", "#.###.#", "#@hq.d#", "###.#E#", "#k....#", "#######"], moveLimit: 60, enemyPeriod: 3),
        .init(name: "Cargo on Ice", rows: ["#######", "#S..qk#", "#.co..#", "#h.#..#", "#..#gE#", "#B.h..#", "#.###.#", "#k....#", "#######"], moveLimit: 65, enemyPeriod: 3),
        .init(name: "Archive Guardian", rows: ["#######", "#S.hqk#", "#.###.#", "#B....#", "#.###d#", "#..h.E#", "#.###.#", "#k..B.#", "#######"], moveLimit: 60, enemyPeriod: 4),
        .init(name: "Relay Reversal", rows: ["#######", "#S.r.k#", "#.###.#", "#B....#", "#.###g#", "#....E#", "###.#.#", "#k.h..#", "#######"], moveLimit: 60, enemyPeriod: 3),
        .init(name: "Twin Key Passage", rows: ["#######", "#S.q@k#", "#.###.#", "#B....#", "#.###d#", "#@h..E#", "###.#.#", "#k.q..#", "#######"], moveLimit: 65, enemyPeriod: 3),
        .init(name: "Relay Cargo", rows: ["#######", "#S.rqk#", "#.co..#", "#..#..#", "#..#gE#", "#B.h..#", "#.###.#", "#k....#", "#######"], moveLimit: 65, enemyPeriod: 3),
        .init(name: "Observatory Patrol", rows: ["#######", "#S.r@k#", "#.###.#", "#B.h..#", "#.###g#", "#@..qE#", "#.#.#.#", "#k..B.#", "#######"], moveLimit: 65, enemyPeriod: 3),
        .init(name: "The Aurora Escape", rows: ["#######", "#S.h@k#", "#.co..#", "#q.#k.#", "#..#gE#", "#B..r.#", "#.###.#", "#@k..B#", "#######"], moveLimit: 60, enemyPeriod: 3)
    ]
}

struct ChaseSession: Codable, Equatable {
    enum Status: String, Codable { case playing, won, lost }
    var level: Int
    var practice: Bool
    var player: QuestCell
    var crates: Set<QuestCell>
    var enemies: [QuestCell]
    var collected: Set<QuestCell> = []
    var switchOn = false
    var turns = 0
    var status = Status.playing
    var reason = "Collect every paint drop, solve the gate and reach the flag. Each step or Wait also advances the creatures."

    init(level: Int, practice: Bool) {
        self.level = level; self.practice = practice
        let board = ChaseLevel.all[level]
        player = board.start; crates = board.positions("c"); enemies = board.enemyStarts
    }
}

enum ChaseEngine {
    static let directions = [(0, -1), (1, 0), (0, 1), (-1, 0)]
    static func gatesOpen(_ session: ChaseSession) -> Bool {
        guard ChaseLevel.all.indices.contains(session.level) else { return false }
        let plates = ChaseLevel.all[session.level].positions("o")
        let switches = ChaseLevel.all[session.level].positions("t").union(ChaseLevel.all[session.level].positions("r"))
        return (!switches.isEmpty || !plates.isEmpty) && (switches.isEmpty || session.switchOn) && (plates.isEmpty || plates.isSubset(of: session.crates))
    }

    static func hazardActive(turn: Int) -> Bool { turn % 4 >= 2 }
    static func doorsOpen(_ session: ChaseSession) -> Bool {
        guard ChaseLevel.all.indices.contains(session.level) else { return false }
        return ChaseLevel.all[session.level].positions("q").isSubset(of: session.collected)
    }
    /// One deliberate player action, then one enemy turn. No background timers move enemies.
    static func step(_ original: ChaseSession, dx: Int, dy: Int) -> ChaseSession {
        guard ChaseLevel.all.indices.contains(original.level), original.status == .playing, (-1...1).contains(dx), (-1...1).contains(dy), abs(dx) + abs(dy) <= 1 else { return original }
        let board = ChaseLevel.all[original.level]
        guard board.floor.contains(original.player), original.turns >= 0, original.turns < board.moveLimit,
              original.enemies.count == board.enemyStarts.count else { return original }
        var next = original
        var target = next.player.offset(dx, dy)
        let gateTiles = board.positions("g")
        func open(_ cell: QuestCell, _ state: ChaseSession) -> Bool {
            board.floor.contains(cell) && (!gateTiles.contains(cell) || gatesOpen(state)) && (!board.positions("d").contains(cell) || doorsOpen(state))
        }
        guard open(target, next) else { return original }
        if next.crates.contains(target) {
            let beyond = target.offset(dx, dy)
            guard open(beyond, next), !next.crates.contains(beyond), !next.enemies.contains(beyond),
                  !board.positions("@").contains(beyond), !board.positions("E").contains(beyond) else { return original }
            next.crates.remove(target); next.crates.insert(beyond)
        }
        if dx != 0 || dy != 0, board.positions("@").contains(target) {
            if let exit = board.positions("@").first(where: { $0 != target }) { target = exit }
        }
        next.player = target; next.turns += 1
        if next.enemies.contains(target) { next.status = .lost; next.reason = "An ink creature caught you. Try a different route."; return next }
        if board.positions("h").contains(target), hazardActive(turn: next.turns) {
            next.status = .lost; next.reason = "The frost pulse caught you. Wait on a safe tile for a cool turn."; return next
        }
        if board.required.contains(target) { next.collected.insert(target) }
        if board.positions("t").contains(target) { next.switchOn = true }
        if board.positions("r").contains(target), dx != 0 || dy != 0 { next.switchOn.toggle() }
        if board.positions("E").contains(target), next.collected == board.required, (gateTiles.isEmpty || gatesOpen(next)) {
            next.status = .won; next.reason = "You escaped with every paint drop!"; return next
        }
        // In world two the second creature patrols toward the exit; the first still pursues you.
        if next.turns % board.enemyPeriod == 0 {
            for index in next.enemies.indices {
                let patrolGoal = next.turns / (board.enemyPeriod * 3) % 2 == 0 ? board.positions("E").first! : board.enemyStarts[index]
                let goal = next.level >= 5 && index == 1 ? patrolGoal : next.player
                if let step = enemyStep(from: next.enemies[index], toward: goal, board: board, session: next) {
                    if !next.enemies.enumerated().contains(where: { $0.offset != index && $0.element == step }) {
                        next.enemies[index] = step
                    }
                }
                if next.enemies[index] == next.player { next.status = .lost; next.reason = "An ink creature caught you. Try a different route."; return next }
            }
        }
        if next.turns >= board.moveLimit {
            next.status = .lost; next.reason = "Out of moves. Try the puzzle again or explore it in Practice."
        } else {
            next.reason = "\(next.collected.intersection(board.positions("k")).count)/\(board.positions("k").count) drops • \(next.collected.intersection(board.positions("q")).count)/\(board.positions("q").count) keys"
        }
        return next
    }

    private static func enemyStep(from start: QuestCell, toward goal: QuestCell, board: ChaseLevel, session: ChaseSession) -> QuestCell? {
        var queue = [start]; var cursor = 0; var visited: Set<QuestCell> = [start]
        var first: [QuestCell: QuestCell] = [:]
        while cursor < queue.count {
            let current = queue[cursor]; cursor += 1
            for (dx, dy) in directions {
                let cell = current.offset(dx, dy)
                guard board.floor.contains(cell), !session.crates.contains(cell),
                      (!board.positions("g").contains(cell) || gatesOpen(session)),
                      (!board.positions("d").contains(cell) || doorsOpen(session)), visited.insert(cell).inserted else { continue }
                first[cell] = current == start ? cell : first[current]
                if cell == goal { return first[cell] }
                queue.append(cell)
            }
        }
        return nil
    }
}

struct ChaseProgress: Codable {
    static let refillInterval: TimeInterval = 20 * 60
    var lives = 5
    var nextLifeAt: Date?
    var spentOnLives = 0
    var cleared: Set<Int> = []
    var session: ChaseSession?

    mutating func refresh(at now: Date) {
        guard lives < 5, let nextLifeAt, now >= nextLifeAt else { return }
        let earned = min(Double(5 - lives), floor(now.timeIntervalSince(nextLifeAt) / Self.refillInterval) + 1)
        guard earned.isFinite, earned > 0 else { return }
        lives += Int(earned)
        self.nextLifeAt = lives == 5 ? nil : nextLifeAt.addingTimeInterval(earned * Self.refillInterval)
    }
    mutating func loseLife(at now: Date) {
        refresh(at: now)
        guard lives > 0 else { return }
        lives -= 1
        if nextLifeAt == nil { nextLifeAt = now.addingTimeInterval(Self.refillInterval) }
    }
    var unlocked: Int { min(cleared.count, ChaseLevel.all.count - 1) }

    var valid: Bool {
        guard (0...5).contains(lives), spentOnLives >= 0, spentOnLives % 100 == 0,
              cleared == Set(0..<cleared.count), cleared.count <= ChaseLevel.all.count,
              lives == 5 ? nextLifeAt == nil : nextLifeAt?.timeIntervalSince1970.isFinite == true else { return false }
        guard let session else { return true }
        guard ChaseLevel.all.indices.contains(session.level), session.practice || session.level <= unlocked else { return false }
        let board = ChaseLevel.all[session.level]
        let victoryValid = session.status != .won || (session.collected == board.required && board.positions("E").contains(session.player) && (board.positions("g").isEmpty || ChaseEngine.gatesOpen(session)))
        return victoryValid && board.floor.contains(session.player) && !session.crates.contains(session.player) &&
            (session.status == .lost || !session.enemies.contains(session.player)) && Set(session.enemies).count == session.enemies.count &&
            session.crates.count == board.positions("c").count && session.crates.isDisjoint(with: session.enemies) &&
            session.crates.isSubset(of: board.floor) && session.collected.isSubset(of: board.required) &&
            session.enemies.count == board.enemyStarts.count && session.enemies.allSatisfy(board.floor.contains) &&
            session.turns >= 0 && session.turns <= board.moveLimit &&
            (session.status != .playing || session.turns < board.moveLimit) &&
            (session.status == .lost || !board.positions("h").contains(session.player) || !ChaseEngine.hazardActive(turn: session.turns))
    }
}
