# Earned coins and local image maker — October 17, 2026

Scope: local working changes layered onto the existing Creative Quest prototype; no unrelated changes committed, pushed or merged. Tracking: GitHub Project 2 / issue #2. Family acceptance remains pending.

## Build and model execution

- Unsigned generic iOS build-for-testing succeeded with Xcode 27.
- Signed physical iPad build succeeded using the configured development team and provisioning updates.
- 18 XCTest model/storage tests passed, zero failures, on the connected 10th-generation iPad. Nine game tests cover movement, sticker/coin completion, restart/reload, 10-adventure reward progression, duplicate/unknown/insufficient unlocks, legacy completed-save migration, malformed economy state and overflow. Other suites cover brand, character migration and private media storage.
- Property-list validation and whitespace checks passed.
- Initial result bundle: `/tmp/LinleyCoinsDevice.xcresult`. This combined run had passing model tests and a UI failure caused by tapping a supply while movement was still underway. The new walkthrough now waits for collection and uses stable cell identifiers.

## Observed runtime behavior

The next physical-iPad UI run completed an adventure, observed 100 Linley Coins, confirmed Garden Party for 100, observed zero coins and unlocked ownership, opened Image Maker, selected an unlocked leaf stamp, placed it and received the successful Save to My Stuff confirmation. Real screenshots were exported from that run:

- [100 coins earned](reviews/2026-10-17-coins-earned-device.png)
- [Garden Party unlocked](reviews/2026-10-17-coins-shop-device.png)
- [Unlocked stamp in Image Maker](reviews/2026-10-17-coins-image-maker-device.png)

These images are DEVICE VERIFIED screenshots from test-only storage. They are separate from the [generated concept](reviews/2026-10-17-earn-unlock-create.md). The screenshot observation is narrower than an overall passing test result.

The runner was killed with signal kill at the final gallery assertion in `/tmp/LinleyCoinsRetry.xcresult`, after those successful actions and screenshot attachments. A subsequent attempt failed before runner connection in `/tmp/LinleyCoinsFinal.xcresult`. The kill cause was not established. A focused run separates the earned-pack-to-save flow from the free-maker-to-gallery check; record its final result below.

## Final focused physical-iPad result

`/tmp/LinleyCoinsFocused.xcresult`: **2 UI tests passed, zero failures**. Earn → confirm unlock → owned stamp → successful image save passed. The separate free-maker → save → private gallery check also passed, with the saved Picture visible. This completes the two focused screen walkthroughs; prior runner-kill attempts remain recorded above. Together with the earlier model run, 18 model/storage tests and two UI tests passed.

Latest screenshots above were refreshed from the passing focused run. [Saved image in the test gallery](reviews/2026-10-17-coins-gallery-device.png).

The synthetic test-only library was copied from its isolated temporary device directory. Its index contained the saved picture, and the actual JPEG decoded visibly as the placed coral star with dimensions 768 × 768. No personal media were read. Linley was then launched normally on the iPad without UI-test arguments; the normal game and media stores are active for owner review.

## Remaining review boundaries

- No real money, purchases, ads, cash value, person-to-person transfers, online accounts or API-backed image generation.
- Existing local heroes/stickers migrate; previously completed adventures do not receive retroactive coins.
- Wallet/unlocks persist locally and are shared across app screens; there is no cross-device sync.
- This pass does not establish new iPhone runtime, physical camera, full accessibility or family visual acceptance.
