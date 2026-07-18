# Solora Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a new private GitHub repository and Firebase project named Solora, then deliver a buildable native SwiftUI application with the approved five-tab shell, core models, design tokens, Firebase configuration, tests, and a verified Simulator build.

**Architecture:** Solora is a native iOS 17+ SwiftUI app generated with XcodeGen. The application begins with dependency-injected demo repositories and strongly typed domain models; Firebase is added as the cloud boundary without placing secrets in the client. Feature work will build on this foundation through separate Capture/Archive, World, Create/OpenAI, and demo-polish plans.

**Tech Stack:** Swift 6.0, SwiftUI, XCTest, XcodeGen, Firebase iOS SDK 12.16.0, Firebase CLI 15.20.0, Cloud Functions for Firebase with TypeScript and Node 20, GitHub CLI.

---

## Scope boundary and follow-on plans

This plan intentionally stops at a working foundation. The approved product spec is divided into these independently verifiable implementation slices:

1. **Foundation** — this plan.
2. **Capture + Living Archive** — simulated post-event prompt, reflection, Solora creation, persistence, and Archive.
3. **Worlds + World Manifest** — Memory Shelves, Career Fridge, Quest Map, strict manifest decoding, and fallback rendering.
4. **Create + OpenAI** — job-description analysis, memory ranking, tailored CV, interview pack, Firebase secret, and Responses API.
5. **Share + Demo polish** — social/presentation previews, onboarding reveal, motion, accessibility, build journal, and golden-path verification.

## Locked file structure

```text
Solora/
├── .firebaserc
├── .gitignore
├── README.md
├── firebase.json
├── firestore.rules
├── project.yml
├── docs/
│   ├── BUILD_JOURNAL.md
│   └── product-design.md
├── functions/
│   ├── package.json
│   ├── tsconfig.json
│   ├── src/index.ts
│   └── test/health.test.ts
├── Solora/
│   ├── App/SoloraApp.swift
│   ├── App/AppContainer.swift
│   ├── DesignSystem/SoloraTheme.swift
│   ├── Models/SoloraMoment.swift
│   ├── Models/WorldManifest.swift
│   ├── Demo/DemoFixtures.swift
│   ├── Features/Root/RootTabView.swift
│   ├── Features/Today/TodayView.swift
│   ├── Features/Archive/ArchiveView.swift
│   ├── Features/Create/CreateView.swift
│   ├── Features/World/WorldView.swift
│   ├── Features/Profile/ProfileView.swift
│   ├── Shared/SoloraOrbView.swift
│   ├── Resources/Assets.xcassets/Contents.json
│   └── Resources/GoogleService-Info.plist
└── SoloraTests/
    ├── SoloraMomentTests.swift
    └── WorldManifestTests.swift
```

### Task 1: Create the local repository and durable project documentation

**Files:**
- Create: `Solora/.gitignore`
- Create: `Solora/README.md`
- Create: `Solora/docs/BUILD_JOURNAL.md`
- Create: `Solora/docs/product-design.md`

- [ ] **Step 1: Create and initialise the repository**

Run:

```bash
mkdir -p "/Users/amirdzakwan/Documents/Solora/docs"
cd "/Users/amirdzakwan/Documents/Solora"
git init -b main
```

Expected: an empty Git repository on `main`.

- [ ] **Step 2: Add the repository ignore policy**

Create `.gitignore` with:

```gitignore
.DS_Store
DerivedData/
build/
*.xcuserstate
xcuserdata/
.swiftpm/
.build/
functions/node_modules/
functions/lib/
firebase-debug.log
.firebase/
.env
.env.*
!.env.example
GoogleService-Info.plist.bak
```

- [ ] **Step 3: Add the README**

Create `README.md` with:

```markdown
# Solora

Your life becomes your lore.

Solora turns CV history, calendar events, and short reflections into a private Living Archive, personalised visual Worlds, and tailored career outputs.

## Local development

1. Install Xcode 26.6 or newer and XcodeGen.
2. Run `xcodegen generate`.
3. Open `Solora.xcodeproj` or run the documented `xcodebuild` command.

The iOS app never contains an OpenAI or other server-side secret. AI calls are routed through Firebase Functions; generated Firebase client configuration is expected and is not a server secret.
```

