# Private Style Studio — local 0.4.7 (12)

Broad milestone [#23](https://github.com/stevewittek/linley/issues/23), GitHub Project 2, In Progress. Requested by Dad: an age-10+ private dress-up game with polished graphics, optional own-photo avatars, hair styling, fan/concert/character-inspired outfits, and purchases using the existing earned Linley Coins. Original designs; no celebrity-photo collection, official merchandise claim, Pinterest integration or online try-on service.

## What is built

Games → Style Studio adds an illustrated paper-doll fashion studio. Seven coordinated complete outfits (four original silhouettes plus three color remixes), four detailed hairstyles, four illustrated face tones, four hair-color choices, four scenes and four accessory choices. These are coordinated sets rather than separately interchangeable tops/bottoms in this first version. Outfits use detailed generated clothing art, hair uses separate transparent layers, and the illustrated faces are original fictional game characters. A locally imported photo can replace the face; this is not a photorealistic AI clothing simulation.

Wardrobe:

| Item | Coins |
|---|---:|
| Lavender Encore + soft bob | Free starter |
| Mint Daydream | 100 |
| Coral Spotlight (concert color remix) | 200 |
| Emerald Storybook | 300 |
| Midnight Headliner (denim color remix) | 400 |
| Pink Cloud Party (tulle/cardigan/leggings) | 500 |
| Moonlight Icon (storybook color remix) | 600 |
| Silky waves | 100 |
| Double star buns | 200 |
| Twin braids | 300 |

Every paid selection requires an explicit coin confirmation. Insufficient funds show how many more coins to earn. Nothing is charged for browsing or selecting an owned item. Ownership and the debit are saved together in the existing QuestProgress record; the economy validation includes wardrobe + art-pack + life spending. Old saves default to an empty wardrobe and retain coins, art packs, levels and heroes. Starter styles, scenes, colors and accessories are free. No StoreKit, real money, ads, subscriptions, expiring coins or service account.

Six styling missions ask for a scene + accessory combination, work with free starter clothing, and each award 100 shared coins once. They do not rate attractiveness, bodies or photos. Duplicate claims and missions using unowned paid styles are rejected. The same coins buy wardrobe items, hairstyles, art packs or existing game lives.

## Private avatar photos and saving

- Choose one photo through the system picker, take a selfie using the existing camera capture with front-camera preference, or explicitly copy the current local profile photo. No automatic profile-photo selection. No photo library scan, upload or server call.
- Before cropping, ImageIO downsamples to 1,600 pixels and re-encodes, removing source metadata. The original owned import/camera temporary file is removed. The face-positioning sheet lets the player zoom/pan; the final face is re-encoded at up to 512 pixels with no source GPS metadata. This also bounds image memory.
- The avatar combines that face locally with illustrated clothes and hair. There is no segmentation, realistic garment fitting, body analysis or celebrity impersonation tool. Existing photos can include their original hair/background inside the crop; tight positioning matters and needs family testing.
- Draft appearance and up to 24 editable looks live in a protected Application Support folder excluded from backup. Look titles are bounded; avatar fields/catalog IDs and image dimensions are validated. Writes are atomic. Corrupt data fails closed without deletion. No face data goes into UserDefaults or GitHub.
- Lookbook is a private inspiration board. Reopen a saved look to edit; delete a look with confirmation. “Remove photos from all editable looks” clears the face copies from draft and saved looks after confirmation. Exported images and profile photos are separate copies and are not silently deleted.
- Save picture creates a re-rendered image in existing private My Stuff. Optional Save picture to Photos requests add-only access at the point of use. Personal Photos syncing follows the device owner's Photos settings. No share sheet, app upload or public posting is added.

## Art and review

Nine bundled PNG assets: four outfit silhouettes, four hairstyles and one four-head sprite atlas. Created with the imagegen skill/built-in tool using text and only our generated clothing reference. No private child photo or existing hero portrait was sent to generation. Early off-template photo collages and a simpler vector-face prototype were rejected; they are not bundled. Final art has actual alpha transparency and was visually inspected. Face atlas pieces are trimmed/cached by the game renderer; the wavy hairstyle uses a face opening so inward strands do not cover the eyes.

Generated wardrobe art is proposed for family approval; implementation permission is not visual acceptance. Asset hashes are under `docs/licenses/style-studio/SHA256SUMS.txt`. [Actual app simulator screen](reviews/2026-10-17-style-studio-simulator.png). [Simulator art/layout gallery](reviews/2026-10-17-style-gallery-simulator.png) uses the actual DressUpCanvas with fictional avatars and sample styling, not a purchase walkthrough. Its DEBUG-only entry is absent from Release and requires isolated UI-test arguments.

## Validation and limits

- `scripts/verify-style-studio.sh` compiles the actual catalog, private store, shared wallet and existing game engines on macOS. PASS: free starters; six fixed mission rewards; wardrobe/hair/Creative Shop shared spending; insufficient/duplicate/unknown purchase rejection; ownership and balance persistence; private look save/reopen/delete; face normalization and GPS stripping; backup exclusion; removing face copies; bounded storage; corrupt-file preservation; unknown-ID rejection and old wallet migration. Only synthetic test photo pixels and temporary stores were used.
- Existing production game check rerun after wardrobe ledger integration: 4,000 generated boards, 200 complete attempts and all twenty objective-driven Match-3 routes/reward/shop/persistence checks passed (`scripts/verify-match-three.sh`).
- Generic simulator and signed generic iOS build-for-testing pass. Six new XCTest methods compile for wallet/migration/private photos, bad inputs, image decoding and renderer coverage. They have **not** been executed on an iPad; prior 49-test device results belong to 0.4.6, not this version.
- Actual headless iPad simulator screens were rendered and inspected. Review caught/fixed the overly simple initial head, faded locked outfit thumbnails, and wavy hair obscuring the face. No real child photos were used in screenshots.
- Dad deferred physical iPad work (“not now”); that boundary remains in force. No physical-device actions, camera/photo-library permission tests, personal photo imports, personal Photos writes or installation by this dress-up round. Button-driven game/mission/purchase/lookbook flows, camera/crop fit, Photos permission denial/success, accessibility, iPhone layout and family fun/visual acceptance remain open.

Source and art remain local and uncommitted/unpushed by this round. No TestFlight/App Store upload, merge or publishing. Existing expanded-game UI issues (#21/#22) remain separate and are not claimed fixed here.


## Interactive fitting room — 0.4.8 (13)
Dad approved the existing outfit direction and explicitly requested a private TestFlight build for his phone. Lorelei's feedback is still pending. Every outfit, hairstyle and companion bag can now be previewed before purchase, even with an empty wallet. Locked selections show a fitting-room notice and an explicit unlock button. Purchases are permanent, use earned coins only, and require confirmation. Keeping/exporting a look or claiming a mission requires owning all its selected paid items. Draft previews themselves are free and persist locally.

Four original vector companion bags: Dumpling Buddy 100, Cloud Bunny 200, Honey Bear 300, Star Kitty 400. Free round glasses/star shades, animal-ear headband and Natural/Peach/Rose/Stage Shimmer palettes. Makeup is a light fixed illustrated overlay, not face-tracked or photorealistic virtual cosmetics. Existing complete-outfit art and hairstyles remain illustrated. A selected personal photo supplies the locally cropped face; no body analysis, garment simulation, brand catalog, retailer ordering, external AI, or photo upload.

Studio reuses bundled CC0 music and effects, with saved music/effect switches, Silent Mode, background/leaving-screen pause, interruption handling and headphone-removal behavior. Six styling briefs continue to award 100 coins once each. Existing old looks decode missing new details to free defaults; shared wallet validates bag purchases alongside outfits, hair, creative packs and game lives. Production-source checks cover bag purchase/reload/duplicate debit, preview ownership/reward guards and old-look migration. Actual camera/Photos permission and family device acceptance remain pending. iPad use is deferred per Dad's instruction.


## Phone editor revision — 0.4.9 (14)
Dad's 0.4.8 phone review requested changes: head/wig separation, hidden editing controls and missing item manipulation. Existing outfit art remains approved, but editor/avatar acceptance is reopened in #23.

The phone now keeps a compact live preview above eight visible categories: Outfits, Hair, Face, Makeup, Extras, Scene, Missions, Save. Each category scrolls independently under the preview. Light appearance is scoped to this studio to avoid the prior white text on a pale background in Dark Mode. Face/hair/makeup categories open a face close-up; Whole look restores the full avatar.

The default face fills a skin-backed oval, meets the neck/collar and sits under the registered hair layer. Soft oval, round and drawn face options, four illustrated tones and local photo choice are directly available. Tone selection switches to an illustrated face; personal photo colors are preserved. Makeup has independent blush, lip and eye-shadow palettes, shimmer and clear controls, all free. Old combined palettes migrate to editable blush.

Move items enables dragging the selected hair, face, bag, glasses, clip/headphones, makeup or ear layer. Sliders offer horizontal/vertical placement, scale 0.6–1.6 and rotation -45–45 degrees; per-item and full-position resets restore registration. Each item's scale/rotation uses its own anchor. Positions are bounded to 30 percent of canvas dimensions, nonfinite/unknown/invalid placements fail validation, and old drafts/looks default to original positions. Gesture previews are transient; only the ended gesture is persisted. Lookbook and picture rendering use the same saved transforms. Existing purchase/mission ownership remains enforced.

This is still an illustrated layer editor. Clothing is a complete outfit, not separate fabric pieces or photorealistic body simulation. Photo/camera/Photos permission and physical-family acceptance remain separate review steps. iPad testing remains deferred.
