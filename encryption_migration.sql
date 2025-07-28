-- Norma Encryption Migration
-- Phase 1: Add encryption infrastructure without breaking existing functionality

-- 1. Create table for storing encrypted master keys
CREATE TABLE IF NOT EXISTS user_encryption_keys (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    password_encrypted_key TEXT NOT NULL,
    recovery_encrypted_key TEXT NOT NULL,
    recovery_hint TEXT, -- Optional hint like "Starts with apple-dog-..."
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Add encryption columns to expenses table
ALTER TABLE expenses 
ADD COLUMN IF NOT EXISTS encrypted_name TEXT,
ADD COLUMN IF NOT EXISTS encrypted_amount TEXT,
ADD COLUMN IF NOT EXISTS is_encrypted BOOLEAN DEFAULT FALSE;

-- 3. Add encryption columns to budgets table
ALTER TABLE budgets
ADD COLUMN IF NOT EXISTS encrypted_name TEXT,
ADD COLUMN IF NOT EXISTS is_encrypted BOOLEAN DEFAULT FALSE;

-- 4. Add encryption columns to bills table (if you want to encrypt bill names too)
ALTER TABLE bills
ADD COLUMN IF NOT EXISTS encrypted_name TEXT,
ADD COLUMN IF NOT EXISTS is_encrypted BOOLEAN DEFAULT FALSE;

-- 5. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_expenses_is_encrypted ON expenses(is_encrypted);
CREATE INDEX IF NOT EXISTS idx_budgets_is_encrypted ON budgets(is_encrypted);
CREATE INDEX IF NOT EXISTS idx_bills_is_encrypted ON bills(is_encrypted);

-- 6. Create a view to track migration progress
CREATE OR REPLACE VIEW encryption_migration_progress AS
SELECT 
    'users' as entity_type,
    COUNT(*) as total_count,
    COUNT(uek.user_id) as encrypted_count,
    ROUND((COUNT(uek.user_id)::DECIMAL / COUNT(*)::DECIMAL) * 100, 2) as percentage_encrypted
FROM auth.users u
LEFT JOIN user_encryption_keys uek ON u.id = uek.user_id

UNION ALL

SELECT 
    'expenses' as entity_type,
    COUNT(*) as total_count,
    COUNT(CASE WHEN is_encrypted = true THEN 1 END) as encrypted_count,
    ROUND((COUNT(CASE WHEN is_encrypted = true THEN 1 END)::DECIMAL / NULLIF(COUNT(*)::DECIMAL, 0)) * 100, 2) as percentage_encrypted
FROM expenses

UNION ALL

SELECT 
    'budgets' as entity_type,
    COUNT(*) as total_count,
    COUNT(CASE WHEN is_encrypted = true THEN 1 END) as encrypted_count,
    ROUND((COUNT(CASE WHEN is_encrypted = true THEN 1 END)::DECIMAL / NULLIF(COUNT(*)::DECIMAL, 0)) * 100, 2) as percentage_encrypted
FROM budgets

UNION ALL

SELECT 
    'bills' as entity_type,
    COUNT(*) as total_count,
    COUNT(CASE WHEN is_encrypted = true THEN 1 END) as encrypted_count,
    ROUND((COUNT(CASE WHEN is_encrypted = true THEN 1 END)::DECIMAL / NULLIF(COUNT(*)::DECIMAL, 0)) * 100, 2) as percentage_encrypted
FROM bills;

-- 7. Add RLS policies for the encryption keys table
ALTER TABLE user_encryption_keys ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own encryption keys" ON user_encryption_keys
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own encryption keys" ON user_encryption_keys
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own encryption keys" ON user_encryption_keys
    FOR UPDATE USING (auth.uid() = user_id);

-- 8. Create function to check if user has encryption enabled
CREATE OR REPLACE FUNCTION has_encryption_enabled(check_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (SELECT 1 FROM user_encryption_keys WHERE user_id = check_user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Grant necessary permissions
GRANT SELECT ON encryption_migration_progress TO authenticated;
GRANT EXECUTE ON FUNCTION has_encryption_enabled TO authenticated;