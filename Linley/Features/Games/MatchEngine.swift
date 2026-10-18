import Foundation

// Native adaptation of Kenney Starter Kit Match-3 (MIT): matching, swap rollback,
// gravity and refill. Campaign, frost, collection goals and earned powers are Linley additions.
struct MatchLevel {
    let title: String
    let target: Int
    let moves: Int
    var collectKind: Int? = nil
    var collectGoal = 0
    var frost: [Int: Int] = [:]
    var chapter: String { frost.values.contains(2) ? "Crystal Conservatory" : frost.isEmpty ? "Gem Garden" : "Frosted Studio" }
    static let legacy: [MatchLevel] = (0..<10).map {
        MatchLevel(title: ["Gem Garden", "Mint Meadow", "Sunshine Swap", "Heart Trail", "Garden Party", "Moonlit Studio", "Color Cascade", "Crystal Crossing", "Sparkle Sprint", "Dream Finale"][$0],
                   target: [120,300,600,900,1200,1500,1800,2100,2400,2800][$0],
                   moves: [18,18,18,18,20,20,21,22,23,24][$0])
    }
    static let all: [MatchLevel] = (0..<20).map { index in
        if index < 2 { return legacy[index] }
        let names = ["Purple Harvest", "Frosted Corners", "Heart Garden", "Crystal Frames", "Sunshine Rescue", "Icy Crossroads", "Garden Delivery", "Studio Showdown", "Double Frost", "Heart of Winter", "Rocket Garden", "Thaw the Frame", "Crystal Festival", "Frozen Sun", "The Last Patches", "Winter Delivery", "All Together", "Conservatory Finale"]
        var level = MatchLevel(title: names[index - 2], target: index < 10 ? legacy[index].target : 1200 + (index-10)*140,
                               moves: index < 10 ? legacy[index].moves + 8 : 32)
        if index % 3 != 0 { level.collectKind = [0,4,1,3][(index / 2) % 4]; level.collectGoal = 8 + index / 2 }
        if index >= 3 {
            let shapes = [[0,5,30,35], [7,10,25,28], [2,3,12,17,18,23,32,33], [7,8,9,10,13,16,19,22,25,26,27,28]]
            level.frost = Dictionary(uniqueKeysWithValues: shapes[(index-3) % shapes.count].map { ($0, index >= 10 ? 2 : 1) })
        }
        return level
    }
}

