# Challenge chapters and stability — 0.4.6 (11)

Owner request: make the games less basic/repetitive, add levels and meaningful challenges, and improve stability. Broad tracking: Puzzle Chase expansion #21 and Match-3 #22, both In Progress. Calm Creative Quest remains the relaxed option. Avatar redesign remains future work.

## What changes how you play

### Gem Garden — 20 levels

The first two boards teach matching. Later boards combine score with specific tile collection and frost clearing. Frost belongs to its board cell: matching/blasting that location removes one layer, so chasing only a high score does not finish the board. Later boards have double frost. Four-tile lines earn row/column rockets; five earns a 3×3 starburst. Match a power to trigger it, or tap to fire for one move. Powers chain and relocate with falling gems. Frost/collection objectives survive a dead-board refresh. Powers are earned through play, never sold. Retries and hints remain free.

Every goal must be complete before moves run out; the last move can win. Every fifth level's first clear earns 200 shared coins, other wins/replays 100. All twenty campaign clears total 2,400. The existing shop, wallet and other games remain connected.

### Puzzle Chase — 20 levels / four chapters

Original Ink Garden and Clockwork Workshop boards are unchanged. Frost Archive adds frost pulses (turns 0/1 cool, 2/3 hot, repeating), a next-turn forecast, gold keys and doors that need every key. Relay Observatory adds switches that toggle on each entry, including mixed crate/portal/key/frost puzzles. Every step and Wait advances the turn; blocked moves do not. Practice remains available for all twenty boards with no lives/rewards. Five challenge lives and earned-coin refills remain unchanged.

## Stability work

- Cache decoded Match-3 sprites instead of reading images repeatedly per cell/frame.
- Resolve cascades with a bounded twelve-wave budget and play at most a short animation sequence; input remains gated while it plays. Persist resolved board/reward before playback, so backgrounding/leaving cancels presentation without losing progress or duplicating rewards.
- Keep tile accessibility labels tied to the stable saved board, with one button and ignored decorative children.
- Reset scroll position when opening/retrying a Match-3 level, so selecting late levels does not leave the new board offscreen.
- Reject invalid Chase levels/positions/turns before indexing/offset arithmetic.
- If only a decoded game board is damaged, back up the original record, close only the damaged attempt, and keep the valid other game, wallet, purchases and cleared levels. Invalid wallet/core records still fail closed and remain preserved; no invented balance repairs.
- Old v0.4.5 Match-3 attempts decode as classic rules version 1. Original score targets/moves, active/terminal state and coins stay intact. Newly started/restarted boards use version 2 goals and powers. No forced reset or completion reward on upgrade.

## Evidence

- Production-engine breadth-first solver found routes for all twenty Chase boards (all below the 300,000-state search ceiling). New routes are exercised in XCTest. Key collection, timed hazards and relay state are included in the search state; timing includes the hazard cycle.
- Production-source `scripts/verify-match-three.sh` passed 4,000 generated stable/playable boards, 200 complete attempts including loss/cascade/dead-board refresh, all twenty objective-aware campaign routes, progression/bonuses, reward/purchase idempotence, save recovery/migration, and free retries. Seed fixtures include alternatives for levels 4 and 20; random play is not guaranteed to win every board.
- Additional balance sample: ten objective-aware automated attempts per level, with 6–10 wins per ten on the current twenty boards. This is an algorithmic smoke sample, not human difficulty or engagement acceptance.
- Physical iPad `/tmp/LinleyExpandedModelsFinal.xcresult`: all **49 model/storage/audio tests passed**, including five new challenge tests. Coverage includes objective gating, frost/power handling and persisted powers, all three earned power types on normally generated boards, last-move outcomes, old terminal save migration, isolated corrupted-board recovery, key doors/relay/pulse timing and malformed Chase input. An earlier model run passed 42/44 but failed two real audio-output assertions; the full final 49-test rerun passed without an audio-code change. This transient audio failure is recorded, not described as a game fix.
- Physical UI walkthroughs and screenshots: incomplete. Further iPad work was deferred by Dad (“not now”), and the running test process was stopped immediately. No owner relaunch/device commands followed. A later UI attempt reported missing Practice-toggle and Match-3 navigation selectors; those failures are unresolved and do not establish a gameplay pass. A first UI attempt could not initialize because device authentication was canceled while locked (`/tmp/LinleyExpandedUI.xcresult`); no app behavior was tested in that attempt.

Generated concept: `docs/reviews/2026-10-17-challenge-chapters-concept.png`, clearly a proposal, not actual gameplay. Artwork/scenery/proxy hero differs from the native build. Family play, difficulty tuning, visual review, broader VoiceOver, iPhone runtime and all-board hands-on testing remain open. No TestFlight/App Store upload, merge, commit/push or unrelated cleanup by this round.
