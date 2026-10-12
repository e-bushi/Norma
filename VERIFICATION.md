# Verifying agent work: the shared standard

Owners: Martin (macOS) and Ian (iOS). This is drawn from DORA (2025 State of AI-assisted Software Development, and the CI and test automation capabilities) and Point-Free's testing libraries.

## Why
AI makes changes cheap and frequent, and without strong safety nets that hurts stability (DORA 2025). So the gate has to be fast, trusted, and blocking: when CI is red, something is really wrong, and nothing merges until it's green.

## 1. Common gate (every repo, every PR)
- GitHub Actions on a macOS runner runs the build, the Swift Testing unit tests, and SwiftLint and swift-format in strict mode.
- Each repo gets one **fast snapshot subset**: a single config (one appearance, default Dynamic Type, one screen size), so obvious visual breaks block the PR. Repos with a light mode use light. Norma has no light mode. `UIUserInterfaceStyle` is `Dark` in Info.plist, and its snapshot is dark mode, default Dynamic Type, iPhone 17 (`home-dark-default`).
- Target time: 10 minutes or less on macOS repos, 15 or less on iOS repos.
- Flaky tests are fixed or quarantined within a day. A quarantined test needs a ticket.
- Determinism: clock, date, UUID, and randomness all go through swift-dependencies, and an un-overridden live dependency fails the test.
- Assertions on structured values use `expectNoDifference` (swift-custom-dump) so a failure prints a readable diff.

## 2. Agent contract (part of every ticket's done criteria)
- One ticket per PR, kept small.
- The ticket names the tests that have to exist, and the agent adds or updates them in the same PR.
- The PR description includes the CI output and links to any new or changed snapshots: evidence, not claims.
- Re-recording a snapshot needs a sentence explaining why the change is intended.
- Commits must not include changes to unrelated files.

## 3. On merge to main and nightly
- Full snapshot matrix: light and dark mode, default and accessibility Dynamic Type, and small and large screens (plus any new device shape added as a config). Norma is dark only, so its matrix is dark mode, default and accessibility Dynamic Type, and small and large screens.
- XCUITest smoke tests: one or two flows per app (launch, main screen, one core action). The keyboard is checked with a simulator screenshot saved as an XCUITest attachment, not a snapshot baseline. SnapshotTesting cannot capture the keyboard.
- When main goes red, the change is reverted immediately, and the fix comes in a new PR.

## 4. Domain checks
**macOS / Structures**
- A golden event-log test per bundled problem: the reference solution's events match a committed log.
- A `MotionMap` test: every event type maps to exactly one pickle gesture.
- A run-pipeline test with a timeout, a compile error, and an oversized output.

**iOS / pickle, ida, norma**
- Every figure JSON passes `FigureRules` in the PR gate.
- Each figure gets snapshots of its rest and touched states, plus motion sampled at fixed spring times (in the matrix).
- Norma's date logic runs under a controlled date.

## 5. Human review and release
- Martin or Ian reviews each PR against the repo's architecture doc and conventions before merge.
- Dan signs off on the look of new motions from screen recordings.
- iOS release candidates go out on TestFlight with an on-device checklist written per ticket, and Chris runs it.
- Mac release candidates get a smoke checklist on a clean macOS install with Xcode.
