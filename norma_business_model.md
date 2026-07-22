# Norma Business Model

> **⚠ Reconciled 2026-07-17 to the RUNWAY ethos.** Positioning + audience are corrected: Norma
> answers **"how long does your money last?"** — it is **not a budget, tracker, or journal.** The
> earlier "financial journal / write it down / voice + receipt capture" framing is **retired** (those
> features were cut in the July runway-first pivot). Audience is a **psychographic — "The
> Escape-Minded"** (see the Avatar section), not a demographic. Live pricing = free to start + Norma
> Pro **$3.99/mo**.
> **Everything downstream of pricing — Cost Analysis, Revenue Projections, Unit Economics, metric
> targets — was computed on the retired $7.99/$14.99 two-tier model and is NOT current, AND assumes
> the retired journal feature set. Recompute against real $3.99 pricing + the runway product before
> trusting any number; left in place (not rewritten) to avoid inventing figures.**

## Overview
Norma turns your money into **time.** You tell it your balance and your bills; it shows your
**runway** — how many days of freedom you have — and keeps that number honest as you re-anchor.
No budgets, no categories, no dashboards. One glance tells you whether you're alright, and watching
the runway grow is the payoff. For people who want **out** — not people who want a better budget.

## Pricing Strategy

Live pricing (`mauldin.xyz/Norma`): **free to start**, **Norma Pro $3.99/month**, cancel anytime,
iPhone-only. The two-tier model below ($7.99 Base / $14.99 Pro) is **retired** — kept only as
historical reference for the AI-cost mechanics.

### Free
See your runway: enter your balance + bills → days of freedom, re-anchor anytime, forecast +
calendar of what's coming. `[NEEDS CHRIS: exact free-vs-Pro feature split — do not assume]`

### Norma Pro — $3.99/month
Everything in free, plus the deeper layer. `[NEEDS CHRIS: confirm Pro feature list against the runway
product. Candidates now that notes/expense-tracking are gone: the shareable runway card + status
tiers, runway insights (collisions / burn spikes), the what-if copilot depth, and bank-connect once
Plaid returns. The old "advanced budgeting optimization" framing is retired — Norma is not a budget.]`

> **AI model strategy (technical — likely also stale):** the original plan used a Sonnet→Haiku
> cascade for logging + Opus for deep analysis (cost lines below). Model versions and that math
> predate current pricing — verify against the app's actual current model config.

<details><summary>Retired two-tier model (historical — do not use for current planning)</summary>

### Base Tier: $7.99/month — RETIRED
**Features:** unlimited AI bill/expense logging · bill period verification · expense-to-bill linking
· basic budgeting · push notifications · encryption · multi-currency.
**AI:** Sonnet 4 → Haiku 3.5 cascade ($3/$15 → $0.80/$4 per MTok), auto-fallback on high demand.

### Pro Tier: $14.99/month — RETIRED
**Features:** everything in Base + "Financial Mind" analyst · MCP data analysis · spending insights ·
cash-flow predictions · advanced budgeting optimization · priority support.
**AI:** Opus for Financial Mind ($15/$75 per MTok), rate-limited 5–10 sessions/mo.

</details>

## Unit economics — recomputed at $3.99 (2026-07-19)

Single tier: free to start + **Norma Pro $3.99/mo**. The retired two-tier tables above are archived
in the collapsible. Two corrections to the old assumptions drive everything:

1. **Apple takes 15%, not 30%** — Norma is an indie under $1M/yr, so it qualifies for the **App Store
   Small Business Program (15% from month one).** `[NEEDS CHRIS: confirm SBP enrollment. If NOT
   enrolled, it's 30% in a subscriber's first year, 15% after — margins below roughly halve on the
   Apple line.]`
2. **RevenueCat is free** under ~$2,500/mo tracked revenue (≈ 625 paid subs), then 1%. The old flat
   1% was wrong at our scale → **$0 for the foreseeable future.**

### Per-paid-subscriber (monthly), SBP 15%
| Line | Amount |
|---|---|
| Gross | **$3.99** |
| Apple 15% (SBP) | −$0.60 |
| RevenueCat (free < $2.5k/mo) | $0.00 |
| AI — Haiku 4.5 chat, proxy + prompt caching *(est.)* | −$0.25 |
| **Contribution margin** | **≈ $3.14 (~79%)** |

