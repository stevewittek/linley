import Foundation

/// Runs the production native engine and wallet on macOS, without modifying owner saves.
@main @MainActor struct VerifyMatchThree {
    static func main() throws {
        func check(_ condition: @autoclosure () -> Bool, _ message: String) {
            precondition(condition(), message)
        }
        for seed in 0..<200 { for level in MatchLevel.all.indices {
            let board = MatchSession(level: level, seed: UInt64(seed))
            check(board.valid, "Generated board not stable/playable")
            check(board == MatchSession(level: level, seed: UInt64(seed)), "Seed not deterministic")
        } }
        print("PASS: 4,000 stable playable boards; deterministic generation")
        var cascades = false, refreshed = false, failed = false
        for seed in 0..<200 {
            var board = MatchSession(level: 9, seed: UInt64(seed))
            while board.status == .playing {
                let move = MatchEngine.hint(board.board)!
                let turn = MatchEngine.step(board, a: move[0], b: move[1])!
                check(turn.session.moves == board.moves - 1, "Move accounting")
                check(turn.session.valid, "Invalid resolved board")
                check(turn.frames.contains(where: { $0.contains(-1) }), "Missing clear stage")
                cascades = cascades || turn.cascades > 1
                refreshed = refreshed || turn.reshuffled
                board = turn.session
            }
            failed = failed || board.status == .lost
            check(MatchEngine.step(board,a:0,b:1) == nil,"Finished board accepted move")
        }
        check(cascades, "Cascades not exercised"); check(failed, "Loss not exercised")
        print("PASS: 200 complete attempts, cascades, failure and terminal guard; dead-board refresh observed: \(refreshed)")
        check(!MatchEngine.adjacent(5,6) && !MatchEngine.adjacent(Int.max,0),"Adjacency")
        let sample = MatchSession(level:0,seed:1)
        check(MatchEngine.step(sample,a:0,b:35) == nil,"Invalid swap")
        let name = "LinleyMatchSmoke.\(UUID())"
        let defaults = UserDefaults(suiteName:name)!
        defer { defaults.removePersistentDomain(forName:name) }
        let store = QuestStore(defaults: defaults)
        check(!store.startMatch(level:1),"Skipped locked level")
        let seeds: [UInt64] = [1,1,1,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2]
        for level in MatchLevel.all.indices {
            check(store.startMatch(level:level,seed:seeds[level]),"Could not start level")
            check(!store.startMatch(level:level),"Replaced active attempt")
            while let board = store.progress.match.session, board.status == .playing {
                let best = MatchEngine.suggestedMove(board)!
                check(store.swapMatch(best.0,best.1) != nil,"Wallet rejected legal move")
            }
            check(store.progress.match.session?.status == .won,"Campaign goal not reached")
            let balance = store.progress.coins
            check(store.swapMatch(0,1) == nil && store.progress.coins == balance,"Duplicate reward")
            let resumed = QuestStore(defaults: defaults)
            check(!resumed.loadError && resumed.progress.match.session == store.progress.match.session,"Resume failed")
        }
        check(store.progress.coins == 2400,"Campaign rewards and bonuses")
        check(store.unlockPack("garden"),"Shared shop could not spend rewards")
        check(!store.unlockPack("garden"),"Duplicate purchase")
        check(store.progress.coins == 2300 && QuestStore.valid(store.progress),"Wallet accounting")
        check(store.startMatch(level:0,seed:1),"Replay did not start")
        while let board = store.progress.match.session, board.status == .playing {
            let move = MatchEngine.hint(board.board)!; store.swapMatch(move[0],move[1])
        }
        check(store.progress.coins == 2400 && store.progress.coinsEarned == 2500,"Replay reward")
        check(store.progress.chase.lives == 5,"Match-3 consumed Chase lives")
        store.endMatch(); check(store.startMatch(level:0,seed:9),"Free retry")
        check(QuestStore(defaults:defaults).progress.match.session == store.progress.match.session,"Active board not saved")
        print("PASS: all 20 campaign goals, progression, chapter bonuses, replay, duplicate prevention, shared shop, persistence and free retry")
        var old = QuestProgress(); old.coins = 100; old.coinsEarned = 200; old.ownedPacks = ["garden"]
        let data = try JSONEncoder().encode(old)
        var object = try JSONSerialization.jsonObject(with:data) as! [String:Any]
        object.removeValue(forKey:"match")
        defaults.set(try JSONSerialization.data(withJSONObject:object),forKey:"linley.creativeQuest.v1")
        let migrated = QuestStore(defaults:defaults)
        check(!migrated.loadError && migrated.progress.coins == 100 && migrated.progress.ownedPacks == ["garden"],"Old save migration")
        var corrupt = old; corrupt.match.session = MatchSession(level:0,seed:1); corrupt.match.session?.board[0] = 99
        check(!QuestStore.valid(corrupt),"Corrupt board accepted")
        corrupt = old; corrupt.match.cleared = [9]
        check(!QuestStore.valid(corrupt),"Skipped progress accepted")
        print("PASS: old save migration and corrupt board/progression rejection")
    }
}
