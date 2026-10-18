# Shared avatars and reactions — working review

Broad ticket #24 / milestone 9. Family review pending; physical iPad remains deferred. Existing outfit direction retained.

## Implemented
Save/name/select an active private avatar from Style Studio; one shared protected look library feeds all games, player cards and victory reactions. Delete/face removal updates shared appearances. Ownership reset uses free wardrobe while preserving saved artwork. Three finite whole-character poses (Hello, Celebrate, Spotlight), backdrop stationary; Reduce Motion and background cancellation. These are illustrated poses, not rigged dancing. Dance Studio remains future work.

Phone layout review reduced the reaction stage, added a selector above it, and fixed the Play label contrast. Avatar and stage screenshots use DEBUG fictional free looks only, no purchase bypass or personal photos. A review flag plays one finite Celebrate sequence for simulator recording; it does not automate normal player input or ship in Release.

## Coordination and bounded reviews
Review source snapshot a2c41065ae70c4419d435a9a533e01a2ce7d6cdf on codex/shared-avatar-milestone includes previously local 0.4.9 game baseline plus new avatar work. Mac HEAD/index and unrelated documentation left intact. All machines receive docs/AVATAR_MILESTONE_HANDOFF.md.

Voyager 1 pulled exact source in D:/Dev/Linley outside Garmin and completed its focused reward/engine/avatar integration review with no actionable findings. Receipt: https://github.com/stevewittek/linley/issues/24#issuecomment-6245116967. Static Windows inspection only, source a2c41065ae70c4419d435a9a533e01a2ce7d6cdf; later Mac fixes outside that review. Mac owns integration and Apple tests. Voyager 2 pulled exact source in /home/nasa/linley-reviews/avatar-milestone. Its CLI rejected GPT-6.1 Sol; GPT-5.6 Sol medium was supported. Its read-only namespace blocked file reads, so an exact line-numbered Git source bundle was supplied through stdin; model was explicitly instructed not to call tools. Review completed source-only, no iOS execution or production-service changes. No further remote worker chains or repeated broad passes.

Voyager 2 findings and disposition:
1. Photos sync disclosure: clarified before export that Photos may sync through system settings; local editable avatars/My Stuff remain private app storage.
2. Crop temporary files: ProfileCropView already removes its file on normal disappearance; added dedicated protected/backup-excluded crop directory, scoped onDismiss cleanup and startup purge for interrupted flows. No broad temp deletion.
3. Corrupt studio recovery: preserve original by default; explicit in-app confirmation can delete only the unreadable studio and restart. Coin wallet/My Stuff separate. Reset error preserves state.
4. Main-actor launch read: app defers protected library read/JSON decoding/validation to a utility task, publishes once; loading blocks mutation. Sync test/fixture initialization retained.
5. Face rendering allocations: view-scoped StateObject retains decoded UIImage for unchanged photo payload; photo identity changes recreate it. No global private-photo cache; synchronous ImageRenderer export preserved.

## Evidence
Production style checker passed avatar atomic selection/reload/unknown ID/deletion, original hero, wardrobe-reset fallback, photo erase propagation, legacy migration, deferred load-once/mutation guards, corrupt file preservation/reset/recovery, scoped crop cleanup and unrelated-file preservation, plus prior wallet/purchase/brief/privacy cases. Match checker passed 4,000 stable/playable boards, 200 attempts and all20 campaign goals/reward/reload guards. Production solver verified all20 authored Chase boards, level20 105909 explored states. Generic ARM64 iOS Simulator build-for-testing passed; test bundles compiled, not executed. Headless simulator runtime review is separate from physical interaction/Photos permissions or family acceptance.

Release target: 0.5.0 (16), private TestFlight iteration under existing authorization. Archive/upload/group assignment still pending at this checkpoint; final status belongs in TESTFLIGHT.md and ticket24 receipt. No public release, merge or new service.

Final preview caught label wrapping over tiny game portraits; portrait canvases now suppress stage text. Build15 upload was interrupted before a success receipt and was never assigned to testers; build16 is the replacement candidate. Apple acceptance of interrupted transport is not inferred.
