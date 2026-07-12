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

This is a SwiftUI-based iOS app for managing bills via a notes-first canvas, using a standard MVVM-like architecture. Expense tracking has been removed — the app no longer logs day-to-day spending in any form.

### Directory Structure
- **Core/Models**: Data models (`Bill`, `Note`, `NoteToken`, etc.)
- **Core/Services**: Business logic and data services
- **Core/View Models**: View models for state management
- **Views/Components**: Reusable UI components (`BillCardView`, `ChipView`, etc.)
- **Views/Screens**: Top-level screens (`NotesListScreen`, `NoteCanvasView`, `BillsView`, etc.)
- **Utilities**: Extensions and helpers for common functionality

### Navigation Flow
The notes list is the primary surface. Bills, forecast (income vs bills), and settings open as sheets from there.

### Key Design Patterns
- Component composition for reusable UI elements
- State management using SwiftUI property wrappers (`@State`, `@StateObject`, etc.)
- Model conformance to `Identifiable` and `Codable` for list rendering and persistence

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
- Minimum iOS deployment target: 17.5
- Swift version: 5.0
- Bundle identifier: com.myndfruit.Norma
- The app currently uses sample data (see `BillHomeView.sampleBills`)
- SwiftData integration is imported but not yet fully implemented