- Annualized per retained sub: **≈ $37.68/yr** contribution.
- At standard 30% (if not SBP-enrolled): contribution ≈ **$2.54/mo (~64%)**.
- **AI cost is an estimate** — the current stack is one Haiku-class model for the mini-chat (rule-based
  insights use **no** LLM; Deepgram is dormant), so per-user AI is far below the retired
  Sonnet-cascade + Opus "Financial Mind" model. `[NEEDS CHRIS: real per-user token telemetry +
  confirm current Haiku 4.5 pricing.]`

### The free-tier drain (the biggest lever)
If the **free tier includes AI chat**, every free user costs ~$0.10–0.30/mo in AI with **zero
revenue.** At a free:paid ratio *R*, that's `R × freeAICost` of drag **per paid subscriber**:
- R = 10, free AI $0.15 → **−$1.50/paid sub** → contribution falls $3.14 → **~$1.64.**

This single decision moves margin more than anything else. Options: **cap free AI** (e.g. N
chats/mo), **gate AI behind Pro**, or eat it as CAC. `[NEEDS CHRIS: free-tier AI policy + expected
free:paid ratio.]`

### Break-even (fixed costs)
Fixed monthly ≈ Apple Dev ($99/yr ≈ $8.25/mo) + Supabase (~$25/mo) + misc `[NEEDS CHRIS: real infra]`
≈ **~$40–75/mo.** Break-even paid subs = fixed ÷ contribution ≈ **~15–25 subs.** The constraint is
**not** fixed cost — it's CAC and volume (below).

## Technology Stack

### AI Integration (current)
- **Single model:** Haiku 4.5 for the mini-chat, via the Supabase `anthropic-proxy` edge function
  (keeps keys server-side), with **prompt caching** to cut per-message cost.
- **No LLM for insights:** `RunwayInsightEngine` is rule-based (deterministic) — zero AI cost.
- **Deepgram (voice) dormant;** the retired Sonnet→Haiku cascade + Opus "Financial Mind" are gone.

### Revenue Infrastructure
- **RevenueCat:** subscription management — **free** under $2.5k/mo tracked revenue, 1% above.
- **Apple App Store:** **15%** via Small Business Program (indie under $1M).

## Market Positioning

Norma doesn't compete on budgeting features — it reframes the question. Everyone else answers "where
did my money go / am I on budget?" Norma answers **"how long does my money last, and am I getting
freer?"** The "competitors" are the systems the audience already abandoned, plus the anxiety of not
knowing how much freedom they've bought.

### What they tried and quit
- **Copilot / Mint / spreadsheets / their own private system** — all demanded they become a
  disciplined budgeter and maintain a system. None stuck, and none told them the one thing they
  actually wanted: *how long can I keep doing this?*
- **YNAB** — a budgeting methodology: overkill and the wrong shape for someone whose goal is escape,
  not category discipline.
- **The banking app** — shows a balance, not a runway. A number that means nothing until you do the
  math in your head.

### Value proposition
**"Know how many days your money lasts — without a budget."** Norma converts a private balance into
**runway (time),** keeps it honest with a one-tap re-anchor, and makes a growing runway feel like
progress toward freedom. The flex is time, not dollars — which is also what makes it shareable.

## Growth Strategy

### Customer Acquisition
- **Free to start + 3-day free trial** of Pro (per the live page).
- **Free tier** = `[NEEDS CHRIS: exact free-vs-Pro split]`. Whatever it includes, its AI cost is the
  key margin lever (see the free-tier drain above).

### Pricing
- **Norma Pro: $3.99/month.** Single tier. `[NEEDS CHRIS: annual plan? An annual SKU (e.g. ~$39.99,
  ~2 months free) improves cash flow + churn; not live today.]`
- The retired $7.99/$14.99 two-tier + annual figures are historical only.

### Retention Strategy
- **Re-anchoring is the habit loop** — the payday nudge + growing-runway reward pull the user back
  (see the reward system). Daily/weekly return is the real retention driver, not feature unlocks.
- **History as switching cost** — the ledger of balance observations + a growing runway streak is
  theirs; leaving resets the story.
- **The shareable runway card** (when built) doubles as organic acquisition.

## Revenue model & projections (at $3.99)

**No fabricated forecasts.** The old MAU tables assumed a two-tier price and a 70/30 split that no
longer exist. Below is the **formula** + an **illustrative scale** — plug in real conversion/churn to
get a forecast.