- [ ] **Step 4: Create the pointer to the approved product design**

Create `docs/product-design.md` as a concise pointer to `docs/superpowers/specs/2026-07-18-solora-product-design.md`, preserving the approved status and tagline.

Expected: `docs/product-design.md` links to the canonical approved Solora specification without duplicating it.

- [ ] **Step 5: Start the Codex build journal**

Create `docs/BUILD_JOURNAL.md` with:

```markdown
# Solora Build Journal

## 2026-07-18 — Product discovery and foundation

- Codex statically analysed the exported Career Fridge IPA to recover its product structure, frameworks, permissions, visual vocabulary, and release risks.
- The product was reframed as a Living Archive with constrained generative Worlds and career-output creation.
- Codex and the project owner developed the approved Solora product design through an iterative design conversation.
- The implementation was split into testable foundation, capture, World, Create, and polish slices.
```

- [ ] **Step 6: Commit the repository foundation**

Run:

```bash
git add .gitignore README.md docs
git commit -m "docs: establish Solora product foundation"
```

Expected: one clean commit on `main`.

### Task 2: Scaffold the native iOS project with XcodeGen

**Files:**
- Create: `Solora/project.yml`
- Create: `Solora/Solora/App/SoloraApp.swift`
- Create: `Solora/Solora/App/AppContainer.swift`
- Create: `Solora/Solora/Features/Root/RootTabView.swift`
- Create: `Solora/Solora/Resources/Assets.xcassets/Contents.json`

- [ ] **Step 1: Create the source directories**

Run:

```bash
mkdir -p Solora/App Solora/Features/Root Solora/Resources/Assets.xcassets SoloraTests
```

Expected: the XcodeGen source paths exist before project generation.

- [ ] **Step 2: Define the Xcode project**

Create `project.yml` with:

```yaml
name: Solora
options:
  bundleIdPrefix: com.amirdzakwan
  deploymentTarget:
    iOS: "17.0"
  xcodeVersion: "26.6"
settings:
  base:
    SWIFT_VERSION: "6.0"
    DEVELOPMENT_TEAM: QYDB6YBZ34
    CODE_SIGN_STYLE: Automatic
packages:
  Firebase:
    url: https://github.com/firebase/firebase-ios-sdk.git
    exactVersion: 12.16.0
targets:
  Solora:
    type: application
    platform: iOS
    sources:
      - path: Solora
        excludes:
          - Resources/GoogleService-Info.plist
    resources:
      - path: Solora/Resources
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.amirdzakwan.solora
        PRODUCT_NAME: Solora
        INFOPLIST_KEY_CFBundleDisplayName: Solora
        GENERATE_INFOPLIST_FILE: YES
        INFOPLIST_KEY_UILaunchScreen_Generation: YES
        INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents: YES
        TARGETED_DEVICE_FAMILY: "1"
    dependencies:
      - package: Firebase
        product: FirebaseCore
      - package: Firebase
        product: FirebaseAuth
      - package: Firebase
        product: FirebaseFirestore
      - package: Firebase
        product: FirebaseFunctions
  SoloraTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - path: SoloraTests
    dependencies:
      - target: Solora
schemes:
  Solora:
    build:
      targets:
        Solora: all
        SoloraTests: [test]
    test:
      targets:
        - SoloraTests
```

- [ ] **Step 3: Add the application entry point**

Create `Solora/App/SoloraApp.swift` with:

```swift
import FirebaseCore
import SwiftUI

@main
struct SoloraApp: App {
    private let container: AppContainer

    init() {
        if FirebaseApp.app() == nil,
           Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") != nil {
            FirebaseApp.configure()
        }
        container = AppContainer.demo
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(container: container)
        }
    }
}
```

- [ ] **Step 4: Add the dependency container**

Create `Solora/App/AppContainer.swift` with:

```swift
import Foundation

struct AppContainer {
    var moments: [SoloraMoment]
    var manifest: WorldManifest

    static let demo = AppContainer(
        moments: DemoFixtures.moments,
        manifest: DemoFixtures.memoryShelvesManifest
    )
}
```

- [ ] **Step 5: Add the provisional root view**

