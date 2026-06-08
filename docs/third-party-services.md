# Third-Party Services

Services Norma pays for, with rough monthly cost. Usage-based services have no
fixed fee — costs scale with volume — so a "per super user" estimate is included
for the three biggest variable ones (Anthropic, Deepgram, Plaid).

A **super user** here means a heavy daily user: frequent note writing (→
extraction + insights), regular voice dictation, mini-chat use, and linked bank
accounts.

| Service | What it does | Pricing model | ~ Monthly cost | Per super user / mo |
|---|---|---|---|---|
| **Anthropic (Claude)** | Core AI — extraction, mini-chat, insights | Per-token usage | Variable — no fixed fee | ~$2–5 |
| **Deepgram** | Real-time speech-to-text | Per-minute audio | Variable — pay-as-you-go | ~$4–8 |
| **Supabase** | DB, auth, edge functions | Pro + usage | $36/mo | — |
| **Plaid** | Bank linking + transactions | Per-linked-item | Variable — $0 in sandbox | ~$1–3 |
| **Railway** | Hosts the Plaid/Cortex backend | Usage-based hosting | ~$5/mo + usage | — |
| **RevenueCat** | Subscriptions / IAP | Free < $2.5k MTR, then 1% | $0 until revenue scales | — |
| **Apple Developer Program** | Ship app, push, Sign in w/ Apple | Annual | $99/yr → ~$8.25/mo | — |

## Fixed monthly floor

Roughly **$49/mo** — Supabase $36 + Railway ~$5 + Apple ~$8.25 — independent of
how many users are active.

## Usage-based, on top of the floor

Anthropic, Deepgram, and Plaid bill purely on volume. As a rough per-super-user
figure, a single heavy user costs about **$7–16/mo** across the three:

- **Anthropic** ~$2–5 — every live AI path runs on Haiku 4.5; extraction,
  mini-chat, and insights all cache their system prompts (~90% off cached input).
- **Deepgram** ~$4–8 — frequent voice dictation
- **Plaid** ~$1–3 — a few linked accounts (production; $0 in sandbox)

These are order-of-magnitude estimates, not invoices. Actual costs depend on
prompt-cache hit rate, minutes of audio, and number of linked Plaid items.

## Anthropic cost notes (June 2026)

The Anthropic figure dropped sharply from an earlier ~$20–30 estimate. Two
reasons:

1. **Correction.** The earlier number assumed an Opus-first model cascade. That
   cascade only ever served the main-chat and conversational-onboarding surfaces,
   both of which had already been removed from the app — so no user could reach an
   Opus call. The live AI surface was always Haiku-based.
2. **Real reduction.** Note extraction (the highest-volume call — runs on
   essentially every note) previously sent its full ~144-line system prompt +
   tool schema uncached on every request. It now uses `cache_control`, so repeat
   extractions pay ~10% on that static prefix.

The dead Opus code (`MainChatView`, `ConversationManager`, `ChatMenuView`, the
conversational-onboarding methods, and most of `AnthropicService`) was deleted in
this pass. `AnthropicService` now only holds the shared API key, read by the three
Haiku services.

## To confirm

- **Plaid**: sandbox (free) vs production (per-item billing)?
- Whether Supabase usage regularly pushes past the $36 Pro baseline.
