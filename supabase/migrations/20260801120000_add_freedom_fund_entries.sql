-- Freedom-fund ledger, mirrored server-side. The client stays local-first
-- (SwiftData is the read path); every local insert/delete pushes here, and
-- login pulls the full ledger back down. This is what makes the ledger
-- survive logout — local data is wiped on sign-out.

create table if not exists public.freedom_fund_entries (
    id uuid primary key,
    user_id uuid not null references auth.users (id) on delete cascade,
    created_at timestamptz not null default now(),
    delta numeric not null,
    balance_after numeric not null,
    source text not null default 'manualEdit'
);

create index if not exists freedom_fund_entries_user_created_idx
    on public.freedom_fund_entries (user_id, created_at desc);

alter table public.freedom_fund_entries enable row level security;

create policy "Users can view own fund entries"
    on public.freedom_fund_entries for select
    using (auth.uid() = user_id);

create policy "Users can insert own fund entries"
    on public.freedom_fund_entries for insert
    with check (auth.uid() = user_id);

create policy "Users can update own fund entries"
    on public.freedom_fund_entries for update
    using (auth.uid() = user_id);

create policy "Users can delete own fund entries"
    on public.freedom_fund_entries for delete
    using (auth.uid() = user_id);
