# Creative Quest and characters — October 17, 2026

Version 0.4.1 build 6, feature branch codex/phase1-iphone. Default character: Lorelei; selectable Hailey and Make my own. The parent supplied the reference and requested these illustrated game characters. The original photograph is excluded from the app and repository. The repository was verified PRIVATE before uploading derived character assets; no public release or main merge is authorized by this work.

## Passed on the physical iPad

- Signed build and app launch.
- 18 model/storage tests passed, 0 failures, including game reachability/blocked movement, completed/partial progress, eight-sticker replay, hero persistence, old-avatar migration, default Lorelei and Hailey encoding, media storage, and the separately requested earned-coin model tests. Summary: validation/creative-quest-model-tests.txt.
- Final game UI test passed, 0 failures, in /tmp/LinleyQuestHeroPortraitLandscape. It opened Games, completed an adventure, verified an earned sticker, switched to Hailey and back to Lorelei, visited custom style controls and started Adventure 2. It also rotated to landscape and verified the Move right control remained hittable. Summary: validation/creative-quest-device-ui-tests.txt.
- Two separate coin/Image Maker UI walkthroughs passed in /tmp/LinleyCoinsFocused.xcresult; see COINS_VALIDATION.md. These are separate runs, not one claimed all-tests-at-once pass.
- Whitespace and project property-list checks passed.

DEVICE VERIFIED screenshots from the final game run:
- [Lorelei / portrait game](reviews/2026-10-17-creative-quest-ipad-portrait-device.png)
- [Hailey selected](reviews/2026-10-17-creative-quest-hailey-device.png)
- [Sticker board](reviews/2026-10-17-creative-quest-stickers-device.png)
- [Landscape controls](reviews/2026-10-17-creative-quest-ipad-landscape-device.png)

The picture concept is separately labeled CONCEPT. Initial screenshot review caught and corrected board alignment; a transient zero-size layout warning was fixed by bounding tile sizes. A partial-progress test originally assumed only the target item would be collected, but pathfinding correctly picked up another supply along the route; the assertion now verifies the complete persisted set. UI waits now follow actual supply disappearance instead of a fixed guessed movement delay. Earlier attempts had runner trust/connection issues and competing device runs; final focused game and coin walkthroughs passed. Hair-control interaction was exercised, but exact custom-hair appearance, full accessibility and family visual acceptance remain manual review items.

## iPhone limits

The signed game/character build succeeded and installation on the iPhone succeeded. Subsequent launch/combined-build update attempts lost the device connection or failed its device-services availability assertion. No new iPhone gameplay acceptance is claimed. The most recent combined coin/shop update still needs an iPhone reconnect/install check. Do not equate the successful earlier installation with this later update or runtime validation.

## Remaining

Family likeness/visual approval, hands-on iPhone gameplay, broad accessibility coverage, varied maps/walking animation and any public distribution. Current replay uses one map, four color themes, eight cycling stickers and local saves. No ads, real-money purchases, chat, tracking or app upload service. The user-authorized coin/art-pack extension is free and local. Milestone #2 remains In Progress.
