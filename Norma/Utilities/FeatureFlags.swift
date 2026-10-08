//
//  FeatureFlags.swift
//  Norma
//
//  Compile-time switches for features that are built but dormant.
//

import Foundation

enum FeatureFlags {
    /// Master switch for the Plaid bank-connect integration.
    ///
    /// Off while the feature is dormant: nobody is connecting banks and the
    /// launch-time balance sync generates billable Plaid API calls for every
    /// user with a linked item. Gates the settings banking section (the only
    /// entry into Plaid Link), RootView's balance sync, and the linked-account
    /// states on the arc sheet and notes list. With the flag off,
    /// `PlaidService.connectedAccounts` simply never loads, so every consumer
    /// falls back to the manual freedom-fund path — including users who had
    /// an account wired, whose fund freezes at its last-synced value in
    /// `settings.freedomFund`.
    ///
    /// Flip to true to revive the feature client-side. The Plaid dashboard
    /// plan and the Cortex proxy are billed independently of this flag.
    static let plaidEnabled = false

    /// Master switch for Deepgram-backed voice capture (the waveform button on
    /// the notes list and note canvas).
    ///
    /// Off while dormant: every dictation is a billable Deepgram call, and at
    /// zero revenue that cost isn't justified. We keep the feature rather than
    /// deleting it because on-device iOS dictation isn't accurate enough — the
    /// Deepgram option stays available to revive. With the flag off the voice
    /// button is hidden and capture is text-only.
    ///
    /// Flip to true to revive. Rotate the leaked Deepgram key before doing so.
    static let voiceCaptureEnabled = false

    /// Master switch for receipt capture: images shared to the Norma share
    /// extension, extracted server-side into pending transactions, then
    /// reviewed from the home toolbar badge.
    ///
    /// Off while the app has no accounts: the share extension and the
    /// `pending_transactions` fetch both authenticate with a Supabase session
    /// that no longer exists. Gates the home badge, the review sheet, and the
    /// pending fetch. Reviving it means either restoring auth or moving
    /// extraction on-device (Vision OCR + Foundation Models).
    static let receiptCaptureEnabled = false
}
