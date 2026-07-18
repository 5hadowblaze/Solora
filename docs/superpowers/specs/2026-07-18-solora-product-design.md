# Solora Product Design

**Date:** 18 July 2026
**Status:** Approved for implementation
**Target:** Native iOS hackathon demo
**Tagline:** Your life becomes your lore.

## 1. Product summary

Solora is a private personal-world platform for ambitious early-career people whose experience is richer than the CV they remember to maintain.

It combines:

- A **Living Archive** that stores trustworthy records of roles, projects, events, achievements, people, skills, evidence, reflections, and photos.
- A **World** that uses constrained generative UI to reinterpret those records in a visual language tailored to the user.
- A **Create** engine that assembles selected records into useful career outputs such as tailored CVs and interview packs.
- Contextual **Share** actions that turn individual records into social and presentation assets.

Career is the first supported personal world. The architecture may later support travel, learning, relationships, health, hobbies, or other user-defined worlds, but those are outside the hackathon scope.

## 2. Problem and audience

The initial user is ambitious and early in their career. They attend many events, build projects, meet people, learn quickly, and accumulate meaningful evidence, but do not have time to document every experience.

The resulting problems are:

- Valuable experiences disappear into calendars, photos, messages, and memory.
- Static CVs flatten rich experiences into generic bullets.
- Preparing for an application or interview requires reconstructing evidence under pressure.
- Sharing achievements publicly takes additional writing and design work.
- Existing career tools feel administrative rather than personally meaningful.

Solora converts everyday activity into structured, reusable career evidence without requiring the user to maintain a document manually.

## 3. Core promise and product principles

The core promise is:

> Turn the traces of your life into a world that feels like you.

The design principles are:

1. **The data is stable; the experience is generative.** Generated Worlds may change, but the underlying Archive remains understandable and trustworthy.
2. **Capture once, reuse many times.** One reflection can update the Archive, World, CV evidence, interview stories, and shareable content.
3. **Private by default, expressive by choice.** The Archive is private. Users deliberately create or share outward-facing outputs.
4. **AI proposes; the user confirms.** Solora must not silently invent achievements, outcomes, or relationships.
5. **Delight supports clarity.** Motion and personality make reflection rewarding but never obscure the record or primary action.
6. **Demo reliability is a product requirement.** Every live AI or integration step has a polished fallback.

## 4. Brand

### 4.1 Name

**Solora** blends:

- **GPT-5.6 Sol** — intelligence and illumination
- **Lore** — the stories and meaning accumulated through a life
- **Aura** — the personal atmosphere in which those stories are rendered

The onboarding brand reveal presents:

> GPT-5.6 Sol + Lore + Aura

The ingredients then animate into:

> Solora

The motto appears afterward:

> Your life becomes your lore.

The public product must avoid implying that Solora is an official OpenAI product unless the hackathon rules explicitly permit that representation. The reveal can describe the name's inspiration while preserving Solora's independent identity.

### 4.2 Visual foundation

Solora extends the verified visual and product vocabulary of the Career Fridge IPA:

- Warm coral-led accent colour
- Friendly rounded typography inspired by Fredoka
- Tactile, collectible objects
- Rounded cards and soft depth
- Fridge magnets, stickers, milestones, and celebratory feedback
- Playful but credible career language
- Personal photos and evidence rather than generic stock imagery

Solora should not adopt a generic dark AI dashboard, excessive glassmorphism, or an undifferentiated purple gradient system.

## 5. The Solora object

Each meaningful captured moment becomes **a Solora**. A Solora is a living memory capsule represented by a warm, fluid orb.

The orb may evoke the responsive quality of a modern voice interface, but its final design must be distinct and grounded in Solora's tactile, coral, gold, cream, and personal-photo visual language.

Visual properties communicate meaning:

- Colour reflects category or era.
- Motion reflects energy and emotional intensity.
- Scale and glow reflect importance.
- Surface fragments may reference photos, stickers, or evidence.
- Completion state reflects whether the moment has outcomes and supporting detail.

Interactions:

- **Tap:** open the complete record.
- **Press:** replay the original voice reflection when available.
- **Swipe:** move between raw memory, structured achievement, and generated story.
- **Drag:** reposition the Solora inside supported Worlds.
- **Remix:** reinterpret it as a magnet, shelf object, game landmark, professional card, or another supported form.

## 6. Information architecture

The stable bottom navigation contains five destinations:

1. **Today** — calendar events, smart post-event prompts, recent activity, and quick capture.
2. **Archive** — the permanent chronological record of every Solora.
3. **Create** — goal-oriented career-output generation from multiple Soloras.
4. **World** — the currently generated visual interpretation of the Archive.
5. **You** — master CV, profile, connected sources, vibe, privacy, and settings.

**Share** is not a navigation destination. It is a contextual action on an individual Solora or completed Create output.

## 7. Onboarding

The hackathon onboarding flow is:

