-- Psychological Profile Tables for Supabase
-- Add these to your existing Supabase schema

-- Money Personality table
CREATE TABLE money_personalities (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category TEXT NOT NULL,
    primary_trait TEXT NOT NULL,
    subconscious TEXT NOT NULL,
    patterns JSONB NOT NULL DEFAULT '[]'::jsonb,
    strengths JSONB NOT NULL DEFAULT '[]'::jsonb,
    growth_areas JSONB NOT NULL DEFAULT '[]'::jsonb,
    psychological_barriers JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Financial Health Insights table
CREATE TABLE financial_health_insights (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    score INTEGER NOT NULL CHECK (score >= 0 AND score <= 100),
    trend TEXT NOT NULL CHECK (trend IN ('improving', 'declining', 'stable')),
    psychological_barriers JSONB NOT NULL DEFAULT '[]'::jsonb,
    assessment_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for better performance
CREATE INDEX idx_money_personalities_user_id ON money_personalities(user_id);
CREATE INDEX idx_money_personalities_created_at ON money_personalities(created_at);
CREATE INDEX idx_financial_health_insights_user_id ON financial_health_insights(user_id);
CREATE INDEX idx_financial_health_insights_created_at ON financial_health_insights(created_at);
CREATE INDEX idx_financial_health_insights_score ON financial_health_insights(score);

-- Row Level Security (RLS) policies
ALTER TABLE money_personalities ENABLE ROW LEVEL SECURITY;
ALTER TABLE financial_health_insights ENABLE ROW LEVEL SECURITY;

-- Policies for money_personalities
CREATE POLICY "Users can view their own money personality" ON money_personalities
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own money personality" ON money_personalities
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own money personality" ON money_personalities
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own money personality" ON money_personalities
    FOR DELETE USING (auth.uid() = user_id);

-- Policies for financial_health_insights
CREATE POLICY "Users can view their own financial health insights" ON financial_health_insights
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own financial health insights" ON financial_health_insights
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own financial health insights" ON financial_health_insights
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own financial health insights" ON financial_health_insights
    FOR DELETE USING (auth.uid() = user_id);

-- Triggers for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_money_personalities_updated_at 
    BEFORE UPDATE ON money_personalities 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_financial_health_insights_updated_at 
    BEFORE UPDATE ON financial_health_insights 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Comments for documentation
COMMENT ON TABLE money_personalities IS 'Stores user psychological money personality profiles from AI analysis';
COMMENT ON TABLE financial_health_insights IS 'Stores financial psychological health scores and trends';

COMMENT ON COLUMN money_personalities.category IS 'Money personality category (e.g., "The Anxious Saver")';
COMMENT ON COLUMN money_personalities.primary_trait IS 'Primary psychological trait (e.g., "Security-Driven")';
COMMENT ON COLUMN money_personalities.subconscious IS 'Subconscious money mantra or belief';
COMMENT ON COLUMN money_personalities.patterns IS 'Array of observed behavioral patterns';
COMMENT ON COLUMN money_personalities.strengths IS 'Array of financial strengths';
COMMENT ON COLUMN money_personalities.growth_areas IS 'Array of areas for improvement';
COMMENT ON COLUMN money_personalities.psychological_barriers IS 'Array of psychological barriers';

COMMENT ON COLUMN financial_health_insights.score IS 'Psychological health score from 0-100';
COMMENT ON COLUMN financial_health_insights.trend IS 'Current trend: improving, declining, or stable';
COMMENT ON COLUMN financial_health_insights.assessment_data IS 'JSON object with assessment metadata';