# Build Journal

## 2026-07-18 — Discovery and foundation

Codex analysed the Career Fridge IPA, reframed the product as Solora, and collaborated on an approved product design. The implementation was then split into five workstreams: foundation, capture, World, Create, and polish.

## 2026-07-18 — Parallel implementation and demo hardening

- Codex coordinated isolated worktrees for the SwiftUI foundation, Firebase configuration, and Functions boundary, then ran independent specification and code-quality reviews before integration.
- A second parallel pass built the animated onboarding, adaptive World showcase, and Create workflow while the main task polished Today, Archive, and You.
- Review found two demo-critical issues: an inert post-event control and a World regeneration value passed as immutable state. Both were fixed and verified in the iPhone 17 Pro Simulator.
- The post-event flow now saves a real in-session Solora that appears immediately in Archive and announces success to VoiceOver.
- Firestore was created in `europe-west2` and its private per-user rules were deployed. The Functions deploy boundary compiled successfully but Firebase correctly blocked cloud deployment until the project has Blaze billing.
- Deterministic launch arguments were added for rapid rehearsal and screenshot capture without compromising the default onboarding demo.

## 2026-07-18 — Cohesive motion system

- Codex audited motion across onboarding, capture, Archive, Create, World, and profile surfaces, then mapped animation only to interactions where it explains state, preserves spatial continuity, or rewards a rare action.
- Research covered Apple’s iOS 17 phase/keyframe animation, spring, symbol-effect, sensory-feedback, and reduced-motion guidance alongside lightweight open-source SwiftUI orb and fluid-motion implementations.
- A shared motion vocabulary now provides consistent easing, springs, tactile press states, blur-assisted reveals, and short stagger timing throughout the app.
- The Solora orb gained a deterministic, low-cost ambient treatment. It animates only in hero, loading, and formation contexts; list orbs remain still except for the focal World memory.
- Saving a reflection now triggers an accessible Solora-formation reward, success haptic, animated archive count, inserted memory transition, and automatically dismissing confirmation toast.
- World switching uses matched geometry, regeneration spatially reorders persistent memories, and Create reveals progress, ranked evidence, selection changes, and output previews with purpose-specific motion.
- The full project built and all unit tests passed on iPhone 17 Pro Simulator. Codex also walked the live onboarding, capture, World, and Create flows and repeated launch verification with Reduce Motion enabled.

## 2026-07-18 — Motion bridge into the reimagined design

- The motion language from `dc75961` is an intentional product invariant; the earlier screen composition is not. New surfaces must reuse the shared springs, tactile press feedback, blur-assisted reveals, haptics, and reduced-motion fallbacks without restoring the former layout.
- The redesigned flow now expresses that language as gather → orbit → settle → unfold: capture condenses into lore, Lore preserves spatial continuity while memories move and expand, and Share carries the same selected orbs into each generated artifact.
- Traveling matched-geometry selection, symbol feedback, and the shared spatial spring were carried into the new Share output picker and Lore world controls so state changes move rather than blink.
