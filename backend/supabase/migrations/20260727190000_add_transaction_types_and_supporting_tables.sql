-- 20260727190000_add_transaction_types_and_supporting_tables.sql
--
-- MIGRATION HISTORY NOTE: this is the first file ever checked into
-- backend/supabase/migrations/. The `public.expenses` table it alters in
-- Part 2 below was created earlier by hand via the Supabase SQL editor (see
-- docs/PROJECT_CONTEXT.md session log, Session 3) and has no baseline
-- migration of its own. This file assumes that table already exists exactly
-- as shipped then: id, user_id, amount, merchant, category, date, notes,
-- source, is_expense, reason_if_not_expense, created_at, updated_at.
--
-- NAMING DECISION: the table stays `expenses` (not renamed to `transactions`)
-- and the Swift model stays `Expense` (not renamed to `Transaction`). Six
-- parallel screen-rebuild threads (Home/Ignored/Add-Edit/Insights/Account/
-- Login) branch off this same commit and call existing methods like
-- `fetchExpenses`/`addExpense` immediately — a rename would touch every call
-- site across all six branches for no functional gain. The new `type` column
-- carries the three prototype transaction kinds (expense/credit/investment)
-- within the same physical table/model.
--
-- APPLICATION NOTE: Part 1 (new tables) is additive and was applied directly.
-- Part 2 (alters `expenses`, which has real test data) was applied only after
-- explicit confirmation from Prannoy, per CLAUDE.md's live-infra caution rule.

-- ============================================================================
-- PART 1 — new, additive tables. No existing table is touched here.
-- ============================================================================

begin;

-- Recurring groups (e.g. "Rent", "Salary", "SIP - Index Fund") a transaction
-- can optionally belong to.
create table public.expense_groups (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  type text not null check (type in ('expense', 'credit', 'investment')),
  recurring boolean not null default false,
  cat_ref text,
  created_at timestamptz not null default now()
);

alter table public.expense_groups enable row level security;

create policy "Users can view own expense groups" on public.expense_groups
  for select using (auth.uid() = user_id);
create policy "Users can insert own expense groups" on public.expense_groups
  for insert with check ((select auth.uid()) = user_id);
create policy "Users can update own expense groups" on public.expense_groups
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete own expense groups" on public.expense_groups
  for delete using ((select auth.uid()) = user_id);

create index idx_expense_groups_user_id on public.expense_groups (user_id);
create index idx_expense_groups_type on public.expense_groups (type);

-- Per-user categories. Defaults are seeded (see function below); users can
-- add custom ones on top.
create table public.categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  type text not null check (type in ('expense', 'credit', 'investment')),
  color_bg text not null,
  color_fg text not null,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  unique (user_id, type, name)
);

alter table public.categories enable row level security;

create policy "Users can view own categories" on public.categories
  for select using (auth.uid() = user_id);
create policy "Users can insert own categories" on public.categories
  for insert with check ((select auth.uid()) = user_id);
create policy "Users can update own categories" on public.categories
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete own categories" on public.categories
  for delete using ((select auth.uid()) = user_id);

create index idx_categories_user_id on public.categories (user_id);
create index idx_categories_type on public.categories (type);

-- Seeds the mockup's default CATS/CAT_COLORS (design/mockups/Expense Tracker.dc.html
-- lines 636-648) for one user. Called by the new-user trigger below, and once
-- directly for the user who already existed before this migration.
create or replace function public.seed_default_categories(target_user_id uuid)
returns void
language sql
as $$
  insert into public.categories (user_id, name, type, color_bg, color_fg, is_default)
  values
    (target_user_id, 'Food', 'expense', '#CCE8D5', '#0E4B24', true),
    (target_user_id, 'Transport', 'expense', '#DCEEFA', '#0B4A7A', true),
    (target_user_id, 'Shopping', 'expense', '#F2DEF2', '#5E1E5E', true),
    (target_user_id, 'Bills', 'expense', '#FDE6D1', '#7A3A05', true),
    (target_user_id, 'Travel', 'expense', '#DAE5FF', '#142C7A', true),
    (target_user_id, 'Entertainment', 'expense', '#F2DCFA', '#58127A', true),
    (target_user_id, 'Health', 'expense', '#D6F1EC', '#0A5A4E', true),
    (target_user_id, 'Other', 'expense', '#E2E2E2', '#221F1F', true),
    (target_user_id, 'Salary', 'credit', '#CCE8D5', '#0E4B24', true),
    (target_user_id, 'Freelance', 'credit', '#DCEEFA', '#0B4A7A', true),
    (target_user_id, 'Interest', 'credit', '#D0F0E6', '#0E5A43', true),
    (target_user_id, 'Refund', 'credit', '#FFE6E8', '#8E0A18', true),
    (target_user_id, 'Cashback', 'credit', '#E4EFD1', '#3C5A09', true),
    (target_user_id, 'Other', 'credit', '#E2E2E2', '#221F1F', true),
    (target_user_id, 'SIP / Mutual Fund', 'investment', '#DAE5FF', '#142C7A', true),
    (target_user_id, 'Stocks', 'investment', '#F2DCFA', '#58127A', true),
    (target_user_id, 'Fixed Deposit', 'investment', '#FDE6D1', '#7A3A05', true),
    (target_user_id, 'PPF', 'investment', '#D6F1EC', '#0A5A4E', true),
    (target_user_id, 'Other', 'investment', '#E2E2E2', '#221F1F', true)
  on conflict (user_id, type, name) do nothing;