1. Solora brand reveal.
2. Brief value proposition.
3. CV upload or sample-CV option.
4. Google Calendar connection or sample-calendar option.
5. Hybrid vibe exercise:
   - Select three visual references.
   - Choose an energy such as calm, bold, playful, cinematic, nostalgic, or strange.
   - Complete: “Make my world feel like ___ meets ___.”
6. Parsed career facts appear for confirmation.
7. Initial Soloras form.
8. The recommended initial World is generated.

The vibe influences metaphor, layout, palette, illustration, motion, hierarchy, and writing voice. It must do more than swap theme colours.

## 8. Capture loop

### 8.1 Trigger

The production concept uses smart post-event prompts for calendar events that appear career-relevant.

The hackathon build also includes a reliable **Simulate event ending** control on Today. This triggers the full flow without waiting for a real calendar event.

### 8.2 Reflection

The user may:

- Speak for approximately 20 seconds.
- Type a reflection.
- Add one or more photos.
- Skip optional media.

Solora may ask one or two focused follow-up questions when a useful outcome, role, or contribution is unclear.

### 8.3 Enrichment

AI proposes:

- Title and concise summary
- Event, role, or project association
- Actions taken
- Outcomes and measurable impact
- Skills demonstrated
- People involved
- Evidence and media
- Potential interview-story structure
- Suggested importance and visual energy

The user confirms or edits material claims before they become permanent Archive facts.

### 8.4 Reward

The new Solora forms with a tactile animation, enters the Archive, and appears in the active World. The ending should feel celebratory without becoming slow or childish.

## 9. Living Archive and Career Graph

The Archive is the human-readable source of truth. The Career Graph is its structured representation.

A Solora record contains:

- Identifier and timestamps
- Source references such as CV, Calendar, reflection, or manual entry
- Raw reflection and optional audio reference
- Confirmed summary
- Role, organisation, project, and event associations
- People and relationship references
- Skills and skill evidence
- Actions, outcomes, and metrics
- Photos and supporting evidence
- Tags, category, importance, and emotional energy
- Privacy and sharing state
- Generated derivatives with provenance

The Career Graph connects Soloras to roles, projects, organisations, people, skills, goals, and eras. A generated World or document may interpret this graph but must not mutate confirmed facts without user action.

## 10. Generative World system

### 10.1 Chosen approach

AI generates a validated **World Manifest** rather than executable SwiftUI.

Solora provides a refined native component library. The model selects and composes supported components through a strict schema. This preserves reliability, accessibility, and visual quality while still allowing meaningful generative composition.

A World Manifest controls:

- Preset and metaphor
- Included Soloras
- Position, grouping, scale, and prominence
- Palette and atmosphere
- Supported component variants
- Motion style and intensity
- Generated headings and narrative
- Recommended focal moment

Invalid or unsupported values fall back to safe defaults.

### 10.2 Hackathon World presets

The demo includes three polished options:

1. **Memory Shelves** — the recommended hero World. Glowing Soloras sit on curved shelves; important memories shine more brightly and related moments cluster together. It uses an original visual language rather than copying any film or entertainment property.
2. **Career Fridge** — Soloras become tactile magnets, photos, notes, stickers, and milestones. This preserves the original app as one generated interpretation inside Solora.
3. **Quest Map** — roles become regions, projects become quests, skills become abilities, and major achievements become landmarks or badges.

The **Remix my world** action presents the three presets, with one recommended from the user's vibe.

### 10.3 Model use

For the hackathon, GPT-5.6 Sol is the primary reasoning and structured-generation model. A later production system could route higher-frequency extraction to Terra or Luna based on cost and latency requirements.

The OpenAI API is accessed through a backend or serverless proxy. API credentials must never be embedded in the iOS application.

## 11. Create

Create turns multiple Soloras into goal-oriented career outputs.

Entry goals include:

- Apply for a role
- Prepare for an interview
- Build a tailored CV
- Create a presentation
- Recap an event or period
- Make social content

### 11.1 Main hackathon workflow

The primary live workflow is **tailored CV + interview pack from a job description**.

Flow:

1. Paste or select a prepared job description or company-page description.
2. Solora identifies priorities, competencies, and language in the target.
3. Solora retrieves and ranks relevant Soloras, skills, evidence, and outcomes.
4. The user reviews the recommended selection and may add or remove memories.
5. Solora generates:
   - Tailored CV
   - Suggested CV entries
   - Interview talking points
   - Relevant STAR stories
   - Skills supported by evidence
   - Suggested questions for the interviewer
   - Optional cover-letter preview

The generated document must distinguish confirmed facts from editable suggestions.

### 11.2 Secondary demo outputs

The app may show polished controlled previews for:

- Presentation outline and slides
- Simulated “Open in Canva” handoff
- Event or period recap
- LinkedIn post
- Instagram Story

These do not need complete third-party publishing integrations for the hackathon.

## 12. Share