Create `Solora/Features/Root/RootTabView.swift` with:

```swift
import SwiftUI

struct RootTabView: View {
    let container: AppContainer

    var body: some View {
        Text("Solora")
    }
}
```

- [ ] **Step 6: Add the asset catalogue root**

Create `Solora/Resources/Assets.xcassets/Contents.json` with:

```json
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- [ ] **Step 7: Generate the project and verify dependency resolution**

Run:

```bash
xcodegen generate
xcodebuild -resolvePackageDependencies -project Solora.xcodeproj -scheme Solora
```

Expected: `Solora.xcodeproj` is generated and Firebase 12.16.0 resolves successfully.

### Task 3: Define and test the stable domain models

**Files:**
- Create: `Solora/Solora/Models/SoloraMoment.swift`
- Create: `Solora/Solora/Models/WorldManifest.swift`
- Create: `Solora/Solora/Demo/DemoFixtures.swift`
- Create: `Solora/SoloraTests/SoloraMomentTests.swift`
- Create: `Solora/SoloraTests/WorldManifestTests.swift`

- [ ] **Step 1: Write the failing moment-model test**

Create `SoloraTests/SoloraMomentTests.swift` with:

```swift
import XCTest
@testable import Solora

final class SoloraMomentTests: XCTestCase {
    func testMomentRoundTripsThroughJSON() throws {
        let original = SoloraMoment(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            title: "AI Builders Meetup",
            summary: "Presented a prototype and met three founders.",
            occurredAt: Date(timeIntervalSince1970: 1_750_000_000),
            skills: ["Public speaking", "AI prototyping"],
            importance: 0.86
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SoloraMoment.self, from: data)

        XCTAssertEqual(decoded, original)
    }
}
```

- [ ] **Step 2: Write the failing manifest fallback test**

Create `SoloraTests/WorldManifestTests.swift` with:

```swift
import XCTest
@testable import Solora

final class WorldManifestTests: XCTestCase {
    func testUnknownWorldKindFallsBackToMemoryShelves() throws {
        let data = Data(#"{"kind":"unknown","title":"My World","featuredMomentIDs":[]}"#.utf8)
        let manifest = try JSONDecoder().decode(WorldManifest.self, from: data)

        XCTAssertEqual(manifest.kind, .memoryShelves)
    }
}
```

- [ ] **Step 3: Run tests to verify they fail**

Run:

```bash
xcodebuild test -project Solora.xcodeproj -scheme Solora -destination 'platform=iOS Simulator,id=27D75B38-EF67-4A19-A9CC-6BB0B90FAB85'
```

Expected: compilation fails because `SoloraMoment` and `WorldManifest` do not exist.

- [ ] **Step 4: Implement the moment model**

Create `Solora/Models/SoloraMoment.swift` with:

```swift
import Foundation

struct SoloraMoment: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var title: String
    var summary: String
    var occurredAt: Date
    var skills: [String]
    var importance: Double
}
```

- [ ] **Step 5: Implement safe World Manifest decoding**

Create `Solora/Models/WorldManifest.swift` with:

```swift
import Foundation

enum WorldKind: String, Codable, CaseIterable, Sendable {
    case memoryShelves
    case careerFridge
    case questMap

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = WorldKind(rawValue: rawValue) ?? .memoryShelves
    }
}

struct WorldManifest: Codable, Equatable, Sendable {
    var kind: WorldKind
    var title: String
    var featuredMomentIDs: [UUID]
}
```

- [ ] **Step 6: Add deterministic demo fixtures**

Create `Solora/Demo/DemoFixtures.swift` with:

```swift
import Foundation

enum DemoFixtures {
    static let moments: [SoloraMoment] = [
        SoloraMoment(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            title: "AI Builders Meetup",
            summary: "Presented a prototype and met three founders.",
            occurredAt: Date(timeIntervalSince1970: 1_750_000_000),
            skills: ["Public speaking", "AI prototyping"],
            importance: 0.86
        ),
        SoloraMoment(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            title: "Shipped Career Fridge",
            summary: "Built and released a playful career reflection app.",
            occurredAt: Date(timeIntervalSince1970: 1_749_000_000),
            skills: ["SwiftUI", "Product design"],
            importance: 0.95
        )
    ]

