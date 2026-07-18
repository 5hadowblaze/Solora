# Solora

> Your life becomes your lore.

Solora is a private personal-world platform that turns everyday career experiences into a trustworthy living archive. It helps people capture evidence once, explore it through a personal visual world, and reuse it to create practical outputs such as tailored CVs and interview packs.

## Current status

The native iOS foundation is available. It includes the SwiftUI tab shell, deterministic demo content, Firebase package references, and focused unit tests.

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

## Security

No OpenAI or other server-side secret is stored in or shipped with the iOS app. OpenAI requests must be made through a trusted server-side service.
