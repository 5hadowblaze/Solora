# Solora:Codex Hackathon Submission 18th June 2026

> Your life becomes your lore.

Solora is a native iOS career-memory app that turns everyday work experiences into a living personal archive. People can capture useful moments while they are fresh, explore the evidence they have built over time, and reuse selected memories to create practical career materials.

## The experience

- **Onboarding** introduces Solora's glass-orb visual language, lets each person choose their sources, energy, and preferred world, and presents a staged learning sequence before opening their personal space.
- **Now** captures post-event reflections and saves them as career memories, with recent moments kept close at hand.
- **Lore** combines a chronological archive with an interactive spatial world. Memories can be opened in detail, rearranged, and viewed as a Core Room, Constellation, or Career Fridge.
- **Share** brings selected memories together as a Story, post, tailored CV, interview talking points, or deck preview.
- **You** holds profile controls, connected-source preferences, world and vibe settings, and account actions.

Motion is central to the product: glass Solora orbs condense from captured experiences, respond inside the world, and gather, orbit, and unfold as memories move into new outputs. Reduced Motion is respected throughout these transitions.

## Accounts and persistence

Google Sign-In creates and restores the user's Firebase Authentication session. Signed-in accounts read and write their private memory archive in Firestore at `users/{uid}/wins`, using a real-time listener and on-device cache so captures appear immediately and can sync after an offline period. Extended CV data is loaded from user-scoped Firestore documents when available.

The repository also includes user-scoped Firestore security rules, Firebase App Check configuration, unit tests, and Firestore rules tests.

## Local setup

Requirements:

- Xcode 26.6 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

Generate and open the project:

```sh
xcodegen generate
open Solora.xcodeproj
```

Select the `Solora` scheme and run it on an iOS 17 or later simulator or device. The generated project resolves the Firebase and Google Sign-In packages declared in `project.yml`.