    static let memoryShelvesManifest = WorldManifest(
        kind: .memoryShelves,
        title: "Your brightest chapters",
        featuredMomentIDs: moments.map(\.id)
    )
}
```

- [ ] **Step 7: Regenerate and run the tests**

Run:

```bash
xcodegen generate
xcodebuild test -project Solora.xcodeproj -scheme Solora -destination 'platform=iOS Simulator,id=27D75B38-EF67-4A19-A9CC-6BB0B90FAB85'
```

Expected: both tests pass.

- [ ] **Step 8: Commit the domain foundation**

Run:

```bash
git add project.yml Solora SoloraTests Solora.xcodeproj
git commit -m "feat: scaffold Solora iOS domain foundation"
```

### Task 4: Build the Career Fridge-inspired application shell

**Files:**
- Create: `Solora/Solora/DesignSystem/SoloraTheme.swift`
- Create: `Solora/Solora/Shared/SoloraOrbView.swift`
- Modify: `Solora/Solora/Features/Root/RootTabView.swift`
- Create: `Solora/Solora/Features/Today/TodayView.swift`
- Create: `Solora/Solora/Features/Archive/ArchiveView.swift`
- Create: `Solora/Solora/Features/Create/CreateView.swift`
- Create: `Solora/Solora/Features/World/WorldView.swift`
- Create: `Solora/Solora/Features/Profile/ProfileView.swift`

- [ ] **Step 1: Add the visual tokens**

Create `Solora/DesignSystem/SoloraTheme.swift` with:

```swift
import SwiftUI

enum SoloraTheme {
    static let coral = Color(red: 0.85, green: 0.31, blue: 0.27)
    static let cream = Color(red: 0.98, green: 0.96, blue: 0.91)
    static let ink = Color(red: 0.12, green: 0.11, blue: 0.14)
    static let gold = Color(red: 0.98, green: 0.73, blue: 0.30)
    static let lavender = Color(red: 0.48, green: 0.36, blue: 0.86)
    static let cardRadius: CGFloat = 24
}
```

- [ ] **Step 2: Add the reusable Solora orb**

Create `Solora/Shared/SoloraOrbView.swift` with:

```swift
import SwiftUI

struct SoloraOrbView: View {
    let moment: SoloraMoment
    var size: CGFloat = 84

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, SoloraTheme.gold, SoloraTheme.coral, SoloraTheme.lavender],
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: size * 0.75
                    )
                )
            Circle()
                .stroke(.white.opacity(0.55), lineWidth: 1)
                .padding(size * 0.08)
        }
        .frame(width: size, height: size)
        .shadow(color: SoloraTheme.coral.opacity(0.28), radius: 18, y: 10)
        .accessibilityLabel(moment.title)
    }
}
```

- [ ] **Step 3: Add focused foundation views**

Create the following views:

```swift
// Solora/Features/Today/TodayView.swift
import SwiftUI

struct TodayView: View {
    let moments: [SoloraMoment]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("What is worth keeping today?")
                        .font(.largeTitle.bold())
                    ForEach(moments) { moment in
                        HStack(spacing: 16) {
                            SoloraOrbView(moment: moment, size: 64)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(moment.title).font(.headline)
                                Text(moment.summary).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                    }
                    Button("Simulate event ending") {}
                        .buttonStyle(.borderedProminent)
                        .tint(SoloraTheme.coral)
                }
                .padding(24)
            }
            .background(SoloraTheme.cream)
            .navigationTitle("Today")
        }
    }
}
```

```swift
// Solora/Features/Archive/ArchiveView.swift
import SwiftUI

struct ArchiveView: View {
    let moments: [SoloraMoment]

    var body: some View {
        NavigationStack {
            List(moments) { moment in
                Label(moment.title, systemImage: "sparkles")
            }
            .navigationTitle("Archive")
        }
    }
}
```

```swift
// Solora/Features/Create/CreateView.swift
import SwiftUI

struct CreateView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Create from your lore",
                systemImage: "wand.and.stars",
                description: Text("Tailor a CV, prepare for an interview, or tell a story.")
            )
            .navigationTitle("Create")
        }
    }
}
```

```swift
// Solora/Features/World/WorldView.swift
import SwiftUI

