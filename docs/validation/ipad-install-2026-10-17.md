# iPad installation attempt — October 17, 2026

Source commit: 3dbfeab, codex/phase1-iphone. Linley 0.4.0 build 5.

- The user reports that Linley is now on the iPhone and authorizes installation on the connected iPad. This is user-reported iPhone installation, not a complete feature-acceptance result.
- Connected iPad (10th generation) was available/paired.
- Signed Debug build targeting that iPad succeeded with Xcode 27 and the existing configured team, using provisioning updates.
- Installation failed before launch: CoreDeviceError 3002, underlying IXUserPresentableErrorDomain 11, “Insufficient storage.” The device reported 5,324,713 bytes needed and only 496,728 bytes available (0 free, 496,728 purgeable).
- No iPad launch or current-version device feature validation is claimed. No personal files or applications were deleted, and no iPhone installation was modified.

Next: the owner frees space using Settings → General → iPad Storage and keeps the device unlocked; then retry installing and launching the already-built app. Leave milestone #2 In Progress pending installation, real device checks and family review.

## Retry after owner freed space

- Installation succeeded on the connected iPad. Bundle: com.netherwooddatapartners.linley, version 0.4.0 build 5.
- Launch was rejected by iPadOS security: invalid signature, inadequate entitlements or profile not explicitly trusted. This is not a confirmed runtime launch.
- Local strict signature verification passed. The embedded provisioning profile includes this iPad and expires October 24, 2026. Manual developer trust is the next check; an entitlement/signing issue remains possible if trust is already established.
- Owner action: Settings → General → VPN & Device Management → developer entry listing Linley → Trust (or follow the displayed Allow & Restart flow), then open Linley. No trust or security setting was changed automatically.

## Developer trust approved

The owner reports approving the developer on the iPad. A new device launch request succeeded for com.netherwooddatapartners.linley. This verifies OS-level app launch after trust; it does not establish camera, import, crop, playback or Parent Center acceptance. Physical iPad XCTest execution was started next using the existing test suite and isolated temporary test storage.

Physical iPad XCTest result: **8 tests passed, 0 failures**. The six PrivateLibraryTests verify media copy/reload/delete using bundled video and a generated JPEG, failed-save behavior, backup exclusion/path validation, profile replacement/removal and creator links, default-deny policy/search/filtering, and corrupt-index preservation. Two existing brand/suggestion tests also passed. Test summary: ipad-tests-2026-10-17.txt. This replaces the prior “not executed” status for this XCTest suite on iPad only; hands-on capture/import/editing/parent-authentication and iPhone tests remain pending.
