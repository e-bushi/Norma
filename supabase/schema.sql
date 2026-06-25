-- Norma Database Schema
-- Generated from Supabase project: tafoviioqavefsyxskpo
-- Updated: 2026-02-06

-- ============================================================================
-- EXTENSIONS
-- ============================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "vector" WITH SCHEMA extensions;

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$function$;

-- Function to auto-update challenge_stats updated_at
CREATE OR REPLACE FUNCTION public.update_challenge_stats_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$function$;

-- Function to get monthly income from settings JSON
CREATE OR REPLACE FUNCTION public.get_monthly_income(settings_json jsonb)
RETURNS numeric
LANGUAGE plpgsql
IMMUTABLE
AS $function$
BEGIN
    RETURN (settings_json->>'monthly_income')::NUMERIC;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$function$;

-- Function to check if user has encryption enabled
CREATE OR REPLACE FUNCTION public.has_encryption_enabled(check_user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
    RETURN EXISTS (SELECT 1 FROM user_encryption_keys WHERE user_id = check_user_id);
END;
$function$;

-- ============================================================================
-- TABLES
-- ============================================================================

-- Profiles table
CREATE TABLE public.profiles (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL UNIQUE REFERENCES auth.users(id),
    email text NOT NULL,
    name text NOT NULL,
    profile_image_url text,
    monthly_income numeric DEFAULT 0,
    freedom_fund numeric DEFAULT 0,
    pain_point text DEFAULT ''::text,
    how_did_you_hear text,
    settings jsonb DEFAULT '{}'::jsonb,
    onboarding_insights jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

COMMENT ON COLUMN public.profiles.monthly_income IS 'User monthly after-tax income collected during onboarding';
COMMENT ON COLUMN public.profiles.freedom_fund IS 'User freedom fund/savings goal collected during onboarding';
COMMENT ON COLUMN public.profiles.pain_point IS 'User financial challenge/goal collected during onboarding';
COMMENT ON COLUMN public.profiles.how_did_you_hear IS 'Tracks how the user discovered the app (App Store, Social Media, Friend, etc.)';

-- Categories table
CREATE TABLE public.categories (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL PRIMARY KEY,
    name text NOT NULL,
    type text NOT NULL CHECK (type = ANY (ARRAY['Income'::text, 'Expense'::text, 'Both'::text])),
    icon text NOT NULL,
    color_hex text NOT NULL,
    is_system boolean DEFAULT false,
    is_active boolean DEFAULT true,
    sort_order integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Bills table (name, amount, notes, merchant are encrypted)
CREATE TABLE public.bills (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES auth.users(id),
    name text NOT NULL,                    -- encrypted
    amount text NOT NULL,                  -- encrypted (ciphertext)
    due_date date NOT NULL,
    next_due_date date,
    status text NOT NULL CHECK (status = ANY (ARRAY['Paid'::text, 'Overdue'::text, 'Scheduled'::text])),
    frequency text NOT NULL CHECK (frequency = ANY (ARRAY['Monthly'::text, 'Quarterly'::text, 'Yearly'::text])),
    category_id uuid REFERENCES public.categories(id),
    merchant text,                         -- encrypted
    reminder_days integer,
    is_reminder_on boolean DEFAULT false,
    notes text,                            -- encrypted
    is_active boolean DEFAULT true,
    verification_date date,
    paid_at timestamp with time zone,      -- most recent mark-paid time; app derives displayed paid status from this
    embedding vector(1024),                -- Voyage AI embeddings for semantic search
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

COMMENT ON COLUMN public.bills.verification_date IS 'Date when the bill was last verified for the current billing period to prevent duplicate verification prompts';
COMMENT ON COLUMN public.bills.embedding IS 'Voyage AI (voyage-finance-2) embedding vector for semantic search';

-- Income table (name, amount, notes are encrypted)
CREATE TABLE public.income (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES auth.users(id),
    name text NOT NULL,                    -- encrypted
    amount text NOT NULL,                  -- encrypted (ciphertext)
    frequency text NOT NULL CHECK (frequency = ANY (ARRAY['One Time'::text, 'Weekly'::text, 'Bi-Weekly'::text, 'Monthly'::text, 'Quarterly'::text, 'Semi-Annually'::text, 'Annually'::text])),
    source text NOT NULL,
    category_id uuid REFERENCES public.categories(id),
    start_date date NOT NULL,
    end_date date,
    notes text,                            -- encrypted
    is_active boolean DEFAULT true,
    embedding vector(1024),                -- Voyage AI embeddings for semantic search
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Budgets table (name, amount, notes are encrypted)
CREATE TABLE public.budgets (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES auth.users(id),
    name text NOT NULL,                    -- encrypted
    amount text NOT NULL,                  -- encrypted (ciphertext)
    category_id uuid REFERENCES public.categories(id),
    period text CHECK (period = ANY (ARRAY['Weekly'::text, 'Bi-Weekly'::text, 'Monthly'::text, 'Quarterly'::text, 'Annually'::text, 'Custom'::text])),
    start_date date NOT NULL,
    end_date date,
    current_spent numeric DEFAULT 0 CHECK (current_spent >= 0::numeric),
    alert_threshold numeric DEFAULT 0.8 CHECK (alert_threshold >= 0::numeric AND alert_threshold <= 1::numeric),
    notes text,                            -- encrypted
    is_active boolean DEFAULT true,
    embedding vector(1024),                -- Voyage AI embeddings for semantic search
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Expenses table (name, amount, notes, merchant, location are encrypted)
CREATE TABLE public.expenses (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES auth.users(id),
    name text NOT NULL,                    -- encrypted
    amount text NOT NULL,                  -- encrypted (ciphertext)
    expense_date timestamp with time zone DEFAULT now() NOT NULL,
    bill_id uuid REFERENCES public.bills(id),
    budget_id uuid REFERENCES public.budgets(id),
    is_recurring boolean DEFAULT false,
    recurring_frequency text CHECK (recurring_frequency = ANY (ARRAY['Daily'::text, 'Weekly'::text, 'Bi-Weekly'::text, 'Monthly'::text, 'Quarterly'::text, 'Annually'::text])),
    payment_method text CHECK (payment_method = ANY (ARRAY['Cash'::text, 'Credit Card'::text, 'Debit Card'::text, 'Bank Transfer'::text, 'Digital Wallet'::text, 'Check'::text, 'Other'::text])),
    merchant text,                         -- encrypted
    location text,                         -- encrypted
    notes text,                            -- encrypted
    tags text[] DEFAULT '{}'::text[],
    attachment_urls text[] DEFAULT '{}'::text[],
    embedding vector(1024),                -- Voyage AI embeddings for semantic search
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Money Personalities table
CREATE TABLE public.money_personalities (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES auth.users(id),
    category text NOT NULL,
    primary_trait text NOT NULL,
    subconscious text NOT NULL,
    strengths jsonb DEFAULT '[]'::jsonb NOT NULL,
    growth_areas jsonb DEFAULT '[]'::jsonb NOT NULL,
    psychological_barriers jsonb DEFAULT '[]'::jsonb NOT NULL,
    patterns jsonb DEFAULT '[]'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

COMMENT ON TABLE public.money_personalities IS 'Stores user psychological money personality profiles from AI analysis';
COMMENT ON COLUMN public.money_personalities.category IS 'Money personality category (e.g., "The Anxious Saver")';
COMMENT ON COLUMN public.money_personalities.primary_trait IS 'Primary psychological trait (e.g., "Security-Driven")';
COMMENT ON COLUMN public.money_personalities.subconscious IS 'Subconscious money mantra or belief';
COMMENT ON COLUMN public.money_personalities.strengths IS 'Array of financial strengths';
COMMENT ON COLUMN public.money_personalities.growth_areas IS 'Array of areas for improvement';
COMMENT ON COLUMN public.money_personalities.psychological_barriers IS 'Array of psychological barriers';
COMMENT ON COLUMN public.money_personalities.patterns IS 'Array of observed behavioral patterns';

-- Financial Health Insights table
CREATE TABLE public.financial_health_insights (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES auth.users(id),
    score integer NOT NULL CHECK (score >= 0 AND score <= 100),
    trend text NOT NULL CHECK (trend = ANY (ARRAY['improving'::text, 'declining'::text, 'stable'::text])),
    psychological_barriers jsonb DEFAULT '[]'::jsonb NOT NULL,
    assessment_data jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

COMMENT ON TABLE public.financial_health_insights IS 'Stores financial psychological health scores and trends';
COMMENT ON COLUMN public.financial_health_insights.score IS 'Psychological health score from 0-100';
COMMENT ON COLUMN public.financial_health_insights.trend IS 'Current trend: improving, declining, or stable';
COMMENT ON COLUMN public.financial_health_insights.assessment_data IS 'JSON object with assessment metadata';

-- User Encryption Keys table
CREATE TABLE public.user_encryption_keys (
    user_id uuid NOT NULL PRIMARY KEY REFERENCES auth.users(id),
    password_encrypted_key text NOT NULL,
    recovery_encrypted_key text NOT NULL,
    recovery_hint text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Chat Conversations table (title, messages are encrypted)
CREATE TABLE public.chat_conversations (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES auth.users(id),
    title text,                            -- encrypted
    messages text DEFAULT '[]',            -- encrypted (JSON array as ciphertext)
    embedding vector(1024),                -- Voyage AI embeddings for semantic search
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Challenges table
CREATE TABLE public.challenges (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES auth.users(id),
    amount_total numeric NOT NULL,
    amount_remaining numeric NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    duration_days integer DEFAULT 5,
    difficulty text DEFAULT 'medium'::text NOT NULL CHECK (difficulty = ANY (ARRAY['easy'::text, 'medium'::text, 'hard'::text])),
    points_earned integer DEFAULT 0 NOT NULL,
    currency character varying DEFAULT 'USD'::character varying,
    status character varying DEFAULT 'active'::character varying,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Challenge Stats table
CREATE TABLE public.challenge_stats (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL UNIQUE REFERENCES public.profiles(user_id),
    total_points integer DEFAULT 0 NOT NULL,
    current_streak integer DEFAULT 0 NOT NULL,
    longest_streak integer DEFAULT 0 NOT NULL,
    total_completed integer DEFAULT 0 NOT NULL,
    total_failed integer DEFAULT 0 NOT NULL,
    easy_completed integer DEFAULT 0 NOT NULL,
    medium_completed integer DEFAULT 0 NOT NULL,
    hard_completed integer DEFAULT 0 NOT NULL,
    total_days_under_cap integer DEFAULT 0,
    last_calculated_date date,
    last_challenge_date date,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- Pending Transactions table
CREATE TABLE public.pending_transactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.profiles(user_id),
    amount numeric,
    currency character varying,
    merchant text,
    transaction_date timestamp with time zone,
    raw_text text,
    created_at timestamp with time zone DEFAULT now()
);

-- User Rewards table
CREATE TABLE public.user_rewards (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES auth.users(id),
    reward_type text NOT NULL,
    metadata jsonb,
    earned_at timestamp with time zone DEFAULT now()
);

-- Monthly Stats table
CREATE TABLE public.monthly_stats (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES auth.users(id),
    month integer NOT NULL CHECK (month >= 1 AND month <= 12),
    year integer NOT NULL,
    total_spent numeric DEFAULT 0,
    arcs_added integer DEFAULT 0,
    challenges_completed integer DEFAULT 0,
    funds_left_over numeric DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Pending Rewards table
CREATE TABLE public.pending_rewards (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.profiles(user_id),
    reward_type text NOT NULL,
    reward_data jsonb,
    earned_at timestamp with time zone DEFAULT now(),
    shown_at timestamp with time zone,
    dismissed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now()
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Vector similarity search indexes (using cosine distance for Voyage embeddings)
CREATE INDEX bills_embedding_idx ON public.bills
USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

CREATE INDEX expenses_embedding_idx ON public.expenses
USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

CREATE INDEX chat_conversations_embedding_idx ON public.chat_conversations
USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_categories_updated_at
    BEFORE UPDATE ON public.categories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bills_updated_at
    BEFORE UPDATE ON public.bills
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_income_updated_at
    BEFORE UPDATE ON public.income
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_budgets_updated_at
    BEFORE UPDATE ON public.budgets
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_expenses_updated_at
    BEFORE UPDATE ON public.expenses
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_money_personalities_updated_at
    BEFORE UPDATE ON public.money_personalities
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_financial_health_insights_updated_at
    BEFORE UPDATE ON public.financial_health_insights
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_challenge_stats_updated_at
    BEFORE UPDATE ON public.challenge_stats
    FOR EACH ROW
    EXECUTE FUNCTION update_challenge_stats_updated_at();

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.income ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.money_personalities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financial_health_insights ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_encryption_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenge_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.monthly_stats ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = user_id);

-- Categories policies
CREATE POLICY "Allow authenticated users to read categories" ON public.categories FOR SELECT TO authenticated USING (true);

-- Bills policies
CREATE POLICY "Users can view own bills" ON public.bills FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own bills" ON public.bills FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own bills" ON public.bills FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own bills" ON public.bills FOR DELETE USING (auth.uid() = user_id);

-- Income policies
CREATE POLICY "Users can view own income" ON public.income FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own income" ON public.income FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own income" ON public.income FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own income" ON public.income FOR DELETE USING (auth.uid() = user_id);

-- Budgets policies
CREATE POLICY "Users can view own budgets" ON public.budgets FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own budgets" ON public.budgets FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own budgets" ON public.budgets FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own budgets" ON public.budgets FOR DELETE USING (auth.uid() = user_id);

-- Expenses policies
CREATE POLICY "Users can view own expenses" ON public.expenses FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own expenses" ON public.expenses FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own expenses" ON public.expenses FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own expenses" ON public.expenses FOR DELETE USING (auth.uid() = user_id);

-- Money Personalities policies
CREATE POLICY "Users can view their own money personality" ON public.money_personalities FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own money personality" ON public.money_personalities FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own money personality" ON public.money_personalities FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own money personality" ON public.money_personalities FOR DELETE USING (auth.uid() = user_id);

-- Financial Health Insights policies
CREATE POLICY "Users can view their own financial health insights" ON public.financial_health_insights FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own financial health insights" ON public.financial_health_insights FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own financial health insights" ON public.financial_health_insights FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own financial health insights" ON public.financial_health_insights FOR DELETE USING (auth.uid() = user_id);

-- User Encryption Keys policies
CREATE POLICY "Users can view their own encryption keys" ON public.user_encryption_keys FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own encryption keys" ON public.user_encryption_keys FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own encryption keys" ON public.user_encryption_keys FOR UPDATE USING (auth.uid() = user_id);

-- Chat Conversations policies
CREATE POLICY "Users can view own conversations" ON public.chat_conversations FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can insert own conversations" ON public.chat_conversations FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own conversations" ON public.chat_conversations FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can delete own conversations" ON public.chat_conversations FOR DELETE USING (user_id = auth.uid());

-- Challenge Stats policies
CREATE POLICY "Users can view their own challenge stats" ON public.challenge_stats FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own challenge stats" ON public.challenge_stats FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own challenge stats" ON public.challenge_stats FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete their own challenge stats" ON public.challenge_stats FOR DELETE USING (auth.uid() = user_id);

-- User Rewards policies
CREATE POLICY "Users can view own rewards" ON public.user_rewards FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own rewards" ON public.user_rewards FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Monthly Stats policies
CREATE POLICY "Users can manage own monthly stats" ON public.monthly_stats FOR ALL USING (auth.uid() = user_id);
