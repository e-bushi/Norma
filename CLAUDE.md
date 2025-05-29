# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands
- Build app: `xcodebuild -scheme Norma build`
- Run all tests: `xcodebuild -scheme Norma test`
- Run unit tests only: `xcodebuild -scheme Norma test -only-testing:NormaTests`
- Run UI tests only: `xcodebuild -scheme Norma test -only-testing:NormaUITests`
- Run single unit test: `xcodebuild -scheme Norma test -only-testing:NormaTests/NormaTests/testName`
- Run single UI test: `xcodebuild -scheme Norma test -only-testing:NormaUITests/NormaUITests/testName`

## Architecture Overview

This is a SwiftUI-based iOS app for managing bills and expenses, using a standard MVVM-like architecture:

### Directory Structure
- **Core/Models**: Data models like `Bill` with enums for status and frequency
- **Core/Services**: Business logic and data services (to be implemented)
- **Core/View Models**: View models for state management (to be implemented)
- **Views/Components**: Reusable UI components (`BillCardView`, `ExpenseCardView`, etc.)
- **Views/Screens**: Top-level screens (`BillHomeView`, `IncomeAndExpenseView`, etc.)
- **Utilities**: Extensions and helpers for common functionality

### Navigation Flow
The app uses a `TabView` as the root with three main tabs:
1. **My Bills**: Shows bill overview and management
2. **Expenses**: Displays income and expense tracking
3. **Settings**: App configuration (placeholder)

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