Share is a lightweight contextual action for an individual Solora or completed Create output.

Supported demo options:

- LinkedIn draft
- Instagram Story
- Presentation preview
- Public mini-page or link preview
- Exported image
- Native iOS share sheet

All outward content is previewed and editable before sharing.

## 13. Reliability and error handling

The golden-path demo must never depend entirely on network or integration state.

- **OpenAI timeout or failure:** use a locally cached manifest or generation result.
- **Invalid World Manifest:** decode safely and fall back to the recommended Memory Shelves manifest.
- **Calendar permission denied:** switch to a polished sample calendar.
- **CV selection or parsing failure:** offer a sample CV or manual continuation.
- **Audio failure:** retain typed reflection and provide a pre-recorded demo reflection.
- **Missing outcome:** store the item as an unconfirmed suggestion rather than inventing a result.
- **Partial generation:** preserve completed output sections and allow retry.

Loading states should explain the current transformation and use the Solora orb as progress feedback.

## 14. Privacy and trust

- Archive data is private by default.
- Calendar events are proposed for capture rather than automatically published or treated as achievements.
- Users confirm career claims before they become trusted facts.
- Social, CV, and presentation outputs are explicitly generated and previewed.
- The app explains which source supported each generated claim.
- The production design should support source deletion, account deletion, and export.
- The hackathon demo should avoid using real private calendar or CV data unless the presenter deliberately supplies it.

## 15. Hackathon implementation boundary

### 15.1 Must work convincingly

- Native SwiftUI navigation and polished motion
- Solora orb component and creation animation
- Three World renderers
- Demo calendar event and smart prompt
- Capture flow with at least one usable input mode
- Archive and active-World update
- Structured World Manifest decoding
- At least one live OpenAI-powered generation
- Tailored CV and interview-pack golden path
- Reliable demo-mode fallbacks

### 15.2 May use controlled demo data

- CV extraction fallback
- Calendar dataset
- Presentation and Canva preview
- Social previews
- Some job-description generation results
- Generated world imagery and textures

### 15.3 Non-goals

- A general-purpose social network
- Unlimited AI-authored SwiftUI code
- Production-ready Canva, LinkedIn, or Instagram publishing
- Support for every personal-life World
- Perfect CV parsing for all document formats
- Complete backend administration or analytics
- A large catalogue of unfinished World themes

## 16. Demo script

The intended two-to-three-minute sequence is:

1. State the problem: early-career people forget the evidence of what they do.
2. Open Solora and briefly show CV + Calendar onboarding.
3. Reveal the initial Memory Shelves World.
4. Tap **Simulate event ending**.
5. Record or play a short reflection from a tech event.
6. Watch a new Solora form.
7. Show the Archive and Memory Shelves update.
8. Open Create and paste a prepared job description.
9. Show Solora selecting relevant memories and evidence.
10. Reveal the tailored CV and interview pack.
11. Briefly show Share, Career Fridge, and Quest Map.
12. Finish on: **Your life becomes your lore.**

## 17. Judging alignment

### Idea + usefulness

Solora solves the gap between lived experience and the career evidence people can retrieve when they need it.

### Use of Codex

Maintain a concise build journal showing how Codex:

- Analysed the previous Career Fridge artifact
- Helped shape and document the new product
- Built the SwiftUI component system
- Implemented structured manifests and fallbacks
- Added tests
- Iterated through Simulator verification

Commit history, generated tests, and visible iteration evidence are more credible than a superficial badge.

### Execution

Execution is demonstrated through native polish, a complete golden path, constrained generative UI, and graceful fallbacks.

### Demo + clarity

The audience should understand one transformation:

> CV + Calendar + reflection → Living Archive → personal World → tailored career output.

## 18. Verification strategy

Verification should include:

- Unit tests for Solora and Career Graph models
- World Manifest decoding and invalid-value fallback tests
- Tests for ranking/selection result mapping
- Snapshot or visual-regression coverage for all three World presets
- State-transition tests for the simulated event flow
- Offline/cached-output tests
- Permission-denied paths for Calendar and microphone
- End-to-end golden-path walkthrough in iOS Simulator
- Manual checks for dynamic type, VoiceOver labels, contrast, reduced motion, and 44-point tap targets

During implementation, Codex should use the available computer-control workflow to operate Xcode and Simulator, alongside mobile UI design, official OpenAI documentation, planning, testing, and verification workflows.

## 19. Completion criteria

The hackathon design is implemented when:

1. A presenter can complete the golden-path demo without external setup during the presentation.
2. At least one OpenAI-powered transformation runs live.
3. Every network-dependent step has a convincing fallback.
4. The same Solora data visibly powers Archive, World, Create, and Share.
5. The three World presets are recognisably different and visually polished.
6. The job-description flow produces a credible tailored CV and interview pack.
7. The visual language clearly descends from Career Fridge while presenting Solora as a broader product.
8. The build journal provides clear evidence of meaningful Codex use.
