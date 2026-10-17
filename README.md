# Linley 0.4.1 — Private creation and Creative Quest

Lorelei's creative app under Netherwood Data Partners. The request calls the app “Linly”; this implementation preserves the existing Linley repository, branding, bundle ID and SwiftUI architecture. iPhone and iPad, iOS 17+.

## Implemented for review
- Home opens immediately, with Watch/My Stuff and a bottom-center branded L camera action; no Idea Lab navigation.
- Native photo/video capture, front/back controls, point-of-use permissions, import through Apple's selected-media picker, preview/save/cancel/retake, and native video trimming.
- My Stuff stores media privately on the device, previews pictures and videos, and confirms deletion.
- Watch has separate Pictures/Videos, original bundled demo artwork/video, search, fictional creator profiles and persistent local creator links.
- Local profile photo capture/import, square crop with zoom/position, replace/remove, and retained nickname/avatar editing.
- Parent Center uses device-owner authentication, locks on leaving/background and shows enforced feature policy. Device authentication does not verify an adult or constitute parental consent.

Implementation is not physical-device acceptance. See [VERIFICATION.md](VERIFICATION.md) for exactly what passed and what remains unverified. No Azure, uploads, analytics, ads, real discovery, public sharing or communication is enabled. Private media/index/profile storage is protected and excluded from backup.

## Creative Quest
Home → **Games** beside Profile → **Let’s play**. Tap garden tiles or use arrows to collect five art supplies and earn a sticker plus **100 Linley Coins**. Eight stickers, four rotating garden names and replayable adventures. **My Hero** offers Lorelei (default), Hailey, or Make my own with hair/skin/outfit controls. Illustrated characters were created from the parent-provided reference; the original family photo is not bundled or committed. Game progress, heroes, coins and unlocked packs save locally. No ads, real-money purchases, timers, chat or online accounts.

Home → **Creative Shop** spends earned coins on permanent art-stamp packs (100, 200 or 300 coins). The balance is shared automatically with the game. Home → **Image Maker** has free basic stamps plus your unlocked packs; place stamps, choose colors, undo and save a private picture to **My Stuff**. Reuse and saving cost no coins. This works locally without paid AI services. See [earn-and-create details](docs/CREATIVE_QUEST.md#earn-and-create).

See [game guide](docs/CREATIVE_QUEST.md), [character art and prompts](docs/CHARACTER_ART.md), and [game validation](docs/CREATIVE_QUEST_VALIDATION.md). The concept board is a proposal; device screenshots and tests are separate evidence. Family visual acceptance remains pending.

## Run on an iPhone
1. Open `Linley.xcodeproj` in Xcode 27 (or compatible Xcode supporting iOS 17+).
2. Connect and unlock the iPhone. Trust the Mac and enable Developer Mode if prompted.
3. Select scheme **Linley**, then your iPhone. In Signing & Capabilities choose your existing authorized Apple Developer team. Keep bundle ID `com.netherwooddatapartners.linley` unless that team requires another registered identifier. Signing may require the adult developer to sign in; no credentials belong in the app or repository.
4. Press Run. Nothing has been submitted to TestFlight or the App Store.
5. Home → L opens photo capture. Cancel back to Create to choose Video, then Record video. The native camera provides a flip control. Video is capped at 60 seconds. Import is available on Create without camera/microphone access. After native capture confirmation, use Save to My Stuff; saving does not export to Photos.
6. Relaunch Linley, open My Stuff, preview saved picture/video, then test Delete with disposable test media. Watch → Videos plays a bundled four-second silent clip. Link a fictional creator and use Linked Creators to filter.
7. Test Profile choose/take/crop/replace/remove. Test Parent Center success, cancellation, background relock and failure without a device passcode. A child who knows the device passcode can unlock this prototype gate.

## Build and test
```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project Linley.xcodeproj -scheme Linley \
  -destination 'generic/platform=iOS' -derivedDataPath /tmp/LinleyPhase1Phone \
  CODE_SIGNING_ALLOWED=NO build-for-testing

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project Linley.xcodeproj -scheme Linley \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/test-storage.sh
```
The last command tests actual production storage/catalog sources on macOS. It is not an iOS UI or camera test. Simulator test destination must exist locally. No third-party runtime dependencies. `scripts/generate-demo-media.sh` requires development-only ffmpeg to regenerate bundled original assets.

## Documentation
- [Audit, milestones and testing plan](docs/PHASE1_PLAN.md)
- [Phase 1 issue map](docs/PHASE1_ISSUES.json)
- [Privacy boundary and future ASP.NET/SQL/private Blob architecture](docs/FUTURE_ARCHITECTURE.md)
- [Asset provenance](docs/ASSET_LICENSES.md)
- [Supervised contribution workflow](docs/CONTRIBUTING.md)

The existing Idea Lab and Builder sources remain for reuse but are outside the active navigation. Android, cloud accounts, verifiable parental consent, moderation, extended filters, quota handling and distribution remain future work.
