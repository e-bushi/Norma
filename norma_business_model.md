# Norma Business Model

## Overview
Norma is an AI-powered personal finance app focused on bill management and expense tracking, with advanced financial analysis capabilities.

## Pricing Strategy

### Base Tier: $7.99/month
**Target Users:** General consumers wanting smart bill/expense tracking

**Features:**
- Unlimited AI-powered bill and expense logging
- Bill period verification system
- Expense-to-bill linking
- Basic budgeting features
- Push notifications
- Data encryption
- Multi-currency support

**AI Model Strategy:** Cascading availability (Sonnet 4 → Haiku 3.5)
- Primary: Claude Sonnet 4 ($3/MTok input, $15/MTok output)
- Fallback: Claude Haiku 3.5 ($0.80/MTok input, $4/MTok output)
- Automatic fallback during high-demand periods

### Pro Tier: $14.99/month
**Target Users:** Power users wanting comprehensive financial insights

**Features:**
- Everything in Base Tier
- **Financial Mind**: AI-powered personal finance analyst
- Deep financial data analysis via MCP database integration
- Personalized spending insights and recommendations
- Cash flow predictions
- Advanced budgeting optimization
- Priority customer support

**AI Model Strategy:** Claude Opus for Financial Mind
- Pro analysis: Claude Opus ($15/MTok input, $75/MTok output)
- Rate limited: 5-10 deep analysis sessions per month
- All other features use Base Tier model cascade

## Cost Analysis

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

### Competitive Analysis
- **YNAB:** $14/month (manual entry, no AI)
- **Mint:** Free (ad-supported, basic features)
- **PocketGuard:** $7.99/month (limited AI features)

### Value Propositions
- **Base Tier:** "Smart bill tracking with AI" - undercuts YNAB while offering AI
- **Pro Tier:** "Your personal AI financial advisor" - unique market position

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

## Target Customer Avatars

### Primary Avatar: "The Overwhelmed Professional"

**Demographics:**
- Age: 28-42
- Income: $50k-$120k
- Location: Urban/suburban areas
- Tech comfort: High
- Occupation: Mid-level professionals, managers, freelancers

**Psychographics:**
- **Primary Pain Point:** Constantly anxious about missing bill payments despite having sufficient income
- **Behavior Patterns:** 
  - Juggles 10-20+ recurring bills (subscriptions, utilities, loans, insurance)
  - Often travels or has irregular schedule
  - Uses multiple financial accounts
- **Core Values:** Automation, peace of mind, financial control, time savings
- **Key Fears:** Late fees, credit score damage, financial chaos, forgetting important payments

**Why They Choose Norma:**
- Don't need complex budgeting systems (YNAB is overkill)
- Want "set and forget" bill management
- AI logging saves precious time
- Notifications prevent costly mistakes
- Bill period verification reduces monthly anxiety

### Secondary Avatar: "The Financial Optimizer"

**Demographics:**
- Age: 25-35
- Income: $75k-$150k+
- Often in tech, finance, or consulting
- Early adopters of financial technology

**Psychographics:**
- **Primary Pain Point:** Wants data-driven insights beyond basic tracking
- **Behavior Patterns:**
  - Already tracks expenses meticulously
  - Seeks patterns and optimization opportunities
  - Values financial efficiency
- **Core Values:** Data transparency, optimization, cutting-edge technology
- **Key Motivations:** Maximizing financial efficiency, understanding spending patterns

**Why They Choose Pro Tier:**
- Financial Mind AI provides advanced analysis
- MCP database integration enables custom queries
- Willing to pay for sophisticated insights
- Appreciate the technical sophistication

### NOT Our Target Customer:
- **The Penny Pincher:** Seeks only free solutions, won't pay for convenience
- **The Simple Spender:** Has fewer than 5 bills, minimal financial complexity
- **The Financial Power User:** Needs full accounting, investment tracking, tax planning
- **The Cash-Only User:** Doesn't embrace digital financial tools
- **The Financially Struggling:** Can't afford subscription fees

### Key Marketing Insights:

**Messaging for Primary Avatar:**
- "Never miss another bill payment"
- "Your AI-powered bill assistant"
- "Peace of mind for $8/month"
- Focus on: Time savings, stress reduction, automation

**Messaging for Secondary Avatar:**
- "Understand your finances like never before"
- "AI-powered financial insights"
- "Your personal finance analyst"
- Focus on: Intelligence, optimization, advanced features

## Next Steps

1. **MVP Testing:** Validate Haiku 3.5 accuracy for bill/expense parsing
2. **Financial Mind Development:** Build MCP database integration
3. **Pricing Validation:** A/B test pricing tiers with beta users
4. **Market Research:** Validate premium tier demand for AI financial analysis
5. **Avatar Validation:** Interview 20-30 potential users matching these profiles
6. **Marketing Strategy:** Develop messaging specific to each avatar