struct WorldView: View {
    let manifest: WorldManifest
    let moments: [SoloraMoment]

    var body: some View {
        NavigationStack {
            ZStack {
                SoloraTheme.ink.ignoresSafeArea()
                VStack(spacing: 28) {
                    Text(manifest.title)
                        .font(.title.bold())
                        .foregroundStyle(.white)
                    HStack(spacing: -12) {
                        ForEach(moments) { moment in
                            SoloraOrbView(moment: moment)
                        }
                    }
                    Text("Memory Shelves")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.65))
                }
            }
            .navigationTitle("World")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
```

```swift
// Solora/Features/Profile/ProfileView.swift
import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Your career") {
                    Label("Master CV", systemImage: "doc.text")
                    Label("Connected sources", systemImage: "link")
                    Label("Vibe", systemImage: "paintpalette")
                }
            }
            .navigationTitle("You")
        }
    }
}
```

- [ ] **Step 4: Replace the provisional root with the five-tab shell**

Create `Solora/Features/Root/RootTabView.swift` with:

```swift
import SwiftUI

struct RootTabView: View {
    let container: AppContainer

    var body: some View {
        TabView {
            TodayView(moments: container.moments)
                .tabItem { Label("Today", systemImage: "sun.max") }
            ArchiveView(moments: container.moments)
                .tabItem { Label("Archive", systemImage: "tray.full") }
            CreateView()
                .tabItem { Label("Create", systemImage: "plus.circle.fill") }
            WorldView(manifest: container.manifest, moments: container.moments)
                .tabItem { Label("World", systemImage: "sparkles") }
            ProfileView()
                .tabItem { Label("You", systemImage: "person.crop.circle") }
        }
        .tint(SoloraTheme.coral)
    }
}
```

- [ ] **Step 5: Build the application**

Run:

```bash
xcodegen generate
xcodebuild build -project Solora.xcodeproj -scheme Solora -destination 'platform=iOS Simulator,id=27D75B38-EF67-4A19-A9CC-6BB0B90FAB85'
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 6: Commit the application shell**

Run:

```bash
git add project.yml Solora Solora.xcodeproj
git commit -m "feat: add Solora five-tab application shell"
```

### Task 5: Create and configure the new Firebase project

**Files:**
- Create: `Solora/.firebaserc`
- Create: `Solora/firebase.json`
- Create: `Solora/firestore.rules`
- Create: `Solora/Solora/Resources/GoogleService-Info.plist`

- [ ] **Step 1: Create the Firebase project with the public display name Solora**

Run from the Solora repository:

```bash
firebase projects:create solora-5hadowblaze --display-name "Solora"
```

Expected: Firebase project `solora-5hadowblaze` is created with display name `Solora`. If Google reports that the globally unique ID is unavailable, stop this task and update this plan with the replacement ID before continuing so configuration never diverges across files.

- [ ] **Step 2: Add deterministic Firebase configuration files**

Create `.firebaserc` with:

```json
{
  "projects": {
    "default": "solora-5hadowblaze"
  }
}
```

Create `firebase.json` with:

```json
{
  "functions": {
    "source": "functions",
    "runtime": "nodejs20"
  },
  "firestore": {
    "rules": "firestore.rules"
  }
}
```

Create `firestore.rules` with:

