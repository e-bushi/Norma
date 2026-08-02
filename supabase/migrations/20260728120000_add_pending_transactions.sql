-- Pending transactions: receipt scans from the share extension waiting for
-- review on the runway home. The extract-transactions edge function inserts
-- (service role); the app reads and deletes rows as the user confirms or
-- discards them. Rows are transient — confirming or discarding deletes them.

CREATE TABLE public.pending_transactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.profiles(user_id) ON DELETE CASCADE,
    amount numeric,
    currency character varying,
    merchant text,
    transaction_date timestamp with time zone,
    raw_text text,
    created_at timestamp with time zone DEFAULT now()
);

CREATE INDEX pending_transactions_user_id_idx
    ON public.pending_transactions (user_id, created_at DESC);

ALTER TABLE public.pending_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own pending transactions"
    ON public.pending_transactions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own pending transactions"
    ON public.pending_transactions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own pending transactions"
    ON public.pending_transactions FOR DELETE
    USING (auth.uid() = user_id);
