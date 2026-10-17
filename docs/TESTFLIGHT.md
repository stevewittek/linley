# Linley private TestFlight — October 17, 2026

Dad explicitly requested TestFlight distribution so he can install on his phone. This authorizes this private beta upload, not a public App Store release, public testing link or Git main merge.

## Verified

- Release archive **0.4.4 (9)** built successfully for generic iOS under **NETHERWOOD DATA PARTNERS LLC**, team `26VH66ATMP`. Existing local-device development signing remains unchanged in the project.
- App Store Connect app record created: **Linley**, Apple app ID **6824064577**, bundle `com.netherwooddatapartners.linley`, English (United States).
- Xcode Organizer **TestFlight Internal Only** upload succeeded. Final UI: `App upload complete: Linley 0.4.4 (9) uploaded`. Distribution log at 21:28:34 UTC: `Upload succeeded for archive Linley`; ContentDelivery: `UPLOAD SUCCEEDED with no errors`.
- Archive: `/tmp/Linley-TestFlight-0.4.4-9.xcarchive`. Build log: `/tmp/linley-testflight-archive.log`. Distribution logs: `/var/folders/gb/hgf3flxx0kq8b7vdvrt_97680000gn/T/Linley_2026-10-17_17-27-12.417.xcdistributionlogs`. Logs can contain authentication information: do not commit or share raw logs.

The first creation attempt returned a UI error immediately after Apple had successfully created the app (HTTP 201); the immediate app-list refresh was still empty. Restarting distribution found the existing record and completed upload. No duplicate app was created.

## Still pending

App Store Connect browser session is signed out; Apple's authentication iframe remains on a loading spinner. Dad has been asked to sign in. Live handoff: [Linley TestFlight](https://appstoreconnect.apple.com/apps/6824064577/testflight).

After sign-in: verify Apple has processed this exact build, complete accurate encryption compliance if requested, create/select a private internal tester group, assign build 0.4.4 (9), and add Dad's existing App Store Connect account as a tester. Then verify the invitation/build is available in TestFlight on his phone. Upload success alone does not prove processing, tester access, invitation delivery or installation. No public link or external beta review requested/submitted. Do not grant a child App Store Connect credentials or team access.

On the phone, use Apple's TestFlight app with the invited Apple Account and install Linley after the build becomes available. Apple's [internal testing instructions](https://developer.apple.com/help/app-store-connect/test-a-beta-version/add-internal-testers) distinguish this from external testing.

## Candidate and validation limits

This archive includes the current combined local app: the private studio, Creative Quest, earned coins/art shop, game music/exploration, Puzzle Chase, and new editable Sketchbook. Base Git commit `9f9a434`; preserved uncommitted game/audio work is included in the uploaded app with Dad's request to publish the current app, but wasn't committed/pushed as unrelated changes. `TESTFLIGHT_0.4.4_SOURCE_MANIFEST.json` records SHA-256 hashes of the exact source/assets in this candidate without secrets or personal reference photographs. No user-created local media is part of the release archive.

Earlier game/device test evidence remains in the relevant validation documents. Sketchbook source/tests compile; its new runtime tests have not run because the iPad is locked. Phone installation, actual new sketchbook screenshots, physical Pencil input, complete accessibility and Dad/Lorelei acceptance remain pending. This is an internal beta upload, not evidence that release milestone #4 is complete.
