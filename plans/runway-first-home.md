# Runway-First Home — Spec

**Branch:** `runway-first-home`
**Status:** Draft, in discussion
**Owner:** Chris

## The pivot in one sentence
The runway/arc becomes the home screen and the whole point of the app ("how long does my money last, and what just changed it"); notes demote from the primary canvas to a narrow **forward-looking what-if capture** that feeds runway; everything that doesn't serve runway is cut or made dormant.

## Why (the reasoning behind this)
- Runway is the painkiller for the target user (long-stay nomad on a draining balance). The notes-to-chips loop is a clever demo, not a need.
- Plaid can't see cash, so **manual balance entry is the correct architecture**, not a compromise. One number, re-anchored occasionally.
- The runway engine already exists (`ArcCalculationService`), just measured in billing cycles and fed only by bills.
- The re-anchor ledger already exists (`FreedomFundEntry`) — timestamped balance observations.
- `freedomFund` is mislabeled "emergency savings" but is meant to be the pool life is funded from.

---

## 1. Core model change: `freedomFund` → "total spendable"

- **Keep the field name** `freedomFund` (renaming the encrypted key is high-risk, no payoff). Change only its **meaning** in ~4 spots:
  - `ToolExtractable.swift:58` — extraction description
  - `NormaSystemPrompts.swift:47,61` — onboarding prompt copy
  - `ArcCalculationService.swift:23` — doc comment
  - Any user-facing "freedom fund / savings" copy → "money you have to live on"
- **One pool only.** No spending-vs-savings split at the data layer. Emotional "you're into your reserve" is a **threshold on one number**, shown at the display layer — never a second tracked account.

## 2. The re-anchor loop

- **Stored balance changes ONLY on re-anchor** (user types the number). It is the ground truth.
- **Runway is a projection**, computed — never a mutation:
  `projected = storedBalance − (bills due since anchor) − (est. burn since anchor) + (income since anchor)`
- **Marking a bill paid is a status flag that feeds the projection — it must NOT mutate the stored balance.** (The current orphaned `deductFreedomFundForBillPayment` double-counts against re-anchor; keep it un-wired / remove it.)
- **Burn is derived from `FreedomFundEntry` deltas**, not from logged expenses. No expense logging, ever.
- **Income must be netted out** or a payday reads as negative burn. ← this is the open fork below.

## 3. Home screen

```
        ┌─────────────────────────┐
   ⚙    │        ◜ arc ◝          │   settings gear only
        │      "3 months"          │   runway = hero (derived, tappable)
        │       $1,900 · Steady     │   balance + tier
        │                          │
        │  what's coming            │   forward outflows + runway cost
        │   visa run · Aug 14 · $600   −8 days
        │   scooter? · someday · $1,200 −16 days
        └─────────────────────────┘
   [ forecast · calendar · insights ]   [ + ]
```

- **Runway hero + re-anchor flip:** tap the runway phrase → flips to reveal the **editable balance** → enter new number → flips back to the **recomputed** runway. Edit target is the balance; runway is the before/after payoff. Writes a `FreedomFundEntry`. No sheet.
- **Delete the freedom-fund toolbar capsule** (redundant once the fund is the home hero).
- **"What's coming" summary:** next few dated forward outflows (bills + `commit` + `intent` tokens), each with amount + runway delta. Triple duty: makes notes' value visible, is the browse-notes door (tap row → full note), warns of forward collisions.

## 4. Notes → runway what-if (the one surviving job)

**Keep:** forward-looking capture — the money moves that haven't happened yet, translated instantly to runway cost ("scooter = −9 days, Steady → Cautionary"). Reuses existing `intent`/`commit` extraction.

**Cut / demote:**
- General notes canvas as home, hero text, month grouping, tag taxonomy — overhead.
- Notes as expense/income ledger — replaced by re-anchor.
- Notes as input for the core numbers (balance, bills) — a tap UI beats prose.

**Capture UX:** `+` opens a **compact composer** (small bottom sheet, not the full two-layers-deep canvas) → type → extract → lands in "what's coming." The full note canvas becomes the **expand view** when tapping an existing item.

## 5. Navigation / IA

