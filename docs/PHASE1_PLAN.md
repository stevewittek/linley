# Phase 1 audit and implementation plan — 2026-10-17

## Verified repository audit
Correct repository: stevewittek/linley, main at 43b224379802b575bf2a85fbc7a79cc2a4cc2221. Only main exists remotely; no PRs. Issues #1–4 are high-level milestones; #1 is closed. All application sources, tests, project settings, README and product documents reviewed.

Existing native SwiftUI iOS/iPadOS 17 app with Xcode project, no package dependencies or backend. Home, nickname/avatar setup, curated Idea Lab, local suggestion Builder, profile and UIKit video capture/preview exist. Capture is temporary only; there is no persistent media gallery, photo/import flow, Watch, creator linking, or parent authentication. First launch forces nickname setup. Existing branding, bundle ID, theme, suggestions and usable native components will be retained. Idea Lab will be removed from navigation, with its source retained. Prior uncommitted UIVideoEditorController wrapper in the earlier local checkout will be reused without modifying that checkout.

## Architecture and dependencies
Keep SwiftUI rather than replace working code with Expo. Apple UIKit camera/editor, PhotosUI selected-item picker, AVKit playback, LocalAuthentication device-owner gate, Foundation atomic JSON/file persistence. No third-party libraries, analytics, advertising, network client, cloud entitlement or Azure provisioning. Use application-support files excluded from backup with complete file protection. Private media are copied out of temporary locations before saving. Original branded assets retained; sample media authored for this project and bundled.

Native camera supplies photo/video modes, front/back controls, system preview and retake; microphone requested only for video. App preview supplies save/cancel/retake and video trimming. Profile uses native crop/replace for camera and selected photo. Parent Center fails closed when device authentication is unavailable and locks on background/navigation exit. Device ownership does not establish adult identity or legal consent. Cloud/posting/communication remain hard-disabled.

## Milestones and priority
P0: Home/navigation/L camera; photo/video capture and import; durable My Stuff, preview/deletion; fail-closed privacy policy; tests and iPhone build.
P1: bundled Pictures/Videos Watch, local sample-profile search/linking; local profile image cropping/replacement; authenticated Parent Center and future service design.
P2: additional effects after reliable capture/storage; Android client reusing documented media/permission contracts rather than SwiftUI UI code.

Issue acceptance/dependencies are tracked in PHASE1_ISSUES.json and GitHub. Issues #5–18 were created, then consolidated into broad active milestone #2 by a concurrent coordination update. They are closed as superseded, not delivered. Keep further progress and review evidence under #2; do not reopen or duplicate the historical issues.

## Validation
Build simulator and generic iPhone targets. Run storage tests covering save/reload/delete, errors, path safety and backup exclusion; verify deny policy and sample search/link persistence. Launch fresh simulator, capture Home/Watch/gallery screenshots when available, and exercise import/playback and process restart. Physical iPhone required for camera, microphone, switching lenses, crop, LocalAuthentication and signing validation. Never equate compilation with camera/device verification. Record limitations and exact results in VERIFICATION.md.

## Authorized extension — Creative Quest
Dad chose Creative Quest on October 17 and requested Lorelei and Hailey illustrated characters from the supplied reference. Add a Games icon while retaining the centered camera L. Keep offline movement/collectibles, saved local rewards and avatar choices under broad milestone #2. Original photograph stays outside the repository and app. Native SwiftUI implementation and generated illustrated assets; no third-party game copy. See CREATIVE_QUEST.md and validation evidence. Do not infer family visual acceptance or public distribution approval from this implementation request.
