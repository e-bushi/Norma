# Income & Paydays — Spec

**Branch:** `runway-first-home`
**Status:** Draft, agreed direction (2026-07-17)
**Ethos:** Runway / "The Escape-Minded" — see [[project_ethos_escape_minded]].

## The problem
Income today is broken (see the diagnosis): fragmented across `settings.monthlyIncome` (the number
the math reads) and `UserProfile.incomeAmount/incomeFrequency/payday` (display only); **frequency is
decorative** (never converted into the monthly number); **payday is a single day-of-month Int** that
can't express weekly / biweekly / irregular. The Escape-Minded have **lumpy, varied income** — the
model assumes one fixed monthly salary on one calendar day. That's the mismatch to fix.

## Goals
1. **Flexible cadence capture** — weekly, biweekly, semi-monthly, monthly, irregular, one-off. The
   input adapts to the user; it must never feel like a rigid form. "The app caters to me."
2. **One source of truth** for income — kill the settings-vs-UserProfile split.
3. **Correct paydays** everywhere (calendar markers, forecast refill, low-point projection).
4. **Honest reconciliation** — income is a forecast, the anchor is truth; and explicit income lets us
   compute *real* burn instead of net burn.
5. **The payday nudge** — a gentle "you should've been paid ~X — re-anchor to confirm?" at the moment
   projection meets reality.

## Decisions locked
- **Entry points:** income/payday is its OWN thing (separate from re-anchor). Captured in
  **onboarding**, editable from the **calendar** and the **profile editor**.
- **Reconciliation rule (same as bills):** income is **projection-only — it NEVER mutates the stored
  balance.** Payday raises the *projected* balance; the next **re-anchor overwrites it with reality.**
  That is the reconciliation. Do NOT auto-add income to the stored balance (double-count trap —
  projection adds it AND the post-payday re-anchor already includes it).
- **Burn back-out (the upside):** with income + bill timing known, a re-anchor yields real spend:
  `true spend since anchor = income received − bills due − (balance change)`. Replaces net-burn.
- **Nudge is an invitation, not an obligation** (see [[project_norma_pain_point]]): in-app banner on
  open by default; push only if the user opts in.

## The cadence model
One flexible type instead of a day-of-month Int:

```
enum IncomeCadence {
    case weekly(weekday: Int)                 // 1=Sun … 7=Sat
    case biweekly(anchor: Date)               // every 14 days from an anchor date
    case semiMonthly(day1: Int, day2: Int)    // e.g. 15 & last day (US salaried)
    case monthly(day: Int)                    // clamped to month length (29–31 → last day)
    case irregular                            // no prediction; learn a rolling average
}
```
Income = `amount` + `cadence` (+ optional label/source). Derivations:
- `nextPaydays(from:through:) -> [Date]` per cadence — powers calendar + forecast + nudge.
- `monthlyEquivalent` — weekly ×4.33, biweekly ×2.166, semi-monthly ×2, monthly ×1, irregular =
  rolling average of recent income-labeled inflows. This is the single number the forecast math reads
  (replaces the raw `settings.monthlyIncome`).
- One-off expected inflows (a client invoice on a date) = a separate positive dated item; can reuse
  the `commit`/token infra, just positive. Keeps recurring cadence clean.

## Capture UX — progressive, not rigid
A two-step reveal so it feels tailored:
1. **"How often do you get paid?"** — weekly · every 2 weeks · twice a month · monthly · it varies.
2. The relevant detail control appears (only the one that matters):
   - weekly → weekday picker
   - biweekly → "last payday was…" date (sets the anchor)
   - semi-monthly → two day pickers (default 15 & last)
   - monthly → day-of-month picker
   - it varies → no schedule; "we'll learn your average and nudge you to check in"
   Plus an **amount** field. "it varies" is a first-class option, not an afterthought — that's the
   Escape-Minded's common case.

Onboarding uses this same component; calendar + profile open it to edit.

## Data model consolidation
- Introduce the income model as the single source of truth (structured fields on `UserProfile`, or a
  small `IncomeSource` — TBD in P1). Derive `monthlyEquivalent`; deprecate the scattered
  `incomeFrequency` string + `payday` Int + reliance on `settings.monthlyIncome` as raw input.
- **Migration:** existing users have `settings.monthlyIncome` (Double) + maybe `payday` (Int). Map →
  `monthly(day: payday ?? 1)` at `amount = monthlyIncome`. Lightweight; no data loss.

## Build phases (tracer order)
- **P1 — Model + consolidation:** cadence model + `monthlyEquivalent` + `nextPaydays`; one source of
  truth; migrate old fields. Forecast/calendar read the derived monthly. Build green.
- **P2 — Capture UX:** the progressive editor. Wire into onboarding (replace the income step) +
  calendar + profile.
- **P3 — Paydays everywhere:** calendar markers + forecast refill + low-point use `nextPaydays` for
  all cadences (fixes biweekly/weekly).
- **P4 — Reconciliation & burn back-out:** switch burn to the income-aware back-out at re-anchor.
- **P5 — Payday nudge:** on a predicted payday, gentle in-app prompt to re-anchor; opt-in push.

## Open decisions
1. **Multiple income sources** (salary + freelance simultaneously) — support in v1, or single primary
   recurring + one-off inflows first? (Lean: single + one-offs first; multi is P-later.)
2. **Irregular prediction:** rolling average of recent inflows vs. no prediction at all? (Lean:
   rolling average, clearly labeled "estimate.")
3. **Storage shape:** structured fields on `UserProfile` vs. a new `IncomeSource` @Model (needed if we
   do multiple sources).
4. **Nudge channel:** in-app-only for v1 vs. opt-in push from the start.