```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

- [ ] **Step 3: Register the iOS app using the exact production bundle ID**

Run:

```bash
firebase apps:create IOS Solora --bundle-id com.amirdzakwan.solora --project solora-5hadowblaze
firebase apps:list IOS --project solora-5hadowblaze
```

Expected: one iOS app named `Solora` with bundle ID `com.amirdzakwan.solora`. Record its App ID from the list output.

- [ ] **Step 4: Download the generated iOS Firebase configuration**

Run:

```bash
APP_ID=$(firebase apps:list IOS --project solora-5hadowblaze --json | jq -r '.result[0].appId')
test -n "$APP_ID"
firebase apps:sdkconfig IOS "$APP_ID" --project solora-5hadowblaze --out Solora/Resources/GoogleService-Info.plist
```

Expected: `GoogleService-Info.plist` reports `BUNDLE_ID = com.amirdzakwan.solora` and `PROJECT_ID = solora-5hadowblaze`.

- [ ] **Step 5: Validate the generated configuration**

Run:

```bash
plutil -lint Solora/Resources/GoogleService-Info.plist
plutil -extract BUNDLE_ID raw Solora/Resources/GoogleService-Info.plist
plutil -extract PROJECT_ID raw Solora/Resources/GoogleService-Info.plist
```

Expected: plist validation succeeds, followed by `com.amirdzakwan.solora` and `solora-5hadowblaze`.

- [ ] **Step 6: Rebuild with Firebase configured**

Run:

```bash
xcodegen generate
xcodebuild build -project Solora.xcodeproj -scheme Solora -destination 'platform=iOS Simulator,id=27D75B38-EF67-4A19-A9CC-6BB0B90FAB85'
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 7: Create the default Firestore database in the London region**

Run:

```bash
firebase firestore:databases:create '(default)' --location europe-west2 --project solora-5hadowblaze
```

Expected: the standard default Firestore database is created in `europe-west2`.

- [ ] **Step 8: Commit Firebase client configuration**

Run:

```bash
git add .firebaserc firebase.json firestore.rules Solora/Resources/GoogleService-Info.plist project.yml Solora.xcodeproj
git commit -m "chore: connect Solora to Firebase"
```

### Task 6: Add and test a minimal Firebase Functions boundary

**Files:**
- Create: `Solora/functions/package.json`
- Create: `Solora/functions/tsconfig.json`
- Create: `Solora/functions/src/index.ts`
- Create: `Solora/functions/test/health.test.ts`

- [ ] **Step 1: Define the Functions package**

Create `functions/package.json` with:

```json
{
  "name": "solora-functions",
  "private": true,
  "main": "lib/index.js",
  "engines": { "node": "20" },
  "scripts": {
    "build": "tsc",
    "test": "npm run build && node --test lib/test/*.test.js"
  },
  "dependencies": {
    "firebase-admin": "^13.0.0",
    "firebase-functions": "^6.0.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "typescript": "^5.7.0"
  }
}
```

- [ ] **Step 2: Configure TypeScript**

Create `functions/tsconfig.json` with:

```json
{
  "compilerOptions": {
    "module": "commonjs",
    "target": "es2022",
    "outDir": "lib",
    "rootDir": ".",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  },
  "include": ["src", "test"]
}
```

- [ ] **Step 3: Write the failing health test**

Create `functions/test/health.test.ts` with:

```typescript
import assert from "node:assert/strict";
import test from "node:test";
import { healthPayload } from "../src/index";

test("health payload identifies Solora", () => {
  assert.deepEqual(healthPayload(), { service: "Solora", status: "ok" });
});
```

- [ ] **Step 4: Run the test to verify it fails**

Run:

```bash
cd functions
npm install
npm test
```

Expected: compilation fails because `healthPayload` does not exist.

- [ ] **Step 5: Implement the health boundary**

Create `functions/src/index.ts` with:

```typescript
import { onRequest } from "firebase-functions/v2/https";

export function healthPayload() {
  return { service: "Solora", status: "ok" } as const;
}

export const health = onRequest({ cors: false }, (_request, response) => {
  response.status(200).json(healthPayload());
});
```

- [ ] **Step 6: Run the Functions test**

Run:

```bash
npm test
```

Expected: one passing Node test.

- [ ] **Step 7: Deploy the safe Firebase foundation**

Run from the repository root:

```bash
firebase deploy --only firestore:rules,functions:health --project solora-5hadowblaze
```

Expected: Firestore rules and the `health` function deploy successfully. If Firebase requires billing to deploy Functions, leave the tested function undeployed, record that exact external prerequisite in `docs/BUILD_JOURNAL.md`, and continue with the local app foundation.

- [ ] **Step 8: Commit the Functions boundary**

Run:

```bash
git add functions firebase.json firestore.rules docs/BUILD_JOURNAL.md
git commit -m "feat: add tested Firebase Functions boundary"
```

### Task 7: Publish the private GitHub repository

**Files:**
- Modify: `Solora/README.md`
- Modify: `Solora/docs/BUILD_JOURNAL.md`

