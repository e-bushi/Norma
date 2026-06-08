-- Lock down the Plaid access_token column.
--
-- plaid_items.access_token grants programmatic access to a user's bank data via
-- Plaid. Only Cortex needs it, and Cortex uses the service-role key (which
-- bypasses RLS and column grants). The iOS client only ever reads the
-- non-secret columns (see SupabaseService+Plaid.swift: fetchPlaidItems selects
-- id, user_id, item_id, created_at, last_synced_at, institution_name).
--
-- Today anon + authenticated both hold table-wide SELECT, so a logged-in client
-- could read its own row's access_token. RLS gates the row; it does NOT gate the
-- column. Replace blanket SELECT with column-scoped SELECT.

-- Remove table-wide SELECT (which includes access_token) from both client roles.
REVOKE SELECT ON public.plaid_items FROM anon, authenticated;

-- Re-grant SELECT on the non-secret columns to authenticated only. anon never
-- legitimately reads plaid_items (the app reads it only while signed in). Row
-- visibility is still governed by the existing RLS policy (auth.uid() = user_id).
GRANT SELECT (id, user_id, item_id, created_at, last_synced_at, institution_name)
  ON public.plaid_items TO authenticated;
