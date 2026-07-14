# Norma Chat — Spec (replaces notes as the input surface)

**Branch:** `runway-first-home` (continues the runway-first work)
**Status:** Draft
**Depends on:** decision A (leave notes live until chat replaces it, then prune)

## The pivot in one sentence
A full-screen conversational surface becomes the way you add bills, reminders, and intentions **and** the "ask Norma anything about my money" copilot — replacing prose notes + background extraction. Notes get deleted only after the chat covers their job.

## Why
- Prose extraction was the weak link: a conversation can **ask, confirm, disambiguate** — structured financial data needs that; free-form notes never did it well.
- The chat doubles as the **retrieval/what-if copilot** — the biggest long-standing gap ("how long do I last if I take this trip?").
- Reuses the value-per-input principle: minimal input → the AI does the structuring, out loud, verifiably.

## Two findings that shape the build
1. **Reuse `MiniChatService`** — Supabase `anthropic-proxy` (already off the leaked key) + Haiku 4.5 + prompt caching + a working tool-loop. Extend it; don't rebuild.
2. **`NoteToken` survives notes.** It's a rich financial-item model (kind, amount, currency, subject, occurredAt, remindAt, confirmedAt, recurrence, userAdjustedAt). Forecast/calendar/reminders already read it. The chat becomes a *token producer* — like extraction was, but conversational. Notes deletion = removing prose/extraction/UI, not the token layer.

---

## 1. New chat tools (the gap)
`MiniChatTools` today: `get_bills`, `update_bill`, `get_freedom_fund`, `get_profile`, `save_fact`, `update_profile`. Missing the **create** verbs:
- `add_bill(name, amount, frequency, dueDate?)` → `BillViewModel.addBill` → Supabase.
- `add_reminder(subject, remindAt, recurrence?)` → standalone `NoteToken(kind: .reminder)` + schedule OS notification (reuse `NoteRepository.scheduleReminderRequest`).
- `add_intention(subject, amount, occurredAt?)` → standalone `NoteToken(kind: .intent)`.
- `add_commitment(subject, amount, occurredAt)` → standalone `NoteToken(kind: .commit)`.
- `set_balance(amount)` → the re-anchor (writes settings + `FreedomFundEntry`), same path as the balance popover.
- `project_runway(delta)` → what-if: runway if balance changes by −delta (uses the P3 burn engine). Powers "can I afford X?"

Each create tool returns a confirmation string the chat surfaces ("added rent · $1,400 · monthly · due the 1st").

## 2. Data model
- **Keep `NoteToken`** as the financial-item store; allow tokens **not attached to a Note** (chat creates standalone).
- Later (prune phase): rename `NoteToken` → e.g. `LedgerItem`/`MoneyItem` and drop the `Note` relationship. Not required for v1 — decoupling is enough.

## 3. UI — full-screen glass chat overlay
- New view (adapt `MiniChatView`, **decouple from `note`**): full-screen, `.glassEffect` transparent layer over the home.
- Conversation transcript (user right, Norma left), input field at the bottom, dismiss (swipe-down / close).
- **Loading state = `DitherShaderView`** (the salvaged notes dither) while a response streams.
- Tool results render as compact confirmation chips inline ("✓ added rent").
- Entry point: a chat action on the home screen (candidate: repurpose the `+` — quick-note dies with notes — into the chat button; or a distinct FAB). **Open decision.**

## 4. Migration order (decision A — replacement first, prune last)
- **C1 — Create tools:** add the `add_*` / `set_balance` / `project_runway` tools to `MiniChatTools` (+ tool schemas in the service). Test via existing MiniChat. Notes still live.
- **C2 — Full-screen chat view:** decoupled glass chat + home entry point + dither loading.
- **C3 — Repoint reads:** confirm forecast/calendar/reminders read tokens regardless of note attachment (should already; verify standalone tokens surface).
- **C4 — Prune notes:** delete `NotesListScreen`, `NoteCanvasView`, `NoteRepository` text/extraction, `NoteSyncQueue`, `NoteExtractionService`, the notes entry points, and the `Note` model + note↔token attachment. Keep `NoteToken`, `DitherShaderView`, `BillTokenBridge`.

## 5. Cost
- Haiku + proxy + prompt caching already minimize per-message cost. Fine for now.
- Add a monthly **meter** when usage grows (ties into the deferred proxy/meter plan). Don't build the meter in v1.

## Open decisions
1. **Chat entry point** on home: repurpose `+` → chat, or a distinct chat FAB? (Lean: repurpose `+`, since quick-note leaves with notes.)
2. **Streaming**: stream tokens (better feel, more edge-fn work) or wait-then-show with the dither (simpler)? (Lean: dither-then-show for v1, stream later — the dither is the whole point of salvaging it.)
3. **Reminder scheduling from chat**: reuse the async permission+schedule path from `confirmReminder`? (Lean: yes.)
