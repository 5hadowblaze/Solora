# Solora

> Your life becomes your lore.

Solora is a private personal-world platform that turns everyday career experiences into a trustworthy living archive. It helps people capture evidence once, explore it through a personal visual world, and reuse it to create practical outputs such as tailored CVs and interview packs.

## Hackathon demo

The native iOS demo is ready for rehearsal. Its golden path is:

1. Watch `GPT-5.6 Sol + Lore + Aura` resolve into **Solora**.
2. Choose a vibe and enter the demo-ready CV + Calendar world.
3. On Today, turn the finished workshop into a Solora and verify it in Archive.
4. In World, compare Memory Shelves, Career Fridge, and Quest Map.
5. In Create, match archive evidence to a Product role and preview the CV, interview, presentation, LinkedIn, and Instagram outputs.

All judge-facing generation is deterministic and local, so the demo remains reliable without network access. Firebase is connected for the production boundary; Firestore rules are deployed.

## Local development

Prerequisites:

- Xcode 26.6 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

Generate and open the project:

```sh
xcodegen generate
open Solora.xcodeproj
```

Run the unit tests with an available iOS Simulator:

```sh
xcodebuild test -project Solora.xcodeproj -scheme Solora -destination 'platform=iOS Simulator,id=27D75B38-EF67-4A19-A9CC-6BB0B90FAB85'
```

For deterministic rehearsal, launch directly into a tab after installing the app:

```sh
xcrun simctl launch booted com.amirdzakwan.solora -skipOnboarding -demoTab world
```

Supported demo tabs are `today`, `archive`, `create`, `world`, and `you`.

## Security

No OpenAI or other server-side secret is stored in or shipped with the iOS app. OpenAI requests are designed to run through Firebase Functions. The Functions health boundary is implemented and tested; deployment requires upgrading the Firebase project to the Blaze plan.
