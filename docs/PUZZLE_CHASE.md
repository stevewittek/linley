# Puzzle Chase — first ten-level milestone

Dad authorized a more involved game on October 17, 2026. Broad GitHub milestone #20 is active; #21 is the future worlds/avatar milestone. Linley 0.4.3 build 8 adds this mode alongside the existing calm Creative Quest. Current hero artwork and creative-studio wallet remain intact.

## Play

Games → Puzzle Chase → level. Move with arrows or tap a neighboring square. There is no automatic walk-to-destination in this mode. Wait takes a turn without moving. Creatures advance after the displayed number of player turns, so the game is strategic and pauses while you think or leave the app. Purple ink blots pursue you; later workshop gear creatures include a patrolling opponent. Walking into a creature or being caught loses the attempt. Invalid wall moves do not advance turns. Each level also has a move allowance; running out loses the attempt.

Collect every coral paint drop, solve the gate and reach the checkered flag. Orange crates can be pushed one square into free space, but cannot be pulled. Keep a crate on every ring pressure plate to hold its gate open. Lightning switches stay on for the attempt. When a level has both plates and a switch, both requirements apply. Blue portals transfer the hero to the other portal; enemies do not teleport. A bad crate push may require restarting. The level selector has a How to play guide.

## Chapters

| Levels | World | Main mechanics |
| --- | --- | --- |
| 1–5 | Ink Garden | Chasing creatures, switches, crate/pressure gates, then a two-creature encounter |
| 6–10 | Clockwork Workshop | New boards and cog creatures, portals, mixed puzzles and a final switch-plus-crate gate |

Each Challenge win awards 100 coins; the first clear of levels 5 and 10 awards 200. Clear levels in order to unlock the next challenge. Replaying a cleared level in Challenge earns another 100 for a fresh successful attempt, with ordinary life risk. A saved win cannot be claimed twice; Practice has no rewards. Completing all ten first clears earns 1,200 coins. The same wallet buys creative art packs elsewhere in the app. No real-money purchase route exists.

## Lives and Practice

Start with five lives. Losing, deliberately ending or restarting a Challenge attempt uses exactly one. Returning to the selector or backgrounding pauses/resumes the saved attempt and does not charge a life. One life returns free every 20 minutes, up to five; accumulated time is reconciled after returning to the app. Further losses do not restart an already-running refill interval. The countdown is shown on the level selector and after a loss. Like other local saves, this uses the device clock rather than an online trusted time service.

Confirming **Use 100 coins for 1 life** spends earned coins and adds exactly one life. The debit and life change are saved together with the shared wallet. Full lives, insufficient balance or a life that naturally refilled before confirmation cannot charge coins. No timed reminder notifications are scheduled.

Practice remains available even with zero lives, including previews of later levels. It does not consume lives, award coins or unlock levels. Calm Creative Quest, the camera and basic art creation also remain available. This keeps the app free while the challenge mode has meaningful failure and progression.

## Persistence and verification

Progression, the live attempt, failure state, life deadline, coin spending and rewards use one persisted QuestProgress record. Old saves gain a fresh campaign with five lives without losing existing coins, art packs, stars, stickers or hero. Failure/reward transitions are idempotent across reloads. Unreadable or invalid saved data is preserved and fails closed.

A breadth-first search using the actual production ChaseEngine found a winning route for all ten authored levels. Saved route fixtures are replayed by XCTest against the same engine, including required gates and paint drops. An initially unwinnable level-5 encounter was rebalanced before acceptance. Model tests cover collision, enemy cadence, waiting, move limits, crate gates, switches, portals, rewards, progression, refill boundaries/caps, purchase races, Practice and old-save migration. Not every possible bad crate state has a recovery route; Restart is the deliberate way to try a new plan.

Developers can rerun the actual-engine solver without a simulator using `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer sh scripts/verify-puzzle-levels.sh`. It prints winning action sequences and fails if a level cannot be solved within its search budget; it does not run inside the game.

The [generated visual concept](reviews/2026-10-17-puzzle-chase.md) is approval pending and uses richer illustrative art than the native implementation. Real device screenshots and exact run results belong in VERIFICATION.md. Family play-testing and difficulty tuning remain review checkpoints, not claims established by automated solvability.
