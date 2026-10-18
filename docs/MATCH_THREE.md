# Gem Garden — Match-3

Broad milestone: [#22](https://github.com/stevewittek/linley/issues/22), GitHub Project 2, In Progress. Local review candidate 0.4.5 (10). Family gameplay/visual acceptance pending.

## Play and rewards

Games now offers Gem Garden, Puzzle Chase and Creative Quest. Every game contributes to the existing local Linley Coins wallet. Gem Garden uses a 6×6 board with five distinguishable tile types. Tap two neighbors or swipe one space; swaps must produce a horizontal/vertical run of three. Invalid swaps cost no moves. Clears score 10 points per tile, multiplied by the cascade number up to 5×. Gravity/refill repeats until stable. No available move triggers a free fresh board; generated boards start match-free and have a legal swap. Hints are free.

Ten levels unlock in sequence with targets 120/300/600/900/1200/1500/1800/2100/2400/2800 and 18–24 moves. Reaching the goal on the last move wins. Running out of moves loses that board, with unlimited free retries and no Puzzle Chase life cost. Restart requires confirmation. Leaving pauses; board, generator state, moves and score persist.

Each fresh completed attempt earns 100 coins; first clears of levels 5/10 earn 200. Replays earn 100. Terminal attempts reject further swaps, so navigation/reopening cannot award twice. The whole QuestProgress record contains the resolved board, cleared levels and wallet update. Existing migration, coins, art packs, hero and Chase lives remain intact. Spend in the existing Creative Shop with its confirmation step. Coins never represent money; no new network/service/account is added.

## Upstream reuse

Adapted from [Kenney Starter Kit Match-3](https://github.com/KenneyNL/Starter-Kit-Match-3), revision `4ddb3d2a50cbf247c79cafe9e7884d7d8f99c012`. This is a **native Swift adaptation**, not an embedded Godot project. Match scanning, swap rollback, collapse/refill follow `main.gd`; campaign, saves, score, dead-board handling and wallet integration are additions. The original `main.gd` and MIT license are preserved under `docs/licenses/kenney-match3/`. Three CC0 tile sprites are bundled under MatchTiles, along with MIT license and provenance. Existing CC0 QuestAudio supplies music/effects, including silence/background/interruption handling.

## Review evidence

- `scripts/verify-match-three.sh` compiles the actual production MatchEngine, ChaseEngine and QuestStore on macOS with an isolated temporary defaults suite. Output below is from October 17, 2026.
- 2,000 stable/playable deterministic boards; 200 complete attempts covering cascades, losses, terminal guards and dead-board refresh.
- All ten goals reached using normal engine swaps; campaign bonuses total 1,200 coins. Shared shop purchase, duplicate-purchase rejection, replay reward, no duplicate completion reward, active/terminal save recovery, free retries, old-save migration and corrupt-state rejection passed.
- Seven focused XCTest methods and a UI walkthrough were added. The UI scenario plays four real swaps on a seed-1 DEBUG test board to earn 100, then buys Garden Party in the existing shop; no injected reward or forced win. All seven Match-3 methods passed as part of 44 model/storage tests on the physical iPad; the final UI walkthrough also passed after the accessibility correction below.
- Signed iOS and generic simulator test builds pass. The iPad was unlocked and runtime validation completed; see the physical evidence below. Default simulator device storage is inaccessible and this installation has no Simulator.app. A separate temporary simulator device set successfully launched the real app headlessly; the actual board screenshot is docs/reviews/2026-10-17-match3-board-simulator.png (SIMULATOR, not physical evidence). A DEBUG-only startup path, gated behind --quest-ui-tests plus --match-review-board, opens the actual MatchGameView with an isolated seed-1 board. It does not inject wins/rewards and is absent from Release. This validates rendering, not tap/swipe interactions. The later physical UI walkthrough verified taps, rewards and shop purchase; family acceptance and broader gesture/accessibility coverage remain pending.
- `docs/reviews/2026-10-17-match3-concept.png` is a generated CONCEPT, not implemented artwork or a working screenshot. Family approval pending. Current native game uses Kenney gem/grass/cog tiles with sun/heart variants. The concept's richer background and leaf/crystal artwork are not implemented; its decorative plus sign is not a purchase feature.

No TestFlight upload, App Store distribution, commit, push or merge is performed by this Match-3 work. Other dirty changes from the studio/release work are preserved.

## Physical iPad verification — October 17, 2026

Installed 0.4.5 (10). `/tmp/LinleyMatchDeviceTests.xcresult` passed all **44 model/storage/audio tests**, including seven Match-3 methods and existing Quest/Chase/Sketchbook coverage. Its UI test exposed duplicate accessibility nodes during tile replacement after the third swap. The first fix flattened tile contents but removed their button role, correctly caught by `/tmp/LinleyMatchDeviceUIFinal.xcresult`. Final tile controls ignore decorative children and explicitly retain the button trait.

`/tmp/LinleyMatchDeviceUIVerified.xcresult`: the full Match-3 UI walkthrough **passed**, zero failures, on the connected physical iPad (10th generation). Entered Games and Match-3, checked both board corners in viewport, made four normal swaps on the isolated seed-1 DEBUG board, observed 120 points/14 moves remaining and 100 Linley Coins, opened the existing Creative Shop, confirmed spending 100 on Garden Party, and verified zero remaining coins plus the Unlocked pack. No score, win or reward injection.

Actual device screenshots: [board](reviews/2026-10-17-match3-board-device.png), [win/reward](reviews/2026-10-17-match3-win-device.png), [shared shop purchase](reviews/2026-10-17-match3-shop-device.png). Images inspected for layout. Tests used the existing isolated game/audio/media stores; afterward a normal launch without test flags succeeded, restoring owner progress/library. No TestFlight upload. Broad milestone stays In Progress for Dad/Lorelei play/visual acceptance. This sample does not establish swipe, VoiceOver, all-level hands-on difficulty or iPhone runtime acceptance.
