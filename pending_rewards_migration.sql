-- Migration: Create pending_rewards table
-- Purpose: Store rewards that need to be shown to users, with persistence across sessions
-- Run this in Supabase SQL Editor

-- Create the pending_rewards table
CREATE TABLE IF NOT EXISTS pending_rewards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(user_id) ON DELETE CASCADE,
    reward_type TEXT NOT NULL,
    reward_data JSONB,
    earned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    shown_at TIMESTAMPTZ,
    dismissed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create index for fetching unshown rewards efficiently
CREATE INDEX IF NOT EXISTS idx_pending_rewards_user_unshown
    ON pending_rewards(user_id)
    WHERE shown_at IS NULL;

-- Create index for fetching all rewards by user
CREATE INDEX IF NOT EXISTS idx_pending_rewards_user_id
    ON pending_rewards(user_id);

-- Create index for reward type lookups
CREATE INDEX IF NOT EXISTS idx_pending_rewards_type
    ON pending_rewards(user_id, reward_type);

-- Enable Row Level Security
ALTER TABLE pending_rewards ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own rewards
CREATE POLICY "Users can view own pending rewards"
    ON pending_rewards
    FOR SELECT
    USING (auth.uid()::text = user_id::text);

-- Policy: Users can insert their own rewards
CREATE POLICY "Users can insert own pending rewards"
    ON pending_rewards
    FOR INSERT
    WITH CHECK (auth.uid()::text = user_id::text);

-- Policy: Users can update their own rewards (for marking shown/dismissed)
CREATE POLICY "Users can update own pending rewards"
    ON pending_rewards
    FOR UPDATE
    USING (auth.uid()::text = user_id::text);

-- Policy: Users can delete their own rewards
CREATE POLICY "Users can delete own pending rewards"
    ON pending_rewards
    FOR DELETE
    USING (auth.uid()::text = user_id::text);

-- Add comment for documentation
COMMENT ON TABLE pending_rewards IS 'Stores rewards pending display to users. Rewards are marked shown when presented, dismissed when user acknowledges.';
COMMENT ON COLUMN pending_rewards.reward_type IS 'The type of reward (e.g., arcEarned, challengeBeaten, streak5Days)';
COMMENT ON COLUMN pending_rewards.reward_data IS 'JSON data needed to reconstruct the reward (points, streak count, etc.)';
COMMENT ON COLUMN pending_rewards.shown_at IS 'When the reward was presented to the user (null if not yet shown)';
COMMENT ON COLUMN pending_rewards.dismissed_at IS 'When the user dismissed/acknowledged the reward (null if not yet dismissed)';
