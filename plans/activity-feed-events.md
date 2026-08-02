# Activity Feed Event Whitelist

**Goal:** Bills, reminders, and intent updates land in the Recent Activity feed on the runway home — without drowning the re-anchor reward loop that feed exists to serve.

**Ranking rule:** an event earns a row only if it changes the runway or demands an action. Everything else is noise.

## Current state

`ArcCountView.timelineRows` merges two sources, newest-first:
- Fund-balance changes (`FreedomFundEntry`: manual edit, linked-account sync)
- AI insights (`Insight`)

## Whitelist (IN)

| Event | Source | Row label pattern | Why it's in |
|---|---|---|---|
| Bill added | `Bill.createdAt` (Supabase) | `added rent · −4 days` | Directly shortens runway |
| Bill paid | `Bill.paidAt` set | `paid rent · $1,200` | The core monthly ritual; confirms burn |
| Bill amount changed | `Bill.updatedAt` where amount differs | `netflix now $18 · −0.2 days` | Changes runway |
| Bill removed / deactivated | `isActive` → false | `dropped hulu · +0.5 days` | Lengthens runway — a win worth celebrating |
| Intent advanced | `NoteToken` kind `.intent`, `occurredAt` +1mo | `still planning: quit gym` | Recurring commitment pressure; nudges action |
| Reminder fired (due today) | `NoteToken.remindAt` in today | `remind: renew visa` | Demands action today |
| Commitment added | `NoteToken` kind `.commit` | `committed: send mom $200` | Future runway obligation |

## Blacklist (OUT — do not build rows for these)

- Reminder created or time edited — bookkeeping, no runway change
- Bill reminder toggled / `reminderDays` changed — settings churn
- Bill name/merchant/category edits — cosmetic
- Bill due-date shift within the same cycle — runway-neutral
- Intent created — chat already confirms it inline; the feed picks it up at first advance
- Profile/fact saves from chat — invisible plumbing

## Runway impact suffix

Where an event changes monthly burn, append the delta in days:

```
days = fund / dailyBurn(after) − fund / dailyBurn(before)
```

- Round to 1 decimal under a day, whole days above
- Skip the suffix when fund == 0 or the delta rounds to 0
- Reuse the burn math in `ArcCalculationService` — do not re-derive it

This is the value-per-input payoff: the feed answers "so what?" in the same row.

## Data sourcing (no new event table)

Derive rows from existing timestamps — same pattern `timelineRows` already uses:
- Bills: `createdAt`, `updatedAt`, `paidAt` from the Supabase fetch already in memory
- Tokens: local SwiftData query on `occurredAt` / `remindAt`
- **Do not** add an events/journal table (BillPaymentJournal was just deleted — don't resurrect it). Accept the known limit: amount-change rows only show the latest change, not history. Fine for a feed.

## Feed hygiene

- Cap the merged feed at the current row limit; balance changes and insights keep their slots — bill/token rows never push a re-anchor row out of the visible window on the same day
- Same-day dedupe: multiple edits to one bill collapse to the latest row
- Fund rows keep their existing visual weight; new rows use the dimmer text style so re-anchors stay the loudest thing in the feed

## Out of scope

- Long-press → chat-seeded context (separate spec, builds on these rows)
- Tapping a bill row → BillDetailSheet (nice-to-have, not this pass)
