# Solora contributor guide

This file is the shared operating index for agents and contributors working in this repository.

## Project at a glance

Solora is a SwiftUI iOS app backed by Firebase. Its four primary surfaces are Now, Lore, Share and You. The app combines personal memory capture, photo-and-sticker bubbles, user-led import, Calendar review, share outputs and a voice companion.

## Working rules

- Keep work on `main` unless a task explicitly requires an isolated worktree or branch.
- Only one Xcode build or physical-device install should run at a time. Check for active builds before starting another.
- Preserve unrelated work in a dirty tree. Never reset, checkout over, delete or merge unrelated worktrees without explicit approval.
- Use `apply_patch` for source and documentation edits.
- Build and install on the connected physical device only when requested or when a user-facing iOS change needs validation.
- Push completed, verified changes to `origin/main` unless the requester specifies a different handoff.

## Architecture boundaries

| Area | Location | Responsibility |
| --- | --- | --- |
| Composition | `Solora/App`, `RootTabView.swift` | application state, surface routing and feature wiring |
| UI | `Solora/Views`, `Solora/Design` | SwiftUI screens, visual worlds, transitions and shared components |
| Domain | `Solora/Domain` | models, Firebase repositories, media upload and local cache |
| Assistant | `Solora/Assistant` | Realtime session, voice UI and strictly local navigation/memory tools |
| Calendar | `Solora/Calendar` | Google OAuth, Calendar API requests and review-before-save flow |
| Onboarding | `Solora/Onboarding` | preference capture and user-controlled memory import |
| Backend | `functions/src/index.ts` | authenticated callable functions and OpenAI server integration |

## Data and privacy invariants

- A `SoloraMoment` belongs to the authenticated user and is stored under `users/{uid}/wins/{momentId}`.
- Photo paths and sticker paths point to Firebase Storage. Media is cached locally in `Library/Caches/SoloraMomentMedia` and must be removed from the cache when a memory is deleted.
- Calendar data is read only. Do not auto-create memories from events; require the user to write a reflection and explicitly save.
- Imported ChatGPT context is user pasted and user selected. Do not add a silent direct import.
- Assistant tool actions that create or update memories require the app’s confirmation layer.
- Destructive memory removal must retain the confirmation-sheet plus swipe-to-confirm interaction.

## Credentials and OpenAI

- Never put API keys, Firebase service credentials or user tokens in the iOS app, source control, logs or documentation.
- `OPENAI_API_KEY` is a Firebase Functions secret. The iOS client requests a short-lived Realtime credential from `createRealtimeClientSecret`.
- Keep Firebase Authentication required for callable voice endpoints.
- Do not broaden a model’s app tools without an explicit product requirement and a local confirmation route for state changes.

## Google Calendar

- Use the narrow `calendar.events.readonly` scope.
- The Google Calendar API and OAuth Data Access scope must both be configured in the Solora Google Cloud project.
- Keep the Calendar review UI truthful: it currently uses completed events from the previous 30 days and does not read descriptions, attendees or meeting links beyond the fields needed to filter the result.

## Verification

Run the smallest relevant verification first, then build the app when an iOS change is involved.

```bash
# Functions
npm --prefix functions run build
npm --prefix functions test

# Firestore rules
npm --prefix firebase-tests test

# Physical device build
xcodebuild -project Solora.xcodeproj -scheme Solora -configuration Debug \
  -destination 'platform=iOS,id=00008150-001640642201401C' \
  -allowProvisioningUpdates build -quiet
```

The current connected demo device is Dzak’s Pear Phone. An iOS 27 device can emit an Xcode SDK-version warning even when the build succeeds; report it, but distinguish it from an actual build failure.

## Release checklist

1. Inspect `git status` and avoid staging unrelated files.
2. Run relevant tests or a device build.
3. Commit with a focused message.
4. Push `main`.
5. State what changed, what was verified and whether the physical app was installed.
