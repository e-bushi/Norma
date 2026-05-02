# Product Validation Playbook

A practical guide for solo / indie developers taking a consumer app from "I built something" to "this is a business." Opinionated, prescriptive, designed to be followed in order.

---

## The single most important question

**Does this become a daily habit?**

Without daily usage, no price works. Word-of-mouth dies. Paid acquisition is unprofitable. Validation comes in two layers: do they *use* it, and do they *pay* for it. Build the funnel to test both — but use first, payment second. They're not the same signal.

---

## Phase 1 — Build the funnel

### Landing page

- Optimize for *qualification*, not signup volume. 50 deeply qualified beats 500 random.
- Lead with **one specific scenario**, not a feature grid. Show the moment that makes the product matter.
- Ask **one qualifying question** on signup beyond email — e.g. "what do you currently use to do X?" — both filters and seeds your interview pipeline.

### Waitlist

- Keep it small. The signal you want is "right user, right pain."
- Don't dump the whole list at once when you launch. Invite in waves of 5–10 so you can actually pay attention to each cohort.

### Email warm-up sequence

Between waitlist signup and beta invite, send 2–3 emails:

1. Welcome + the thinking behind the product
2. A scenario / story that primes the value
3. "You're in this week, here's what to expect"

Cold invites convert at ~30%. Warmed invites hit 60–70%.

### Distribution

- **iOS:** TestFlight (public link supports up to 10,000 testers, internal testing for closer cohort)
- **Android:** Play Console internal testing or Firebase App Distribution
- **Web:** invite-only signup with a code

---

## Phase 2 — Run the closed beta

### Send the first invite the moment you have qualified signups

Don't batch. Don't wait for a "round number" cohort. The moment you have 3–5 qualified waitlist signups, invite them. Add subsequent waves as they come in. Each wave runs against a slightly improved version of the product because you fixed what the previous wave surfaced.

If signups are coming in slowly, that itself is information — your landing page or channel isn't qualifying the right users. Diagnose during the slow ramp; don't just wait it out.

### Set positioning in the invite email, not the app

Frame what the product is in 1–2 sentences before they download. This isn't a feature walkthrough — it's the *frame* they need to know what they're looking at when they open it. Example: *"It's a financial journal — you write what's happening in plain English, the AI catches the money parts."* Enough orientation to start, not so much that you preempt their natural discovery.

### Don't walk users through features

This feels generous and helpful. It's the most damaging thing you can do to your beta data.

A walkthrough makes activation look better than it actually is — you demo the magic moment, the user goes "oh wow," you mark them activated, they never come back. They activated to *the demo you gave*, not to the product. You've trained yourself to think the onboarding works because **you** are the onboarding.

The whole point of beta is to find where the in-app experience fails users who have no help. Smoothing those failures over with personal demos throws away your most valuable data.

### Then step back

After the invite goes out: no nudges, no "did you use it today?" emails. The product needs to survive without you pushing it.

If it doesn't, that's a finding. Habit products that need constant prompting from the founder don't scale.

### After ~3 days of unaided use, schedule the call

Wait until they've used (or not used) the app for 3–5 days unaided. Then book a 20-minute structured call. Four parts:

**Part 1 — Real usage context (~2 min)**
*"Walk me through the last few times you opened the app this week."*
Their words for their own behavior — gold for positioning.

**Part 2 — Live behavioral observation (~8 min)**
Give them 1–2 realistic tasks based on their actual life: *"You bought coffee this morning. Show me how you'd add that right now."* Watch them attempt it.

When they stumble, the magic question: **"What did you expect to happen?"** Their wrong assumption tells you exactly what to fix.

**Critical rule:** never ask hypothetical questions like *"what would you do if..."* — those get socially desirable answers about an idealized self. Always ask them to actually do it in front of you.

**Part 3 — Strategic context (~8 min)**
The five questions that surface positioning, alternatives, and viral potential:

1. What were you doing right before opening the app the last time?
2. What problem were you trying to solve?
3. What were you using before this?
4. If it went away tomorrow, what would you replace it with?
5. Who else do you know who needs this?

Question 5 is the viral signal in disguise. If they can't name anyone, you have a market problem features won't fix.

**Part 4 — Open mic (~2 min)**
*"Anything else on your mind?"* Lets them surface what your structured questions missed.

### Don't rescue them when stuck

The instinct to help when a user is frustrated is what destroys the data. Sit with the silence. Watch them work through it (or not). The stuck point IS the data.

If they're truly about to abandon the app entirely, you can step in — but ask yourself first: *would a stranger who downloaded this from the App Store get unstuck?* If no, the product needs a fix, not a save.

### The kill switch on guidance

If you find yourself doing extensive 1:1 onboarding for every user just to get them to "get it," that's a product problem, not a hand-holding problem. Note where they got stuck — that's your activation roadmap.

---

## Phase 3 — Metrics that matter

### Quantitative (in priority order)

| Metric | Target | What it tells you |
|---|---|---|
| **Day-2 return rate** | 50%+ | Earliest churn signal. <30% = onboarding broken |
| **Week-4 retention** | 30%+ | Make-or-break for habit products |
| **DAU/WAU ratio** | 50%+ | "WhatsApp-tier" engagement |
| **Sessions per active user** | Trending UP | Real value vs. novelty fade |
| **Activation rate** | 60%+ | % of installs completing the core action once |

### Qualitative (more important than quant at this scale)

- **Sean Ellis test** — at ~30 users, ask: *"How would you feel if you could no longer use this?"* If **40%+ say "very disappointed,"** you have product-market fit. This is the metric Superhuman, Slack, and HubSpot used to know they were ready to scale.
- **Unprompted referrals** — did anyone ask to invite a friend without you bringing it up? Even one or two is stronger signal than 100 thumbs-ups.
- **Their language** — pay obsessive attention to how users describe your product unprompted. *"It's like X but Y"* and the literal sentences they use become your future positioning copy.

