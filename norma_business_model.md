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

### Premium Tier: $14.99/month
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
- Premium analysis: Claude Opus ($15/MTok input, $75/MTok output)
- Rate limited: 5-10 deep analysis sessions per month
- All other features use Base Tier model cascade

## Cost Analysis

### Base Tier ($7.99/month)
- **Gross Revenue:** $7.99
- **Apple's 30% cut:** -$2.40 (first year), -$1.60 (after year 1)
- **RevenueCat 1%:** -$0.08
- **API costs (heavy user):** -$1.00 to -$3.00
- **Net Margin:** ~$4.51 to $6.51 (first year), ~$5.31 to $7.31 (after year 1)

### Premium Tier ($14.99/month)
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
- **Premium Tier:** "Your personal AI financial advisor" - unique market position

## Growth Strategy

### Customer Acquisition
- **7-Day Free Trial:** Full access to Base Tier features
- **Freemium Alternative:** 10 AI entries/month free tier (if needed for growth)
- **Annual Discounts:** $79.99/year Base, $149.99/year Premium

### Retention Strategy
- **Progressive Feature Unlock:** Natural upgrade path from Base to Premium
- **Financial Mind Preview:** Limited free sessions to drive Premium upgrades
- **Data Lock-in:** Comprehensive financial history creates switching costs

## Revenue Projections

### Conservative Estimates (Year 1)
- **1,000 Base Tier users:** $95,880 annual revenue
- **200 Premium Tier users:** $35,976 annual revenue
- **Total:** ~$132k ARR

### Growth Targets (Year 2)
- **5,000 Base Tier users:** $479,400 annual revenue  
- **1,500 Premium Tier users:** $269,820 annual revenue
- **Total:** ~$749k ARR

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

### Financial KPIs
- **Monthly Recurring Revenue (MRR)**
- **Customer Acquisition Cost (CAC)**
- **Lifetime Value (LTV)**
- **Churn rate by tier**

### Product KPIs
- **API usage patterns**
- **Feature adoption rates**
- **Financial Mind engagement**
- **Upgrade conversion rates**

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

**Why They Choose Premium Tier:**
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