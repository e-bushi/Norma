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

## Cost Analysis

> ⚠ **STALE — computed on retired $7.99/$14.99 pricing. Not current. Recompute at free + $3.99.**

### Base Tier ($7.99/month)
- **Gross Revenue:** $7.99
- **Apple's 30% cut:** -$2.40 (first year), -$1.60 (after year 1)
- **RevenueCat 1%:** -$0.08
- **API costs (heavy user):** -$1.00 to -$3.00
- **Net Margin:** ~$4.51 to $6.51 (first year), ~$5.31 to $7.31 (after year 1)

### Pro Tier ($14.99/month)
- **Gross Revenue:** $14.99
- **Apple's 30% cut:** -$4.50 (first year), -$3.00 (after year 1)
- **RevenueCat 1%:** -$0.15
- **API costs (including Financial Mind):** -$3.00 to -$8.00
- **Net Margin:** ~$6.34 to $11.34 (first year), ~$7.84 to $12.84 (after year 1)

## Technology Stack

### AI Integration
- **Model Cascading:** Automatic fallback ensures 99.9% availability
- **Cost Optimization:** Natural cost reduction during peak API demand
- **Quality Assurance:** Best available model for optimal user experience

### Revenue Infrastructure
- **RevenueCat:** Subscription management and analytics (1% of MRR)
- **Apple App Store:** 30% first year, 15% after year 1 for subscribers
- **MCP Integration:** Custom database layer for Financial Mind feature

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
- **7-Day Free Trial:** Full access to Base Tier features
- **Freemium Alternative:** 10 AI entries/month free tier (if needed for growth)

### Pricing Options

#### Monthly Pricing
- **Base Tier:** $7.99/month
- **Pro Tier:** $14.99/month

#### Annual Pricing (Save 17%)
- **Base Tier:** $79.99/year (saves $15.89/year)
- **Pro Tier:** $149.99/year (saves $29.89/year)

**Annual Pricing Benefits:**
- Improved cash flow from upfront payments
- Higher customer lifetime value (reduced churn)
- Lower payment processing costs
- More predictable revenue forecasting

### Retention Strategy
- **Progressive Feature Unlock:** Natural upgrade path from Base to Pro
- **Financial Mind Preview:** Limited free sessions to drive Pro upgrades
- **Data Lock-in:** Comprehensive financial history creates switching costs

## Revenue Projections

### Initial Milestone: 1,500 Paying MAU
**Target Timeline: Month 12-18**

**Revenue Breakdown (70/30 split):**
- **1,050 Base Tier users:** $100,680 annual revenue
- **450 Premium Tier users:** $80,952 annual revenue
- **Total Gross ARR:** $181,632
- **MRR:** $15,136

**Unit Economics at 1,500 MAU:**
- **Net Revenue (after costs):** $107k-125k annually
- **Net Margin:** 59-69%
- **Monthly Profit:** $9,000-10,500
- **Customer Acquisition Need:** 100-125 new customers/month (10% growth)
- **CAC Budget Required:** $1,500-2,500/month

**Why This Milestone Matters:**
- Proves product-market fit
- Achieves profitability
- Validates unit economics
- Creates foundation for scaling to $1M ARR

### Growth Target: Scale Phase
**Target Timeline: Month 18-24**

- **5,000 Base Tier users:** $479,400 annual revenue  
- **1,500 Pro Tier users:** $269,820 annual revenue
- **Total:** ~$749k ARR

### Scale Scenario: 10,000 Customers
**Revenue Breakdown (70/30 split):**
- **7,000 Base Tier users:** $671,160 annual revenue
- **3,000 Premium Tier users:** $539,640 annual revenue
- **Total Gross ARR:** ~$1.21M

**Net Revenue After Costs:**
- **Monthly Net Revenue:** $56,190 - $89,690
- **Annual Net Revenue:** $674k - $1.08M
- **Gross Margins:** 55-75%

