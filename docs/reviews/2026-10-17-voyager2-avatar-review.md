# Voyager 2 bounded source review

GPT-5.6 Sol, medium effort. Exact line-numbered Git source was supplied through stdin after read-only shell namespace failure. No model tool calls or Linux iOS tests. This is the original review; findings were evaluated and fixes recorded in 2026-10-17-shared-avatars.md. Normal crop-sheet disappearance already cleaned its file; the follow-up closes interrupted-flow cleanup. Later Mac commits are outside this original review.

SHA `a2c41065ae70c4419d435a9a533e01a2ce7d6cdf`

1. `DressUpView.swift:198` — Trigger: saving to Photos while iCloud Photos or another sync service is enabled. Consequence: the image can leave the device despite the pre-save claim “Everything stays on this device”; the accurate warning appears only after saving. Smallest safe fix: state beside the Photos button that Photos may sync according to system settings, and reserve “stays on this device” for My Stuff/editable avatars.

2. `DressUpView.swift:145` — Trigger: the crop sheet is interactively dismissed or the app terminates before its completion callback. Consequence: the protected normalized face file created in the temporary directory remains behind and is not removed by “Remove photos from all editable looks.” Smallest safe fix: track the crop URL and delete it in the sheet’s `onDismiss`, plus purge the app’s dedicated crop-temporary directory at startup.

3. `DressUpStore.swift:40` — Trigger: `studio.json` becomes corrupt, oversized, or incompatible. Consequence: `healthy` remains false, so `removeEveryFace`, deletion, and every other persistence operation fail while the private-photo document remains stored with no in-app recovery path. Smallest safe fix: offer an explicit confirmed “Reset unreadable Style Studio” action that deletes the protected document and reinitializes an empty healthy store.

4. `DressUpStore.swift:35` — Trigger: launching with a near-limit library containing up to 24 face-bearing looks. Consequence: reading and decoding as much as 35 MB of JSON/base64 image data occurs synchronously on the main actor, delaying launch and potentially causing a watchdog termination on slower devices. Smallest safe fix: read, decode, and validate the document off-main, then publish the validated state on `MainActor`.

5. `DressUpCanvas.swift:104` — Trigger: reaction phase updates, editor changes, or scrolling a face-heavy Lookbook. Consequence: `UIImage(data:)` repeatedly recreates image objects during SwiftUI body evaluation, causing avoidable decoding work and animation/scroll stutter. Smallest safe fix: move private-face rendering into a stateful/cached component that decodes once per changed face payload, preferably off-main before publishing the image.