- [ ] **Step 1: Verify no private export artifacts or secrets are staged**

Run:

```bash
git status --short
git ls-files | rg 'Career Fridge\.ipa|Packaging\.log|DistributionSummary|ExportOptions|\.env'
```

Expected: the second command returns no files. The legacy IPA and packaging metadata remain outside the new repository.

- [ ] **Step 2: Run the complete foundation verification**

Run:

```bash
xcodebuild test -project Solora.xcodeproj -scheme Solora -destination 'platform=iOS Simulator,id=27D75B38-EF67-4A19-A9CC-6BB0B90FAB85'
npm --prefix functions test
git diff --check
```

Expected: iOS tests pass, Functions test passes, and `git diff --check` produces no output.

- [ ] **Step 3: Create the private GitHub repository and push**

Run:

```bash
gh repo create 5hadowblaze/Solora --private --description "Your life becomes your lore." --source . --remote origin --push
```

Expected: `https://github.com/5hadowblaze/Solora` exists as a private repository and `main` is pushed.

- [ ] **Step 4: Record foundation completion**

Append to `docs/BUILD_JOURNAL.md`:

```markdown

## Foundation verification

- Created the private `5hadowblaze/Solora` GitHub repository.
- Created the Firebase project with public display name `Solora`.
- Registered the exact iOS bundle ID `com.amirdzakwan.solora`.
- Verified the native iOS build and model tests on iPhone 17 Pro Simulator.
- Verified the Firebase Functions health boundary locally.
```

Commit and push:

```bash
git add docs/BUILD_JOURNAL.md
git commit -m "docs: record verified Solora foundation"
git push origin main
```

### Task 8: Launch and visually verify the iOS foundation

**Files:**
- Modify only if verification finds a concrete issue in a file created above.

- [ ] **Step 1: Boot the pinned Simulator and install the app**

Run:

```bash
xcrun simctl boot 27D75B38-EF67-4A19-A9CC-6BB0B90FAB85 || true
open -a Simulator
xcodebuild build -project Solora.xcodeproj -scheme Solora -destination 'platform=iOS Simulator,id=27D75B38-EF67-4A19-A9CC-6BB0B90FAB85' -derivedDataPath DerivedData
xcrun simctl install 27D75B38-EF67-4A19-A9CC-6BB0B90FAB85 DerivedData/Build/Products/Debug-iphonesimulator/Solora.app
xcrun simctl launch 27D75B38-EF67-4A19-A9CC-6BB0B90FAB85 com.amirdzakwan.solora
```

Expected: Solora opens on the Today tab.

- [ ] **Step 2: Use the computer-control workflow to inspect the real Simulator**

Verify:

- Today opens without a crash.
- Five tab labels fit and remain readable.
- Coral, cream, orb, and rounded visual language is visible.
- Each tab opens.
- World renders the two deterministic Soloras.
- Text remains legible at the default Dynamic Type size.
- No Firebase configuration error appears in the Xcode console.

- [ ] **Step 3: Re-run tests after any visual correction**

Run:

```bash
xcodebuild test -project Solora.xcodeproj -scheme Solora -destination 'platform=iOS Simulator,id=27D75B38-EF67-4A19-A9CC-6BB0B90FAB85'
npm --prefix functions test
git diff --check
```

Expected: all verification remains green.

- [ ] **Step 4: Commit and push any verified correction**

Run only if files changed:

```bash
git add Solora SoloraTests project.yml Solora.xcodeproj docs/BUILD_JOURNAL.md
git commit -m "fix: polish verified Solora foundation"
git push origin main
```

## Foundation completion criteria

The plan is complete when:

1. `5hadowblaze/Solora` exists privately on GitHub.
2. Firebase shows a project with public display name `Solora`.
3. Firebase contains an iOS app named `Solora` with bundle ID `com.amirdzakwan.solora`.
4. The five-tab SwiftUI shell builds and launches on the pinned iPhone 17 Pro Simulator.
5. Core model and manifest-fallback tests pass.
6. The Firebase Functions health test passes locally.
7. No OpenAI or other server-side secret is tracked; generated Firebase client configuration is expected and is not treated as a server secret.
8. The build journal records meaningful Codex involvement.
