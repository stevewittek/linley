# Linley private TestFlight — October 17, 2026

Dad explicitly requested TestFlight distribution so he can install on his phone. This authorizes this private beta upload, not a public App Store release, public testing link or Git main merge.

## Verified

- Release archive **0.4.4 (9)** built successfully for generic iOS under **NETHERWOOD DATA PARTNERS LLC**, team `26VH66ATMP`. Existing local-device development signing remains unchanged in the project.
- App Store Connect app record created: **Linley**, Apple app ID **6824064577**, bundle `com.netherwooddatapartners.linley`, English (United States).
- Xcode Organizer **TestFlight Internal Only** upload succeeded. Final UI: `App upload complete: Linley 0.4.4 (9) uploaded`. Distribution log at 21:28:34 UTC: `Upload succeeded for archive Linley`; ContentDelivery: `UPLOAD SUCCEEDED with no errors`.
- Archive: `/tmp/Linley-TestFlight-0.4.4-9.xcarchive`. Build log: `/tmp/linley-testflight-archive.log`. Distribution logs: `/var/folders/gb/hgf3flxx0kq8b7vdvrt_97680000gn/T/Linley_2026-10-17_17-27-12.417.xcdistributionlogs`. Logs can contain authentication information: do not commit or share raw logs.

The first creation attempt returned a UI error immediately after Apple had successfully created the app (HTTP 201); the immediate app-list refresh was still empty. Restarting distribution found the existing record and completed upload. No duplicate app was created.

## Private testing enabled

Dad signed in to App Store Connect. Build **0.4.4 (9)** finished processing, initially showing **Missing Compliance**. Source inspection confirmed no proprietary or standard encryption implementation outside Apple's OS APIs or third-party crypto dependencies. Selected **None of the algorithms mentioned above** in Apple's encryption dialog; build changed to **Ready to Test**.

Created internal group **Linley Private Beta**, group ID `d3514be3-500e-4da6-9dc5-72beba08ab85`, with automatic distribution disabled. Added only build **0.4.4 (9)**, build ID `2c1a2ac9-592a-4041-8376-d17393a10d1c`. Added Dad's existing Steven Wittek Account Holder/Admin account as a tester. Apple confirmed **1 Tester · 1 Build**, with that tester **Invited** and the assigned build **Ready to Test**. No team roles or credentials were created or expanded.

Actual App Store Connect screenshot: `reviews/2026-10-17-testflight-ready.png`. It shows the private group, tester/build count, and exact ready build without the tester email. This is web-console evidence, not a screenshot of the app running on a phone.

