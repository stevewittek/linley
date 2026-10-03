# Linley 0.3

Linley is an iPad-first SwiftUI creativity prototype led by Lorelei and managed under Netherwood Data Partners. It also adapts to iPhone. Version 0.3 is intentionally local-first: kids can explore ideas, make short videos, and write feature suggestions without creating public accounts or publishing anything.

## What works now

- A first-run local nickname and avatar setup
- A coral-and-white home screen designed for iPad
- A curated Idea Lab with trendy creative prompts
- A 15, 30, or 60 second video creator with local preview
- A Builder where feature ideas are saved locally as **Dad review** cards
- A local profile and plain-language safety promises

Nothing is uploaded, posted, or sent to other users in this version.

## Project structure

- `Linley/App`: app entry point and first-run flow
- `Linley/Navigation`: expandable tab navigation
- `Linley/Features`: Home, Idea Lab, Create, Builder, and Profile areas
- `Linley/Components`: reusable brand and card views
- `Linley/Models`: local suggestion storage
- `Linley/Theme`: colors, gradients, and design constants
- `Linley/Resources`: app icon and local assets
- `LinleyTests`: basic unit tests
- `docs`: product boundaries, contribution rules, and roadmap

## Open in Xcode

1. Open `Linley.xcodeproj` in Xcode.
2. Select the `Linley` scheme in the toolbar.
3. Choose an iPad simulator, an iPhone simulator, or a connected device.
4. Press **Run** or `Command-R`.

## Run on a connected iPad

1. Connect and unlock the iPad, trust the Mac if asked, and enable Developer Mode.
2. In Xcode, select the Linley project, then the **Linley** target.
3. Open **Signing & Capabilities** and choose the Netherwood Apple Developer team.
4. Keep `com.netherwooddatapartners.linley` unless the selected team requires a different registered identifier.
5. Choose the connected iPad from the run-destination menu and press `Command-R`.
6. If iPadOS asks, trust the developer certificate under **Settings > General > VPN & Device Management**.

## Requirements

- Xcode 26.6 or a compatible stable Xcode
- iOS/iPadOS 17.0 or later
- Apple Developer signing only for a physical device; Simulator does not need signing

## Not implemented yet

- Public or private social feeds
- Friend accounts, comments, messaging, or group chat
- Cloud video storage or backend services
- Automatic changes submitted by children or ChatGPT
- Analytics, advertising, tracking, or third-party social SDKs
- App Store or TestFlight distribution

See [ROADMAP.md](docs/ROADMAP.md) for the deliberately high-level product plan and [CONTRIBUTING.md](docs/CONTRIBUTING.md) for the Dad-approved workflow.