### Vanity metrics to ignore

Signup count. Total entries created across all users. Total API calls. These go up by default. Only retention curves and per-user behavior tell you the truth.

---

## Phase 4 — Habit formation timeline

| Timeframe | What you learn |
|---|---|
| **Day 1–2** | Did they activate? (opened, completed core action) |
| **Day 3–7** | Who churned? Day-2 return is the leading indicator. |
| **Day 7–14** | Does the cohort retain? Sessions trending up or down? |
| **Day 21–30** | **The habit signal.** Week-4 retention 30%+ on a daily product = real |

**You know who's gone within 5 days. You don't know who's stuck until 3–4 weeks.** Don't make pricing or scaling decisions before the 30-day mark.

### Behavioral signals beyond "did they open the app"

- **Time-of-day clustering** — habits anchor to triggers ("after lunch," "before bed"). Random distribution = no habit yet.
- **Return after a gap** is stronger than perfect streaks. "I missed it" beats gamified daily-streak compulsion.
- **Active creation vs. passive viewing** — track the ratio. Real habits are creation-driven.

---

## Phase 5 — Pricing strategy

### Don't price on day zero

A free user telling you "I'd totally pay $X/mo" is the noisiest signal in product. The credit card is the only honest one.

But: "wait six months to charge" usually becomes "charge never." The longer you train a cohort on free, the harder the wall is to put up.

### The right window: 2–3 weeks after first beta

Long enough to fix obvious bugs and onboarding friction. Short enough that you don't anchor users to free.

### Founder's pricing

- Small price (e.g. $5/mo or $50 lifetime), capped (e.g. first 200 buyers), framed as "founding member."
- The cap creates urgency. The low price filters who actually values it. The framing means you're not locked into a permanent low price.
- **The first 10 paying users teach you more than the next 1000 free users would.**

### Eventually: standard pricing

Set retail once you have real cost-per-active-user data. Grandfather the founder cohort.

### The trap

Charging $X/mo on day one to "validate." You'll get 5 buyers, conclude either "people will pay" or "no one will pay," and both conclusions will be wrong because the sample is your immediate network and the product is still becoming itself.

---

## Phase 6 — Measuring cost per user

No single SaaS does this end-to-end for an indie app. You assemble it.

### Recommended stack

- **LLM costs:** [Helicone](https://helicone.ai) — proxy in front of OpenAI/Anthropic that logs cost per user via custom header. Free tier covers most beta volume.
- **Third-party services** (Plaid, Twilio, etc.): their dashboards + a manual cross-reference spreadsheet. Don't over-build at <100 users.
- **Revenue:** RevenueCat (iOS subscriptions), Stripe (web)
- **Infrastructure** (Supabase, Firebase, etc.): treat as fixed cost until 1000+ users
- **Product analytics:** [PostHog](https://posthog.com) (free up to 1M events/mo) for retention curves

### Skip these

Datadog, Vantage, or any "FinOps" platform. Built for AWS-heavy startups burning $10k+/mo. They'll cost more than your actual variable spend at indie scale.

### The number that matters

Per-user net contribution = (revenue per user) − (variable cost per user). If it's negative, no amount of growth fixes the business. Get this positive before you scale acquisition.

---

## Phase 7 — Kill criteria

**Pre-commit to these so you don't lie to yourself later.**

| Threshold | What it means |
|---|---|
| Week-4 retention <10% | Product fundamentally doesn't work — pivot or kill |
| <30% of users complete core action 5+ times | Activation broken — fix before opening gates wider |
| DAU/WAU stays <25% | It's a "sometimes" tool, not a habit. Positioning needs to change. |
| Sean Ellis "very disappointed" <20% | No PMF signal — significant changes needed |
| Net contribution per user negative at scale | Unit economics broken — fix costs or raise prices |

If two or more thresholds are missed at week 4, you have hard data that the current shape isn't working. Don't power through.

---

## Self-test: are you using your own app?

Tricky for founders because you're in the app daily as a developer.

The honest tests:

1. **Track personal entries SEPARATE from test entries.** Only count what you made because you needed to, not because you wanted to test something.
2. **Did you reach for it without thinking "I should test this"?** Reflexive use, not deliberate.
3. **Two-week gap test.** Stop touching the codebase for two weeks. Do you still open the app on day 10?

If you've been building for months and aren't using it daily for real, that's a finding worth taking seriously. The product might be for someone slightly different than you, or there's friction you've been engineering around without noticing.

---

## The traps to avoid (summary)

- **Vanity metrics** — they go up by default and tell you nothing
- **Pricing too early** — you're guessing without retention data
- **Pricing too late** — "I'll add a paywall once it's good" usually becomes never
- **Free-forever** — the noisiest signal in product
- **High-touch forever** — needing 1:1 onboarding for every user is a product problem, not a hand-holding one
- **Powering through bad metrics** — week-4 retention <10% won't fix itself with one more feature

---

## TL;DR

1. Small qualified waitlist > big random one
2. Send the first invite the moment you have 3–5 qualified signups; add waves as they arrive — don't batch
3. Set positioning in the invite email; **no feature walkthroughs** — you are not the onboarding
4. After 3–5 days of unaided use, run a 20-min call: live observation ("show me, don't tell me") + the 5 strategic questions
5. Day-2 return tells you who's gone in days; week-4 retention tells you who's stuck in weeks
6. Charge after 2–3 weeks of fixing obvious onboarding bugs, not before, not after
7. Founder's pricing first, retail later
8. The Sean Ellis test (40%+ "very disappointed") is the canonical PMF signal
9. Pre-commit to kill criteria so you can read your own data honestly
