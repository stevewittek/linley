# Shared avatars and reactions — milestone 5

Owner ticket: https://github.com/stevewittek/linley/issues/24. Extends #23 and #21; no invented due date. Family acceptance stays open.

## Product contract
Save/name/select a private avatar from Style Studio. Use the same protected saved look across Creative Quest, Puzzle Chase, Gem Garden player cards and victory scenes. Three finite reactions: Hello, Celebrate, Spotlight. These are whole-look animated poses with existing flat illustrated artwork, not rigged limb dancing or photorealistic virtual try-on. Dance Studio, original routines and licensed music are future work.

No real money. Existing earned Linley Coins buy permanent wardrobe and creative packs. Previewing is free; completed saves/rewards retain ownership guards. Photos are cropped/re-encoded on device, protected and excluded from backup; never transfer user media to other machines or services. Avatar selection references existing SavedStyle entries rather than duplicating private photos. Delete/face removal and legacy document migration must remain coherent across screens.

## Source and coordination
The review branch codex/shared-avatar-milestone includes the prior 0.4.9 game baseline previously local to the Mac, plus milestone work. The broader diff against older repository HEAD is not all newly implemented in this milestone. Use exact commit receipts in issue comments; do not review stale default HEAD as the current app. Follow AGENTS.md. Parent sources/ are read-only synced project references.

Mac: integration, SwiftUI, graphics, Apple compilation and simulator previews. Local helpers own the shared library/integration and finite reaction component respectively. Voyager 1: isolated Windows checkout, focused game/reward/persistence input review, no overlapping UI edits. Voyager 2: isolated Linux checkout, read-only bounded storage/privacy/performance review with GPT-6.1 Sol medium. Return concrete file/line findings; Mac integrates fixes. No extra worker chains, continuous polls or repeated broad review. No changes to Motion Relay checkouts, production services, SQL, Docker, monitoring, credentials or firewall. Do not install tools to emulate Apple platforms.

## Main files
- DressUp/DressUpStore.swift: protected atomic Codable document, maximum 24 saved styles, selected UUID, strict validation, normalized faces and face removal.
- DressUp/DressUpView.swift: editor, private photo import, explicit wardrobe spending and save ownership.
- DressUp/SharedAvatarViews.swift: shared character/player/library/victory views.
- DressUp/AvatarReactions.swift: finite on-demand poses, reduced-motion and scene cancellation.
- QuestStore.swift: shared atomic coin/reward/ownership ledger and game persistence.
- ChaseEngine.swift, MatchEngine.swift: portable Foundation game engines. Actual authored level/objective validators in scripts/.

## Validation
Mac uses DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer. Run sh scripts/verify-style-studio.sh, sh scripts/verify-match-three.sh, sh scripts/verify-puzzle-levels.sh for production-source checks. Style check imports SwiftUI/ImageIO and requires Mac; do not call static Linux/Windows inspection an executed iOS test. Generic iOS Simulator xcodebuild verifies whole app and test compilation. Custom headless simulator set /tmp/LinleyMatchSimDevices is Mac-only. Physical iPad tests remain deferred by Dad. New screenshot fixtures use fictional local avatars and are labeled SIMULATOR; fixtures do not prove user tap/drag or device acceptance.

Review completion is not milestone Done: camera/Photos permissions, physical interaction, accessibility and Dad/Lorelei acceptance remain explicit gates. Do not merge/release/publish from remote machines.
