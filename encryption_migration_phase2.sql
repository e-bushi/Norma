-- Norma Encryption Migration Phase 2
-- Add missing encryption columns and prepare for settings encryption

-- 1. Add encrypted_amount column to bills table
ALTER TABLE bills
ADD COLUMN IF NOT EXISTS encrypted_amount TEXT;

-- 2. Add encrypted_settings column to profiles table for future use
-- This will store the entire settings JSON encrypted
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS encrypted_settings TEXT,
ADD COLUMN IF NOT EXISTS settings_encrypted BOOLEAN DEFAULT FALSE;

-- 3. Update the migration progress view to include bills amount encryption
DROP VIEW IF EXISTS encryption_migration_progress;

CREATE VIEW encryption_migration_progress AS
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
FROM bills

UNION ALL

SELECT 
    'profiles' as entity_type,
    COUNT(*) as total_count,
    COUNT(CASE WHEN settings_encrypted = true THEN 1 END) as encrypted_count,
    ROUND((COUNT(CASE WHEN settings_encrypted = true THEN 1 END)::DECIMAL / NULLIF(COUNT(*)::DECIMAL, 0)) * 100, 2) as percentage_encrypted
FROM profiles;

-- 4. Create helper function to extract monthly_income from settings JSON
-- This will be useful during migration
CREATE OR REPLACE FUNCTION get_monthly_income(settings_json JSONB)
RETURNS NUMERIC AS $$
BEGIN
    RETURN (settings_json->>'monthly_income')::NUMERIC;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 5. Grant permissions
GRANT SELECT ON encryption_migration_progress TO authenticated;