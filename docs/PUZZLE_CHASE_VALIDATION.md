# Puzzle Chase verification — October 17, 2026

Linley 0.4.3 build 8, existing working branch. Game milestone #20 is active, future expansion milestone #21 is planned. The earlier calm-game and studio changes are preserved. Changes are local and uncommitted/unpushed by this session.

## Solvability and model checks

A development-only native breadth-first solver compiled the actual production `ChaseEngine.swift`, searched all ten boards and found winning routes. It detected an unwinnable initial level-5 encounter; that encounter was rebalanced and rechecked. The resulting route fixtures are replayed in XCTest, with required paint drops and gates checked at the exit. The final mixed-puzzle level requires both its switch and a crate on its plate. Solvability proves a route exists, not that the difficulty is appropriate for every player.

Final selected physical-iPad run `/tmp/LinleyChaseFinal.xcresult`: **32 model/storage/audio tests plus two UI walkthroughs passed, zero failures**. New model tests cover:

- All ten winning routes, blocking/invalid movement, enemy turn cadence, waiting/capture and move-limit failure.
- Crate pushing and plate gates, switches, portals, chapter/level progression, repeat-win coins and prevention of duplicate saved-win claims.
- Life loss exactly once, persistence, the 20-minute boundary, accumulated refills capped at five, clock rollback not granting refills, confirmed coin/life accounting and natural-refill/purchase races.
- Practice having no rewards/unlocks/life costs, and old studio/game saves migrating without losing coins, packs or hero.

Earlier `/tmp/LinleyChaseModels.xcresult` passed all 32 model tests after the owner unlocked the iPad. `/tmp/LinleyChaseUI.xcresult` had one passing Practice/crate walkthrough and one test failure because iPad confirmation popovers omit an explicit Cancel button. The final test dismisses that popover outside its bounds and checks the balance before confirming a later purchase.

## Actual iPad walkthroughs

- Completed level 1, observed 100 coins and next-level access; waited for capture in level 2, observed four lives and a refill timer; dismissed the coin confirmation without a debit, then confirmed 100 coins for one life and observed five lives/zero coins.
- Entered level 3 in Practice, pushed a crate onto its pressure plate, observed the gate opening, then waited for capture and verified five lives and zero coins remained.
- Final source adds a wording-only gate instruction correction distinguishing switch-only, plate-only and combined requirements; it is rebuilt before owner installation. It does not change game rules or the passing open-gate assertion.
- Visual inspection of the first passing-run screenshots caught a board origin/alignment bug: the offset tiles were centered inside their fixed frame and extended offscreen. The maze frame was corrected to top-leading alignment. Both walkthroughs are rerun with explicit top-left/bottom-right viewport assertions and separation from movement controls; their final result is recorded below. This illustrates why the earlier behavior-only pass did not establish visual acceptance.

Real test-storage screenshots:

- [Level clear and earned coins](reviews/2026-10-17-puzzle-chase-win-device.png)
- [Capture, life loss and free-refill timer](reviews/2026-10-17-puzzle-chase-loss-lives-device.png)
- [Crate and pressure gate in Practice](reviews/2026-10-17-puzzle-chase-crate-device.png)

The separate [generated design concept](reviews/2026-10-17-puzzle-chase.md) is labeled CONCEPT and remains approval pending. Its richer illustration and proxy hero are not implemented or accepted app art. Real app hero artwork is retained.

## Final visual/layout check

`/tmp/LinleyChaseLayoutFinal.xcresult`: both UI walkthroughs passed after the alignment correction, with viewport checks confirming both maze corners are inside the screen and the board does not overlap the Down control. The initial viewport test also exposed a parent accessibility identifier overwriting tile identifiers; the aggregate identifier was removed and wall labels were made explicit. Final screenshots above replace the earlier offset-board captures and come from this passing layout run. The final source still has 32 passing model/storage/audio tests from the combined run and the same production rules; the last changes were layout, instructions and accessibility labels.

The development-only reproducible solver at `scripts/verify-puzzle-levels.sh` was rerun successfully against the final production engine; all ten boards still have winning routes. Signed 0.4.3 build 8 was installed during device tests. A normal owner launch without test arguments succeeded after the final run, restoring the real owner game/media stores. Test progress did not overwrite owner progress.

## Remaining family and device review

Dad/Lorelei play-feedback, visual approval, difficulty pacing across all ten levels, broader accessibility/device coverage and new iPhone runtime acceptance remain open. The automated UI sample does not claim hands-on play-testing of every board. No real-money purchases, network account, ads, push notifications, publishing, store distribution, main merge or unrelated cleanup occurred.
