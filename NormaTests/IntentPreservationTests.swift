//
//  IntentPreservationTests.swift
//  NormaTests
//
//  Regression tests for NoteRepository.applyExtractedTokens token preservation.
//
//  Background: re-extraction rebuilds a note's tokens from scratch (delete all,
//  recreate from the fresh LLM emission). A user can directly mutate an
//  intent/commit token — advancing it to a later month or upgrading it to a
//  commitment — and that edit lives only on the token, not in the prose. Those
//  edits must survive a later re-extraction; an un-edited intention must NOT
//  (the AI still owns it). These tests pin both halves of that contract.
//

import Testing
import SwiftData
import Foundation
@testable import Norma

@MainActor
struct IntentPreservationTests {

    /// Isolated in-memory context holding just the note graph (Note + NoteToken
    /// reference only each other, so no other @Model types are needed).
    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Note.self, NoteToken.self, configurations: config)
        return ModelContext(container)
    }

    /// A fixed June 2026 date so assertions don't depend on the wall clock.
    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
    }

    /// Builds an intent token for the canonical "$200 bali trip" prose.
    private func intentToken(occurredAt: Date) -> NoteToken {
        NoteToken(
            kind: .intent,
            amount: 200,
            currency: "USD",
            subject: "bali trip",
            occurredAt: occurredAt
        )
    }

    @Test("A user-advanced intention survives note re-extraction")
    func advancedIntentionSurvivesReextraction() throws {
        let context = try makeContext()

        // A note whose prose produced one intention.
        let note = Note(rawText: "thinking about a $200 bali trip")
        context.insert(note)
        let original = intentToken(occurredAt: date(2026, 6, 1))
        note.tokens = [original]
        try context.save()

        // User advances it to next month and stamps userAdjustedAt — the real
        // performAdvanceIntentions flow.
        let advancedDate = date(2026, 7, 1)
        original.occurredAt = advancedDate
        original.userAdjustedAt = Date()
        try context.save()

        // Re-extraction: the LLM re-emits a fresh intent for the same prose,
        // with occurredAt reset to its creation-date (June), unaware of the move.
        let reEmitted = intentToken(occurredAt: date(2026, 6, 1))
        NoteRepository.applyExtractedTokens([reEmitted], to: note, in: context)
        try context.save()

        // The advanced intention must survive untouched — exactly one intent,
        // still in July, still stamped — NOT replaced by the AI's reset copy.
        let intents = note.tokens.filter { $0.kind == .intent }
        #expect(intents.count == 1)
        let surviving = try #require(intents.first)
        #expect(surviving.userAdjustedAt != nil)
        #expect(abs(surviving.occurredAt.timeIntervalSince(advancedDate)) < 1)
    }

    @Test("An untouched intention is replaced by re-extraction")
    func unadjustedIntentionIsReplacedOnReextraction() throws {
        let context = try makeContext()

        // An intention the user never touched (no userAdjustedAt stamp).
        let note = Note(rawText: "thinking about a $200 bali trip")
        context.insert(note)
        let stale = intentToken(occurredAt: date(2026, 7, 1))
        note.tokens = [stale]
        try context.save()

        // Re-extraction emits a fresh intent dated June.
        let reEmitted = intentToken(occurredAt: date(2026, 6, 1))
        NoteRepository.applyExtractedTokens([reEmitted], to: note, in: context)
        try context.save()

        // The AI owns un-stamped intentions, so the fresh June copy replaces the
        // old one. This guards the inverse: preservation must be specific to
        // user-adjusted tokens, never blanket (else stale intentions could
        // never update).
        let intents = note.tokens.filter { $0.kind == .intent }
        #expect(intents.count == 1)
        let surviving = try #require(intents.first)
        #expect(surviving.userAdjustedAt == nil)
        #expect(abs(surviving.occurredAt.timeIntervalSince(date(2026, 6, 1))) < 1)
    }
}
