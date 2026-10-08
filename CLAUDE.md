# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Communication Style

Write to save Chris effort. Always:
- Lead with the point in one sentence ("The finding:", "The fix:", "The bug:").
- Bold labels, short numbered lists, one line per item.
- One idea per sentence. No repetition, no hedging, no wind-up.
- Explicitly say what NOT to do when it saves a wrong turn.
- End with the single next action, not a menu.
- Long-form only when walking through an experience or when Chris asks for depth.

## Build & Test Commands
- Build app: `xcodebuild -scheme Norma build`
- Run all tests: `xcodebuild -scheme Norma test`
- Run unit tests only: `xcodebuild -scheme Norma test -only-testing:NormaTests`
- Run UI tests only: `xcodebuild -scheme Norma test -only-testing:NormaUITests`
- Run single unit test: `xcodebuild -scheme Norma test -only-testing:NormaTests/NormaTests/testName`
- Run single UI test: `xcodebuild -scheme Norma test -only-testing:NormaUITests/NormaUITests/testName`

## Architecture Overview

Norma is a free, fully local SwiftUI app: track your bills and your income, and see what's left each month. No account, no server, no analytics. Everything is stored with SwiftData on device.

### Directory Structure
- **Core/Models**: SwiftData models `Bill` and `UserProfile`, plus `BillFrequency` and `IncomeCadence`. These hold the pure date math: bill occurrences and paydays.
- **Core/Services**: `MonthSummary` (income − bills = what's left), `NotificationService` (bill reminders), and `LocalDataReset`.
- **Views/Components**: Shared UI (`NormaComponents`, `CadencePicker`/`IncomeEditSheet`), plus the dither shader and wave text.
- **Views/Screens**: `RootView`, `HomeView`, `BillEditorSheet`, `CalendarSheet`, `SettingsView`, and `Onboarding/`.
- **Utilities**: `NormaPalette` (color tokens), `AppTheme` (accent), `Money` (formatting), and `Haptics`.

### Navigation Flow
`RootView` shows onboarding until a `UserProfile` exists, then `HomeView`. Home is the only screen. Settings, the calendar, the income editor and the bill editor open as sheets from it.

### Key Design Patterns
- Views read models directly with `@Query`. There are no view models.
- Nothing derived is stored. `MonthSummary` is rebuilt from bills and the profile on every render.
- Bill paid state is "paid through" a date, so paying ahead settles earlier occurrences.
- Colors come from `NormaPalette` only. Don't redeclare hex colors in views.

## Code Style Guidelines
- **Formatting**: 4-space indentation, consistent spacing around operators
- **Imports**: Group imports by framework (Swift standard libraries first, then Apple frameworks, then third-party)
- **Types**: Use SwiftData's `@Model` for persistence models, SwiftUI's property wrappers for view state
- **Naming**: Use camelCase for variables/properties/functions, PascalCase for types/protocols
- **Error Handling**: Use `do/catch` blocks for recoverable errors, `fatalError()` only when unrecoverable
- **SwiftUI**: Prefer composition, extract complex views into separate components
- **Comments**: Include standard header comments and document complex logic

## Testing
- Unit tests use the `Testing` framework with `@Test` annotation
- UI tests use `XCTest` with `XCUIApplication` for app interaction
- Use `@MainActor` annotation for UI tests to run on the main thread
- Tests are located in `NormaTests/` and `NormaUITests/` directories

## Development Notes
- Minimum iOS deployment target: 26.0
- Swift version: 5.0
- Bundle identifier: com.myndfruit.Norma
- The SwiftData store is named "Norma". UI tests launch with `--ui-testing` to use an in-memory store.
- The pre-cut app (runway, chat, Plaid, Supabase, receipts) lives at git tag `pre-core-cut`.