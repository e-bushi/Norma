-- Server mirrors for user-authored SwiftData content: note tokens (reminders,
-- intentions, commitments, bill chips) and confirmed receipt transactions.
-- Local stays the read path; UserContentSync mirrors local state up and
-- restores it after the post-logout wipe. Insights are NOT mirrored — they
-- regenerate from this data.

create table if not exists public.note_tokens (
    id uuid primary key,
    user_id uuid not null references auth.users (id) on delete cascade,
    kind text not null,
    amount numeric not null default 0,
    currency text not null default 'USD',
    usd_equivalent numeric,
    category text,
    subject text,
    counterparty text,
    recurrence text,
    occurred_at timestamptz not null,
    source_start integer not null default 0,
    source_end integer not null default 0,
    is_provisional boolean not null default false,
    remind_at timestamptz,
    confirmed_at timestamptz,
    bill_id text,
    user_adjusted_at timestamptz
);

create index if not exists note_tokens_user_idx
    on public.note_tokens (user_id, occurred_at desc);

alter table public.note_tokens enable row level security;

create policy "Users can view own note tokens"
    on public.note_tokens for select using (auth.uid() = user_id);
create policy "Users can insert own note tokens"
    on public.note_tokens for insert with check (auth.uid() = user_id);
create policy "Users can update own note tokens"
    on public.note_tokens for update using (auth.uid() = user_id);
create policy "Users can delete own note tokens"
    on public.note_tokens for delete using (auth.uid() = user_id);

create table if not exists public.captured_transactions (
    id uuid primary key,
    user_id uuid not null references auth.users (id) on delete cascade,
    amount numeric not null,
    currency text not null default 'USD',
    merchant text,
    transaction_date timestamptz not null,
    raw_text text,
    confirmed_at timestamptz not null
);

create index if not exists captured_transactions_user_idx
    on public.captured_transactions (user_id, transaction_date desc);

alter table public.captured_transactions enable row level security;

create policy "Users can view own captured transactions"
    on public.captured_transactions for select using (auth.uid() = user_id);
create policy "Users can insert own captured transactions"
    on public.captured_transactions for insert with check (auth.uid() = user_id);
create policy "Users can update own captured transactions"
    on public.captured_transactions for update using (auth.uid() = user_id);
create policy "Users can delete own captured transactions"
    on public.captured_transactions for delete using (auth.uid() = user_id);
