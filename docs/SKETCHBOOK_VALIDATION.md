# Sketchbook validation — October 17, 2026

Batch: Prototype 0.4.4, build 9. Broad studio milestone #2 remains In Progress, family acceptance pending.

## Build evidence

- **PASS:** signed generic-iOS `build-for-testing` of the current combined local app. Both XCTest targets compile. Log: `/tmp/linley-sketchbook-build-for-testing.log`, products `/tmp/LinleySketchbook/Build/Products/Debug-iphoneos/`.
- **PASS:** separate clean source snapshot of the committed baseline plus only this sketchbook batch, unsigned generic-iOS `build-for-testing`. This verifies the change doesn't depend on the other session's uncommitted Puzzle Chase/audio source. Log: `/tmp/linley-sketch-review-build.log`.
- **PASS:** signed app installed on the physical 10th-generation iPad. Installation replaces the app bundle and keeps app data. No phone installation attempted; iPhone 17 Pro is currently unavailable.

## Runtime status

**PENDING:** new sketchbook model and UI tests. Initial physical-iPad test run compiled, then Xcode reported `Unlock Angelique’s iPad to Continue`. The waiting run was interrupted; it is not a passing test run. Dad has been asked to unlock and keep the device awake. Result path `/tmp/LinleySketchbookTests` records the interrupted attempt (not a passing result). A later normal launch also returned `Locked`, confirming launch remains pending.

Five new model/storage test cases compile: editable drawing reload/update without duplicates, failed replacement preserving the original, corrupt-file preservation, draft deletion preserving exported pictures, title bounds/private storage. A new UI walkthrough compiles for a drawn stroke, undo/redo, renamed draft surviving app relaunch, and separate gallery export. These assertions have **not executed** yet. Prior game/model test passes are historical evidence, not sketchbook validation.

An alternative simulator creation attempt failed because CoreSimulator allocated the device but left it stuck in creation. No simulator runtime or storage configuration was changed. No working screenshot or simulator pass is claimed.

## Review

Generated CONCEPT and exact prompt: reviews/2026-10-17-sketchbook.md. Proposal only; no physical-device screenshots of the new feature yet. Required follow-up: execute tests on the unlocked iPad, inspect actual editor/library layout in portrait and landscape, hand-check Apple Pencil and finger input, and obtain Dad/Lorelei feedback. Full accessibility, force-quit stress and a new iPhone run remain open.

The new source is intentionally separate from the other session's local game/audio work. No main merge, store release, backend or public sharing is part of this batch.
