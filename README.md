# Solora

> Your life becomes your lore.

Solora is a private personal-world platform that turns everyday career experiences into a trustworthy living archive. It helps people capture evidence once, explore it through a personal visual world, and reuse it to create practical outputs such as tailored CVs and interview packs.

## Hackathon demo

The native iOS demo is ready for rehearsal. Its golden path is:

1. Watch `GPT-5.6 Sol + Lore + Aura` resolve into **Solora**.
2. Choose a vibe and enter the demo-ready CV + Calendar world.
3. In **Now**, keep the finished workshop and watch it condense into a piece of lore.
4. In **Lore**, move through the living spatial world, open a memory, then switch its form between Core Room, Constellation, and Career Fridge.
5. In **Share**, select real memories and watch the same orbs gather, orbit, and unfold as a Story, post, CV, talking points, or deck.

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
xcrun simctl launch booted com.amirdzakwan.solora -skipOnboarding -demoTab lore
```

Supported demo tabs are `now`, `lore`, `share`, and `you`. The legacy values `today`, `archive`, `world`, and `create` still map to their new equivalents for saved rehearsal scripts.

## Google sign-in

The app uses Google Sign-In to create and restore a Firebase Authentication session. The Google provider and iOS OAuth client are configured in the linked Firebase project; `GoogleService-Info.plist` and the callback URL scheme are tracked with the app configuration.

If the iOS app is recreated in Firebase, download its refreshed `GoogleService-Info.plist`, update `GOOGLE_CLIENT_ID` and `GOOGLE_REVERSED_CLIENT_ID` in `project.yml`, then run `xcodegen generate`.

The existing `-skipOnboarding` rehearsal flag also bypasses authentication so the offline demo remains deterministic. Use `-skipAuthentication` to exercise onboarding without signing in.

## Firestore moments

Signed-in accounts read and write their private archive at `users/{uid}/wins`. The listener is real-time and uses Firestore's Apple-platform disk cache, so a capture appears immediately and queues for sync when the device is offline. The mapper remains compatible with the richer Career Fridge win documents already in the project; new Solora captures use `schemaVersion: 1` with server-owned creation and update timestamps.

Generate the project after Firebase dependency changes, then run both app and security-rule tests:

```sh
xcodegen generate
xcodebuild test -quiet -project Solora.xcodeproj -scheme Solora -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath DerivedDataRoot CODE_SIGNING_ALLOWED=NO
JAVA_HOME=$(/usr/libexec/java_home -v 21) firebase emulators:exec --only firestore "npm --prefix firebase-tests test"
```

Deploy the versioned Firestore rules and index configuration with:

```sh
firebase deploy --only firestore --project solora-5hadowblaze
```

Release builds use App Attest through Firebase App Check. Debug builds use Firebase's debug provider so simulator tokens can be registered without weakening release attestation. Keep Firestore enforcement in monitoring mode until the first signed distribution build has produced valid App Check traffic, then enable enforcement in the Firebase console.

## Security

No OpenAI or other server-side secret is stored in or shipped with the iOS app. OpenAI requests are designed to run through Firebase Functions. The Functions health boundary is implemented and tested; deployment requires upgrading the Firebase project to the Blaze plan.