**Operational Requirements:**
- **Support Staff:** 1-2 dedicated agents (~$10-15k/month)
- **API Costs:** $7,000-$33,000/month (managed via cascading)
- **Infrastructure:** ~$1,000/month RevenueCat at this scale
- **CAC Budget:** $30-50k/month for sustained growth

**Key Success Indicators at 10K Scale:**
- **MRR:** ~$100,900
- **Sustainable Churn:** Can support 5-8% monthly churn
- **CAC Payback:** 2-3 months enables aggressive growth
- **Team Size:** 5-7 people (product, engineering, support, marketing)

## Risk Mitigation

### API Cost Management
- **Model cascading** prevents cost spikes during high demand
- **Rate limiting** on premium features controls Opus usage
- **Usage monitoring** allows real-time cost optimization

### Market Risks
- **Differentiation:** AI integration creates moat vs traditional apps
- **Pricing flexibility:** Tier structure allows market response
- **Feature expansion:** MCP architecture enables rapid feature development

## Success Metrics

### Growth Metrics
- **MoM Growth Rate:** Target 10-20% month-over-month revenue growth in early stage
- **Net Revenue Retention (NRR):** Target >100% (growth from existing customers via upgrades)
- **Cohort Retention:** Track monthly cohort behavior over 12-month periods
- **Quick Ratio:** Target >4 ((New MRR + Expansion) / (Churned + Contraction))
- **Magic Number:** Target >0.75 (Quarter ARR Growth / Previous Quarter Sales & Marketing Spend)

### Unit Economics
- **Customer Acquisition Cost (CAC):** Target $10-15 Base, $18-27 Premium
- **Lifetime Value (LTV):** Target $200+ Base, $500+ Premium
- **LTV:CAC Ratio:** Target >3:1 (minimum viable), >5:1 (excellent)
- **CAC Payback Period:** Target 2-3 months
- **Gross Margin:** Target 70-80% after all direct costs
- **Contribution Margin:** Revenue minus variable costs per customer

### Engagement Metrics
- **Daily Active Users (DAU):** Target 40% of paying subscribers
- **Monthly Active Users (MAU):** Target 85% of paying subscribers
- **Time to Value:** Target <5 minutes to first bill logged
- **Feature Adoption Rate:** 
  - Bill verification: >80% of Base users
  - Financial Mind: >60% of Premium users monthly
- **Session Duration:** Average 3-5 minutes per session
- **Actions per Session:** 2-3 meaningful actions (add bill, check expense, etc.)

### Financial Health Metrics
- **Monthly Burn Rate:** Track if pre-profitable
- **Runway:** Maintain 18+ months
- **Revenue per Employee:** Target $150k+ ARR per team member
- **API Cost per Customer:** Target <$1.50 Base, <$5 Premium
- **Support Cost per Customer:** Target <$0.50/month

### Retention & Churn Metrics
- **Monthly Churn Rate:** Target <5% Base, <3% Premium
- **Annual Churn Rate:** Target <40% Base, <30% Premium
- **Gross Dollar Retention:** Target 85%+ (revenue retained from cohort)
- **Logo Retention:** Target 90%+ annual (% of customers retained)
- **Resurrection Rate:** Target 10%+ (churned users who return)

### Conversion Metrics
- **Trial to Paid Conversion:** Target 25-30%
- **Base to Premium Upgrade Rate:** Target 15-20% within 6 months
- **Annual Plan Adoption:** Target 30%+ of customers
- **Referral Rate:** Target 20%+ of customers refer at least one user

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

1. **MVP Testing:** Validate Haiku 3.5 accuracy for bill/expense parsing
2. **Financial Mind Development:** Build MCP database integration
3. **Pricing Validation:** A/B test pricing tiers with beta users
4. **Market Research:** Validate premium tier demand for AI financial analysis
5. **Avatar Validation:** Interview 20-30 potential users matching the budgeting-app-dropout profile (use the `product_validation_playbook.md` call structure)
6. **Marketing Strategy:** Develop messaging specific to each avatar
