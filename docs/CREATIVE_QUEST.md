# Creative Quest — local mini game

Requested and chosen by Dad on October 17, 2026. Added to the existing native app under milestone #2, without changing the private creation studio's media features. Version 0.4.2 build 7 adds audio and garden exploration. Current illustrated characters are retained; a fuller customizable in-world avatar is deferred per Dad's direction.

## Play
Home → Games (controller icon beside Profile) → Creative Quest → Let's play.
Tap a garden tile to walk there automatically, or use the four arrow buttons. Plants block movement. Collect the paintbrush, palette, pencil, scissors and paper star. When all five are found, earn the adventure's sticker and 100 Linley Coins, then choose Next adventure. Garden themes rotate through Coral Garden, Blue Daydream, Sunshine Studio and Mint Meadow, with four mirrored layouts and different start/supply/plant positions. Eight sticker designs cycle, plus another 100 coins for each newly completed adventure. There is no timer, loss state or combat.

## Garden exploration and sound

Three optional garden stars are separate from the five required supplies. Collect all three before the final art supply to earn that garden's explorer badge. There are four badges, one per garden layout. Badges persist across adventures and restarts; stars reset for the next adventure. They do not award extra coins or block the main 100-coin completion reward. **Hint** shows a golden path to the next missing supply. Completion adds a banner, a gentle hero scale celebration and haptic feedback where supported; Reduce Motion suppresses the scale animation.

**Game Sound**, beside the coin balance, has separate persistent Music and Sound effects switches plus an optional test sound. Movement, supplies, garden stars and completion have short effects; the background track loops quietly. Audio is bundled for offline play, follows Silent Mode and mixes with other audio. Leaving the game or backgrounding the app pauses it. Calls/audio interruptions pause playback; the system's resume permission controls whether it resumes. Removing headphones turns music off. Audible volume, headphone behavior and interruption behavior still require owner listening on the target devices in addition to automated checks.

Music is Flowerbed Fields by Zane Little Music; effects are Kenney Interface Sounds. Both are CC0 1.0 assets with [licenses and provenance](ASSET_LICENSES.md#creative-quest-audio--cc0-10) and in-app credits. Apple's AVFoundation handles playback; there is no new game-engine package or runtime download.

Old saves keep their current original map for that in-progress adventure so a saved hero cannot become trapped in a newly mirrored plant. The next adventure upgrades to the rotating layouts, preserving coins, owned art packs, stickers and hero. New stars/badges default empty for old saves.

## Earn and create
Dad authorized earned currency on October 17, 2026. Linley Coins fit the existing art-supply game and work across the game and creation studio automatically. They are fictional local points, with no cash value, purchase route, cash-out, person-to-person trading, ads, random prizes, expiry or daily streak requirements. Completing an adventure awards 100 coins once; revisiting a completed adventure cannot claim again. Partial restarts preserve existing coins, stickers and packs.

Home → Creative Shop shows the shared balance and three permanent unlocks: Garden Party (100 coins), Dream Studio (200), Maker Magic (300). Each includes three reusable art stamps. A confirmation shows the cost before spending; duplicate unlocks, unknown packs and insufficient funds cannot deduct coins. The wallet and owned packs live in the same persisted record as adventure completion, preventing a separate reward claim from duplicating a completed level. One app-owned QuestStore serves all screens.

Home → Image Maker works immediately with free star, heart and circle stamps. Choose ink and paper colors, select a stamp, and tap to place it. Earned packs add more stamps; reuse and saving cost no coins. Undo removes the last stamp. Up to 40 stamps fit on one image; images render locally as 768 × 768 JPEGs and save privately into My Stuff. This is a local composition tool, not a paid AI generation service. Camera, import and basic creation remain free.

Existing saves migrate with heroes, partial progress and stickers intact. Old completed adventures do not retroactively claim coins; the next newly completed adventure earns 100. Malformed balances or ownership fail closed. Explicit corrupt-game reset includes game coins/packs; it does not touch My Stuff or profile media. Points remain on the current device; cross-device sync is not implemented.

My Hero selects Lorelei, Hailey or Make my own and changes custom skin tone, hair color/length and outfit. Lorelei is the default illustrated hero, inspired by the parent-supplied reference. Hailey is a second illustrated choice. Make my own retains the native customizable character. Changing style controls switches to Make my own; choosing Lorelei/Hailey restores that preset. The original photo is not bundled or committed. Sticker Board shows earned/locked stickers. Hero, partial adventure and earned stickers persist on this device. Restart resets only the current unfinished adventure; earned stickers remain. Corrupt game data is preserved until the owner explicitly resets only the game. App photos/videos are not involved.

## Implementation and reuse
Original small SwiftUI game, native SF Symbols, AVFoundation and Foundation/UserDefaults. Third-party CC0 audio is credited above; no third-party game code, engine packages, web views, download-at-runtime, network client or backend. Apple supplies native UI, animation and playback tools. A compact grid game does not need a physics engine or old template code. Source is not represented as Roblox or Pinterest code/content.

Movement is bounded/adjacent, with breadth-first pathfinding around obstacles. Completed adventures cannot award extra stickers by continuing to move. Saved fields are validated before use. Walking cancels on leaving/background and respects Reduce Motion. Larger text and VoiceOver have native labels; full accessibility acceptance remains a device review item.

## Validation
Game model tests cover reachability/adjacent paths, blocked moves/teleports, win/reward persistence, bounded eight-sticker replay, hero and partial-save/restart behavior, corrupt-data recovery, coin spending, duplicate/insufficient/unknown unlocks, legacy migration and integer overflow. An isolated DEBUG-only UI-test game suite and temporary media directory prevent UI tests from resetting the child's real game or saving into their library. The earned-currency UI walkthrough completes an adventure, spends 100 coins, uses an unlocked stamp and saves to the test My Stuff gallery. See validation logs for actual execution results; source presence is not acceptance.

## Visual review
[Generated concept and exact prompt](reviews/2026-10-17-creative-quest.md). CONCEPT only. Actual prototype artwork is simpler. Visual acceptance remains pending.
