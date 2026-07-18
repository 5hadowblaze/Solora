# Solora

> Your life becomes your lore.

Solora is a private personal-world platform that turns everyday career experiences into a trustworthy living archive. It helps people capture evidence once, explore it through a personal visual world, and reuse it to create practical outputs such as tailored CVs and interview packs.

## Local development

Prerequisites:

- Xcode 26.6 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

Generate and open the project:

```sh
xcodegen generate
open Solora.xcodeproj
```

## Security

OpenAI API keys are never stored in or shipped with the iOS app. OpenAI requests must be made through a trusted server-side service.
