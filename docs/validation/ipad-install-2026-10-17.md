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