- No tab bar today — floating glass capsules on the (notes) home. Arc and notes **trade places**.
- **Bottom capsule stays:** forecast · calendar · insights.
- **`+` stays**, repurposed from "new note" → "capture what's coming." This is the notes entry point.
- **Browse notes archive:** low priority (value already surfaces in runway/forecast). Entry = tap a "what's coming" row. Do NOT add a fourth bottom icon.

## 6. Dormancy & deletions

- **Voice / Deepgram capture → DORMANT behind a `FeatureFlags` flag** (same pattern as `plaidEnabled`). Not deleted — on-device dictation isn't accurate enough, so we keep the Deepgram option available. Add `FeatureFlags.voiceCaptureEnabled = false`; gate the voice button in `NotesListScreen` + `NoteCanvasView`.
- **Freedom-fund toolbar capsule → removed** (see §3).
- **General notes canvas → demoted** to expand-view, not home.

## 7. Insights

- **Remove the paywall** (`hasAccess` gate → open access).
- Keep the tab **only if runway-framed.** Every insight must tie to runway/burn and be actionable:
  - ✅ "burn up 30% this week — 6 fewer days than last"
  - ✅ "rent + visa hit the same week next month; you'll dip into reserve"
  - ❌ "you've been writing a lot about food"

---

## Open decisions (need Chris)

1. **Income model — DECIDED: A.** Ignore income for v1: every downward balance delta = burn; tell users "re-anchor after payday." Add the minimal income-event model (B) only once the loop proves out. Don't build the income model before we know people re-anchor.
2. **Insights:** keep as bottom-nav tab (runway-framed) or demote to a home card?
3. **Browse-notes entry:** "what's coming" row tap (leaning yes) vs. a header icon.
4. **Bill-paid behavior:** confirm bill-paid never mutates stored balance (status flag only) — feeds projection, not the anchor.

---

## Build phases (tracer-bullet order)

- **P0 — Dormancy:** ✅ DONE. `voiceCaptureEnabled=false`, voice button gated on notes list + canvas. Build green.
- **P1 — Swap home:** ✅ DONE. New `HomeView` hosts `ArcCountView` + bottom nav; `MainLayerView.notes → HomeView`; `+` presents `NotesListScreen` (untouched). Build green. FF toolbar capsule not carried over. *Prune later:* NotesListScreen still carries duplicate arc plumbing.
- **P2 — Home hero + chrome:** ✅ DONE. Balance number = hero; tap → inline `decimalPad` edit → writes balance + `FreedomFundEntry` (re-anchor), no sheet, commits on blur, no-ops if unchanged. Runway text demoted to subtitle. Settings → top-left; notes icon → top-right; info button removed; `ArcCountView` NavigationStack dropped (HomeView owns chrome). Build green.
  - *Follow-up:* notes icon still presents `NotesListScreen` as a fullScreenCover, not a true push. True segue needs stripping NotesListScreen's own NavigationStack — deferred.
  - *Interim:* bottom `+` still opens notes too; becomes quick-capture in P5.
- **P3 — Runway in days + burn engine:** ✅ DONE. `ArcCalculationService.dailyBurn` (ledger deltas ÷ days, fallback bills ÷ 30); hero speaks in compact time (`compactRunway`); status tiers re-keyed to days (`getStateName(days:)`) + legend updated. Build green. Early behavior = bill-coverage; observed burn sharpens it after 2+ anchors.
- **P4 — "What's coming":** render intents/commits with runway cost, **interleaved into the Recent Activity timeline** (decision Q2), not a separate block.
- **P5 — Compact capture:** `+` → quick-note **accessory composer** ("what's coming / what I'm thinking") → extract → surfaces in the timeline. Demote full canvas to expand-view.
- **P6 — Insights → timeline:** ✅ DONE. Insights merged into the Recent Activity feed as lavender rows (✦ + "hold to read"); long-press → full `InsightsView` sheet; un-paywalled; insights bottom icon removed (bar = forecast + calendar). Build green. *Still TODO (content):* re-aim insight generation to runway deltas / collisions.
  - *Note:* InsightsView is only reachable via long-press, so it's unreachable when there are zero insights (acceptable — nothing to show).
- **P7 — Calendar + forecast merge (LAST, own mini-spec):** consolidate into one screen. Inventory every place a reminder (`NoteToken.reminder` + bill notifications) renders/fires first — "cleanly" is the whole risk.
</content>
</invoke>
