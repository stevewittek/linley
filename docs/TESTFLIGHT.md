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