[Private group](https://appstoreconnect.apple.com/teams/cebebcc3-3c4c-4ec9-b8ea-421150297b27/apps/6824064577/testflight/groups/d3514be3-500e-4da6-9dc5-72beba08ab85). On the phone, install Apple's TestFlight app, open Dad's invitation and accept, then install Linley. Invitation acceptance and phone installation remain user steps and have not been verified. The beta has no public testing link; no external beta review or public release was submitted. Future uploaded builds require manual group selection.

## Candidate and validation limits

This archive includes the current combined local app: the private studio, Creative Quest, earned coins/art shop, game music/exploration, Puzzle Chase, and new editable Sketchbook. Base Git commit `9f9a434`; preserved uncommitted game/audio work is included in the uploaded app with Dad's request to publish the current app, but wasn't committed/pushed as unrelated changes. `TESTFLIGHT_0.4.4_SOURCE_MANIFEST.json` records SHA-256 hashes of the exact source/assets in this candidate without secrets or personal reference photographs. No user-created local media is part of the release archive.

Earlier game/device test evidence remains in the relevant validation documents. Sketchbook source/tests compile; its new runtime tests have not run because the iPad is locked. Phone installation, actual new sketchbook screenshots, physical Pencil input, complete accessibility and Dad/Lorelei acceptance remain pending. This is an internal beta upload, not evidence that release milestone #4 is complete.


## 0.4.8 (13) — interactive Style Studio
Dad explicitly authorized this private TestFlight upload for his iPhone. Signed Release archive `/tmp/Linley-TestFlight-0.4.8-13.xcarchive` succeeded with team 26VH66ATMP. Upload via xcodebuild exportArchive/app-store-connect/internal-only succeeded October 17, 2026 at 20:11:57 Eastern (`Upload succeeded`, `EXPORT SUCCEEDED`). App Store Connect processing completed. Saved the source-verified None of the algorithms mentioned above encryption answer; build 13 became Ready to Test. Manually assigned it to existing Linley Private Beta. Verified group: 1 Tester, 2 Builds, exact 0.4.8 (13) status Testing. Build ID 3096082b-f089-4935-b0a2-aa7c8550e6fd. Evidence: docs/reviews/2026-10-17-testflight-048-ready.png. No phone installation/acceptance claim. No physical iPad use.

Source hashes: TESTFLIGHT_0.4.8_SOURCE_MANIFEST.json; exact signed bundle hashes: TESTFLIGHT_0.4.8_ARCHIVE_MANIFEST.json. Combined current local app includes preserved earlier work; no unrelated commit/push or merge. Source uses existing Apple-provided protection/audio/photo APIs and no new crypto library. Personal photo mode remains a local illustrated face avatar, not photorealistic garment transfer.

Latest evidence: docs/reviews/2026-10-17-style-fitting-room-simulator.png and style-fitting-gallery-simulator.png. Style production-source reward/ownership/ledger/migration/private storage checks and Match-3 4,000-board/200-attempt regression passed; generic simulator build and signed archive passed. New physical camera/Photos, iPhone hands-on, accessibility and family approval remain open.

Extra iPhone simulator startup stalled and was shut down; no iPhone runtime/layout acceptance is claimed.


## 0.4.9 (14) — owner-requested phone editor revision
Dad reviewed 0.4.8 on his phone and requested continued development: hidden editing tools, no movement and disconnected head/hair. Revised editor and avatar registration prepared under the existing private beta scope. Signed Release archive `/tmp/Linley-TestFlight-0.4.9-14.xcarchive` succeeded. Internal-only upload completed October 17, 2026 at 21:13:21 Eastern: Upload succeeded / EXPORT SUCCEEDED. Apple processing completed; saved the source-backed Apple-only encryption answer. Build 14 became Ready to Test, then was assigned to existing Linley Private Beta through Add Group. Verified exact Version 0.4.9 / Build 14 / Testing / Linley Private Beta. Build ID 1e29f513-7a5e-4a24-968f-b00fbf416e04. Evidence: docs/reviews/2026-10-17-testflight-049-ready.png. No 0.4.9 phone installation or owner acceptance claim.

Source manifest: TESTFLIGHT_0.4.9_SOURCE_MANIFEST.json. Exact archived-bundle manifest: TESTFLIGHT_0.4.9_ARCHIVE_MANIFEST.json. Verified bundle version/build and unchanged source hashes before upload. Combined current local app preserved; no unrelated commit/push/merge. No new encryption implementation or backend.

Production-source wardrobe/coin/storage/migration/placement checks passed; final generic simulator build-for-testing and signed archive passed. Actual iPhone 17 Pro simulator shows the persistent preview, visible categories and fictional-avatar makeup/movement review fixtures. New phone UI test compiled but did not execute: default simulator creation failed and Xcode doesn't discover the custom device set. No physical iPad actions or real-photo/camera/Photos testing. Owner acceptance remains open. Review evidence: docs/reviews/2026-10-17-style-editor-revision.md.

## 0.5.0 (16) — shared avatars and reactions
Dad authorized the next avatar milestone and cross-machine coordination. Broad issue #24, milestone9 and draft PR#25 record scope and review. Shared protected saved avatars now appear across games/player cards/victories. Three finite poses; Dance Studio later. Voyager1 performed exact-source Windows game/reward inspection with no actionable findings; Voyager2 used supported GPT-5.6 Sol medium for a source-bundle review after its shell sandbox blocked reads. Mac integrated privacy/storage/rendering findings and verified source checks, simulator compilation/previews and signed Release archive.

Signed archive /tmp/Linley-TestFlight-0.5.0-16.xcarchive, team26VH66ATMP, exact0.5.0/build16. Source hashes unchanged before export. Internal-only upload succeeded October17,2026 at23:23:43 Eastern; EXPORT SUCCEEDED. Apple processing completed. Saved source-verified Apple-only encryption metadata. Assigned exact version0.5.0/build16 to the existing Linley Private Beta group; console verifies Testing and the selected group. Build ID2c25c709-6319-436a-911d-6375df40dd61. Proof: docs/reviews/2026-10-17-testflight-050-ready.png. No installation or family acceptance claim. Source/archive manifests TESTFLIGHT_0.5.0_*.json. Physical iPad deferred.

An earlier build15 upload was interrupted without success receipt after a tiny-avatar label overlap was caught; it was never assigned to testers. Final build16 suppresses stage lettering in game portraits. The source handoff branch preserves the original working HEAD/index and publishes only the reviewed app/game baseline plus related evidence, not unrelated documentation. No merge, public App Store release, new services or credentials.