$$;

-- Auto-seed defaults for every new signup going forward.
create or replace function public.handle_new_user_categories()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.seed_default_categories(new.id);
  return new;
end;
$$;

create trigger on_auth_user_created_seed_categories
  after insert on auth.users
  for each row execute function public.handle_new_user_categories();

-- Backfill for the one real user who already existed before this migration
-- (the trigger above only fires for signups going forward).
select public.seed_default_categories('fd750254-4858-42d5-94ba-244adc91fa59');

-- Connected Gmail accounts. This is the Phase 2 table already specced in
-- docs/PROJECT_CONTEXT.md section 4, pulled forward into this migration
-- (scope decision — see docs/PROJECT_CONTEXT.md session log for this session).
create table public.connected_accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  email text not null,
  provider text not null default 'gmail',
  status text not null default 'connected' check (status in ('connected', 'syncing', 'error', 'disconnected')),
  -- SECURITY FOLLOW-UP: access_token/refresh_token are plaintext columns.
  -- No Gmail OAuth writer exists yet (that's Phase 3), so nothing real is
  -- stored here today, but before Phase 3 ships these must be encrypted
  -- (Supabase Vault / pgsodium, or app-layer encryption before insert) rather
  -- than relying on RLS alone to protect live OAuth tokens.
  access_token text,
  refresh_token text,
  created_at timestamptz not null default now(),
  unique (user_id, email)
);

alter table public.connected_accounts enable row level security;

create policy "Users can view own connected accounts" on public.connected_accounts
  for select using (auth.uid() = user_id);
create policy "Users can insert own connected accounts" on public.connected_accounts
  for insert with check ((select auth.uid()) = user_id);
create policy "Users can update own connected accounts" on public.connected_accounts
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete own connected accounts" on public.connected_accounts
  for delete using ((select auth.uid()) = user_id);

create index idx_connected_accounts_user_id on public.connected_accounts (user_id);

-- Notification preferences, one row per user.
create table public.notification_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  new_transaction_enabled boolean not null default true,
  budget_alert_enabled boolean not null default false
);

alter table public.notification_preferences enable row level security;

create policy "Users can view own notification preferences" on public.notification_preferences
  for select using (auth.uid() = user_id);
create policy "Users can insert own notification preferences" on public.notification_preferences
  for insert with check ((select auth.uid()) = user_id);
create policy "Users can update own notification preferences" on public.notification_preferences
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete own notification preferences" on public.notification_preferences
  for delete using ((select auth.uid()) = user_id);

commit;

-- ============================================================================
-- PART 2 — alters the existing `expenses` table (real test data). Requires
-- explicit confirmation before running against the live project.
-- ============================================================================

begin;

alter table public.expenses
  add column type text not null default 'expense'
    check (type in ('expense', 'credit', 'investment'));

-- The old constraint only ever allowed the 8 hardcoded expense categories.
-- Now that a row can be an expense, credit, or investment — each with its own
-- category list, seeded per-user into the new `categories` table above — a
-- single static list can't validate every row. Category correctness moves to
-- the app layer (validated against `categories` for the row's `type`) instead
-- of a DB check constraint.
alter table public.expenses
  drop constraint expenses_category_check;

create index idx_expenses_type on public.expenses (type);

alter table public.expenses
  add column group_id uuid references public.expense_groups(id) on delete set null;

create index idx_expenses_group_id on public.expenses (group_id);

commit;