enum MatchStatus: String, Codable { case playing, won, lost }
struct MatchSession: Codable, Equatable {
    var level: Int
    var board: [Int]
    var seed: UInt64
    var moves: Int
    var score = 0
    var status = MatchStatus.playing
    var rulesVersion = 2
    var collected = 0
    var frost: [Int: Int] = [:]
    // 1 = row rocket, 2 = 3×3 starburst, 3 = column rocket. Powers are earned, never bought.
    var powers: [Int: Int] = [:]
    var rules: MatchLevel { rulesVersion == 1 ? MatchLevel.legacy[level] : MatchLevel.all[level] }
    var goalMet: Bool { score >= rules.target && collected >= rules.collectGoal && frost.isEmpty }
    init(level: Int, seed: UInt64) {
        self.level = level; self.seed = seed; moves = MatchLevel.all[level].moves
        frost = MatchLevel.all[level].frost; board = []
        board = MatchEngine.freshBoard(seed: &self.seed)
    }
    enum CodingKeys: String, CodingKey { case level, board, seed, moves, score, status, rulesVersion, collected, frost, powers }
    init(from decoder: Decoder) throws {
        let data = try decoder.container(keyedBy: CodingKeys.self)
        level = try data.decode(Int.self, forKey: .level); board = try data.decode([Int].self, forKey: .board)
        seed = try data.decode(UInt64.self, forKey: .seed); moves = try data.decode(Int.self, forKey: .moves)
        score = try data.decode(Int.self, forKey: .score); status = try data.decode(MatchStatus.self, forKey: .status)
        // Keep an already-started v0.4.5 board's original goals, including terminal rewards.
        rulesVersion = try data.decodeIfPresent(Int.self, forKey: .rulesVersion) ?? 1
        collected = try data.decodeIfPresent(Int.self, forKey: .collected) ?? 0
        frost = try data.decodeIfPresent([Int:Int].self, forKey: .frost) ?? [:]
        powers = try data.decodeIfPresent([Int:Int].self, forKey: .powers) ?? [:]
    }
    var valid: Bool {
        guard MatchLevel.all.indices.contains(level), (1...2).contains(rulesVersion), rulesVersion != 1 || level < 10,
              board.count == 36, board.allSatisfy({ (0..<5).contains($0) }),
              (0...rules.moves).contains(moves), (0...1_000_000).contains(score), (0...100_000).contains(collected),
              frost.allSatisfy({ (0..<36).contains($0.key) && (1...2).contains($0.value) && $0.value <= (rules.frost[$0.key] ?? 0) }),
              powers.allSatisfy({ (0..<36).contains($0.key) && (1...3).contains($0.value) }),
              MatchEngine.matches(board).isEmpty, MatchEngine.hint(board) != nil else { return false }
        if rulesVersion == 1 && (collected != 0 || !frost.isEmpty || !powers.isEmpty) { return false }
        switch status {
        case .playing: return moves > 0 && !goalMet
        case .won: return goalMet
        case .lost: return moves == 0 && !goalMet
        }
    }
}
struct MatchProgress: Codable {
    var cleared: Set<Int> = []
    var session: MatchSession?
    var unlocked: Int { min(MatchLevel.all.count - 1, cleared.count) }
    var valid: Bool {
        cleared.count <= MatchLevel.all.count && cleared == Set(0..<cleared.count) &&
        (session.map { $0.valid && $0.level <= unlocked && ($0.status != .won || cleared.contains($0.level)) } ?? true)
    }
}
struct MatchTurn {
    let session: MatchSession
    let frames: [[Int]]
    let cascades: Int
    let reshuffled: Bool
}
enum MatchEngine {
    static let size = 6
    static func random(_ seed: inout UInt64) -> Int {
        seed &+= 0x9e3779b97f4a7c15
        var value = seed
        value = (value ^ (value >> 30)) &* 0xbf58476d1ce4e5b9
        value = (value ^ (value >> 27)) &* 0x94d049bb133111eb
        return Int((value ^ (value >> 31)) % 5)
    }
    static func adjacent(_ a: Int, _ b: Int) -> Bool {
        (0..<36).contains(a) && (0..<36).contains(b) && abs(a / 6 - b / 6) + abs(a % 6 - b % 6) == 1
    }
    static func matches(_ board: [Int]) -> Set<Int> {
        guard board.count == 36 else { return [] }
        var found: Set<Int> = []
        for y in 0..<6 { for x in 0..<6 {
            let i = y * 6 + x
            guard board[i] >= 0 else { continue }
            if x < 4 && board[i] == board[i+1] && board[i] == board[i+2] { found.formUnion([i,i+1,i+2]) }
            if y < 4 && board[i] == board[i+6] && board[i] == board[i+12] { found.formUnion([i,i+6,i+12]) }
        } }
        return found
    }
    static func hint(_ board: [Int]) -> [Int]? {
        guard board.count == 36 else { return nil }
        for a in 0..<36 { for b in [a+1,a+6] where adjacent(a,b) {
            var swapped = board; swapped.swapAt(a,b)
            if !matches(swapped).isEmpty { return [a,b] }
        } }
        return nil
    }
    static func freshBoard(seed: inout UInt64) -> [Int] {
        for _ in 0..<100 {
            var board: [Int] = []
            for i in 0..<36 {
                var type = random(&seed)
                while (i % 6 >= 2 && board[i-1] == type && board[i-2] == type) ||
                      (i >= 12 && board[i-6] == type && board[i-12] == type) { type = (type+1) % 5 }
                board.append(type)
            }
            if hint(board) != nil { return board }
        }
        return [0,1,0,2,3,4, 2,0,3,4,1,2, 1,2,4,0,2,3, 3,4,1,2,3,0, 4,0,2,3,4,1, 0,1,3,4,0,2]
    }
    static func step(_ old: MatchSession, a: Int, b: Int) -> MatchTurn? {
        guard old.valid, old.status == .playing, adjacent(a,b) else { return nil }
        var next = old; next.board.swapAt(a,b)
        let pa = next.powers.removeValue(forKey:a), pb = next.powers.removeValue(forKey:b)
        next.powers[a] = pb; next.powers[b] = pa
        guard !matches(next.board).isEmpty else { return nil }
        return resolve(next, initial: matches(next.board), preferred: b)
    }
    static func activate(_ old: MatchSession, at index: Int) -> MatchTurn? {
        guard old.valid, old.status == .playing, old.powers[index] != nil else { return nil }
        return resolve(old, initial: [index], preferred: nil)
    }
    private static func blast(_ index: Int, kind: Int) -> Set<Int> {
        if kind == 1 { return Set((0..<6).map { index / 6 * 6 + $0 }) }
        if kind == 3 { return Set((0..<6).map { $0 * 6 + index % 6 }) }
        return Set((0..<36).filter { abs($0/6 - index/6) <= 1 && abs($0%6 - index%6) <= 1 })
    }
    private static func spawn(_ board: [Int], preferred: Int?) -> (Int,Int)? {
        var candidates: [(Int,Int,Int)] = []
        for i in 0..<36 { for stride in [1,6] {
            if stride == 1 && i % 6 > 2 { continue }
            if stride == 6 && i / 6 > 2 { continue }
            var run = [i]
            var j = i + stride
            while j < 36 && (stride == 6 || j/6 == i/6) && board[j] == board[i] { run.append(j); j += stride }
            if run.count >= 4 { candidates.append((run.contains(preferred ?? -1) ? preferred! : run[1], run.count >= 5 ? 2 : stride == 1 ? 1 : 3, run.count)) }
        } }
        return candidates.max(by: { $0.2 < $1.2 }).map { ($0.0,$0.1) }
    }
    private static func resolve(_ old: MatchSession, initial: Set<Int>, preferred: Int?) -> MatchTurn {
        var next = old; next.moves -= 1
        var frames = [next.board], count = 0, matched = initial
        while !matched.isEmpty && count < 12 {
            count += 1
            let earned = next.rulesVersion >= 2 ? spawn(next.board, preferred: preferred) : nil
            // Existing powers chain once each; set union prevents double score/collection/frost hits.
            var triggered: Set<Int> = []
            while let index = matched.sorted().first(where: { next.powers[$0] != nil && !triggered.contains($0) }) {
                triggered.insert(index); matched.formUnion(blast(index,kind:next.powers[index]!))
            }
            let newPower = earned.flatMap { !triggered.contains($0.0) ? $0 : nil }
            next.score += matched.count * 10 * min(count,5)
            if let kind = next.rules.collectKind { next.collected += matched.filter { next.board[$0] == kind }.count }
            let powerTile = newPower.map { next.board[$0.0] }
            for i in matched {
                if let frost = next.frost[i] { next.frost[i] = frost > 1 ? frost-1 : nil }
                next.powers[i] = nil; next.board[i] = -1
            }
            if let (i,kind) = newPower { next.board[i] = powerTile!; next.powers[i] = kind }
            frames.append(next.board)
            var fallenPowers: [Int:Int] = [:]
            for x in 0..<6 {
                let kept = (0..<6).map { $0*6+x }.filter { next.board[$0] >= 0 }
                let missing = 6-kept.count
                let column = (0..<missing).map { _ in random(&next.seed) } + kept.map { next.board[$0] }
                for (y, source) in kept.enumerated() { if let power = next.powers[source] { fallenPowers[(y+missing)*6+x] = power } }
                for y in 0..<6 { next.board[y*6+x] = column[y] }
            }
            next.powers = fallenPowers; frames.append(next.board); matched = matches(next.board)
        }
        var reshuffled = false
        if !matched.isEmpty || hint(next.board) == nil {
            next.board = freshBoard(seed: &next.seed); reshuffled = true
            // Preserve every earned power across a board refresh; frost stays at its objective cell.
            frames.append(next.board)
        }
        if next.goalMet { next.status = .won } else if next.moves == 0 { next.status = .lost }
        return MatchTurn(session:next,frames:frames,cascades:count,reshuffled:reshuffled)
    }
    // Objective-aware guide used for campaign validation, not an in-app autoplay.
    static func suggestedMove(_ state: MatchSession) -> (Int,Int)? {
        var choices: [(Int,Int,MatchSession)] = []
        for a in 0..<36 {
            if let turn = activate(state,at:a) { choices.append((a,a,turn.session)) }
            for b in [a+1,a+6] where adjacent(a,b) { if let turn = step(state,a:a,b:b) { choices.append((a,b,turn.session)) } }
        }
        func value(_ next: MatchSession) -> Int {
            let frost = state.frost.values.reduce(0,+)-next.frost.values.reduce(0,+)
            let collected = min(state.rules.collectGoal,next.collected)-min(state.rules.collectGoal,state.collected)
            return (next.status == .won ? 1_000_000 : 0) + frost*500 + collected*120 + min(next.score,state.rules.target)-min(state.score,state.rules.target) + next.powers.count*20
        }
        return choices.max(by: { value($0.2) < value($1.2) }).map { ($0.0,$0.1) }
    }
}
