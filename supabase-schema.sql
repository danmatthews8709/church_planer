-- ============================================================
-- The Church Planner — Supabase schema
-- Run this once in Supabase: Dashboard → SQL Editor → New query → paste → Run
-- ============================================================

create extension if not exists "pgcrypto"; -- for gen_random_uuid()

-- ---------- Team members (name + PIN, attribution only — not a security boundary) ----------
create table if not exists users (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  pin text not null,
  created_at timestamptz not null default now()
);

-- ---------- Audiences (Whole Church, Chapter, Leadership, named ministries) ----------
create table if not exists audiences (
  name text primary key
);

-- ---------- Tags (Small Group, Prayer, Lead Night... each carries one audience) ----------
create table if not exists tags (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  audience text not null references audiences(name) on update cascade,
  created_at timestamptz not null default now()
);

-- ---------- Recurring rhythm templates (e.g. "Small Group, every week from Sept") ----------
create table if not exists recurring_rhythms (
  id uuid primary key default gen_random_uuid(),
  tag_id uuid not null references tags(id) on delete cascade,
  note text default '',
  start_date date not null,
  end_date date, -- null = ongoing
  created_at timestamptz not null default now()
);

-- ---------- Weeks (one row per Sunday on the rhythm) ----------
create table if not exists weeks (
  id uuid primary key default gen_random_uuid(),
  occasion text default '',
  sunday_date date not null,
  sunday_series text default '',
  post_service text default '',
  week_commencing date,
  happening text default '',
  created_by text,
  created_at timestamptz not null default now(),
  unique (sunday_date)
);

-- ---------- One-off midweek activities tied to a specific week (not recurring) ----------
create table if not exists week_midweek_items (
  id uuid primary key default gen_random_uuid(),
  week_id uuid not null references weeks(id) on delete cascade,
  tag_id uuid not null references tags(id) on delete cascade,
  note text default ''
);

-- ---------- Per-week exceptions: "skip this recurring rhythm for this week only" ----------
create table if not exists week_excluded_recurring (
  week_id uuid not null references weeks(id) on delete cascade,
  recurring_id uuid not null references recurring_rhythms(id) on delete cascade,
  primary key (week_id, recurring_id)
);

-- ---------- Ad-hoc one-off/recurring events (baptisms, socials, etc.) ----------
create table if not exists events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  category text not null default 'event', -- small-group | prayer | service | event
  event_date date not null,
  recurrence text not null default 'none', -- none | weekly | monthly
  recurrence_end date,
  notes text default '',
  created_by text,
  created_at timestamptz not null default now()
);

-- ============================================================
-- Row Level Security
-- The app has no real per-user login (PIN is attribution only, same as before),
-- so every table is open to the "anon" key for read/write. This matches the exact
-- security posture of the current shared-storage version: anyone with the app link
-- can see and edit everything. Tighten these policies later if you add real auth.
-- ============================================================

alter table users enable row level security;
alter table audiences enable row level security;
alter table tags enable row level security;
alter table recurring_rhythms enable row level security;
alter table weeks enable row level security;
alter table week_midweek_items enable row level security;
alter table week_excluded_recurring enable row level security;
alter table events enable row level security;

do $$
declare
  t text;
begin
  for t in select unnest(array[
    'users','audiences','tags','recurring_rhythms',
    'weeks','week_midweek_items','week_excluded_recurring','events'
  ])
  loop
    execute format('drop policy if exists "public read" on %I', t);
    execute format('create policy "public read" on %I for select using (true)', t);
    execute format('drop policy if exists "public write" on %I', t);
    execute format('create policy "public write" on %I for insert with check (true)', t);
    execute format('drop policy if exists "public update" on %I', t);
    execute format('create policy "public update" on %I for update using (true) with check (true)', t);
    execute format('drop policy if exists "public delete" on %I', t);
    execute format('create policy "public delete" on %I for delete using (true)', t);
  end loop;
end $$;

-- ============================================================
-- Realtime — lets every open browser tab hear about changes instantly,
-- solving the "no live sync between users" gap from the artifact version.
-- ============================================================
alter publication supabase_realtime add table weeks;
alter publication supabase_realtime add table week_midweek_items;
alter publication supabase_realtime add table week_excluded_recurring;
alter publication supabase_realtime add table tags;
alter publication supabase_realtime add table audiences;
alter publication supabase_realtime add table recurring_rhythms;
alter publication supabase_realtime add table events;
alter publication supabase_realtime add table users;

-- ============================================================
-- Default seed data (tags + audiences) — safe to re-run, skips if already present
-- ============================================================
insert into audiences (name) values
  ('Whole Church'),('Chapter'),('Leadership'),
  ('Alpha Team'),('Cleaning Team'),('Connections'),('Foodbank Team'),
  ('Host'),('Kids'),('Locking Up Team'),('Production'),
  ('Toddlers/Little Treasures Team'),('Worship'),('Youth')
on conflict (name) do nothing;

insert into tags (name, audience) values
  ('Small Group','Whole Church'),
  ('Prayer','Whole Church'),
  ('Chapter Meeting','Chapter'),
  ('Lead Night','Leadership'),
  ('Margin Week','Whole Church'),
  ('Team Development','Leadership'),
  ('Meetings Week','Whole Church')
on conflict (name) do nothing;
