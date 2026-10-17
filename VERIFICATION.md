# Phase 1 verification — October 17, 2026

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
