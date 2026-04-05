-- ============================================================
-- TANYA USTADZ — COMPLETE SUPABASE SETUP
-- ============================================================

-- ============================================================
-- 1. TABLES
-- ============================================================

-- Questions table
create table if not exists questions (
  id          uuid default gen_random_uuid() primary key,
  created_at  timestamp with time zone default timezone('utc', now()) not null,
  question    text not null,
  category    text,
  status      text default 'pending',
  answer      text,
  is_pinned   boolean default false,
  upvotes     int default 0,
  ticket_id   text generated always as ('#TU-' || upper(substring(id::text from 33))) stored
);

-- Constraint: valid status values only
alter table questions
  add constraint valid_status check (
    status in ('pending', 'verified', 'rejected', 'answered')
  );

-- Constraint: question length
alter table questions
  add constraint question_max_length check (char_length(question) <= 500);

-- Constraint: answer length
alter table questions
  add constraint answer_max_length check (char_length(answer) <= 2000);

-- Constraint: valid categories
alter table questions
  add constraint valid_category check (
    category in ('Fikih', 'Akhlak & Adab', 'Keluarga', 'Muamalah', 'Umum') or category is null
  );

-- Question votes table (anti-spam upvote)
create table if not exists question_votes (
  id          uuid default gen_random_uuid() primary key,
  question_id uuid references questions(id) on delete cascade,
  fingerprint text not null,
  created_at  timestamp with time zone default now(),
  unique(question_id, fingerprint)
);

-- Profiles table (linked to Supabase auth.users)
create table if not exists profiles (
  id          uuid references auth.users on delete cascade primary key,
  full_name   text,
  email       text,
  avatar_url  text,
  role        text default null,
  constraint valid_role check (role in ('admin', 'ustadz') or role is null)
);

-- ============================================================
-- 2. TRIGGER: Auto-create profile on new Google OAuth user
-- ============================================================

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, email, avatar_url)
  values (
    new.id,
    new.raw_user_meta_data->>'full_name',
    new.email,
    new.raw_user_meta_data->>'avatar_url'
  )
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ============================================================
-- 3. TRIGGER: Sync upvotes count from question_votes
-- ============================================================

create or replace function sync_upvotes()
returns trigger as $$
begin
  if (TG_OP = 'INSERT') then
    update questions set upvotes = upvotes + 1 where id = NEW.question_id;
  elsif (TG_OP = 'DELETE') then
    update questions set upvotes = greatest(upvotes - 1, 0) where id = OLD.question_id;
  end if;
  return null;
end;
$$ language plpgsql security definer;

create trigger on_vote_change
  after insert or delete on question_votes
  for each row execute procedure sync_upvotes();

-- ============================================================
-- 4. ROW LEVEL SECURITY (RLS)
-- ============================================================

-- Enable RLS
alter table questions enable row level security;
alter table question_votes enable row level security;
alter table profiles enable row level security;

-- Drop any existing policies to avoid conflicts
drop policy if exists "Public can read answered questions" on questions;
drop policy if exists "Anyone can insert a question" on questions;
drop policy if exists "Admin can verify or reject" on questions;
drop policy if exists "Ustadz can answer" on questions;
drop policy if exists "Admin can read all questions" on questions;
drop policy if exists "Ustadz can read verified questions" on questions;
drop policy if exists "Anyone can insert vote" on question_votes;
drop policy if exists "Anyone can read votes" on question_votes;
drop policy if exists "Users can read own profile" on profiles;
drop policy if exists "Users can update own role" on profiles;
drop policy if exists "Admin and Ustadz can read all profiles" on profiles;

-- ---- QUESTIONS POLICIES ----

-- Jemaah: read only answered questions
create policy "Public can read answered questions"
  on questions for select
  using (status = 'answered');

-- Admin: read all questions (to moderate)
create policy "Admin can read all questions"
  on questions for select
  using (
    exists (
      select 1 from profiles
      where profiles.id = auth.uid()
      and profiles.role = 'admin'
    )
  );

-- Ustadz: read verified questions (to answer)
create policy "Ustadz can read verified questions"
  on questions for select
  using (
    exists (
      select 1 from profiles
      where profiles.id = auth.uid()
      and profiles.role = 'ustadz'
    )
    and status in ('verified', 'answered')
  );

-- Anyone can insert a question (Jemaah, no auth required)
create policy "Anyone can insert a question"
  on questions for insert
  with check (
    status = 'pending'
    and answer is null
    and is_pinned = false
  );

-- Admin: update status to verified or rejected ONLY (column-level restriction via with check)
create policy "Admin can verify or reject"
  on questions for update
  using (
    exists (
      select 1 from profiles
      where profiles.id = auth.uid()
      and profiles.role = 'admin'
    )
    and status != 'answered'
  )
  with check (
    status in ('verified', 'rejected')
    and answer is null  -- admin cannot fill answer
  );

-- Admin: can update is_pinned (separate policy for archive pinning)
create policy "Admin can pin questions"
  on questions for update
  using (
    exists (
      select 1 from profiles
      where profiles.id = auth.uid()
      and profiles.role = 'admin'
    )
  )
  with check (true);

-- Ustadz: update answer and set status to answered ONLY
create policy "Ustadz can answer"
  on questions for update
  using (
    exists (
      select 1 from profiles
      where profiles.id = auth.uid()
      and profiles.role = 'ustadz'
    )
    and status = 'verified'
  )
  with check (
    status = 'answered'
    and answer is not null
  );

-- ---- QUESTION_VOTES POLICIES ----

create policy "Anyone can insert vote"
  on question_votes for insert
  with check (true);

create policy "Anyone can read votes"
  on question_votes for select
  using (true);

-- ---- PROFILES POLICIES ----

create policy "Users can read own profile"
  on profiles for select
  using (auth.uid() = id);

create policy "Users can update own role"
  on profiles for update
  using (auth.uid() = id)
  with check (role in ('admin', 'ustadz'));

create policy "Admin and Ustadz can read all profiles"
  on profiles for select
  using (
    exists (
      select 1 from profiles p
      where p.id = auth.uid()
      and p.role in ('admin', 'ustadz')
    )
  );

-- ============================================================
-- 5. INDEXES (performance)
-- ============================================================

create index if not exists idx_questions_status on questions(status);
create index if not exists idx_questions_created_at on questions(created_at desc);
create index if not exists idx_questions_is_pinned on questions(is_pinned);
create index if not exists idx_question_votes_fingerprint on question_votes(fingerprint, question_id);

-- ============================================================
-- 6. REALTIME (enable publication for tables)
-- ============================================================

-- Run these in Supabase dashboard > Database > Replication
-- or via the Supabase CLI:
-- alter publication supabase_realtime add table questions;
-- alter publication supabase_realtime add table question_votes;

-- ============================================================
-- 7. EDGE FUNCTION: Auto-delete (30 days) — deploy via CLI
-- ============================================================
-- File: supabase/functions/cleanup-questions/index.ts
-- Cron schedule: "0 0 * * *" (midnight UTC every day)
-- Content is in the functions folder (see project structure)

-- ============================================================
-- DONE
-- ============================================================
