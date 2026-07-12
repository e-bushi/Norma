//
//  ReminderPreservationTests.swift
//  NormaTests
//
//  Regression tests for NoteRepository.applyExtractedTokens reminder
//  reconciliation.
//
//  Background: re-extraction rebuilds a note's tokens from scratch. A reminder
//  the user has confirmed (tapped the chip, picked a time) carries state that
//  lives only on the token — confirmedAt and the user-chosen remindAt. That
//  state must survive re-extraction two ways: when the LLM re-emits the same
//  reminder (carry the confirmation onto the fresh token, user's time wins),
//  and when the LLM drops it entirely (the confirmed token is sticky and
//  survives the swap). An unconfirmed reminder has no user state, so the AI
//  still owns it and the fresh emission replaces it.
//

import Testing
import SwiftData
import Foundation
@testable import Norma

@MainActor
struct ReminderPreservationTests {

    /// Isolated in-memory context holding just the note graph (Note + NoteToken
    /// reference only each other, so no other @Model types are needed).
    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Note.self, NoteToken.self, configurations: config)
        return ModelContext(container)
    }

    /// A fixed future date so assertions don't depend on the wall clock.
    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 9) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    /// Builds a reminder token for the canonical "renew visa" prose.
    private func reminderToken(remindAt: Date?, confirmedAt: Date? = nil) -> NoteToken {
        NoteToken(
            kind: .reminder,
            amount: 0,
            currency: "USD",
            subject: "renew visa",
            occurredAt: remindAt ?? Date(),
            remindAt: remindAt,
            confirmedAt: confirmedAt
        )
    }

    @Test("A confirmed reminder re-emitted by the LLM keeps the user's confirmation and time")
    func confirmedReminderCarriesAcrossReextraction() throws {
        let context = try makeContext()

        let note = Note(rawText: "remind me to renew visa friday")
        context.insert(note)

        // The user confirmed the chip and picked their own time.
        let userTime = date(2027, 8, 13, hour: 15)
        let confirmedStamp = date(2027, 8, 1)
        let original = reminderToken(remindAt: userTime, confirmedAt: confirmedStamp)
        note.tokens = [original]
        try context.save()

        // Re-extraction: the LLM re-emits the same reminder but re-infers a
        // different fire time from the prose.
        let reEmitted = reminderToken(remindAt: date(2027, 8, 13, hour: 9))
        NoteRepository.applyExtractedTokens([reEmitted], to: note, in: context)
        try context.save()

        // Exactly one reminder, still confirmed, still at the user's time.
        let reminders = note.tokens.filter { $0.kind == .reminder }
        #expect(reminders.count == 1)
        let surviving = try #require(reminders.first)
        #expect(surviving.confirmedAt != nil)
        let remindAt = try #require(surviving.remindAt)
        #expect(abs(remindAt.timeIntervalSince(userTime)) < 1)
        #expect(abs(surviving.occurredAt.timeIntervalSince(userTime)) < 1)
    }

    @Test("A confirmed reminder dropped from the new emission is sticky and survives")
    func confirmedReminderStickyWhenDropped() throws {
        let context = try makeContext()

        let note = Note(rawText: "remind me to renew visa friday")
        context.insert(note)

        let userTime = date(2027, 8, 13, hour: 15)
        let confirmed = reminderToken(remindAt: userTime, confirmedAt: date(2027, 8, 1))
        note.tokens = [confirmed]
        try context.save()

        // Re-extraction after the user rephrased the prose: the LLM no longer
        // emits the reminder at all.
        NoteRepository.applyExtractedTokens([], to: note, in: context)
        try context.save()

        // Confirmation is the source of truth — the token must survive.
        let reminders = note.tokens.filter { $0.kind == .reminder }
        #expect(reminders.count == 1)
        let surviving = try #require(reminders.first)
        #expect(surviving.id == confirmed.id)
        #expect(surviving.confirmedAt != nil)
    }

    @Test("An unconfirmed reminder is replaced by the fresh emission")
    func unconfirmedReminderReplacedOnReextraction() throws {
        let context = try makeContext()

        let note = Note(rawText: "remind me to renew visa friday")
        context.insert(note)

        // Never confirmed — the AI still owns it.
        let stale = reminderToken(remindAt: date(2027, 8, 13, hour: 9))
        note.tokens = [stale]
        try context.save()

        // The LLM re-infers a different time from edited prose.
        let freshTime = date(2027, 8, 20, hour: 9)
        let reEmitted = reminderToken(remindAt: freshTime)
        NoteRepository.applyExtractedTokens([reEmitted], to: note, in: context)
        try context.save()

        // The fresh copy wins; no zombie confirmation appears.
        let reminders = note.tokens.filter { $0.kind == .reminder }
        #expect(reminders.count == 1)
        let surviving = try #require(reminders.first)
        #expect(surviving.confirmedAt == nil)
        let remindAt = try #require(surviving.remindAt)
        #expect(abs(remindAt.timeIntervalSince(freshTime)) < 1)
    }

    @Test("Duplicate reminders in one emission collapse to a single token")
    func duplicateRemindersDeduplicated() throws {
        let context = try makeContext()

        let note = Note(rawText: "renew visa. seriously, renew the visa")
        context.insert(note)
        try context.save()

        let a = reminderToken(remindAt: date(2027, 8, 13, hour: 9))
        let b = reminderToken(remindAt: date(2027, 8, 13, hour: 10))
        NoteRepository.applyExtractedTokens([a, b], to: note, in: context)
        try context.save()

        #expect(note.tokens.filter { $0.kind == .reminder }.count == 1)
    }

    @Test("Reminder notification identifiers round-trip through parse")
    func reminderIdentifierRoundTrip() {
        let tokenId = UUID()
        let identifier = NoteRepository.reminderIdentifier(tokenId: tokenId)
        #expect(NoteRepository.parseReminderTokenId(from: identifier) == tokenId)

        // Foreign identifiers (chat reminders, bill notifications) must not parse.
        #expect(NoteRepository.parseReminderTokenId(from: "ai_reminder_\(UUID().uuidString)") == nil)
        #expect(NoteRepository.parseReminderTokenId(from: "\(UUID().uuidString)_0_due") == nil)
    }
}
