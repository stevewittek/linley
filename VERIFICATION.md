# Phase 1 verification — October 17, 2026

## Creative Quest 0.4.1 update

Lorelei/Hailey illustrated heroes, the game loop and current iPad evidence are documented in [CREATIVE_QUEST_VALIDATION.md](docs/CREATIVE_QUEST_VALIDATION.md). The physical iPad passed 18 model/storage tests and the focused game UI walkthrough; two coin/Image Maker walkthroughs passed separately. Portrait and landscape device screenshots are saved. This supersedes the earlier simulator/device blocking notes only for these verified checks; camera and iPhone gameplay/family acceptance remain open.


## Earned coins and Image Maker update

Working source adds 100 Linley Coins per new adventure completion, a shared local balance, confirmed permanent art-pack unlocks and a free local stamp Image Maker saving into My Stuff. No real-money purchases or paid AI service.

On the physical 10th-generation iPad: **18 model/storage tests passed**, and **two focused UI walkthroughs passed** for earned-pack-to-image-save and free-image-to-gallery. Earlier UI timing/runner failures and their final passing result are recorded in [COINS_VALIDATION.md](docs/COINS_VALIDATION.md). Real test-only device screenshots are linked there. Family visual acceptance and new iPhone runtime checks remain open; this does not close milestone #2.

## Physical iPhone retry — October 17, 2026

- Current source commit: `3dbfeab` on `codex/phase1-iphone`.
- Signed Debug build succeeded for the paired iPhone 17 Pro after allowing Xcode provisioning updates using the configured developer team.
- Device installation succeeded for `com.netherwooddatapartners.linley`, version 0.4.0 build 5.
- Launch was denied by iOS security: invalid signature, inadequate entitlements, or developer profile not explicitly trusted. The device error does not distinguish these causes; no successful launch or hands-on feature validation is claimed.
- Next: on the iPhone, review the developer trust prompt or Settings > General > VPN & Device Management, then open Linley again. If trust is already established, investigate the signing/profile rejection further.
- This supersedes the earlier connection timeout for build/install only. Family acceptance and runtime checks remain open.

## Passed
- Xcode 27.0 (27A266a): unsigned generic iOS `build-for-testing` compiles the iPhone/iPad application and XCTest bundle.
- Unsigned arm64 iOS Simulator `build-for-testing` compiles the app and XCTest bundle.
- `scripts/test-storage.sh` compiles and executes actual production MediaStore/DemoCatalog sources on macOS: six passing groups covering copy/save/reload/delete; missing-source rollback; backup exclusion/path validation; profile replace/remove and persisted creator links; default deny policy/search/linked-only filtering; corrupt-index preservation and write denial. Output: `docs/validation/storage-tests.txt`. File-copy smoke fixtures are synthetic bytes; this is not a media-decoding/playback test.
- Project and privacy manifest property-list validation; whitespace check.
- Source audit: no networking code or third-party package dependencies; connected features hard-disabled. Preserved Builder has a historical suggestion ShareLink but is not reachable from active navigation. No media export surface exists.

## Attempted, blocked
- Default simulator creation failed because CoreSimulator's configured storage resolves to `/Volumes/Netherwood/Xcode-Development/Mac-Support/Developer/CoreSimulator/Devices` and reported permission errors. That configuration was not modified.
- Created an isolated iPhone 17 Pro/iOS 27 simulator under `/tmp/LinleyPhase1Devices`; it booted, but app installation did not complete and Xcode could not discover it as a test destination. Test execution failed with “Unable to find a device matching the provided destination specifier.” The isolated device was shut down and its orphan processes cleaned up. No runtime success is claimed.
- Physical iPhone was listed as paired/available by devicectl. A signed build targeting that iPhone timed out with “Connecting to iPhone (63) Xcode will continue when the operation completes.” Signing, installation and launch were not reached; no account, provisioning, or device settings changed.
- Native screenshot/UI automation was unavailable. No app screenshots were obtained, and no generated concepts are presented as running-app evidence.

## Not verified on a running iPhone or simulator
Camera photos/video, front/back switching, permission denial/recovery, microphone recording, library import, media preview/playback, camera retake, video trimming, profile crop, navigation appearance/layout, Parent Center authentication/background relock, and actual process-kill/relaunch persistence through the UI.

The local storage reload checks passed; they do not establish end-to-end iPhone Definition of Done. The new XCTest suite compiled but could not execute in this environment. Device acceptance remains open.

## Remaining acceptance and next step
Open Linley.xcodeproj in Xcode, unlock/trust the paired iPhone, resolve its connection, select the existing authorized developer team, and Run. Follow README's disposable-media walkthrough and record actual observations under GitHub #2. Capture real Home/My Stuff/Watch screenshots and obtain Dad/Lorelei visual approval. Keep #2 open until device and family acceptance are observed. Historical detail issues #5–18 are closed as superseded, not completed.

Additional filters, large-media quota/downsampling, interrupted-write/orphan recovery, Android, production adult identity/consent/moderation, backend, TestFlight and App Store distribution remain incomplete. No merge, deployment, Azure provisioning or child-media transmission occurred.