### The formulas
- **Gross ARR** = paidSubs × $3.99 × 12
- **Contribution ARR** = Gross ARR × ~0.79 (SBP 15%, minus est. AI; before fixed + CAC + free-tier drain)
- **LTV** = monthly contribution ($3.14) × avg lifetime months (1 ÷ monthly churn)
- **CAC payback (months)** = CAC ÷ $3.14
- **Healthy acquisition:** LTV:CAC ≥ 3 → **CAC ≤ LTV ÷ 3**

### Illustrative scale (SBP 15%, ~$3.14 contribution/sub — NOT a forecast)
| Paid subs | Gross ARR | Contribution ARR |
|---|---|---|
| 1,000 | $47,880 | ~$37,700 |
| 5,000 | $239,400 | ~$188,400 |
| 10,000 | $478,800 | ~$376,800 |
| ~20,900 | **~$1.0M** | ~$791,000 |

**The headline reality of $3.99:** hitting **$1M gross ARR needs ~21,000 paying subs** — roughly
**2× the subscriber count** the retired $7.99/$14.99 model assumed for the same ARR. Lower price →
lower friction, but the volume bar for a given revenue goal roughly doubles. Worth it only if the
lower price lifts conversion/retention enough to more than double the funnel.

### LTV by churn (at $3.14 contribution/sub)
| Monthly churn | Avg lifetime | LTV | Max CAC (LTV:CAC 3) |
|---|---|---|---|
| 4% | 25 mo | ~$78 | ~$26 |
| 6% | 16.7 mo | ~$52 | ~$17 |
| 8% | 12.5 mo | ~$39 | ~$13 |

### Inputs only Chris can supply (to turn this into a forecast)
- `[NEEDS CHRIS]` **trial → paid conversion** (3-day trial).
- `[NEEDS CHRIS]` **monthly churn** (drives LTV directly).
- `[NEEDS CHRIS]` **CAC by channel** (and whether acquisition is paid or organic/content-led).
- `[NEEDS CHRIS]` **free:paid ratio + free-tier AI policy** (the margin lever).
- `[NEEDS CHRIS]` **real per-user AI cost** + fixed infra.

## Risk Mitigation

### Margin risk
- **Free-tier AI drain** is the top variable cost risk — cap or gate free AI (see above).
- **Prompt caching + rule-based insights** already keep paid-user AI cost low; monitor per-user
  tokens as volume grows and add a usage meter before it bites (deferred proxy/meter plan).

### Market risks
- **Differentiation:** runway framing (time, not budget) is the moat — nobody else answers "how long
  does my money last?" for cash-heavy, irregular-income users.
- **Price positioning:** $3.99 is an impulse price; the risk is *volume*, not willingness to pay.
- **Platform dependency:** iPhone-only, Apple-commission exposed — SBP enrollment is load-bearing.

## Success Metrics

### Growth Metrics
- **MoM Growth Rate:** Target 10-20% month-over-month revenue growth in early stage
- **Net Revenue Retention (NRR):** Target >100% (growth from existing customers via upgrades)
- **Cohort Retention:** Track monthly cohort behavior over 12-month periods
- **Quick Ratio:** Target >4 ((New MRR + Expansion) / (Churned + Contraction))
- **Magic Number:** Target >0.75 (Quarter ARR Growth / Previous Quarter Sales & Marketing Spend)

### Unit Economics (single tier, $3.99)
- **CAC:** Target ≤ **$13–17** (so LTV:CAC ≥ 3 at 6–8% churn — see the LTV table).
- **LTV:** ~$39–78 depending on churn (not the retired $200–500 — that assumed higher ARPU).
- **LTV:CAC Ratio:** >3:1 minimum, >5:1 excellent.
- **CAC Payback Period:** Target ≤ 4 months (CAC ÷ $3.14 contribution).
- **Contribution Margin:** ~79% at SBP 15% (before free-tier drain).

### Engagement Metrics
- **Daily Active Users (DAU):** Target 40% of paying subscribers
- **Monthly Active Users (MAU):** Target 85% of paying subscribers
- **Time to Value:** Target <2 minutes to **first runway shown** (enter balance + a bill).
- **Core habit — re-anchor rate:** % of active users who re-anchor at least weekly (the lifeblood
  input; runway is fiction without it).
- **Payday-nudge → re-anchor conversion:** % of nudges that lead to a balance update.
- **Feature adoption:** income cadence set, ≥1 bill added, uses the what-if / forecast.

### Financial Health Metrics
- **Monthly Burn Rate:** Track if pre-profitable
- **Runway:** Maintain 18+ months
- **Revenue per Employee:** Target $150k+ ARR per team member
- **AI Cost per Paid Customer:** Target < **$0.40/month** (Haiku chat + caching; verify with telemetry).
- **Free-tier AI cost per free user:** Track it — this is the margin lever.
- **Support Cost per Customer:** Target <$0.50/month

### Retention & Churn Metrics
- **Monthly Churn Rate:** Target <6% (drives LTV directly — see the LTV-by-churn table).
- **Gross Dollar Retention:** Target 85%+ (revenue retained from cohort)
- **Logo Retention:** Target 90%+ annual (% of customers retained)
- **Resurrection Rate:** Target 10%+ (churned users who return)

### Conversion Metrics
- **Trial to Paid Conversion:** Target 25-30% (3-day trial).
- **Free to Paid Conversion:** the number that matters at $3.99 — `[NEEDS CHRIS: target]`.
- **Referral Rate:** Target 20%+ (the runway share card is the intended engine).

## Target Customer Avatar

Full profile: [[project_ethos_escape_minded]] (canonical). Summary:

**"The Escape-Minded."** Defined by a mindset, not income or occupation: they **measure wealth in
freedom, not totals,** and want *out* (or to stay out) — the pursuit of "fuck you money." The line is
**wants freedom vs. content on the treadmill,** not "self-funded vs. salaried."
- **Primary pain:** they can't see how much freedom they actually have. A balance is just a number;
  they want to know *how long it buys them* — and whether they're getting closer to escape.
- **Two postures, one mind:** *Building* (has income, wants out — watches runway grow toward escape
  velocity) and *Living* (off a finite pool — stays free longer). Escape isn't one-time: builders
  plan it, the already-free defend it.
- **Behavior:** quit the budgeting apps (a countdown never needed categories); often cash-heavy /
  multi-currency, so bank-sync is blind to them; want a glance, not a dashboard.
- **Core values:** freedom over optimization; reassurance over analysis; tools they never have to
  maintain.
- **Key emotional driver:** the *satisfaction of runway growing* is the hook; the *fear of running
  dry unseen* is the retention.

**Beachhead → beyond nomads:** nomads are the sharpest instance, not the definition — also
freelancers between contracts, sabbatical-takers, coast/lean-FIRE, bootstrapped founders on savings,
lumpy-income creatives, and salaried people plotting an exit.

(The earlier "budgeting-app dropout," "Overwhelmed Professional," and "Financial Optimizer" avatars
are **retired** — the first was the journal-era audience; the last two defined the user by income
bracket and an optimization job-to-be-done that never matched the product.)

### NOT our customer
- People who **want** a budget/system and happily run YNAB, Mint, or a spreadsheet.
- Optimizers who enjoy the dashboard and want investment / tax / accounting depth.
- Anyone content on the treadmill whose account refills, untouched, every payday — runway means
  little to them.

### Messaging (runway ethos — the live page still runs the retired journal copy; rewrite pending)
On-positioning:
- "know how many days your money lasts."
- "your money, measured in freedom — not a budget."
- "how much runway do you have?"
- "watch your freedom grow."
- "one number. no budget. no dashboard."

Retire (journal-era, currently live — replace on the landing page):
- "now there's a place to write it down"
- "you tried the budgeting apps. they didn't stick. but the bills still live in your head."
- "a financial journal for what's due, what's coming, and what you keep meaning to buy."
- and the older "never miss another bill payment," "your AI bill assistant," "peace of mind for $8/month."

## Next Steps

1. **Confirm the load-bearing inputs:** SBP enrollment, free-tier AI policy + free:paid ratio, real
   per-user AI cost, and fixed infra — these decide whether the $3.14 contribution holds.
2. **Instrument the funnel:** trial→paid, free→paid, monthly churn, re-anchor rate. Nothing here
   becomes a forecast until these are measured.
3. **Decide the free-tier AI cap/gate** before free-user volume makes it a real drain.
4. **Pricing validation:** test $3.99 vs. an annual SKU with real cohorts.
5. **Avatar validation:** interview 20-30 "Escape-Minded" users (`product_validation_playbook.md`).
6. **Marketing:** runway-first messaging (`marketing/norma-landing-copy.md`).
